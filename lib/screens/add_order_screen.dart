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

  String _selectedVehicle = 'Moto';
  String _selectedCity = 'Toutes les villes';
  DateTime _selectedDeliveryDate = DateTime.now();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController(text: '06');
  final _trackingNumberController = TextEditingController();
  final _parcelNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _amountController = TextEditingController(text: '150');
  final _driverFeeController = TextEditingController(text: '25'); // Gain du livreur
  
  String? _selectedDriverId;
  List<Map<String, dynamic>> _drivers = [];
  Set<String> _onlineDriverIds = {};

  bool _isLoadingDrivers = true;
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _vehicleOptions = [
    {'name': 'Tous', 'label': 'Tous', 'icon': Icons.all_inclusive_rounded},
    {'name': 'Moto', 'label': 'Moto', 'icon': Icons.two_wheeler_rounded},
    {'name': 'Vélo', 'label': 'Vélo', 'icon': Icons.pedal_bike_rounded},
    {'name': 'Voiture', 'label': 'Voiture', 'icon': Icons.directions_car_rounded},
    {'name': 'Fourgonnette', 'label': 'Van', 'icon': Icons.local_shipping_rounded},
  ];

  final List<String> _cities = [
    'Toutes les villes',
    'Casablanca',
    'Rabat',
    'Marrakech',
    'Tanger',
    'Fès',
    'Agadir',
    'Meknès',
    'Oujda',
    'Kénitra',
    'Tétouan',
    'Salé',
    'Mohammedia',
    'El Jadida',
    'Nador',
    'Béni Mellal',
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
          .select('id, full_name, phone, vehicle_type, zone, avatar_url, role')
          .eq('role', 'driver');

      final onlineIds = <String>{};
      try {
        final locData = await supabase
            .from('driver_locations')
            .select('driver_id, updated_at');
        final now = DateTime.now().toUtc();
        for (final l in locData) {
          final dId = l['driver_id'] as String?;
          final updatedAtStr = l['updated_at'] as String?;
          if (dId != null && updatedAtStr != null) {
            final dt = DateTime.tryParse(updatedAtStr);
            // Considered online if updated within last 20 minutes
            if (dt != null && now.difference(dt.toUtc()).inMinutes.abs() < 20) {
              onlineIds.add(dId);
            }
          }
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _drivers = List<Map<String, dynamic>>.from(data);
          _onlineDriverIds = onlineIds;
          _syncSelectedDriverWithFilter();
          _isLoadingDrivers = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingDrivers = false);
    }
  }

  List<Map<String, dynamic>> get _filteredDrivers {
    return _drivers.where((driver) {
      // 1. Vehicle filter
      if (_selectedVehicle != 'Tous') {
        final v = DriverAvatarHelper.cleanVehicle(driver['vehicle_type']).toLowerCase();
        final target = _selectedVehicle.toLowerCase();
        bool match = false;
        if (target.contains('moto') && v.contains('moto')) {
          match = true;
        } else if ((target.contains('vélo') || target.contains('velo')) &&
            (v.contains('vélo') || v.contains('velo') || v.contains('bike'))) {
          match = true;
        } else if (target.contains('voiture') && (v.contains('voiture') || v.contains('car'))) {
          match = true;
        } else if (target.contains('fourgon') && (v.contains('fourgon') || v.contains('van'))) {
          match = true;
        } else if (v.contains(target) || target.contains(v)) {
          match = true;
        }
        if (!match) return false;
      }

      // 2. City filter
      if (_selectedCity != 'Toutes les villes') {
        final z = DriverAvatarHelper.cleanZone(driver['zone']).toLowerCase();
        final targetCity = _selectedCity.toLowerCase();
        if (!z.contains(targetCity)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _syncSelectedDriverWithFilter() {
    final filtered = _filteredDrivers;
    if (_selectedDriverId != null && !filtered.any((d) => d['id'] == _selectedDriverId)) {
      _selectedDriverId = filtered.isNotEmpty ? (filtered.first['id'] as String) : null;
    } else if (_selectedDriverId == null && filtered.isNotEmpty) {
      _selectedDriverId = filtered.first['id'] as String;
    }
  }

  Widget _buildQuickDateChip(String label, int addDays) {
    final targetDate = DateTime.now().add(Duration(days: addDays));
    final isSelected = _selectedDeliveryDate.year == targetDate.year &&
        _selectedDeliveryDate.month == targetDate.month &&
        _selectedDeliveryDate.day == targetDate.day;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDeliveryDate = targetDate;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AmeexColors.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AmeexColors.primaryBlue : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AmeexColors.primaryBlue.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDeliveryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeliveryDate,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AmeexColors.primaryBlue,
              onPrimary: Colors.white,
              onSurface: AmeexColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDeliveryDate = picked;
      });
    }
  }

  String _formatDisplayDate(DateTime dt) {
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
    final dayName = days[dt.weekday - 1];
    final monthName = months[dt.month - 1];
    return '$dayName ${dt.day} $monthName ${dt.year}';
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

      final effectiveCity = _selectedCity != 'Toutes les villes' ? _selectedCity : 'Casablanca';
      final String rawAddress = _addressController.text.trim().isEmpty 
          ? '$effectiveCity Centre' 
          : _addressController.text.trim();
      final String addressWithParcel = ParcelHelper.formatWithParcel(rawAddress, parcelNumber);

      final String notes = _notesController.text.trim();
      final String formattedDeliveryDate =
          '${_selectedDeliveryDate.year}-${_selectedDeliveryDate.month.toString().padLeft(2, '0')}-${_selectedDeliveryDate.day.toString().padLeft(2, '0')}';

      final Map<String, dynamic> insertPayload = {
        'tracking_number': _trackingNumberController.text.trim(),
        'customer_name': _customerNameController.text.trim(),
        'customer_phone': _customerPhoneController.text.trim(),
        'destination_city': effectiveCity,
        'delivery_address': addressWithParcel,
        'amount': amount,
        'status': 'pending',
        'assigned_driver_id': _selectedDriverId,
      };

      // Safely try inserting with new columns
      try {
        await supabase.from('orders').insert({
          ...insertPayload,
          'delivery_type': _selectedVehicle,
          'driver_fee': driverFee,
          'parcel_number': parcelNumber,
          'delivery_date': formattedDeliveryDate,
          'notes': notes.isNotEmpty ? notes : null,
        });
      } catch (_) {
        try {
          await supabase.from('orders').insert({
            ...insertPayload,
            'delivery_type': _selectedVehicle,
            'driver_fee': driverFee,
            'parcel_number': parcelNumber,
          });
        } catch (_) {
          final String extraInfo = [
            'Véhicule: $_selectedVehicle',
            'Ville: $effectiveCity',
            'Date livraison: $formattedDeliveryDate',
            if (notes.isNotEmpty) 'Remarques: $notes',
            'Gain: $driverFee MAD',
          ].join(' | ');

          await supabase.from('orders').insert({
            ...insertPayload,
            'delivery_address': '$addressWithParcel [$extraInfo]',
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
    _notesController.dispose();
    _amountController.dispose();
    _driverFeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const navyColor = AmeexColors.primaryBlue;

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
          'Nouvelle commande',
          style: TextStyle(
            color: AmeexColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: -0.3,
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
              // 1. Type de véhicule requis (remplace Type de livraison)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLabel('Type de véhicule requis'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: AmeexColors.primaryBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AmeexColors.primaryBlue.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.filter_alt_rounded, size: 12, color: AmeexColors.primaryBlue),
                        SizedBox(width: 4),
                        Text(
                          'Filtre automatique',
                          style: TextStyle(color: AmeexColors.primaryBlue, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: _vehicleOptions.map((v) {
                  final isSelected = _selectedVehicle == v['name'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedVehicle = v['name'] as String;
                          _syncSelectedDriverWithFilter();
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AmeexColors.primaryBlue : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? AmeexColors.primaryBlue : const Color(0xFFE2E8F0),
                            width: isSelected ? 1.5 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AmeexColors.primaryBlue.withValues(alpha: 0.22),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              v['icon'] as IconData,
                              color: isSelected ? Colors.white : const Color(0xFF64748B),
                              size: 20,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              v['label'] as String,
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

              const SizedBox(height: 16),

              // 1. bis Ville de livraison
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLabel('Ville de livraison'),
                  Text(
                    'Filtre livreurs par ville',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
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
                        child: Row(
                          children: [
                            Icon(
                              city == 'Toutes les villes' ? Icons.map_rounded : Icons.location_city_rounded,
                              size: 16,
                              color: city == 'Toutes les villes' ? Colors.grey : AmeexColors.primaryBlue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                city,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedCity = val;
                          _syncSelectedDriverWithFilter();
                        });
                      }
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

              // 5. Ville choisie
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Ville de livraison'),
                        const SizedBox(height: 6),
                        Container(
                          decoration: _fieldBoxDecoration(),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          child: Row(
                            children: [
                              const Icon(Icons.location_city_rounded, size: 18, color: AmeexColors.primaryBlue),
                              const SizedBox(width: 8),
                              Text(
                                _selectedCity == 'Toutes les villes' ? 'Casablanca' : _selectedCity,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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

              // 6. bis Date de livraison souhaitée (تاريخ التسليم)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLabel('Date de livraison souhaitée'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: AmeexColors.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _formatDisplayDate(_selectedDeliveryDate),
                      style: const TextStyle(
                        color: AmeexColors.primaryBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _buildQuickDateChip('Aujourd\'hui', 0),
                  const SizedBox(width: 6),
                  _buildQuickDateChip('Demain', 1),
                  const SizedBox(width: 6),
                  _buildQuickDateChip('Après-demain', 2),
                  const SizedBox(width: 6),
                  Expanded(
                    child: InkWell(
                      onTap: _pickDeliveryDate,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                        decoration: BoxDecoration(
                          color: AmeexColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_month_rounded, size: 16, color: AmeexColors.primaryBlue),
                            SizedBox(width: 4),
                            Text(
                              'Autre date',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AmeexColors.primaryBlue),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 6. ter Remarques & Instructions spéciales (ملاحظات)
              _buildLabel('Remarques & Instructions spéciales (ملاحظات)'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                decoration: _inputDecoration(
                  hint: 'Ex: Sonner à l\'interphone B, appeler avant d\'arriver, ne pas laisser chez le concierge...',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 22),
                    child: Icon(Icons.sticky_note_2_outlined, size: 20, color: Colors.black45),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 7. Livreur assigné (Filtré dynamiquement)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLabel('Livreur assigné'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _filteredDrivers.isEmpty ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _filteredDrivers.isEmpty ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC),
                      ),
                    ),
                    child: Text(
                      _filteredDrivers.isEmpty
                          ? '0 livreur correspondant'
                          : '${_filteredDrivers.length} livreur(s) disponible(s)',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: _filteredDrivers.isEmpty ? const Color(0xFFB91C1C) : const Color(0xFF15803D),
                      ),
                    ),
                  ),
                ],
              ),
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
                                ..._filteredDrivers.map((driver) {
                                  final name = driver['full_name'] ?? 'Livreur';
                                  final vehicle = DriverAvatarHelper.cleanVehicle(driver['vehicle_type']);
                                  final zone = DriverAvatarHelper.cleanZone(driver['zone']);
                                  final isOnline = _onlineDriverIds.contains(driver['id']);

                                  return DropdownMenuItem<String?>(
                                    value: driver['id'] as String,
                                    child: Row(
                                      children: [
                                        Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            DriverAvatar(
                                              driverData: driver,
                                              radius: 16,
                                              borderColor: isOnline ? const Color(0xFF10B981) : AmeexColors.primaryBlue,
                                              borderWidth: 1.5,
                                            ),
                                            Positioned(
                                              bottom: 0,
                                              right: 0,
                                              child: Container(
                                                width: 10,
                                                height: 10,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                                  border: Border.all(color: Colors.white, width: 2),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      name,
                                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Container(
                                                    margin: const EdgeInsets.only(left: 4),
                                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                    decoration: BoxDecoration(
                                                      color: isOnline ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Container(
                                                          width: 6,
                                                          height: 6,
                                                          decoration: BoxDecoration(
                                                            shape: BoxShape.circle,
                                                            color: isOnline ? const Color(0xFF15803D) : const Color(0xFFDC2626),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          isOnline ? 'En ligne' : 'Hors ligne',
                                                          style: TextStyle(
                                                            fontSize: 9.5,
                                                            fontWeight: FontWeight.bold,
                                                            color: isOnline ? const Color(0xFF15803D) : const Color(0xFFDC2626),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
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

                        if (_filteredDrivers.isEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Aucun livreur avec le véhicule "$_selectedVehicle" dans cette ville ($_selectedCity). Vous pouvez choisir "Tous" ou enregistrer la commande sans livreur.',
                                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF92400E)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

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
                            final isOnline = _onlineDriverIds.contains(selectedDriver['id']);

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
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      DriverAvatar(
                                        driverData: selectedDriver,
                                        radius: 22,
                                        borderColor: isOnline ? const Color(0xFF10B981) : AmeexColors.primaryBlue,
                                        borderWidth: 2,
                                        showBadge: true,
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                            border: Border.all(color: Colors.white, width: 2),
                                          ),
                                        ),
                                      ),
                                    ],
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
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: isOnline ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    width: 6,
                                                    height: 6,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: isOnline ? const Color(0xFF15803D) : const Color(0xFFDC2626),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    isOnline ? 'En ligne' : 'Hors ligne',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: isOnline ? const Color(0xFF15803D) : const Color(0xFFDC2626),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Ville : $zone • 📞 $phone',
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
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitOrder,
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
                              'Transmettre la commande',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
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

  InputDecoration _inputDecoration({required String hint, Widget? prefixIcon, Widget? suffixIcon, String? suffixText}) {
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
      suffixText: suffixText,
      suffixStyle: const TextStyle(
        color: AmeexColors.textMuted,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
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
