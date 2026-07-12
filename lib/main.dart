import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cashbook/l10n/generated/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'providers/person_provider.dart';
import 'providers/record_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/auth_provider.dart';

import 'core/theme/light_theme.dart';
import 'core/theme/dark_theme.dart';
import 'core/theme/premium_themes.dart';
import 'core/constants/app_colors.dart';
import 'core/widgets/lock_screen_wrapper.dart';
import 'core/services/notification_service.dart';

import 'screens/splash/splash_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Request permission for push notifications
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }

  await NotificationService().init();
  NotificationService().scheduleInactivityReminder();

  runApp(const SmartKhataApp());
}

class SmartKhataApp extends StatelessWidget {
  const SmartKhataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PersonProvider()),

        ChangeNotifierProvider(create: (_) => RecordProvider()),

        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],

      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          final activeColor =
              AppColors.themeColors[settingsProvider.themeColor] ??
              const Color(0xFF5B67F1);

          ThemeData? customTheme;
          if (settingsProvider.appTheme == 'Midnight Ocean')
            customTheme = PremiumThemes.midnightOcean;
          if (settingsProvider.appTheme == 'Sunset Glow')
            customTheme = PremiumThemes.sunsetGlow;
          if (settingsProvider.appTheme == 'Forest Emerald')
            customTheme = PremiumThemes.forestEmerald;
          if (settingsProvider.appTheme == 'Cherry Blossom')
            customTheme = PremiumThemes.cherryBlossom;

          return MaterialApp(
            debugShowCheckedModeBanner: false,

            title: 'SmartKhata',

            builder: (context, child) {
              return LockScreenWrapper(child: child!);
            },

            theme: customTheme ?? LightTheme.theme(activeColor),
            darkTheme: customTheme ?? DarkTheme.theme(activeColor),

            themeMode: customTheme != null
                ? ThemeMode.light
                : (settingsProvider.darkMode
                      ? ThemeMode.dark
                      : ThemeMode.light),

            locale: settingsProvider.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('hi')],

            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
