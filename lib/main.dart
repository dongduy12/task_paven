import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:task_paven/localization/app_translations.dart';
import 'package:task_paven/services/theme_services.dart';
import 'package:task_paven/ui/pages/home_page.dart';
import 'package:task_paven/ui/pages/onboarding_page.dart';
import 'package:task_paven/ui/theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'db/db_helper.dart';

//future
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  await DBHelper.initDb();
  await GetStorage.init();
  final savedLocaleCode = GetStorage().read<String>('language_code');
  final deviceLocaleCode = Get.deviceLocale?.languageCode;

  // Ensure locale-specific date data is ready for whichever language is active.
  if ((savedLocaleCode ?? deviceLocaleCode) != null) {
    await initializeDateFormatting(savedLocaleCode ?? deviceLocaleCode);
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  final _storage = GetStorage();

  Locale? get _initialLocale {
    final saved = _storage.read<String>('language_code');
    if (saved != null && saved.isNotEmpty) {
      return Locale(saved);
    }
    return Get.deviceLocale;
  }

  @override
  Widget build(BuildContext context) {
    final hasCompletedOnboarding = _storage.read<bool>('onboarding_completed') ?? false;

    return GetMaterialApp(
      theme: Themes.light,
      darkTheme: Themes.dark,
      themeMode: ThemeServices().theme,
      translations: AppTranslations(),
      locale: _initialLocale,
      fallbackLocale: const Locale('en'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('vi'),
      ],
      title: 'Task Paven',
      debugShowCheckedModeBanner: false,
      home: hasCompletedOnboarding ? const HomePage() : const OnboardingPage(),
    );
  }
}
