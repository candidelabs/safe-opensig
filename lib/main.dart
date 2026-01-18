import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'package:safe_verify/core/router/app_router.dart';
import 'package:safe_verify/core/storage/accounts_box.dart';
import 'package:safe_verify/core/storage/migrations/migration_runner.dart';
import 'package:safe_verify/core/storage/misc_box.dart';
import 'package:safe_verify/core/storage/theme_box.dart';
import 'package:safe_verify/core/theme/app_theme.dart';
import 'package:window_manager/window_manager.dart';

final botToastBuilder = BotToastInit();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await Hive.initFlutter();

  // Open Boxes - router will check if migration is needed
  await Future.wait([
    MiscBox.init(),
    ThemeBox.init(),
    AccountsBox.init()
  ]);
  await HiveMigrationRunner.needsMigration();

  // Initialize platform-specific features
  if (!kIsWeb && Platform.isWindows) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(360, 800),
      minimumSize: Size(360, 800),
      maximumSize: Size(360, 800),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    var isMobile = Platform.isAndroid || Platform.isIOS;
    var isDarkMode = true; // todo ThemeBox.isDarkMode();
    return MaterialApp.router(
      title: 'Safe Verify',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
      scrollBehavior: !isMobile ? WebScrollBehaviour() : null,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        if (!isMobile) {
          return Center(
            child: SizedBox(
              width: 360,
              height: 800,
              child: botToastBuilder(context, child),
            ),
          );
        }
        return botToastBuilder(context, child);
      },
    );
  }
}

class WebScrollBehaviour extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
  };
}