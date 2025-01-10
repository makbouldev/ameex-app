import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/ameex_theme.dart';
import '../widgets/driver_avatar.dart';
import '../widgets/ameex_animations.dart';
import '../widgets/parcel_scanner_dialog.dart';

class AddOrderScreen extends StatefulWidget {
  const AddOrderScreen({super.key});

  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;

  String _deliveryType = 'Standard';
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController(text: '06');
  final _trackingNumberController = TextEditingController();
  final _parcelNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _amountController = TextEditingController(text: '150');
  final _driverFeeController = TextEditingController(text: '25'); // Gain du livreur
  
  String _selectedCity = 'Casablanca';
  String? _selectedDriverId;
  List<Map<String, dynamic>> _drivers = [];

  bool _isLoadingDrivers = true;
  bool _isSubmitting = false;

  final List<String> _deliveryTypes = ['Standard', 'Express', 'Même jour (Urgent)'];
  final List<String> _cities = [
    'Casablanca',
    'Rabat',
    'Marrakech',
    'Tanger',
    'Fès',
    'Agadir',
  ];

  @override
  void initState() {
    super.initState();
    _trackingNumberController.text = _generateTrackingNumber();
    _parcelNumberController.text = _generateParcelNumber();
    _fetchDrivers();
  }

  String _generateTrackingNumber() {
    final random = Random();
    final numPart = 10000 + random.nextInt(90000);
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final suffix = List.generate(3, (index) => chars[random.nextInt(chars.length)]).join();
    return 'AMX$numPart$suffix';
  }

  String _generateParcelNumber() {
    final random = Random();
    final numPart = 10000 + random.nextInt(90000);
    return 'CLS-CAS-$numPart-MA';
  }

