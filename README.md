# Flutter Screenshot Generator
Generate screenshots for a Flutter application across different screens and languages

## Implementation

```dart
# ./test/integration_test/capture_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenshot_generator/flutter_screenshot_generator.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:test/main.dart';

void main() {
  final gen = ScreenshotGenerator(
    locales: [Locale('en', 'US'), Locale('de', 'DE')],
    fnGetApp: () => const MyApp(),
  );
  gen.inject('1_home');
  gen.inject('2_tap', before: (tester) async {
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
  });
  gen.run();
}
```

## Usage

```
# Run all tests
flutter test integration_test/capture_test.dart

# Limit by devices
flutter test integration_test/capture_test.dart --dart-define=SCREENSHOT_DEVICES="iPhone 15 Pro"

# Limit by languages
flutter test integration_test/capture_test.dart --dart-define=SCREENSHOT_LOCALES=en

# Limit by steps
flutter test integration_test/capture_test.dart --dart-define=SCREENSHOT_STEPS=2_tap

# Skip devices for which a folder already exists
flutter test integration_test/capture_test.dart --dart-define=SKIP_EXISTANT=true

```

## Results: iPhone 14

<img src="./test/screenshots/en_US/iPhone_14/1_home.png" width="240" /> . <img src="./test/screenshots/en_US/iPhone_14/2_tap.png" width="240" />

Other screenshots can be viewed on [screenshots](./test/screenshots/)-folder.

## Production example
[https://github.com/lyskouski/app-finance/blob/main/integration_test/screenshots/capture_test.dart](https://github.com/lyskouski/app-finance/blob/main/integration_test/screenshots/capture_test.dart)

## Support (Sponsorship)

If you'd like to contribute financially towards the efforts, please consider these options:

* [Github Sponsorship](https://github.com/users/lyskouski/sponsorship)
* [Paypal](https://www.paypal.me/terCAD)
* [Patreon](https://www.patreon.com/terCAD)
* [Donorbox](https://donorbox.org/tercad)

Or, [buy a coffee](https://www.buymeacoffee.com/lyskouski).