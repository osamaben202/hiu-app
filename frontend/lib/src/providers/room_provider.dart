/**
 * 房间状态管理
 */
import 'package:flutter/foundation.dart';
import '../models/room.dart';
import '../models/gift.dart';
import '../services/api_service.dart';

class RoomProvider extends ChangeNotifier {
    final ApiService _api = ApiService();
    
    List<Room> _rooms = [];
    Room? _currentRoom;
    bool _isLoading = false;
    String? _error;
    String? _agoraToken;
    String? _channelName;
    List<Gift> _gifts = [];

    List<Room> get rooms => _rooms;
    Room? get currentRoom => _currentRoom;
    bool get isLoading => _isLoading;
    String? get error => _error;
    String? get agoraToken => _agoraToken;
    String? get channelName => _channelName;
    List<Gift> get gifts => _gifts;

    /// 获取房间列表
    Future<void> fetchRooms({
        int page = 1,
        int limit = 20,
        String? keyword,
        String sort = 'created',
    }) async {
        _isLoading = true;
        notifyListeners();

        try {
            _rooms = await _api.getRooms(
                page: page,
                limit: limit,
                keyword: keyword,
                sort: sort,
            );
            _error = null;
        } catch (e) {
            _error = e.toString();
        } finally {
            _isLoading = false;
            notifyListeners();
        }
    }

    /// 获取房间详情
    Future<void> fetchRoomDetail(String roomId) async {
        _isLoading = true;
        notifyListeners();

        try {
            _currentRoom = await _api.getRoomDetail(roomId);
            _error = null;
        } catch (e) {
            _error = e.toString();
        } finally {
            _isLoading = false;
            notifyListeners();
        }
    }

    /// 创建房间
    Future<Room?> createRoom({
        required String name,
        String? cover,
        String? description,
        bool isPublic = true,
        String? password,
        String? tags,
    }) async {
        _isLoading = true;
        notifyListeners();

        try {
            final room = await _api.createRoom(
                name: name,
                cover: cover,
                description: description,
                isPublic: isPublic,
                password: password,
                tags: tags,
            );
            _rooms.insert(0, room);
            _error = null;
            notifyListeners();
            return room;
        } catch (e) {
            _error = e.toString();
            notifyListeners();
            return null;
        } finally {
            _isLoading = false;
            notifyListeners();
        }
    }

    /// 加入房间
    Future<bool> joinRoom(String roomId, {String? password}) async {
        _isLoading = true;
        notifyListeners();

        try {
            final data = await _api.joinRoom(roomId, password: password);
            _agoraToken = data['agora_token'];
            _channelName = data['channel_name'];
            await fetchRoomDetail(roomId);
            _error = null;
            return true;
        } catch (e) {
            _error = e.toString();
            notifyListeners();
            return false;
        } finally {
            _isLoading = false;
            notifyListeners();
        }
    }

    /// 离开房间
    Future<void> leaveRoom(String roomId) async {
        try {
            await _api.leaveRoom(roomId);
        } catch (e) {
            // 忽略错误
        }
        _currentRoom = null;
        _agoraToken = null;
        _channelName = null;
        notifyListeners();
    }

    /// 上麦
    Future<bool> joinSeat(int seatIndex) async {
        if (_currentRoom == null) return false;
        
        try {
            await _api.joinSeat(_currentRoom!.id, seatIndex);
            await fetchRoomDetail(_currentRoom!.id);
            return true;
        } catch (e) {
            _error = e.toString();
            notifyListeners();
            return false;
        }
    }

    /// 下麦
    Future<bool> leaveSeat(int seatIndex) async {
        if (_currentRoom == null) return false;
        
        try {
            await _api.leaveSeat(_currentRoom!.id, seatIndex);
            await fetchRoomDetail(_currentRoom!.id);
            return true;
        } catch (e) {
            _error = e.toString();
            notifyListeners();
            return false;
        }
    }

    /// 踢人下麦
    Future<bool> kickSeat(int seatIndex) async {
        if (_currentRoom == null) return false;
        
        try {
            await _api.kickSeat(_currentRoom!.id, seatIndex);
            await fetchRoomDetail(_currentRoom!.id);
            return true;
        } catch (e) {
            _error = e.toString();
            notifyListeners();
            return false;
        }
    }

    /// 闭麦/开麦
    Future<bool> muteSeat(int seatIndex, bool isMuted) async {
        if (_currentRoom == null) return false;
        
        try {
            await _api.muteSeat(_currentRoom!.id, seatIndex, isMuted);
            // 更新本地状态
            final seat = _currentRoom!.seats.firstWhere(
                (s) => s.seatIndex == seatIndex,
                orElse: () => _currentRoom!.seats[seatIndex],
            );
            seat.isMuted = isMuted;
            notifyListeners();
            return true;
        } catch (e) {
            _error = e.toString();
            notifyListeners();
            return false;
        }
    }

    /// 锁定/解锁麦位
    Future<bool> lockSeat(int seatIndex, bool isLocked) async {
        if (_currentRoom == null) return false;
        
        try {
            await _api.lockSeat(_currentRoom!.id, seatIndex, isLocked);
            await fetchRoomDetail(_currentRoom!.id);
            return true;
        } catch (e) {
            _error = e.toString();
            notifyListeners();
            return false;
        }
    }

    /// 关闭房间
    Future<bool> closeRoom() async {
        if (_currentRoom == null) return false;
        
        try {
            await _api.closeRoom(_currentRoom!.id);
            _currentRoom = null;
            _agoraToken = null;
            _channelName = null;
            notifyListeners();
            return true;
        } catch (e) {
            _error = e.toString();
            notifyListeners();
            return false;
        }
    }

    /// 获取礼物列表
    Future<void> fetchGifts() async {
        try {
            _gifts = await _api.getGifts();
            notifyListeners();
        } catch (e) {
            _error = e.toString();
        }
    }

    /// 发送礼物
    Future<Map<String, dynamic>?> sendGift({
        required String giftId,
        required String receiverId,
        int count = 1,
    }) async {
        try {
            final result = await _api.sendGift(
                giftId: giftId,
                receiverId: receiverId,
                roomId: _currentRoom?.id,
                count: count,
            );
            return result;
        } catch (e) {
            _error = e.toString();
            notifyListeners();
            return null;
        }
    }

    /// 更新麦位状态
    void updateSeat(int seatIndex, RoomSeat seat) {
        if (_currentRoom == null) return;
        
        final index = _currentRoom!.seats.indexWhere((s) => s.seatIndex == seatIndex);
        if (index != -1) {
            _currentRoom!.seats[index] = seat;
            notifyListeners();
        }
    }

    /// 获取我的麦位索引
    int? getMySeatIndex(String oderId) {
        if (_currentRoom == null) return null;
        
        for (var seat in _currentRoom!.seats) {
            if (seat.userId == oderId) {
                return seat.seatIndex;
            }
        }
        return null;
    }

    /// 清除状态
    void clear() {
        _rooms = [];
        _currentRoom = null;
        _agoraToken = null;
        _channelName = null;
        _gifts = [];
        notifyListeners();
    }
}
