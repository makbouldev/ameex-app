import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/driver_home_screen.dart';
import 'screens/login_screen.dart';
import 'theme/ameex_theme.dart';

// Top-level Supabase client
final supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://mgnanilybghwxnppwsnc.supabase.co',
    publishableKey: 'sb_publishable_GG9AAryfHTt6M_7gL0fpCw_05KJClnp',
  );

  runApp(const AmeexApp());
}

class AmeexApp extends StatelessWidget {
  const AmeexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ameex Logistics Suite',
      debugShowCheckedModeBanner: false,
      theme: AmeexTheme.lightTheme,
      routes: {
        '/login': (_) => const LoginScreen(),
        '/admin': (_) => const AdminDashboardScreen(),
        '/driver': (_) => const DriverHomeScreen(),
      },
      home: const AuthGate(),
    );
  }
}

/// Dynamic Role-Based Routing Gate
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? supabase.auth.currentSession;

        if (session == null) {
          return const LoginScreen();
        }

        // Fetch User Profile Role from 'profiles' table
        return FutureBuilder<Map<String, dynamic>?>(
          future: supabase
              .from('profiles')
              .select('role')
              .eq('id', session.user.id)
              .maybeSingle(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Color(0xFF0A192F),
                body: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              );
            }

            final data = profileSnapshot.data;
            final role = data?['role']?.toString();
            final email = session.user.email ?? '';

            // If profile role is admin OR email contains 'admin' -> Admin Dashboard
            if (role == 'admin' || email.contains('admin')) {
              return const AdminDashboardScreen();
            } else {
              return const DriverHomeScreen();
            }
          },
        );
      },
    );
  }
}
