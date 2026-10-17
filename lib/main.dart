import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/hotel_list_screen.dart';
import 'screens/login_screen.dart';
import 'screens/manager_dashboard.dart';
import 'screens/receptionist_dashboard.dart';
import 'services/auth_service.dart';
import 'services/profile_service.dart';

const String appMode = String.fromEnvironment(
  'APP_MODE',
  defaultValue: 'full',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://lxkcrodfyzelrrzpitiz.supabase.co',
    publishableKey: 'sb_publishable_RKZDiVx_-BlWReDU04pU6Q_wktJpHdx',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF173B56);
    const royalBlue = Color(0xFF245A7A);
    const gold = Color(0xFFD4A72C);
    const cream = Color(0xFFF7F5F0);
    const darkText = Color(0xFF17202A);
    const secondaryGray = Color(0xFF7A8490);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: royalBlue,
      brightness: Brightness.light,
      primary: navy,
      secondary: gold,
      surface: Colors.white,
      error: const Color(0xFFB53B3B),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Syber Hotel',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: cream,
        splashFactory: InkSparkle.splashFactory,
        appBarTheme: const AppBarTheme(
          backgroundColor: cream,
          foregroundColor: darkText,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: darkText,
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1,
          shadowColor: navy.withValues(alpha: 0.08),
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: darkText,
          displayColor: darkText,
        ),
        iconTheme: const IconThemeData(color: secondaryGray),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          hintStyle: const TextStyle(color: secondaryGray),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE9E6DF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: royalBlue, width: 1.5),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: navy,
            foregroundColor: Colors.white,
            minimumSize: const Size(48, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: navy,
            foregroundColor: Colors.white,
            minimumSize: const Size(48, 52),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: navy,
            minimumSize: const Size(48, 52),
            side: const BorderSide(color: Color(0xFFD9DEE2)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFE9E6DF),
          space: 1,
        ),
      ),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: AuthService.authStateChanges,
      initialData: AuthState(
        AuthChangeEvent.initialSession,
        AuthService.currentSession,
      ),
      builder: (context, snapshot) {
        final session = snapshot.data?.session;
        if (session == null) return const LoginScreen();
        if (session.user.emailConfirmedAt == null) {
          return const _UnconfirmedEmailGuard();
        }
        if (appMode == 'customer') return const HotelListScreen();

        return FutureBuilder<UserProfile?>(
          future: ProfileService.getCurrentProfile(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState != ConnectionState.done) {
              return const _LoadingScreen();
            }

            if (profileSnapshot.hasError) {
              return const _ProfileMissingScreen(
                message: 'تعذر تحميل ملف الحساب',
              );
            }

            final profile = profileSnapshot.data;
            if (profile == null) {
              return const _ProfileMissingScreen(
                message: 'تعذر العثور على ملف الحساب',
              );
            }

            switch (profile.appRole) {
              case AppRole.manager:
                return const ManagerDashboard();
              case AppRole.receptionist:
                return const ReceptionistDashboard();
              case AppRole.customer:
                return const HotelListScreen();
              default:
                return const _ProfileMissingScreen(
                  message: 'دور الحساب غير موجود أو غير صالح',
                );
            }
          },
        );
      },
    );
  }
}

class _UnconfirmedEmailGuard extends StatefulWidget {
  const _UnconfirmedEmailGuard();

  @override
  State<_UnconfirmedEmailGuard> createState() => _UnconfirmedEmailGuardState();
}

class _UnconfirmedEmailGuardState extends State<_UnconfirmedEmailGuard> {
  late final Future<void> _signOutFuture;

  @override
  void initState() {
    super.initState();
    _signOutFuture = AuthService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _signOutFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _ProfileMissingScreen(
            message: 'تعذر إنهاء الجلسة قبل تأكيد البريد الإلكتروني',
          );
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return const LoginScreen();
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _ProfileMissingScreen extends StatelessWidget {
  const _ProfileMissingScreen({required this.message});

  final String message;

  Future<void> _signOut(BuildContext context) async {
    await AuthService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _signOut(context),
                child: const Text('تسجيل الخروج'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
