import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/ameex_theme.dart';
import '../widgets/ameex_animations.dart';
import '../widgets/ameex_ui.dart';
import 'admin_dashboard_screen.dart';
import 'driver_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'driver@ameex.ma');
  final _passwordController = TextEditingController(text: 'driver123456');
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _isLoading = false;

  final supabase = Supabase.instance.client;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw const AuthException('Utilisateur introuvable.');
      }

      final profile = await supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      final role = profile?['role']?.toString();
      final userEmail = user.email ?? '';

      // Block deleted or deactivated driver accounts
      if (!userEmail.contains('admin') && (profile == null || role == 'deleted' || role == 'inactive')) {
        await supabase.auth.signOut();
        throw const AuthException('Ce compte livreur a été supprimé ou désactivé par l\'administrateur.');
      }

      if (role == 'admin' || userEmail.contains('admin')) {
        Navigator.of(context).pushReplacement(
          AmeexPageRoute(page: const AdminDashboardScreen()),
        );
      } else if (role == 'driver') {
        Navigator.of(context).pushReplacement(
          AmeexPageRoute(page: const DriverHomeScreen()),
        );
      } else {
        await supabase.auth.signOut();
        throw const AuthException('Accès refusé. Ce compte ne dispose pas des autorisations nécessaires.');
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(_prettifyError(e.message));
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(_prettifyError(e.toString()));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _prettifyError(String raw) {
    final low = raw.toLowerCase();
    if (low.contains('database error querying schema') ||
        low.contains('unexpected_failure')) {
      return 'Service temporairement indisponible. Veuillez réessayer dans un instant.';
    }
    if (low.contains('invalid login') ||
        low.contains('invalid credentials')) {
      return 'Email ou mot de passe incorrect.';
    }
    if (low.contains('email not confirmed')) {
      return 'Compte non confirmé. Vérifiez votre boîte mail.';
    }
    if (low.contains('network') || low.contains('socket') ||
        low.contains('failed host lookup')) {
      return 'Connexion internet indisponible.';
    }
    if (low.contains('rate limit') || low.contains('too many')) {
      return 'Trop de tentatives. Patientez quelques minutes.';
    }
    // Fall back to a short message, never raw JSON
    final clean = raw.replaceAll(RegExp(r'[{}"]'), '').trim();
    return clean.length > 120 ? '${clean.substring(0, 120)}…' : clean;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AmeexColors.dangerRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AmeexColors.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 32),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Brand mark
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    AmeexLogo(height: 32),
                                  ],
                                ),

                                const SizedBox(height: 40),

                                // Headline
                                const Text(
                                  'Connexion',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: AmeexTheme.fontFamily,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                    color: AmeexColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Accédez à votre espace Ameex',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: AmeexTheme.fontFamily,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AmeexColors.textMuted,
                                  ),
                                ),

                                const SizedBox(height: 32),

                                _label('Email'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  cursorColor: AmeexColors.primaryBlue,
                                  style: const TextStyle(
                                    fontFamily: AmeexTheme.fontFamily,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: AmeexColors.textDark,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'contact@ameex.ma',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Veuillez saisir votre email';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Email invalide';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 18),

                                _label('Mot de passe'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _handleLogin(),
                                  cursorColor: AmeexColors.primaryBlue,
                                  style: const TextStyle(
                                    fontFamily: AmeexTheme.fontFamily,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: AmeexColors.textDark,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Votre mot de passe',
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        size: 20,
                                      ),
                                      splashRadius: 20,
                                      onPressed: () => setState(() =>
                                          _obscurePassword = !_obscurePassword),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Veuillez saisir votre mot de passe';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 10),

                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Contactez votre administrateur pour réinitialiser le mot de passe.',
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text('Mot de passe oublié ?'),
                                  ),
                                ),

                                const SizedBox(height: 18),

                                AmeexPrimaryButton(
                                  label: 'Se connecter',
                                  isLoading: _isLoading,
                                  onPressed: _isLoading ? null : _handleLogin,
                                ),

                                const Spacer(),

                                const SizedBox(height: 24),

                                const Center(
                                  child: Text(
                                    'Ameex Delivery Suite',
                                    style: TextStyle(
                                      fontFamily: AmeexTheme.fontFamily,
                                      color: AmeexColors.textFaint,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontFamily: AmeexTheme.fontFamily,
          color: AmeexColors.textDark,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      );

}
