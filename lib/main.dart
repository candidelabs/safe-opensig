import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'package:safe_opensig/core/router/app_router.dart';
import 'package:safe_opensig/core/storage/accounts_box.dart';
import 'package:safe_opensig/core/storage/migrations/migration_runner.dart';
import 'package:safe_opensig/core/storage/misc_box.dart';
import 'package:safe_opensig/core/storage/network_config_box.dart';
import 'package:safe_opensig/core/storage/theme_box.dart';
import 'package:safe_opensig/shared/constants/event_bus.dart';
import 'package:safe_opensig/shared/constants/network_constants.dart';
import 'package:safe_opensig/shared/services/analytics_service.dart';
import 'package:safe_opensig/shared/utils/platform_helper.dart' as platform;
import 'package:safe_opensig/core/theme/app_theme.dart';
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
    AccountsBox.init(),
    NetworkConfigBox.init(),
  ]);
  await HiveMigrationRunner.needsMigration();

  await Analytics.init();

  rebuildEffectiveNetworks();
  eventBus.on<OnNodeConfigChange>().listen((_) => rebuildEffectiveNetworks());

  // Initialize platform-specific features
  if (platform.isWindows) {
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
    var isMobile = platform.isMobile;
    var isDarkMode = true; // todo ThemeBox.isDarkMode();
    return MaterialApp.router(
      title: 'Safe OpenSig',
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
        return botToastBuilder(
          context,
          SafeArea(bottom: true, top: false, child: child!),
        );
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
