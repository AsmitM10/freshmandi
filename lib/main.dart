import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/env_keys.dart';
import 'core/localization/app_language.dart';
import 'core/localization/language_provider.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/secure_session_storage.dart';
import 'l10n/gen/app_localizations.dart';

void main() {
  // TEMPORARY debug instrumentation — remove once the "not navigating to
  // Home after login" report is confirmed fixed.
  //
  // FlutterError.onError only catches errors thrown during Flutter's own
  // build/layout/paint/gesture handling. It does NOT catch a generic
  // uncaught error in a plain async function (e.g. inside a Riverpod
  // provider body or an awaited Future chain) — those go through the
  // current Zone's uncaught-error handler instead, silently, with nothing
  // printed by default. That gap fits the observed symptom exactly: the
  // provider's own body ran to completion and returned a value, but the
  // code awaiting it never resumed and nothing was ever printed or thrown
  // where we could see it. Wrapping main() in runZonedGuarded plus setting
  // PlatformDispatcher.instance.onError gives two independent, overlapping
  // nets so nothing can be silently swallowed anymore.
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (FlutterErrorDetails details) {
        // ignore: avoid_print
        print('[FLUTTER ERROR] ${details.exceptionAsString()}');
        // ignore: avoid_print
        print(details.stack);
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        // ignore: avoid_print
        print('[ZONE ERROR via PlatformDispatcher] $error');
        // ignore: avoid_print
        print(stack);
        return true;
      };

      await dotenv.load(fileName: '.env');

      await Supabase.initialize(
        url: dotenv.env[EnvKeys.supabaseUrl]!,
        publishableKey: dotenv.env[EnvKeys.supabaseAnonKey]!,
        authOptions: FlutterAuthClientOptions(
          localStorage: SecureSessionStorage(),
        ),
      );

      runApp(const ProviderScope(child: FreshMandiApp()));
    },
    (error, stack) {
      // ignore: avoid_print
      print('[UNCAUGHT ZONE ERROR via runZonedGuarded] $error');
      // ignore: avoid_print
      print(stack);
    },
  );
}

class FreshMandiApp extends ConsumerWidget {
  const FreshMandiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final language = ref.watch(languageProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'FreshMandi',
      theme: AppTheme.theme,
      routerConfig: router,
      locale: language.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
