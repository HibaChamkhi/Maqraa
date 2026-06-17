import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/di/injection.dart';
import 'core/ui/styles/theme.dart';
import 'firebase_options.dart';
import 'presentation/app/auth_gate.dart';
import 'presentation/auth/bloc/auth_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // On Flutter web the default Firestore streaming (WebChannel) connection is
  // often blocked by networks/ad-blockers, which makes queries hang forever.
  // Forcing long-polling avoids that and makes where/orderBy queries work.
  if (kIsWeb) {
    FirebaseFirestore.instance.settings = const Settings(
      webExperimentalAutoDetectLongPolling: true,
    );
  }
  await initializeDateFormatting('ar', null);
  await configureDependencies();
  runApp(
    ScreenUtilInit(
      designSize: const Size(428, 810),
      builder: (context, child) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthBloc>()..add(const AuthCheckRequested()),
      child: MaterialApp(
        title: 'وصال',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system, // light/dark toggle ready (US-23)
        // Arabic + full RTL support (US-22).
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        ),
        home: const AuthGate(),
      ),
    );
  }
}
