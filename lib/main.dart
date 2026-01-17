import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';  
import 'firebase_options.dart';  
import 'core/theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() async { 
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase initialization
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    DevicePreview(
      enabled: true,
      builder: (context) => const WaveShareApp(),
    ),
  );
}

class WaveShareApp extends StatelessWidget {
  const WaveShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize:  const Size(375, 812),
      minTextAdapt:  true,
      splitScreenMode:  true,
      builder: (context, child) {
        return MaterialApp(
          title: 'WaveShare',
          debugShowCheckedModeBanner: false,
          useInheritedMediaQuery: true,
          locale:  DevicePreview.locale(context),
          builder: DevicePreview.appBuilder,
          theme: AppTheme.lightTheme,
          home: const SplashScreen(), 
        );
      },
    );
  }
}