import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:task_paven/localization/app_translations.dart';
import 'package:task_paven/services/theme_services.dart';
import 'package:task_paven/ui/pages/home_page.dart';
import 'package:task_paven/ui/theme.dart';

import 'db/db_helper.dart';

//future
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DBHelper.initDb();
  await GetStorage.init();
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
    return GetMaterialApp(
      theme: Themes.light,
      darkTheme: Themes.dark,
      themeMode: ThemeServices().theme,
      translations: AppTranslations(),
      locale: _initialLocale,
      fallbackLocale: const Locale('en'),
      title: 'Task Paven',
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}
