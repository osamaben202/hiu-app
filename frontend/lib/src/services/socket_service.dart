/**
 * 全局 Socket 服务
 * 整个 App 共享一个 Socket.IO 连接
 */
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'api_service.dart';

class _PendingEmit {
    final String event;
    final dynamic data;
    _PendingEmit(this.event, this.data);
}

class SocketService with ChangeNotifier {
    static final SocketService _instance = SocketService._internal();
    factory SocketService() => _instance;
    SocketService._internal();

    io.Socket? _socket;
    bool _isConnected = false;
    String? _token;
    String? _currentRoomId;

    // 事件监听器
    final Map<String, List<Function>> _listeners = {};

    // 连接成功回调
    final List<VoidCallback> _onConnectCallbacks = [];

    bool get isConnected => _isConnected;
    io.Socket? get socket => _socket;

    void init(String token) {
        _token = token;
        if (_socket != null && _isConnected && _token == token) {
            debugPrint('[SocketService] Already connected with same token');
            return;
        }
        _connect();
    }

    void _connect() {
        _socket?.dispose();

        debugPrint('[SocketService] Connecting to ${ApiService.baseHost} with websocket transport...');

        // 使用 websocket-only 传输，避免 polling 兼容性问题
        _socket = io.io(
            ApiService.baseHost,
            <String, dynamic>{
                'transports': ['websocket'],
                'autoConnect': false,
                'auth': {'token': _token},
                'reconnection': true,
                'reconnectionAttempts': 100,
                'reconnectionDelay': 2000,
                'timeout': 10000,
                'forceNew': true,
            },
        );

        _socket?.onConnect((_) {
            debugPrint('[SocketService] Connected! socket.id: ${_socket?.id}');
            _isConnected = true;
            notifyListeners();
            // 发送所有待发事件
            _flushPendingEmits();
            // 自动重新加入房间
            if (_currentRoomId != null) {
                debugPrint('[SocketService] Auto re-joining room: $_currentRoomId');
                _socket!.emit('join_room', {'room_id': _currentRoomId});
            }
            // 执行连接成功回调
            for (final cb in _onConnectCallbacks) {
                try { cb(); } catch (e) {
                    debugPrint('[SocketService] OnConnect callback error: $e');
                }
            }
            _onConnectCallbacks.clear();
        });

        _socket?.onDisconnect((_) {
            debugPrint('[SocketService] Disconnected');
            _isConnected = false;
            notifyListeners();
        });

        _socket?.onConnectError((error) {
            debugPrint('[SocketService] Connect error: $error');
            _isConnected = false;
        });

        _socket?.onError((error) {
            debugPrint('[SocketService] Error: $error');
        });

        // 注册所有持久监听器
        _setupPersistentListeners();

        _socket?.connect();
    }

    void _setupPersistentListeners() {
        _socket?.on('chat_message', (data) {
            _notifyListeners('chat_message', data);
        });

        _socket?.on('friend_request', (data) {
            debugPrint('[SocketService] Friend request received: $data');
            _notifyListeners('friend_request', data);
        });

        _socket?.on('friend_accepted', (data) {
            debugPrint('[SocketService] Friend accepted: $data');
            _notifyListeners('friend_accepted', data);
        });

        _socket?.on('seat_request', (data) {
            debugPrint('[SocketService] Seat request: $data');
            _notifyListeners('seat_request', data);
        });

        _socket?.on('seat_request_sent', (data) {
            _notifyListeners('seat_request_sent', data);
        });

        _socket?.on('seat_approved', (data) {
            _notifyListeners('seat_approved', data);
        });

        _socket?.on('seat_rejected', (data) {
            _notifyListeners('seat_rejected', data);
        });

        _socket?.on('seat_update', (data) {
            _notifyListeners('seat_update', data);
        });

        _socket?.on('user_joined', (data) {
            _notifyListeners('user_joined', data);
        });

        _socket?.on('user_left', (data) {
            _notifyListeners('user_left', data);
        });

        _socket?.on('room_closed', (data) {
            debugPrint('[SocketService] Room closed: $data');
            _notifyListeners('room_closed', data);
        });

        _socket?.on('room_deleted', (data) {
            debugPrint('[SocketService] Room deleted: $data');
            _notifyListeners('room_deleted', data);
        });

        _socket?.on('room_update', (data) {
            _notifyListeners('room_update', data);
        });

        _socket?.on('gift_sent', (data) {
            _notifyListeners('gift_sent', data);
        });
    }

    void on(String event, Function callback) {
        _listeners.putIfAbsent(event, () => []);
        _listeners[event]!.add(callback);
    }

    void off(String event, Function callback) {
        _listeners[event]?.remove(callback);
    }

    void _notifyListeners(String event, dynamic data) {
        _listeners[event]?.forEach((callback) {
            try {
                callback(data);
            } catch (e) {
                debugPrint('[SocketService] Listener error for $event: $e');
            }
        });
    }

    final List<_PendingEmit> _pendingEmits = [];

    void emit(String event, dynamic data) {
        if (_socket != null && _isConnected) {
            _socket!.emit(event, data);
        } else {
            debugPrint('[SocketService] Queuing $event (not connected)');
            _pendingEmits.add(_PendingEmit(event, data));
        }
    }

    void _flushPendingEmits() {
        for (final pending in _pendingEmits) {
            if (_socket != null) {
                debugPrint('[SocketService] Flushing pending: ${pending.event}');
                _socket!.emit(pending.event, pending.data);
            }
        }
        _pendingEmits.clear();
    }

    /// 添加一次性连接成功回调
    void onConnected(VoidCallback callback) {
        if (_isConnected) {
            callback();
        } else {
            _onConnectCallbacks.add(callback);
        }
    }

    void joinRoom(String roomId) {
        _currentRoomId = roomId;
        if (_isConnected) {
            _socket!.emit('join_room', {'room_id': roomId});
            debugPrint('[SocketService] Joined room: $roomId');
        } else {
            debugPrint('[SocketService] Queuing join_room for $roomId');
            _pendingEmits.add(_PendingEmit('join_room', {'room_id': roomId}));
        }
    }

    void leaveRoom(String roomId) {
        _currentRoomId = null;
        if (_isConnected) {
            _socket!.emit('leave_room', {'room_id': roomId});
        }
    }

    void sendChatMessage(String roomId, String content, {String type = 'text'}) {
        emit('chat_message', {
            'room_id': roomId,
            'content': content,
            'type': type,
        });
    }

    void requestSeat(String roomId, int seatIndex) {
        emit('seat_request', {
            'room_id': roomId,
            'seat_index': seatIndex,
        });
    }

    void approveSeat(String roomId, String requesterId, int seatIndex) {
        emit('approve_seat', {
            'room_id': roomId,
            'requester_id': requesterId,
            'seat_index': seatIndex,
        });
    }

    void rejectSeat(String roomId, String requesterId) {
        emit('reject_seat', {
            'room_id': roomId,
            'requester_id': requesterId,
        });
    }

    @override
    void dispose() {
        _socket?.dispose();
        _listeners.clear();
        super.dispose();
    }
}
