import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings.dart';
import 'events_screen.dart';
import 'firebase_options.dart';
import 'login_screen.dart';

const eventlyBlue = Color(0xff10388f);
const eventlyBackground = Color(0xfff2f5ff);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  settings = AppSettings(await SharedPreferences.getInstance());
  await Firebase.initializeApp(options: eventlyFirebaseOptions);
  runApp(const EventlyApp());
}

class EventlyApp extends StatefulWidget {
  const EventlyApp({super.key});

  @override
  State<EventlyApp> createState() => _EventlyAppState();
}

class _EventlyAppState extends State<EventlyApp> {
  late Stream<User?> authStream = FirebaseAuth.instance.userChanges();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, child) {
        var colors = ColorScheme.fromSeed(
          seedColor: eventlyBlue,
          brightness: settings.isDark ? Brightness.dark : Brightness.light,
        );
        if (!settings.isDark) colors = colors.copyWith(primary: eventlyBlue);
        var background = settings.isDark
            ? const Color(0xff11172a)
            : eventlyBackground;
        return MaterialApp(
          title: 'Evently',
          debugShowCheckedModeBanner: false,
          locale: Locale(settings.language),
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: ThemeData(
            colorScheme: colors,
            scaffoldBackgroundColor: background,
            appBarTheme: AppBarTheme(
              backgroundColor: background,
              centerTitle: true,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: colors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          home: settings.onboarded
              ? StreamBuilder<User?>(
                  stream: authStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }
                    var user = snapshot.data;
                    if (user == null) return const LoginScreen();
                    return EventsScreen(key: ValueKey(user.uid));
                  },
                )
              : const OnboardingScreen(),
        );
      },
    );
  }
}
