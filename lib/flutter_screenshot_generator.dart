export 'src/device_config.dart';
export 'src/screenshot_config.dart';
export 'src/screenshot_helper.dart';

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_screenshot_generator/flutter_screenshot_generator.dart';
import 'package:flutter_test/flutter_test.dart';

typedef InitFunction = Future<void> Function(DeviceConfig device, ScreenshotConfig config, String localeCode);
typedef StepFunction = Future<void> Function(WidgetTester tester);

class ScreenshotGenerator {
  late final ScreenshotConfig config;
  List<DeviceConfig> devices = [];
  List<Locale> locales = [];
  Map<String, StepFunction?> steps = {};
  InitFunction? fnInit;
  Widget Function() fnGetApp;
  
  ScreenshotGenerator({
    ScreenshotConfig? config,
    required this.locales,
    required this.fnGetApp,
    this.fnInit,
  }) {
    if (config == null) {
      final preset = ScreenshotPresets.comprehensive;
      this.config = ScreenshotConfig(
        enabledPlatforms: preset.enabledPlatforms,
        enabledDeviceTypes: preset.enabledDeviceTypes,
        outputDirectory: preset.outputDirectory,
        pixelRatio: preset.pixelRatio,
        animationSettleTime: preset.animationSettleTime,
        generateHtmlReport: false,
        enableGoldenComparison: false,
        comparisonThreshold: preset.comparisonThreshold,
      );
    } else {
      this.config = config;
    }
    _initDevices();
    _initLocales();
  }

  // flutter test integration_test/screenshots/capture_test.dart --dart-define=SCREENSHOT_DEVICES="iPhone 15 Pro"
  void _initDevices() {
    final enabledDevices = config.getEnabledDevices();
    final deviceCsv = String.fromEnvironment('SCREENSHOT_DEVICES');
    final deviceFilter = deviceCsv.split(',').map((v) => v.trim()).where((v) => v.isNotEmpty).toSet();
    bool matchesDeviceFilter(DeviceConfig device) {
      if (deviceFilter.isEmpty) {
        return true;
      }
      final name = device.name;
      final normalized = name.toLowerCase();
      final underscored = name.replaceAll(' ', '_').toLowerCase();
      return deviceFilter.any((f) {
        final ff = f.toLowerCase();
        return ff == normalized || ff == underscored;
      });
    }
    devices = enabledDevices.where(matchesDeviceFilter).toList();
  }

  // flutter test integration_test/screenshots/capture_test.dart --dart-define=SCREENSHOT_LOCALES=en
  void _initLocales() {
    final localeCsv = String.fromEnvironment('SCREENSHOT_LOCALES');
    final localeFilter = localeCsv.split(',').map((v) => v.trim()).where((v) => v.isNotEmpty).toSet();
    if (localeFilter.isNotEmpty) {
      locales = locales.where((l) => localeFilter.contains(l.toString())).toList();
    }
  }

  // Allow test code to inject steps to be run for each device/locale combination. 
  // Steps will be run in the order they were injected.
  void inject(String title, {StepFunction? before}) => steps[title] = before;

  // Main entry point to run the screenshot generation process
  void run() {
    // flutter test integration_test/screenshots/capture_test.dart --dart-define=SCREENSHOT_STEPS=4_m_budgets
    const stepCsv = String.fromEnvironment('SCREENSHOT_STEPS');
    final stepFilter = stepCsv.split(',').map((v) => v.trim()).where((v) => v.isNotEmpty).toSet();

    // flutter test integration_test/screenshots/capture_test.dart --dart-define=SKIP_EXISTANT=true
    const skipExistant = String.fromEnvironment('SKIP_EXISTANT');
    final shouldSkipExisting = skipExistant.toLowerCase() == 'true' || skipExistant == '1';

    TestWidgetsFlutterBinding.ensureInitialized();
    for (final locale in locales) {
      final localeCode = locale.toString();
      for (final device in devices) {
        // Check if we should skip this locale/device combination
        if (shouldSkipExisting) {
          final deviceFolderName = device.name.replaceAll(' ', '_').replaceAll(RegExp(r'[^\w\-_]'), '');
          final outputPath = Directory('${config.outputDirectory}/$localeCode/$deviceFolderName');
          if (outputPath.existsSync()) {
            print('Skipping $localeCode/${device.name} - folder exists with screenshots');
            continue;
          }
        }
        // Run steps for this device/locale
        for (final step in steps.entries) {
          final stepId = step.key;
          final before = step.value;
          if (stepFilter.isNotEmpty && !stepFilter.contains(stepId)) {
            print('Skipping step $stepId - not in filter');
            continue;
          }
          _screenshotForDevice(
            stepId,
            device,
            config,
            localeCode: localeCode,
            beforeScreenshot: before,
          );
        }
      }
    }
  }

  void _screenshotForDevice(
    String description,
    DeviceConfig device,
    ScreenshotConfig config, {
    StepFunction? beforeScreenshot,
    required String localeCode,
  }) {
    testWidgets('$description - ${device.name} - $localeCode', (WidgetTester tester) async {
      // Configure device settings
      ScreenshotHelper.configureDevice(tester, device);

      try {
        // Initialize app preferences
        if (fnInit != null) {
          await fnInit!(device, config, localeCode);
        }

        // Create screenshot-ready app
        final appWidget = ScreenshotHelper.createScreenshotApp(
          device: device,
          screenshotKey: '${description}_${device.name}_$localeCode',
          child: fnGetApp(),
        );

        await tester.pumpWidget(appWidget);
        await tester.pumpAndSettleForDevice(device);
        await tester.loadDeviceAssets(device);

        // Execute pre-screenshot actions
        if (beforeScreenshot != null) {
          await beforeScreenshot(tester);
        }

        // Wait for any final animations
        await tester.pumpAndSettle(config.animationSettleTime);

        // Capture the screenshot
        await ScreenshotHelper.captureScreenshot(
          testName: description,
          device: device,
          screenshotKey: '${description}_${device.name}_$localeCode',
          customPath: '${config.outputDirectory}/$localeCode',
          pixelRatio: device.devicePixelRatio,
        );

        // Optionally compare with golden files
        if (config.enableGoldenComparison) {
          await ScreenshotHelper.expectScreenshotForDevice(
            tester,
            device,
            description,
            threshold: config.comparisonThreshold,
          );
        }
      } finally {
        // Reset device configuration
        ScreenshotHelper.resetDevice(tester);
      }
    });
  }
}
