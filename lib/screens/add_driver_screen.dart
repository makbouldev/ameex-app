import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/ameex_theme.dart';
import '../widgets/driver_avatar.dart';
import '../widgets/ameex_animations.dart';

class AddDriverScreen extends StatefulWidget {
  const AddDriverScreen({super.key});

  @override
  State<AddDriverScreen> createState() => _AddDriverScreenState();
}

class _AddDriverScreenState extends State<AddDriverScreen> {
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController(text: 'driver123456');
  final _phoneController = TextEditingController(text: '06');

  String _selectedVehicle = 'Moto / Scooter';
  String _selectedZone = 'Casablanca - Maarif & Anfa';
  String _selectedAvatarUrl = '';
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isPickingImage = false;
  bool _isSubmitting = false;
  bool _obscurePassword = true;

  final List<Map<String, dynamic>> _vehicles = [
    {'name': 'Moto / Scooter', 'icon': Icons.two_wheeler_rounded},
    {'name': 'Vélo (Bike)', 'icon': Icons.pedal_bike_rounded},
    {'name': 'Voiture (Car)', 'icon': Icons.directions_car_rounded},
    {'name': 'Fourgonnette (Van)', 'icon': Icons.local_shipping_rounded},
  ];

  final List<String> _zones = [
    'Casablanca - Maarif & Anfa',
    'Casablanca - Sidi Maarouf & Californie',
    'Casablanca - Centre Ville & Port',
    'Casablanca - Ain Sebaa & Bernoussi',
    'Rabat - Agdal & Hassan',
    'Marrakech - Guéliz & Médina',
    'Tanger - Malabata & Centre',
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    setState(() => _isPickingImage = true);
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 240,
        maxHeight: 240,
        imageQuality: 50,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';

        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageName = image.name;
          _selectedAvatarUrl = base64String;
        });

        // Supabase storage background upload attempt
        try {
          final fileExt = image.name.split('.').last;
          final fileName = 'driver_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
          await supabase.storage.from('avatars').uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
          );
          final publicUrl = supabase.storage.from('avatars').getPublicUrl(fileName);
          if (publicUrl.isNotEmpty) {
            _selectedAvatarUrl = publicUrl;
          }
        } catch (_) {
          // Keep compressed base64 URI
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible d\'ouvrir la galerie: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  Future<void> _handleCreateDriver() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final phone = _phoneController.text.trim();
    final effectiveAvatarUrl = _selectedAvatarUrl.isNotEmpty
        ? _selectedAvatarUrl
        : DriverAvatarHelper.getAvatarUrl(null, defaultName: fullName);
    final zoneWithAvatar = DriverAvatarHelper.formatWithAvatar(_selectedZone, effectiveAvatarUrl);

    try {
      // 1. Try via RPC function
      try {
        await supabase.rpc('create_driver_account', params: {
          'p_email': email,
          'p_password': password,
          'p_full_name': fullName,
          'p_phone': phone,
          'p_vehicle_type': _selectedVehicle,
          'p_zone': zoneWithAvatar,
        });
      } catch (rpcError) {
        // Fallback: Use isolated client to register user so admin session is untouched
        // and header/cookie limits are never exceeded by auth metadata.
        final tempClient = SupabaseClient(
          'https://mgnanilybghwxnppwsnc.supabase.co',
          'sb_publishable_GG9AAryfHTt6M_7gL0fpCw_05KJClnp',
          authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
        );

        final res = await tempClient.auth.signUp(
          email: email,
          password: password,
          data: {
            'full_name': fullName,
            'role': 'driver',
            'phone': phone,
            'vehicle_type': _selectedVehicle,
            'zone': _selectedZone,
          },
        );

        if (res.user != null) {
          try {
            await supabase.from('profiles').upsert({
              'id': res.user!.id,
              'full_name': fullName,
              'phone': phone,
              'role': 'driver',
              'vehicle_type': _selectedVehicle,
              'zone': zoneWithAvatar,
              'avatar_url': effectiveAvatarUrl,
            });
          } catch (_) {
            // If avatar_url column does not exist on profiles, zone has [AVATAR:...] tag
            await supabase.from('profiles').upsert({
              'id': res.user!.id,
              'full_name': fullName,
              'phone': phone,
              'role': 'driver',
              'vehicle_type': _selectedVehicle,
              'zone': zoneWithAvatar,
            });
          }
        }
      }

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 28),
              SizedBox(width: 8),
              Text('Livreur Ajouté !', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              DriverAvatar(
                avatarUrl: _selectedAvatarUrl,
                name: fullName,
                radius: 36,
                borderColor: AmeexColors.primaryBlue,
                borderWidth: 2.5,
                showBadge: true,
              ),
              const SizedBox(height: 12),
              Text(
                fullName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AmeexColors.primaryBlue),
              ),
              const SizedBox(height: 4),
              Text(
                'Compte livreur Ameex opérationnel',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email : $email', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('Mot de passe : $password', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('Véhicule : $_selectedVehicle', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                    const SizedBox(height: 2),
                    Text('Zone : $_selectedZone', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AmeexColors.primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Terminer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final raw = e.toString().toLowerCase();
      String msg;
      if (raw.contains('email rate limit') ||
          raw.contains('over_email_send_rate_limit') ||
          raw.contains('429')) {
        msg = 'Limite d\'envoi d\'emails atteinte. Désactivez la confirmation d\'email dans Supabase ou patientez une heure.';
      } else if (raw.contains('already registered') ||
          raw.contains('user already') ||
          raw.contains('duplicate')) {
        msg = 'Cet email est déjà utilisé.';
      } else if (raw.contains('weak password') ||
          raw.contains('password should')) {
        msg = 'Mot de passe trop faible (6 caractères minimum).';
      } else if (raw.contains('invalid') && raw.contains('email')) {
        msg = 'Email invalide.';
      } else if (raw.contains('network') || raw.contains('socket')) {
        msg = 'Connexion internet indisponible.';
      } else {
        final clean = e.toString().replaceAll(RegExp(r'[{}"]'), '').trim();
        msg = clean.length > 140 ? '${clean.substring(0, 140)}…' : clean;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(msg)),
            ],
          ),
          backgroundColor: AmeexColors.dangerRed,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const deepNavy = AmeexColors.primaryBlue;

    return Scaffold(
      backgroundColor: AmeexColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 4,
        toolbarHeight: 60,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AmeexColors.textDark, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Nouveau livreur',
          style: TextStyle(
            color: AmeexColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: AmeexFadeSlideIn(
          child: Form(
            key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Créer un compte livreur',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: AmeexColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Informations, zone de livraison et accès de connexion.',
                style: TextStyle(
                  color: AmeexColors.textMuted,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 22),

              // 0. PHOTO DE PROFIL DU LIVREUR (SELECTION DEPUIS LA GALERIE)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.photo_library_rounded, color: AmeexColors.primaryBlue, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Photo de profil du livreur',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const Spacer(),
                        if (_selectedImageBytes != null || _selectedAvatarUrl.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF10B981)),
                                SizedBox(width: 4),
                                Text(
                                  'Photo prête',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Avatar Preview + Gallery Action
                    Row(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFEFF5FF),
                                border: Border.all(
                                  color: (_selectedImageBytes != null || _selectedAvatarUrl.isNotEmpty)
                                      ? AmeexColors.primaryBlue
                                      : const Color(0xFFCBD5E1),
                                  width: 2.5,
                                ),
                              ),
                              child: ClipOval(
                                child: _selectedImageBytes != null
                                    ? Image.memory(
                                        _selectedImageBytes!,
                                        width: 72,
                                        height: 72,
                                        fit: BoxFit.cover,
                                      )
                                    : _selectedAvatarUrl.isNotEmpty
                                        ? DriverAvatar(
                                            avatarUrl: _selectedAvatarUrl,
                                            name: _fullNameController.text.isNotEmpty
                                                ? _fullNameController.text
                                                : 'Livreur',
                                            radius: 36,
                                          )
                                        : const Center(
                                            child: Icon(
                                              Icons.person_rounded,
                                              size: 38,
                                              color: Color(0xFF94A3B8),
                                            ),
                                          ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _isPickingImage ? null : _pickImageFromGallery,
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: const BoxDecoration(
                                    color: AmeexColors.primaryBlue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add_photo_alternate_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),

                        // Action button & status
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AmeexPressable(
                                onTap: _isPickingImage ? null : _pickImageFromGallery,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF5FF),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AmeexColors.primaryBlue.withValues(alpha: 0.6),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (_isPickingImage)
                                        const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: AmeexColors.primaryBlue),
                                        )
                                      else
                                        const Icon(
                                          Icons.photo_library_rounded,
                                          size: 18,
                                          color: AmeexColors.primaryBlue,
                                        ),
                                      const SizedBox(width: 8),
                                      Text(
                                        (_selectedImageBytes != null || _selectedAvatarUrl.isNotEmpty)
                                            ? 'Changer l\'image (Galerie)'
                                            : 'Choisir depuis la galerie',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AmeexColors.primaryBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (_selectedImageName != null) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _selectedImageName!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedImageBytes = null;
                                          _selectedImageName = null;
                                          _selectedAvatarUrl = '';
                                        });
                                      },
                                      child: const Text(
                                        'Supprimer',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                Text(
                                  'Sélectionnez une image JPG ou PNG depuis votre appareil.',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 1. Nom complet
              _buildLabel('Nom complet du livreur'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _fullNameController,
                style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                decoration: _inputDecoration(
                  hint: 'Ex: Karim Benjelloun',
                  prefixIcon: const Icon(Icons.person_outline, size: 20, color: Colors.black45),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Nom complet requis' : null,
              ),

              const SizedBox(height: 16),

              // 2. Email de connexion
              _buildLabel('Email de connexion'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                decoration: _inputDecoration(
                  hint: 'karim.driver@ameex.ma',
                  prefixIcon: const Icon(Icons.email_outlined, size: 20, color: Colors.black45),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Email requis';
                  if (!val.contains('@')) return 'Email invalide';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 3. Mot de passe
              _buildLabel('Mot de passe initial'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                decoration: _inputDecoration(
                  hint: 'driver123456',
                  prefixIcon: const Icon(Icons.lock_outline, size: 20, color: Colors.black45),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Colors.black45,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (val) => val == null || val.length < 6 ? 'Minimum 6 caractères' : null,
              ),

              const SizedBox(height: 16),

              // 4. Téléphone
              _buildLabel('Numéro de téléphone portable'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                decoration: _inputDecoration(
                  hint: '06 12 34 56 78',
                  prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: Colors.black45),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Téléphone requis' : null,
              ),

              const SizedBox(height: 16),

              // 5. Zone d'affectation
              _buildLabel('Zone d\'affectation principale'),
              const SizedBox(height: 6),
              Container(
                decoration: _fieldBoxDecoration(),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedZone,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
                    items: _zones.map((zone) {
                      return DropdownMenuItem(
                        value: zone,
                        child: Text(zone, style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A))),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedZone = val);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 6. Type de véhicule
              _buildLabel('Type de véhicule'),
              const SizedBox(height: 8),
              Row(
                children: _vehicles.map((v) {
                  final isSelected = _selectedVehicle == v['name'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedVehicle = v['name']),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? deepNavy : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? deepNavy : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              v['icon'] as IconData,
                              color: isSelected ? Colors.white : const Color(0xFF64748B),
                              size: 24,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              v['name'].toString().split(' ').first,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleCreateDriver,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AmeexColors.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Créer le compte livreur',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AmeexColors.textDark,
        letterSpacing: -0.1,
      ),
    );
  }

  BoxDecoration _fieldBoxDecoration() {
    return BoxDecoration(
      color: AmeexColors.surfaceAlt,
      borderRadius: BorderRadius.circular(14),
    );
  }

  InputDecoration _inputDecoration({required String hint, Widget? prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      filled: true,
      fillColor: AmeexColors.surfaceAlt,
      hintText: hint,
      hintStyle: const TextStyle(
        color: AmeexColors.textFaint,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AmeexColors.primaryBlue, width: 1.5),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}
