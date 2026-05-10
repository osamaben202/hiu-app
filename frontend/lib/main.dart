/**
 * HIU 语音房 App 入口
 */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/providers/user_provider.dart';
import 'src/providers/room_provider.dart';
import 'src/providers/chat_provider.dart';
import 'src/pages/splash_page.dart';

void main() {
    runApp(const HIUApp());
}

class HIUApp extends StatelessWidget {
    const HIUApp({super.key});

    @override
    Widget build(BuildContext context) {
        return MultiProvider(
            providers: [
                ChangeNotifierProvider(create: (_) => UserProvider()),
                ChangeNotifierProvider(create: (_) => RoomProvider()),
                ChangeNotifierProvider(create: (_) => ChatProvider()),
            ],
            child: MaterialApp(
                title: 'HIU',
                debugShowCheckedModeBanner: false,
                theme: ThemeData(
                    primarySwatch: Colors.purple,
                    primaryColor: const Color(0xFF6C5CE7),
                    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
                    appBarTheme: const AppBarTheme(
                        backgroundColor: Color(0xFF6C5CE7),
                        foregroundColor: Colors.white,
                        elevation: 0,
                    ),
                    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                        backgroundColor: Colors.white,
                        selectedItemColor: Color(0xFF6C5CE7),
                        unselectedItemColor: Colors.grey,
                    ),
                    colorScheme: ColorScheme.fromSeed(
                        seedColor: const Color(0xFF6C5CE7),
                    ),
                    fontFamily: 'Roboto',
                ),
                home: const SplashPage(),
            ),
        );
    }
}