  Future<void> _fetchDrivers() async {
    try {
      final data = await supabase
          .from('profiles')
          .select('id, full_name, phone')
          .eq('role', 'driver');

      if (mounted) {
        setState(() {
          _drivers = List<Map<String, dynamic>>.from(data);
          if (_drivers.isNotEmpty) {
            _selectedDriverId = _drivers.first['id'] as String;
          }
          _isLoadingDrivers = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingDrivers = false);
    }
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final double amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
      final double driverFee = double.tryParse(_driverFeeController.text.trim()) ?? 25.0;
      final String parcelNumber = _parcelNumberController.text.trim().isNotEmpty
          ? _parcelNumberController.text.trim()
          : _generateParcelNumber();

      final String rawAddress = _addressController.text.trim().isEmpty 
          ? '$_selectedCity Centre' 
          : _addressController.text.trim();
      final String addressWithParcel = ParcelHelper.formatWithParcel(rawAddress, parcelNumber);

      final Map<String, dynamic> insertPayload = {
        'tracking_number': _trackingNumberController.text.trim(),
        'customer_name': _customerNameController.text.trim(),
        'customer_phone': _customerPhoneController.text.trim(),
        'destination_city': _selectedCity,
        'delivery_address': addressWithParcel,
        'amount': amount,
        'status': 'pending',
        'assigned_driver_id': _selectedDriverId,
      };

      // Safely try inserting with new columns
      try {
        await supabase.from('orders').insert({
          ...insertPayload,
          'delivery_type': _deliveryType,
          'driver_fee': driverFee,
          'parcel_number': parcelNumber,
        });
      } catch (_) {
        try {
          await supabase.from('orders').insert({
            ...insertPayload,
            'delivery_type': _deliveryType,
            'driver_fee': driverFee,
          });
        } catch (_) {
          // Fallback in case SQL columns delivery_type/driver_fee not yet added
          await supabase.from('orders').insert({
            ...insertPayload,
            'delivery_address': '$addressWithParcel [Type: $_deliveryType | Gain: ${driverFee} MAD]',
          });
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Commande ajoutée et transmise au livreur avec succès !'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop();
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
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _trackingNumberController.dispose();
    _parcelNumberController.dispose();
    _addressController.dispose();
    _amountController.dispose();
    _driverFeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const navyColor = AmeexColors.primaryBlue;

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
          'Ajouter Commande',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
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
              // 1. Type de livraison
              _buildLabel('Type de livraison'),
              const SizedBox(height: 6),
              Container(
                decoration: _fieldBoxDecoration(),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _deliveryType,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
                    items: _deliveryTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type, style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A))),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _deliveryType = val);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 2. Nom du client
              _buildLabel('Nom du client'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _customerNameController,
                style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                decoration: _inputDecoration(hint: 'Ex: Mohammed El Amrani'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Champ obligatoire' : null,
              ),

              const SizedBox(height: 16),

              // 3. Numéro de téléphone du client
              _buildLabel('Numéro de téléphone du client'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _customerPhoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                decoration: _inputDecoration(
                  hint: '06 12 34 56 78',
                  prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: Colors.black45),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Numéro de téléphone requis' : null,
              ),

              const SizedBox(height: 16),

              // 4. Numéro de suivi
              _buildLabel('Numéro de suivi'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _trackingNumberController,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                decoration: _inputDecoration(
                  hint: 'AMX09268IPF',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.black45, size: 20),
                    onPressed: () {
                      setState(() {
                        _trackingNumberController.text = _generateTrackingNumber();
                      });
                    },
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Champ obligatoire' : null,
              ),

              const SizedBox(height: 16),

              // 4. bis. Numéro de Colis & Scanner Code-barres
              Row(
                children: [
                  _buildLabel('Numéro du Colis (Code-barres / Référence)'),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: const Text(
                      'Reconnaissance Auto',
                      style: TextStyle(color: Color(0xFF166534), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _parcelNumberController,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                  color: Color(0xFF0F172A),
                  letterSpacing: 0.8,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Ex: CLS-CAS-89241-MA',
                  prefixIcon: const Icon(Icons.inventory_2_outlined, size: 20, color: AmeexColors.primaryBlue),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Scanner Button with Ameex Blue badge
                      InkWell(
                        onTap: () async {
                          final scanned = await ParcelScannerDialog.show(context);
                          if (scanned != null && scanned.trim().isNotEmpty) {
                            setState(() {
                              _parcelNumberController.text = scanned.trim();
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                      const SizedBox(width: 8),
                                      Text('Code colis scanné : $scanned'),
                                    ],
                                  ),
                                  backgroundColor: const Color(0xFF10B981),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AmeexColors.primaryBlue,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: AmeexColors.primaryBlue.withValues(alpha: 0.25),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text('Scanner', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.black45, size: 18),
                        tooltip: 'Générer un nouveau code',
                        onPressed: () {
                          setState(() {
                            _parcelNumberController.text = _generateParcelNumber();
                          });
                        },
                      ),
                    ],
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AmeexColors.primaryBlue, width: 1.5),
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Numéro de colis requis' : null,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 13, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Cliquez sur "Scanner" pour scanner le code-barres physique du colis.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 5. Ville de destination
              _buildLabel('Ville de destination'),
              const SizedBox(height: 6),
              Container(
                decoration: _fieldBoxDecoration(),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCity,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
                    items: _cities.map((city) {
                      return DropdownMenuItem(
                        value: city,
                        child: Text(city, style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A))),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCity = val);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 6. Adresse de livraison exacte
              _buildLabel('Adresse de livraison exacte'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _addressController,
                style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                decoration: _inputDecoration(
                  hint: 'Ex: Maarif, 45 Rue Abou Al Alaa, Imm B Appt 4',
                  prefixIcon: const Icon(Icons.location_on_outlined, size: 20, color: Colors.black45),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Veuillez saisir l\'adresse exacte' : null,
              ),

              const SizedBox(height: 16),

              // 7. Livreur assigné
              _buildLabel('Livreur assigné'),
              const SizedBox(height: 6),
              _isLoadingDrivers
                  ? const LinearProgressIndicator(color: navyColor)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: _fieldBoxDecoration(),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String?>(
                              value: _selectedDriverId,
                              isExpanded: true,
                              itemHeight: 56,
                              hint: const Text('Sélectionner un livreur', style: TextStyle(fontSize: 14, color: Colors.black38)),
                              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: Color(0xFFE2E8F0),
                                        child: Icon(Icons.person_off_rounded, size: 16, color: Colors.black45),
                                      ),
                                      SizedBox(width: 10),
                                      Text('Aucun livreur (En attente)', style: TextStyle(fontSize: 14, color: Colors.black54)),
                                    ],
                                  ),
                                ),
                                ..._drivers.map((driver) {
                                  final name = driver['full_name'] ?? 'Livreur';
                                  final vehicle = DriverAvatarHelper.cleanVehicle(driver['vehicle_type']);
                                  final zone = DriverAvatarHelper.cleanZone(driver['zone']);

                                  return DropdownMenuItem<String?>(
                                    value: driver['id'] as String,
                                    child: Row(
                                      children: [
                                        DriverAvatar(
                                          driverData: driver,
                                          radius: 16,
                                          borderColor: AmeexColors.primaryBlue,
                                          borderWidth: 1.5,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                name,
                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                '$vehicle • $zone',
                                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (val) {
                                setState(() => _selectedDriverId = val);
                              },
                            ),
                          ),
                        ),

                        // Selected Driver Preview Card
                        if (_selectedDriverId != null) ...[
                          Builder(builder: (context) {
                            final selectedDriver = _drivers.firstWhere(
                              (d) => d['id'] == _selectedDriverId,
                              orElse: () => <String, dynamic>{},
                            );
                            if (selectedDriver.isEmpty) return const SizedBox.shrink();

                            final name = selectedDriver['full_name'] ?? 'Livreur';
                            final phone = selectedDriver['phone'] ?? '';
                            final vehicle = DriverAvatarHelper.cleanVehicle(selectedDriver['vehicle_type']);
                            final zone = DriverAvatarHelper.cleanZone(selectedDriver['zone']);

                            return Container(
                              margin: const EdgeInsets.only(top: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF5FF),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AmeexColors.primaryBlue.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  DriverAvatar(
                                    driverData: selectedDriver,
                                    radius: 22,
                                    borderColor: AmeexColors.primaryBlue,
                                    borderWidth: 2,
                                    showBadge: true,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              name,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AmeexColors.primaryBlue),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                vehicle,
                                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Zone : $zone • 📞 $phone',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ),

              const SizedBox(height: 16),

              // 8 & 9. Montant de la commande & Gain du livreur
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Montant commande (MAD)'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
                          decoration: _inputDecoration(hint: '150', suffixText: 'MAD'),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Requis' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Gain du livreur (MAD)'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _driverFeeController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 14, color: Color(0xFF16A34A), fontWeight: FontWeight.bold),
                          decoration: _inputDecoration(hint: '25', suffixText: 'MAD'),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Requis' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navyColor,
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
                          'Transmettre la commande au livreur',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              const SizedBox(height: 24),
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

  InputDecoration _inputDecoration({required String hint, Widget? prefixIcon, Widget? suffixIcon, String? suffixText}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      suffixText: suffixText,
      suffixStyle: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
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
