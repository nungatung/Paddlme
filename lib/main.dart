import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'screens/launch_screen.dart';
import 'services/notification_service.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

// Top-level background handler - must be outside main()
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('Background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Only initialize notifications on mobile (not web)
  NotificationService? notificationService;
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    notificationService = NotificationService();
    await notificationService.initialize();
  }

  runApp(
    DevicePreview(
      enabled: true,
      builder: (context) => WaveShareApp(notificationService: notificationService),
    ),
  );
}

class WaveShareApp extends StatelessWidget {
  final NotificationService? notificationService;

  const WaveShareApp({super.key, required this.notificationService});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'WaveShare',
          debugShowCheckedModeBanner: false,
          useInheritedMediaQuery: true,
          locale: DevicePreview.locale(context),
          builder: DevicePreview.appBuilder,
          theme: AppTheme.lightTheme,
          home: LaunchScreen(notificationService: notificationService),
        );
      },
    );
  }
}