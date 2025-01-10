import 'package:flutter/material.dart';
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
  String _selectedAvatarUrl = DriverAvatarHelper.defaultPresets[0].url;
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

  Future<void> _handleCreateDriver() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final phone = _phoneController.text.trim();
    final zoneWithAvatar = DriverAvatarHelper.formatWithAvatar(_selectedZone, _selectedAvatarUrl);

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
        // Fallback: If RPC not yet run in SQL editor, register user
        final res = await supabase.auth.signUp(
          email: email,
          password: password,
          data: {
            'full_name': fullName,
            'role': 'driver',
            'phone': phone,
            'vehicle_type': _selectedVehicle,
            'zone': zoneWithAvatar,
            'avatar_url': _selectedAvatarUrl,
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
              'avatar_url': _selectedAvatarUrl,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Nouveau Livreur',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: AmeexFadeSlideIn(
          child: Form(
            key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Création du compte Livreur Ameex',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              const Text(
                'Remplissez les informations pour générer ses accès et affecter sa zone.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
              const SizedBox(height: 20),

              // 0. PHOTO DE PROFIL DU LIVREUR (SELECTION PAR L'ADMIN)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_circle_rounded, color: AmeexColors.primaryBlue, size: 20),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF5FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AmeexColors.primaryBlue.withValues(alpha: 0.3)),
                          ),
                          child: const Text(
                            'Visible partout',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AmeexColors.primaryBlue),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Selected Preview & Description
                    Row(
                      children: [
                        DriverAvatar(
                          avatarUrl: _selectedAvatarUrl,
                          name: _fullNameController.text.isNotEmpty ? _fullNameController.text : 'Livreur',
                          radius: 34,
                          borderColor: AmeexColors.primaryBlue,
                          borderWidth: 2.5,
                          showBadge: true,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _fullNameController.text.trim().isNotEmpty
                                    ? _fullNameController.text.trim()
                                    : 'Aperçu du Livreur',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Cette photo s\'affichera lors de l\'affectation des commandes, sur le suivi GPS et dans l\'application.',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Horizontal Presets Gallery
                    const Text(
                      'Sélectionnez une photo d\'équipe :',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: DriverAvatarHelper.defaultPresets.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final preset = DriverAvatarHelper.defaultPresets[index];
                          final isSelected = _selectedAvatarUrl == preset.url;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedAvatarUrl = preset.url;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 76,
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFEFF5FF) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? AmeexColors.primaryBlue : const Color(0xFFE2E8F0),
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AmeexColors.primaryBlue.withValues(alpha: 0.15),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Stack(
                                    children: [
                                      ClipOval(
                                        child: Image.network(
                                          preset.url,
                                          width: 44,
                                          height: 44,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      if (isSelected)
                                        Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              color: AmeexColors.primaryBlue,
                                              shape: BoxShape.circle,
                                            ),
                                            padding: const EdgeInsets.all(2),
                                            child: const Icon(Icons.check, size: 10, color: Colors.white),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    preset.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected ? AmeexColors.primaryBlue : const Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 10),
                    // Option to paste custom URL
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.link_rounded, size: 16, color: AmeexColors.primaryBlue),
                        label: const Text('Entrer une URL personnalisée', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AmeexColors.primaryBlue)),
                        onPressed: () {
                          final textCtrl = TextEditingController(text: _selectedAvatarUrl);
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('URL de la photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              content: TextField(
                                controller: textCtrl,
                                decoration: const InputDecoration(
                                  hintText: 'https://...',
                                  labelText: 'Lien direct vers l\'image (JPG/PNG)',
                                ),
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
                                ElevatedButton(
                                  onPressed: () {
                                    if (textCtrl.text.trim().isNotEmpty) {
                                      setState(() => _selectedAvatarUrl = textCtrl.text.trim());
                                    }
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text('Valider'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
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
                    backgroundColor: deepNavy,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Enregistrer & Créer le compte Livreur',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
    );
  }

  BoxDecoration _fieldBoxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    );
  }

  InputDecoration _inputDecoration({required String hint, Widget? prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF0A192F), width: 1.2),
      ),
    );
  }
}
