import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/notifications/local_push_service.dart';
import 'core/supabase/supabase_bootstrap.dart';
import 'core/system/app_system_ui.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'screens/welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSystemUi.initLightChrome();
  await LocalPushService.init();
  await SupabaseBootstrap.initializeIfConfigured();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flood Guard AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const WelcomeScreen(),
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        final mq = MediaQuery.of(context);
        final p = mq.padding;
        final v = mq.viewPadding;
        final blended = EdgeInsets.fromLTRB(
          math.max(p.left, v.left),
          math.max(p.top, v.top),
          math.max(p.right, v.right),
          math.max(p.bottom, v.bottom),
        );
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: AppSystemUi.lightWhiteBars,
          // Full-bleed base so inset around SafeArea (status / gesture nav)
          // is not transparent over the FlutterView (shows as black stripes).
          child: Material(
            color: AppColors.background,
            child: MediaQuery(
              data: mq.copyWith(padding: blended),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
