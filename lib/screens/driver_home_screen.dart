import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:swipeable_button_view/swipeable_button_view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../theme/ameex_theme.dart';
import '../widgets/driver_avatar.dart';
import '../widgets/ameex_animations.dart';
import '../widgets/parcel_scanner_dialog.dart';
import '../widgets/caisse_remittance_helper.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    const deepNavy = AmeexColors.primaryBlue;

    return Scaffold(
      body: AnimatedIndexedStack(
        index: _currentNavIndex,
        children: const [
          DriverLiveMapTab(),
          DriverHistoryTab(),
          DriverEarningsTab(),
          DriverProfileTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: const Color(0xFFE2E8F0), width: 0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentNavIndex,
          onTap: (index) => setState(() => _currentNavIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: deepNavy,
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.navigation_rounded),
              label: 'Course',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded),
              label: 'Historique',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Revenus',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// TAB 1: LIVE MAP WITH MULTI-STAGE AGENCY PICKUP & CLIENT PINPOINT WORKFLOW
// ============================================================================
class DriverLiveMapTab extends StatefulWidget {
  const DriverLiveMapTab({super.key});

  @override
  State<DriverLiveMapTab> createState() => _DriverLiveMapTabState();
}

class _DriverLiveMapTabState extends State<DriverLiveMapTab> {
  final supabase = Supabase.instance.client;
  final MapController _mapController = MapController();

  Timer? _locationTimer;
  LatLng _driverLocation = const LatLng(33.5892, -7.6324);
  LatLng? _orderStartLocation;

  // Agency Location in Casablanca (e.g. Ameex Hub)
  final LatLng _agencyLocation = const LatLng(33.5870, -7.6350);

  // Manual Position Adjustment Mode
  bool _isAdjustingMyPosition = false;

  // Client Custom Destination Pin (Selected on Map by Driver)
  LatLng? _customDestinationPin;
  bool _isSelectingLocationOnMap = false;

  // Search Bar on Map (OpenStreetMap Nominatim + Moroccan shortcuts)
  final TextEditingController _mapSearchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _showSearchResults = false;
  bool _showQuickChips = false;
  Timer? _searchDebounceTimer;

  // Live Telemetry
  double _currentSpeedKmh = 0.0;
  double _totalTripDistanceKm = 4.5;
  double _distanceTraveledKm = 0.0;
  double _remainingDistanceKm = 4.5;
  int _progressPercentage = 0;
  int _estimatedMinutesRemaining = 12;

  Map<String, dynamic>? _currentOrder;
  bool _isLoadingOrder = true;
  bool _isSwipeFinished = false;

  Map<String, dynamic>? _driverProfile;

  @override
  void initState() {
    super.initState();
    final u = supabase.auth.currentUser;
    if (u != null) {
      supabase.from('profiles').select().eq('id', u.id).maybeSingle().then((p) {
        if (mounted && p != null) setState(() => _driverProfile = p);
      });
    }
    _startLiveGPS();
    _fetchAssignedOrder();
    _listenToOrderUpdates();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _searchDebounceTimer?.cancel();
    _mapSearchController.dispose();
    super.dispose();
  }

  void _onSearchQueryChanged(String query) {
    _searchDebounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
        _isSearching = false;
      });
      return;
    }

    _searchDebounceTimer = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _isSearching = true);
      final results = await _queryNominatim(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _showSearchResults = true;
          _isSearching = false;
        });
      }
    });
  }

  Future<List<Map<String, dynamic>>> _queryNominatim(String query) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&countrycodes=ma&limit=6',
      );
      final resp = await http.get(uri, headers: {
        'User-Agent': 'AmeexLogistics/1.0 (contact@ameex.ma)',
        'Accept-Language': 'fr,ar',
      }).timeout(const Duration(seconds: 4));

      if (resp.statusCode == 200) {
        final List data = jsonDecode(resp.body);
        if (data.isNotEmpty) {
          return data.cast<Map<String, dynamic>>();
        }
      }
    } catch (_) {}

    // Fallback list of major Moroccan neighborhoods and cities
    final lower = query.toLowerCase();
    final moroccanPlaces = [
      {'display_name': 'Maârif, Casablanca', 'lat': '33.5878', 'lon': '-7.6375'},
      {'display_name': 'Gauthier, Casablanca', 'lat': '33.5935', 'lon': '-7.6272'},
      {'display_name': 'Anfa / Bd d\'Anfa, Casablanca', 'lat': '33.5852', 'lon': '-7.6534'},
      {'display_name': 'Ain Diab / Corniche, Casablanca', 'lat': '33.5886', 'lon': '-7.6781'},
      {'display_name': 'Sidi Maarouf / Technopark, Casablanca', 'lat': '33.5350', 'lon': '-7.6430'},
      {'display_name': 'Bourgogne, Casablanca', 'lat': '33.5982', 'lon': '-7.6410'},
      {'display_name': 'Derb Ghallef, Casablanca', 'lat': '33.5765', 'lon': '-7.6258'},
      {'display_name': 'Sbata / Jamila, Casablanca', 'lat': '33.5520', 'lon': '-7.5850'},
      {'display_name': 'Hay Mohammadi, Casablanca', 'lat': '33.5950', 'lon': '-7.5750'},
      {'display_name': 'Hay Hassani, Casablanca', 'lat': '33.5570', 'lon': '-7.6820'},
      {'display_name': 'Centre-Ville / Bd Mohammed V, Casablanca', 'lat': '33.5950', 'lon': '-7.6180'},
      {'display_name': 'Oulfa / Place Financière, Casablanca', 'lat': '33.5510', 'lon': '-7.6710'},
      {'display_name': 'Ain Sebaa, Casablanca', 'lat': '33.6060', 'lon': '-7.5350'},
      {'display_name': 'Bernoussi, Casablanca', 'lat': '33.6040', 'lon': '-7.5020'},
      {'display_name': 'Californie, Casablanca', 'lat': '33.5380', 'lon': '-7.6320'},
      {'display_name': 'Hay Riad, Rabat', 'lat': '33.9650', 'lon': '-6.8780'},
      {'display_name': 'Agdal, Rabat', 'lat': '33.9980', 'lon': '-6.8480'},
      {'display_name': 'Guéliz, Marrakech', 'lat': '31.6340', 'lon': '-8.0120'},
      {'display_name': 'Hivernage, Marrakech', 'lat': '31.6210', 'lon': '-8.0150'},
      {'display_name': 'Médina, Tanger', 'lat': '35.7880', 'lon': '-5.8120'},
      {'display_name': 'Malabata, Tanger', 'lat': '35.7760', 'lon': '-5.7860'},
    ];

    return moroccanPlaces.where((p) => p['display_name']!.toLowerCase().contains(lower)).toList();
  }

  void _selectSearchedPlace(Map<String, dynamic> place) {
    final lat = double.tryParse(place['lat'].toString());
    final lon = double.tryParse(place['lon'].toString());
    if (lat == null || lon == null) return;

    final target = LatLng(lat, lon);
    setState(() {
      _customDestinationPin = target;
      _showSearchResults = false;
      _showQuickChips = false;
      _isSelectingLocationOnMap = true;
      _mapSearchController.text = (place['display_name'] ?? '').toString().split(',').take(2).join(', ');
      FocusScope.of(context).unfocus();
    });

    _mapController.move(target, 16.5);
    _syncDestinationToSupabase(target);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Point placé à "${_mapSearchController.text}". Vous pouvez toucher la carte pour ajuster.'),
        backgroundColor: const Color(0xFF0A192F),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _syncDestinationToSupabase(LatLng point) async {
    if (_currentOrder == null) return;
    try {
      await supabase.from('orders').update({
        'dest_latitude': point.latitude,
        'dest_longitude': point.longitude,
      }).eq('id', _currentOrder!['id']);
    } catch (_) {}
  }

  Future<void> _startLiveGPS() async {
    try {
      // 1. Try real hardware/browser GPS with highest navigation accuracy
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation),
      ).timeout(const Duration(seconds: 4));

      final realLatLng = LatLng(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() {
          _driverLocation = realLatLng;
          _updateTelemetry(pos);
        });
        _mapController.move(realLatLng, 16.0);
      }

      await _streamToSupabase(pos);
    } catch (e) {
      // 2. HTTP Web Browser Fallback: IP-based real coordinates
      try {
        final client = Supabase.instance.client;
        // Try getting accurate real coordinates from ipapi
        final res = await client.functions.invoke('get_ip_location').catchError((_) => const FunctionResponse(data: null, status: 500));
        if (res.data != null && res.data['latitude'] != null) {
          final lat = (res.data['latitude'] as num).toDouble();
          final lng = (res.data['longitude'] as num).toDouble();
          final ipLatLng = LatLng(lat, lng);
          if (mounted) {
            setState(() => _driverLocation = ipLatLng);
            _mapController.move(ipLatLng, 15.0);
          }
        }
      } catch (_) {}
    }

    // Continuous GPS polling
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      try {
        final p = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation),
        );
        if (mounted) {
          setState(() {
            _driverLocation = LatLng(p.latitude, p.longitude);
            _updateTelemetry(p);
          });
        }
        await _streamToSupabase(p);
      } catch (_) {}
    });
  }

  void _updateTelemetry(Position pos) {
    final speedKmh = pos.speed > 0 ? (pos.speed * 3.6) : 0.0;
    _currentSpeedKmh = speedKmh;

    if (_currentOrder == null || _currentOrder!['status'] != 'in_transit') return;

    final destination = _customDestinationPin ?? LatLng(_driverLocation.latitude + 0.012, _driverLocation.longitude + 0.014);
    _orderStartLocation ??= _driverLocation;

    const distanceCalc = Distance();
    final totalMeters = distanceCalc.as(LengthUnit.Meter, _orderStartLocation!, destination);
    final remainingMeters = distanceCalc.as(LengthUnit.Meter, _driverLocation, destination);

    final totalKm = totalMeters > 500 ? (totalMeters / 1000.0) : 4.5;
    final remainingKm = (remainingMeters / 1000.0).clamp(0.1, totalKm);
    final traveledKm = (totalKm - remainingKm).clamp(0.0, totalKm);

    final progress = (traveledKm / totalKm).clamp(0.0, 1.0);
    final progressPct = (progress * 100).round();

    final effectiveSpeed = _currentSpeedKmh > 5 ? _currentSpeedKmh : 28.0;
    final etaMinutes = ((remainingKm / effectiveSpeed) * 60).round().clamp(1, 120);

    setState(() {
      _totalTripDistanceKm = double.parse(totalKm.toStringAsFixed(1));
      _distanceTraveledKm = double.parse(traveledKm.toStringAsFixed(1));
      _remainingDistanceKm = double.parse(remainingKm.toStringAsFixed(1));
      _progressPercentage = progressPct;
      _estimatedMinutesRemaining = etaMinutes;
    });
  }

  Future<void> _streamToSupabase(Position pos) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('driver_locations').upsert({
        'driver_id': user.id,
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'heading': pos.heading,
        'speed': _currentSpeedKmh,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'driver_id');
    } catch (_) {}
  }

  Future<void> _fetchAssignedOrder() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await supabase
          .from('orders')
          .select()
          .eq('assigned_driver_id', user.id)
          .filter('status', 'in', ['pending', 'accepted', 'in_transit'])
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _currentOrder = data;
          _isLoadingOrder = false;

          // Check if custom dest coords exist
          if (data != null && data['dest_latitude'] != null && data['dest_longitude'] != null) {
            _customDestinationPin = LatLng(
              (data['dest_latitude'] as num).toDouble(),
              (data['dest_longitude'] as num).toDouble(),
            );
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingOrder = false);
    }
  }

  void _listenToOrderUpdates() {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('assigned_driver_id', user.id)
        .listen((orders) {
          final active = orders
              .where((o) => o['status'] == 'pending' || o['status'] == 'accepted' || o['status'] == 'in_transit')
              .toList();

          if (mounted) {
            setState(() {
              _currentOrder = active.isNotEmpty ? active.first : null;
              _isSwipeFinished = false;

              if (_currentOrder != null &&
                  _currentOrder!['dest_latitude'] != null &&
                  _currentOrder!['dest_longitude'] != null) {
                _customDestinationPin = LatLng(
                  (_currentOrder!['dest_latitude'] as num).toDouble(),
                  (_currentOrder!['dest_longitude'] as num).toDouble(),
                );
              }
            });
          }
        });
  }

  /// STAGE 1: Driver Swipes to Accept Mission -> Status becomes 'accepted'
  Future<void> _acceptMissionGoToAgency() async {
    if (_currentOrder == null) return;
    try {
      // Set status to accepted
      try {
        await supabase
            .from('orders')
            .update({'status': 'accepted'})
            .eq('id', _currentOrder!['id']);
      } catch (_) {
        // Fallback: If enum 'accepted' not added, use delivery_address tag
        await supabase.from('orders').update({
          'delivery_address': '${_currentOrder!['delivery_address'] ?? ''} [ETAT: ACCEPTE_ATTENTE_AGENCE]',
        }).eq('id', _currentOrder!['id']);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mission acceptée ! Rendez-vous à l\'agence pour récupérer le colis.'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _showError('Erreur: $e');
    }
  }

  /// STAGE 2: Confirm destination point on map & start delivery
  Future<void> _confirmDestinationAndStartRoute() async {
    if (_currentOrder == null) return;

    final targetPin = _customDestinationPin ?? LatLng(_driverLocation.latitude + 0.012, _driverLocation.longitude + 0.014);

    try {
      await supabase.from('orders').update({
        'status': 'in_transit',
        'dest_latitude': targetPin.latitude,
        'dest_longitude': targetPin.longitude,
      }).eq('id', _currentOrder!['id']);

      setState(() {
        _isSelectingLocationOnMap = false;
        _orderStartLocation = _driverLocation;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Point de livraison confirmé ! Le trajet est maintenant tracé.'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _showError('Erreur: $e');
    }
  }

  Future<void> _markAsDelivered() async {
    if (_currentOrder == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la livraison'),
        content: const Text('Confirmez-vous la livraison complète du colis au client ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Oui, Colis Livré', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await supabase
          .from('orders')
          .update({'status': 'delivered'})
          .eq('id', _currentOrder!['id']);

      setState(() {
        _customDestinationPin = null;
        _isSelectingLocationOnMap = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Félicitations ! Course livrée et rémunération créditée.'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _showError('Erreur: $e');
    }
  }

  Future<void> _cancelOrderWithMotif() async {
    if (_currentOrder == null) return;

    final bool isEligibleForPayment = _progressPercentage >= 50;
    final double driverFee = (_currentOrder!['driver_fee'] as num?)?.toDouble() ?? 25.0;

    final motifController = TextEditingController();
    String selectedPredefined = 'Client injoignable';

    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Annuler la commande', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isEligibleForPayment ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isEligibleForPayment ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isEligibleForPayment ? Icons.verified_user_rounded : Icons.info_outline_rounded,
                        color: isEligibleForPayment ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEligibleForPayment ? 'Rémunération 100% Garantie !' : 'Annulation sans indemnité',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isEligibleForPayment ? const Color(0xFF166534) : const Color(0xFF92400E),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isEligibleForPayment
                                  ? 'Vous avez parcouru $_progressPercentage% du trajet (> 50%). Votre gain de $driverFee MAD reste intégralement crédité !'
                                  : 'Trajet parcouru : $_progressPercentage% (inférieur à 50%).',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                const Text('Motif d\'annulation :'),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: selectedPredefined,
                  isExpanded: true,
                  items: [
                    'Client injoignable',
                    'Adresse introuvable',
                    'Refus du client',
                    'Colis endommagé',
                    'Autre motif',
                  ].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (val) {
                    if (val != null) setDlgState(() => selectedPredefined = val);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: motifController,
                  decoration: const InputDecoration(
                    hintText: 'Précisions supplémentaires...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(10),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Retour'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                final text = motifController.text.trim();
                final finalMotif = text.isNotEmpty ? '$selectedPredefined : $text' : selectedPredefined;
                Navigator.of(ctx).pop(finalMotif);
              },
              child: const Text('Confirmer l\'annulation', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (result == null || result.isEmpty) return;

    try {
      final compensationTag = isEligibleForPayment
          ? ' [INDEMNISÉ >50% TRAJET: +${driverFee} MAD GARANTI]'
          : '';

      await supabase.from('orders').update({
        'status': 'cancelled',
        'delivery_address': '${_currentOrder!['delivery_address'] ?? ''} [MOTIF: $result]$compensationTag',
      }).eq('id', _currentOrder!['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEligibleForPayment
                ? 'Commande annulée. Rémunération de $driverFee MAD garantie (>50% trajet) !'
                : 'Commande annulée. Motif transmis à l\'administrateur.'),
            backgroundColor: isEligibleForPayment ? const Color(0xFF10B981) : Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _showError('Erreur: $e');
    }
  }

  void _callCustomer(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final Uri launchUri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      }
    } catch (_) {}
  }

  Future<void> _streamManualLocation(LatLng point) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    try {
      await supabase.from('driver_locations').upsert({
        'driver_id': user.id,
        'latitude': point.latitude,
        'longitude': point.longitude,
        'heading': 0.0,
        'speed': _currentSpeedKmh,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'driver_id');
    } catch (_) {}
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    const deepNavy = AmeexColors.primaryBlue;
    const orangeAccent = Color(0xFFFA5A1E);

    final bool hasActiveOrder = _currentOrder != null;
    final String rawStatus = _currentOrder?['status'] ?? 'none';
    final String addressRaw = _currentOrder?['delivery_address'] ?? '';

    // Check custom state:
    final bool isAcceptedWaitingAgency = rawStatus == 'accepted' || addressRaw.contains('[ETAT: ACCEPTE_ATTENTE_AGENCE]');
    final bool isAdminHandoverDone = rawStatus == 'in_transit' || addressRaw.contains('[COLIS_REMIS_PAR_ADMIN]');
    final bool isInTransitDelivering = isAdminHandoverDone && _customDestinationPin != null && !_isSelectingLocationOnMap;
    final bool isWaitingPinSelection = isAdminHandoverDone && (_customDestinationPin == null || _isSelectingLocationOnMap);

    final String trackingNumber = _currentOrder?['tracking_number'] ?? '#AMX';
    final String deliveryType = _currentOrder?['delivery_type'] ?? 'Standard';
    final String customerName = _currentOrder?['customer_name'] ?? 'Client';
    final String customerPhone = _currentOrder?['customer_phone'] ?? 'Non renseigné';
    final String destinationCity = _currentOrder?['destination_city'] ?? 'Casablanca';
    final String deliveryAddress = _currentOrder?['delivery_address'] ?? 'Adresse non spécifiée';
    final double amount = (_currentOrder?['amount'] as num?)?.toDouble() ?? 0.0;
    final double driverFee = (_currentOrder?['driver_fee'] as num?)?.toDouble() ?? 25.0;

    final LatLng finalClientDestination = _customDestinationPin ??
        LatLng(_driverLocation.latitude + 0.012, _driverLocation.longitude + 0.014);

    return Stack(
      children: [
        // 1. OPENSTREETMAP (ONLY REAL ROUTE AFTER DESTINATION PINPOINTED)
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _driverLocation,
            initialZoom: 15.0,
            onTap: (tapPosition, point) {
              if (_isAdjustingMyPosition) {
                setState(() {
                  _driverLocation = point;
                });
                _streamManualLocation(point);
              } else if (hasActiveOrder) {
                setState(() {
                  _customDestinationPin = point;
                  _isSelectingLocationOnMap = true;
                  _showSearchResults = false;
                  _showQuickChips = false;
                });
                _syncDestinationToSupabase(point);
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('📍 Point client ajusté et synchronisé avec l\'Admin !'),
                    backgroundColor: Color(0xFF10B981),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.ameex.app',
            ),

            // ROUTE IS ONLY DRAWN WHEN COLIS IS REMIS AND IN TRANSIT TO CLIENT!
            if (isInTransitDelivering && _customDestinationPin != null)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [
                      _driverLocation,
                      _customDestinationPin!,
                    ],
                    strokeWidth: 4.5,
                    color: const Color(0xFF10B981),
                  ),
                ],
              ),

            // Route to Agency (if driver is on the way to agency)
            if (isAcceptedWaitingAgency)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [_driverLocation, _agencyLocation],
                    strokeWidth: 3.5,
                    color: Colors.blueAccent,
                  ),
                ],
              ),

            MarkerLayer(
              markers: [
                // Real Driver GPS Marker
                Marker(
                  point: _driverLocation,
                  width: 90,
                  height: 60,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                          ],
                        ),
                        child: const Text(
                          'Moi (GPS)',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: deepNavy),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Icon(Icons.delivery_dining_rounded, color: orangeAccent, size: 34),
                    ],
                  ),
                ),

                // Agency Marker (If going to agency)
                if (isAcceptedWaitingAgency)
                  Marker(
                    point: _agencyLocation,
                    width: 100,
                    height: 60,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: deepNavy,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '🏢 Agence Ameex',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Icon(Icons.storefront_rounded, color: deepNavy, size: 32),
                      ],
                    ),
                  ),

                // Client Destination Pin (When pinpointed or delivering)
                if (_customDestinationPin != null)
                  Marker(
                    point: _customDestinationPin!,
                    width: 140,
                    height: 68,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person_pin_circle_rounded, color: Colors.white, size: 12),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  customerName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Icon(Icons.location_on, color: Color(0xFFDC2626), size: 36),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),

        // 2. LIVE TELEMETRY HUD (Only when delivering on the road)
        if (isInTransitDelivering)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 14,
            right: 14,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: deepNavy,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 3)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.speed_rounded, color: Color(0xFF38BDF8), size: 26),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_currentSpeedKmh.toStringAsFixed(0)} km/h',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                              const Text('Vitesse', style: TextStyle(color: Colors.white70, fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                      Container(width: 1, height: 26, color: Colors.white24),
                      Column(
                        children: [
                          Text(
                            '${_distanceTraveledKm.toStringAsFixed(1)} km',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const Text('Parcouru', style: TextStyle(color: Colors.white70, fontSize: 10)),
                        ],
                      ),
                      Container(width: 1, height: 26, color: Colors.white24),
                      Column(
                        children: [
                          Text(
                            '${_remainingDistanceKm.toStringAsFixed(1)} km (~${_estimatedMinutesRemaining}m)',
                            style: const TextStyle(color: Color(0xFFFDE047), fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const Text('Reste / Arrivée', style: TextStyle(color: Colors.white70, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _progressPercentage >= 50 ? Icons.shield_rounded : Icons.shield_outlined,
                                color: _progressPercentage >= 50 ? const Color(0xFF10B981) : Colors.orange,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _progressPercentage >= 50
                                    ? 'Trajet > 50% : Rémunération garantie ($driverFee MAD)'
                                    : 'Avancement : $_progressPercentage% (Reste 50% pour garantie)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _progressPercentage >= 50 ? const Color(0xFF166534) : const Color(0xFF92400E),
                                ),
                              ),
                            ],
                          ),
                          Text('$_progressPercentage%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: _progressPercentage / 100.0,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _progressPercentage >= 50 ? const Color(0xFF10B981) : orangeAccent,
                          ),
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // TOP HEADER (Shown when not in transit)
        if (!isInTransitDelivering)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                bottom: 12,
                left: 18,
                right: 18,
              ),
              decoration: const BoxDecoration(
                color: deepNavy,
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const AmeexLogo(isWhite: true, height: 24),
                      const SizedBox(width: 10),
                      Container(width: 1, height: 16, color: Colors.white24),
                      const SizedBox(width: 10),
                      const AmeexPulseBadge(
                        color: Color(0xFF10B981),
                        size: 8,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'En Ligne',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.my_location, color: Colors.white70, size: 20),
                        tooltip: 'Actualiser GPS',
                        onPressed: _startLiveGPS,
                      ),
                      const SizedBox(width: 4),
                      DriverAvatar(
                        driverData: _driverProfile,
                        name: _driverProfile?['full_name'] ?? 'Livreur',
                        radius: 14,
                        borderColor: Colors.white,
                        borderWidth: 1.5,
                        showBadge: true,
                        badgeColor: const Color(0xFF10B981),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

        // 3. SEARCH BAR ON MAP (For manually picking or searching client destination)
        if (hasActiveOrder)
          Positioned(
            top: MediaQuery.of(context).padding.top + (isInTransitDelivering ? 118 : 64),
            left: 14,
            right: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 3)),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 12, right: 6),
                        child: Icon(Icons.search, color: deepNavy, size: 22),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _mapSearchController,
                          onChanged: _onSearchQueryChanged,
                          onTap: () {
                            if (_mapSearchController.text.isEmpty) {
                              setState(() => _showQuickChips = true);
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'Rechercher adresse client (ex: Maarif, Sbata...)',
                            hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            suffixIcon: _mapSearchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                                    onPressed: () {
                                      _mapSearchController.clear();
                                      setState(() {
                                        _searchResults = [];
                                        _showSearchResults = false;
                                        _showQuickChips = false;
                                      });
                                    },
                                  )
                                : (_isSearching
                                    ? const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: deepNavy),
                                        ),
                                      )
                                    : null),
                          ),
                        ),
                      ),
                      if (_customDestinationPin != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: IconButton(
                            icon: const Icon(Icons.my_location, color: Color(0xFF10B981), size: 20),
                            tooltip: 'Centrer sur la destination client',
                            onPressed: () => _mapController.move(_customDestinationPin!, 16.5),
                          ),
                        ),
                    ],
                  ),
                ),

                // QUICK MOROCCAN NEIGHBORHOOD CHIPS
                if (_showQuickChips && !_showSearchResults)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Quartiers fréquents (Casablanca / Maroc)',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: deepNavy),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _showQuickChips = false),
                              child: const Icon(Icons.close, size: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              'Maârif',
                              'Gauthier',
                              'Anfa',
                              'Bourgogne',
                              'Sbata',
                              'Sidi Maarouf',
                              'Ain Diab',
                              'Derb Ghallef',
                              'Hay Hassani',
                              'Centre-Ville',
                            ].map((q) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ActionChip(
                                label: Text(q, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                backgroundColor: const Color(0xFFF1F5F9),
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  _mapSearchController.text = q;
                                  _onSearchQueryChanged(q);
                                },
                              ),
                            )).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),

                // SEARCH SUGGESTIONS DROPDOWN
                if (_showSearchResults && _searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4)),
                      ],
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (context, index) {
                        final item = _searchResults[index];
                        final name = item['display_name'] ?? '';
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.location_on, color: Color(0xFFFA5A1E), size: 20),
                          title: Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: deepNavy),
                          ),
                          onTap: () => _selectSearchedPlace(item),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

        // FLOATING VALIDATION BANNER (When destination pin is set or being adjusted)
        if (hasActiveOrder && (_isSelectingLocationOnMap || isWaitingPinSelection) && _customDestinationPin != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: hasActiveOrder ? 380 : 180,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: deepNavy,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 3)),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Point client pointé sur la carte',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          '${_customDestinationPin!.latitude.toStringAsFixed(4)}, ${_customDestinationPin!.longitude.toStringAsFixed(4)} (Synchronisé Admin)',
                          style: const TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: _confirmDestinationAndStartRoute,
                    child: const Text('Valider', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),

        // RECENTER & MANUAL POSITION ADJUST BUTTONS
        Positioned(
          right: 16,
          bottom: hasActiveOrder ? 370 : 160,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'adjust_gps_btn',
                backgroundColor: _isAdjustingMyPosition ? const Color(0xFF10B981) : Colors.white,
                tooltip: 'Pointer ma position exacte',
                onPressed: () {
                  setState(() => _isAdjustingMyPosition = !_isAdjustingMyPosition);
                },
                child: Icon(
                  Icons.edit_location_alt_rounded,
                  color: _isAdjustingMyPosition ? Colors.white : deepNavy,
                ),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'recenter_gps_btn',
                backgroundColor: Colors.white,
                onPressed: () => _mapController.move(_driverLocation, 16.0),
                child: const Icon(Icons.gps_fixed, color: deepNavy),
              ),
            ],
          ),
        ),

        // INSTRUCTION OVERLAY IF ADJUSTING POSITION MANUALLY
        if (_isAdjustingMyPosition)
          Positioned(
            top: 70,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8)],
              ),
              child: Row(
                children: [
                  const Icon(Icons.touch_app_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Touchez la carte à l\'endroit exact où vous vous trouvez actuellement.',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(backgroundColor: Colors.white),
                    onPressed: () => setState(() => _isAdjustingMyPosition = false),
                    child: const Text('OK', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),

        // BOTTOM DRAGGABLE ORDER CARD (WITH ALL WORKFLOW STAGES)
        DraggableScrollableSheet(
          initialChildSize: hasActiveOrder ? 0.46 : 0.20,
          minChildSize: 0.18,
          maxChildSize: hasActiveOrder ? 0.75 : 0.28,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, -4)),
                ],
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (_isLoadingOrder)
                      const Center(child: CircularProgressIndicator(color: AmeexColors.primaryBlue))
                    else if (!hasActiveOrder) ...[
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Aucune course en cours',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: deepNavy),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Votre position et télémétrie GPS sont diffusées en direct.',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // ORDER DETAILS HEADER
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            trackingNumber,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Text(
                              deliveryType,
                              style: const TextStyle(color: Color(0xFF1D4ED8), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // PARCEL IDENTIFIER & BARCODE VERIFICATION CARD
                      Builder(
                        builder: (context) {
                          final parcelNumber = ParcelHelper.getParcelNumber(_currentOrder!);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AmeexColors.lightBlue,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.inventory_2_rounded, color: AmeexColors.primaryBlue, size: 20),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'RÉFÉRENCE COLIS (CODE-BARRES)',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        parcelNumber,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.bold,
                                          color: AmeexColors.primaryBlue,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: () async {
                                    final scanned = await ParcelScannerDialog.show(context);
                                    if (scanned != null && context.mounted) {
                                      final isMatch = scanned.trim().toLowerCase() == parcelNumber.toLowerCase();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              Icon(
                                                isMatch ? Icons.check_circle_rounded : Icons.warning_rounded,
                                                color: Colors.white,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  isMatch
                                                      ? '✅ Colis vérifié avec succès ($scanned) !'
                                                      : '⚠️ Attention : Le colis scanné ($scanned) ne correspond pas à cette commande ($parcelNumber) !',
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: isMatch ? const Color(0xFF10B981) : Colors.redAccent,
                                          duration: const Duration(seconds: 4),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AmeexColors.primaryBlue,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 14),
                                        SizedBox(width: 4),
                                        Text('Scanner', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      // ==============================================================
                      // WORKFLOW STAGE 2: DRIVER ACCEPTED -> MUST GO TO AGENCY TO PICK UP
                      // ==============================================================
                      if (isAcceptedWaitingAgency) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Row(
                                children: [
                                  Icon(Icons.storefront_rounded, color: Color(0xFFD97706), size: 24),
                                  SizedBox(width: 8),
                                  Text(
                                    'Étape 1 : Récupération à l\'agence',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF92400E)),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Veuillez vous diriger vers l\'agence Ameex pour récupérer le colis. L\'administrateur doit confirmer la remise physique du colis dans son application avant que le trajet client ne commence.',
                                style: TextStyle(fontSize: 12, color: Color(0xFF78350F)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // ==============================================================
                      // WORKFLOW STAGE 3: ADMIN HANDED OVER PARCEL -> POINT CUSTOMER ON MAP
                      // ==============================================================
                      if (isWaitingPinSelection) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 22),
                                  SizedBox(width: 8),
                                  Text(
                                    'Colis récupéré à l\'agence !',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF166534)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Touchez la carte pour pointer l\'adresse du client : "$deliveryAddress", puis validez pour tracer l\'itinéraire.',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF166534)),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: const Icon(Icons.alt_route_rounded),
                                  label: const Text('Confirmer le point & Tracer l\'itinéraire'),
                                  onPressed: _confirmDestinationAndStartRoute,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Client Info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: deepNavy,
                              child: Text(
                                customerName.isNotEmpty ? customerName[0].toUpperCase() : 'C',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customerName,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    customerPhone,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              style: IconButton.styleFrom(backgroundColor: const Color(0xFFDCFCE7)),
                              icon: const Icon(Icons.phone, color: Color(0xFF16A34A), size: 20),
                              tooltip: 'Appeler le client',
                              onPressed: () => _callCustomer(customerPhone),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Destination Address
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on, color: deepNavy, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    destinationCity,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    deliveryAddress,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                                  ),
                                  const SizedBox(height: 6),
                                  if (_customDestinationPin != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFF86EFAC)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF16A34A)),
                                          const SizedBox(width: 4),
                                          Text(
                                            'GPS fixé: ${_customDestinationPin!.latitude.toStringAsFixed(4)}, ${_customDestinationPin!.longitude.toStringAsFixed(4)}',
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFFEFF6FF),
                              ),
                              icon: const Icon(Icons.edit_location_alt_rounded, color: Color(0xFF1D4ED8), size: 20),
                              tooltip: 'Pointer / Rechercher sur la carte',
                              onPressed: () {
                                setState(() {
                                  _isSelectingLocationOnMap = true;
                                  _showQuickChips = true;
                                });
                                if (_customDestinationPin != null) {
                                  _mapController.move(_customDestinationPin!, 16.5);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Financials
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Montant à encaisser (COD)', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                const SizedBox(height: 2),
                                Text(
                                  '${amount.toStringAsFixed(2)} MAD',
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: deepNavy),
                                ),
                              ],
                            ),
                            Container(height: 28, width: 1, color: const Color(0xFFCBD5E1)),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Votre Gain Net', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                const SizedBox(height: 2),
                                Text(
                                  '+${driverFee.toStringAsFixed(2)} MAD',
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF16A34A)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ACTIONS ACCORDING TO STAGES:
                      // 1. Initial State: Swipe to accept mission
                      if (rawStatus == 'pending') ...[
                        SwipeableButtonView(
                          isFinished: _isSwipeFinished,
                          onWaitingProcess: () {
                            Future.delayed(const Duration(milliseconds: 300), () {
                              setState(() => _isSwipeFinished = true);
                            });
                          },
                          onFinish: () async {
                            await _acceptMissionGoToAgency();
                          },
                          activeColor: orangeAccent,
                          buttonWidget: Container(
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                            child: const Icon(Icons.keyboard_double_arrow_right_rounded, color: orangeAccent, size: 24),
                          ),
                          buttonText: 'Glisser pour accepter la mission',
                          buttontextstyle: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ] else if (isInTransitDelivering) ...[
                        Row(
                          children: [
                            Expanded(
                              flex: 7,
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.check_circle_rounded),
                                  label: const Text('Marquer comme Livré', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                  onPressed: _markAsDelivered,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: SizedBox(
                                height: 48,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.redAccent,
                                    side: const BorderSide(color: Colors.redAccent),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: _cancelOrderWithMotif,
                                  child: const Text('Annuler', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ============================================================================
// TAB 2: HISTORIQUE DES LIVRAISONS & COURSES ANNULÉES AVEC INDEMNITÉ
// ============================================================================
class DriverHistoryTab extends StatelessWidget {
  const DriverHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    const deepNavy = AmeexColors.primaryBlue;
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: deepNavy,
        elevation: 0,
        title: const Text('Historique des Livraisons', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('orders')
            .stream(primaryKey: ['id'])
            .eq('assigned_driver_id', user?.id ?? '')
            .order('updated_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AmeexColors.primaryBlue));
          }

          final allOrders = snapshot.data ?? [];
          final historyOrders = allOrders.where((o) {
            final status = o['status'];
            final address = (o['delivery_address'] ?? '').toString();
            return status == 'delivered' || (status == 'cancelled' && address.contains('[INDEMNISÉ >50%'));
          }).toList();

          if (historyOrders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.inventory_2_outlined, size: 54, color: Color(0xFF94A3B8)),
                  SizedBox(height: 12),
                  Text('Aucune course terminée ou indemnisée', style: TextStyle(color: Color(0xFF64748B), fontSize: 15)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: historyOrders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final order = historyOrders[index];
              final tracking = order['tracking_number'] ?? '#AMX';
              final customer = order['customer_name'] ?? 'Client';
              final city = order['destination_city'] ?? 'Casablanca';
              final driverFee = (order['driver_fee'] as num?)?.toDouble() ?? 25.0;
              final bool isCancelledIndemnified = order['status'] == 'cancelled';

              return AmeexFadeSlideIn(
                duration: const Duration(milliseconds: 280),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCancelledIndemnified ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isCancelledIndemnified ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isCancelledIndemnified ? Icons.shield_rounded : Icons.done_all_rounded,
                          color: isCancelledIndemnified ? const Color(0xFFD97706) : const Color(0xFF16A34A),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$tracking • $customer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF5FF),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Colis: ${ParcelHelper.getParcelNumber(order)}',
                                    style: const TextStyle(fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold, color: AmeexColors.primaryBlue),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    isCancelledIndemnified ? '$city (Annulé >50% indemnisé)' : city,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isCancelledIndemnified ? const Color(0xFFB45309) : const Color(0xFF64748B),
                                      fontSize: 12,
                                      fontWeight: isCancelledIndemnified ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '+${driverFee.toStringAsFixed(2)} MAD',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF16A34A)),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================================
// TAB 3: REVENUS & GAINS DU LIVREUR (SEPARATION CAISSE AGENCE & COMMISSIONS)
// ============================================================================
class DriverEarningsTab extends StatefulWidget {
  const DriverEarningsTab({super.key});

  @override
  State<DriverEarningsTab> createState() => _DriverEarningsTabState();
}

class _DriverEarningsTabState extends State<DriverEarningsTab> {
  String _ordersFilter = 'all'; // 'all', 'pending_caisse', 'remitted'

  void _showWithdrawDialog(BuildContext context, double availableAmount) {
    if (availableAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Votre solde disponible est de 0.00 MAD. Remettez votre caisse à l\'agence pour débloquer vos gains.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final amountController = TextEditingController(text: availableAmount.toStringAsFixed(2));
    final detailsController = TextEditingController();
    String selectedMethod = 'agency'; // 'agency', 'bank', 'cashplus'

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF16A34A), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Retirer vos Gains', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A))),
                        Text('Rémunération disponible', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Solde Débloqué :', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                          Text(
                            '${availableAmount.toStringAsFixed(2)} MAD',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Montant à retirer (MAD)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        suffixText: 'MAD',
                        suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: AmeexColors.primaryBlue),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Mode de versement', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('🏢 Espèces Agence', style: TextStyle(fontSize: 11)),
                          selected: selectedMethod == 'agency',
                          selectedColor: const Color(0xFFEFF5FF),
                          onSelected: (val) => setDialogState(() => selectedMethod = 'agency'),
                        ),
                        ChoiceChip(
                          label: const Text('🏦 Virement CIH / Attijari', style: TextStyle(fontSize: 11)),
                          selected: selectedMethod == 'bank',
                          selectedColor: const Color(0xFFEFF5FF),
                          onSelected: (val) => setDialogState(() => selectedMethod = 'bank'),
                        ),
                        ChoiceChip(
                          label: const Text('📱 Cash Plus / Barid Bank', style: TextStyle(fontSize: 11)),
                          selected: selectedMethod == 'cashplus',
                          selectedColor: const Color(0xFFEFF5FF),
                          onSelected: (val) => setDialogState(() => selectedMethod = 'cashplus'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (selectedMethod != 'agency') ...[
                      Text(
                        selectedMethod == 'bank' ? 'Numéro de RIB (24 chiffres)' : 'Numéro de Téléphone / CIN Cash Plus',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: detailsController,
                        decoration: InputDecoration(
                          hintText: selectedMethod == 'bank' ? 'ex: 230 780 0001234567890123 45' : 'ex: 06 12 34 56 78 (CIN: AB12345)',
                          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: AmeexColors.primaryBlue),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Les demandes de retrait sont validées sous 24h par l\'administration Ameex.',
                              style: TextStyle(fontSize: 11, color: AmeexColors.primaryBlue),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Annuler', style: TextStyle(color: Color(0xFF64748B))),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text('Confirmer le Retrait', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onPressed: () {
                    final enteredAmount = double.tryParse(amountController.text.trim()) ?? 0;
                    if (enteredAmount <= 0 || enteredAmount > availableAmount) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Veuillez saisir un montant valide inférieur ou égal à votre solde disponible.')),
                      );
                      return;
                    }
                    Navigator.of(ctx).pop();
                    _showWithdrawSuccess(context, enteredAmount, selectedMethod);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showWithdrawSuccess(BuildContext context, double amount, String method) {
    final ref = 'RET-AMX-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    String methodLabel = 'Espèces au Guichet Agence';
    if (method == 'bank') methodLabel = 'Virement Bancaire';
    if (method == 'cashplus') methodLabel = 'Cash Plus / Barid Bank';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'Demande de Retrait Transmise !',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Text(
              'Votre demande de ${amount.toStringAsFixed(2)} MAD via $methodLabel a été enregistrée avec succès.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Réf : ', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  Text(ref, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AmeexColors.primaryBlue)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AmeexColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Compris', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const deepNavy = AmeexColors.primaryBlue;
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: deepNavy,
        elevation: 0,
        title: const Text('Mes Revenus & Caisse Agence', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('orders')
            .stream(primaryKey: ['id'])
            .eq('assigned_driver_id', user?.id ?? ''),
        builder: (context, snapshot) {
          final orders = snapshot.data ?? [];
          final balances = CaisseRemittanceHelper.calculateBalances(orders);

          // Filter delivered and compensated orders for history list
          final relevantOrders = orders.where((o) {
            final status = o['status'];
            final address = (o['delivery_address'] ?? '').toString();
            final isCompensated = status == 'cancelled' && address.contains('[INDEMNISÉ >50%');
            return status == 'delivered' || isCompensated;
          }).toList();

          final filteredOrders = relevantOrders.where((o) {
            if (_ordersFilter == 'pending_caisse') {
              return o['status'] == 'delivered' && !CaisseRemittanceHelper.isRemitted(o);
            }
            if (_ordersFilter == 'remitted') {
              return o['status'] == 'delivered' && CaisseRemittanceHelper.isRemitted(o);
            }
            return true;
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: AmeexFadeSlideIn(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==========================================================
                  // EXPLANATION / WORKFLOW BANNER
                  // ==========================================================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF5FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_rounded, color: AmeexColors.primaryBlue, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Les espèces collectées auprès des clients (COD) appartiennent à l\'agence. Dès que vous remettez la caisse à l\'agence et que l\'admin la valide, votre commission de livraison est immédiatement débloquée pour le retrait.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF1E3A8A), height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ==========================================================
                  // 1. FLOSS L'AGENCE: CAISSE ESPÈCES À REMETTRE À L'AGENCE (COD)
                  // ==========================================================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: balances.codToRemitToAgency > 0 ? const Color(0xFFFFFBEB) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: balances.codToRemitToAgency > 0 ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
                        width: balances.codToRemitToAgency > 0 ? 1.5 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: balances.codToRemitToAgency > 0
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                              : Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: balances.codToRemitToAgency > 0 ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.storefront_rounded,
                                color: balances.codToRemitToAgency > 0 ? const Color(0xFFD97706) : const Color(0xFF64748B),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '🏢 Caisse Agence Ameex (COD)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    'Espèces clients encaissées à verser à l\'agence',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: balances.codToRemitToAgency > 0 ? const Color(0xFFB45309) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: balances.codToRemitToAgency > 0 ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: balances.codToRemitToAgency > 0 ? const Color(0xFFFDE68A) : const Color(0xFF86EFAC),
                                ),
                              ),
                              child: Text(
                                balances.codToRemitToAgency > 0 ? 'À verser' : 'À jour',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: balances.codToRemitToAgency > 0 ? const Color(0xFFB45309) : const Color(0xFF16A34A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${balances.codToRemitToAgency.toStringAsFixed(2)} MAD',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: balances.codToRemitToAgency > 0 ? const Color(0xFFD97706) : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${balances.unremittedCount} colis à verser)',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: balances.codToRemitToAgency > 0 ? const Color(0xFFFFF7ED) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                balances.codToRemitToAgency > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                                size: 16,
                                color: balances.codToRemitToAgency > 0 ? const Color(0xFFC2410C) : const Color(0xFF16A34A),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  balances.codToRemitToAgency > 0
                                      ? 'Remettez ces espèces à l\'agence Ameex. Dès confirmation par l\'admin, votre commission de +${balances.pendingCommission.toStringAsFixed(2)} MAD sera ajoutée à votre solde.'
                                      : 'Super ! Toutes vos remises d\'espèces sont à jour. Total remis : ${balances.codRemittedToAgency.toStringAsFixed(2)} MAD.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: balances.codToRemitToAgency > 0 ? const Color(0xFF9A3412) : const Color(0xFF166534),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==========================================================
                  // 2. REVENU DU LIVREUR (COMMISSIONS) & BOUTON RETIRER (WITHDRAW)
                  // ==========================================================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0A192F), Color(0xFF1E3A8A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 5)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.wallet_rounded, color: Color(0xFF38BDF8), size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Mon Revenu Net Disponible',
                                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(radius: 3, backgroundColor: Color(0xFF10B981)),
                                  SizedBox(width: 5),
                                  Text(
                                    'Prêt pour retrait',
                                    style: TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // ROW: SOLDE DISPONIBLE + BOUTON RETIRER (WITHDRAW)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${balances.availableCommission.toStringAsFixed(2)} MAD',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Rémunération personnelle validée',
                                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),

                            // BUTTON RETIRER (WITHDRAW)
                            AmeexPressable(
                              onTap: () => _showWithdrawDialog(context, balances.availableCommission),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.payments_rounded, color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Retirer',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (balances.pendingCommission > 0) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.hourglass_top_rounded, color: Color(0xFFFDE047), size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '+${balances.pendingCommission.toStringAsFixed(2)} MAD en attente (débloqués dès remise caisse à l\'agence)',
                                    style: const TextStyle(color: Color(0xFFFEF08A), fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),
                        const Divider(color: Colors.white12, height: 1),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Colis livrés : ${balances.deliveredCount}',
                              style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                            Text(
                              'Indemnisés (>50%) : ${balances.compensatedCount}',
                              style: const TextStyle(color: Color(0xFFFDE047), fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==========================================================
                  // 3. GARANTIE AMEEX (>50%)
                  // ==========================================================
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.shield_rounded, color: Color(0xFF16A34A), size: 28),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Garantie Rémunération Ameex : Si une commande est annulée après avoir dépassé 50% du trajet, vous touchez l\'intégralité de votre rémunération pour vos frais de carburant et temps !',
                            style: TextStyle(fontSize: 11, color: Color(0xFF166534), fontWeight: FontWeight.w500, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==========================================================
                  // 4. HISTORIQUE DÉTAILLÉ DES COLIS & STATUT CAISSE
                  // ==========================================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Détail des Colis & Statut Caisse',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        '${filteredOrders.length} colis',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // FILTER CHIPS
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Tous les colis', style: TextStyle(fontSize: 11)),
                          selected: _ordersFilter == 'all',
                          selectedColor: const Color(0xFFEFF5FF),
                          onSelected: (val) => setState(() => _ordersFilter = 'all'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text('⏳ Caisse à verser (${balances.unremittedCount})', style: const TextStyle(fontSize: 11)),
                          selected: _ordersFilter == 'pending_caisse',
                          selectedColor: const Color(0xFFFEF3C7),
                          onSelected: (val) => setState(() => _ordersFilter = 'pending_caisse'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text('✅ Caisse Validée (${balances.deliveredCount - balances.unremittedCount})', style: const TextStyle(fontSize: 11)),
                          selected: _ordersFilter == 'remitted',
                          selectedColor: const Color(0xFFDCFCE7),
                          onSelected: (val) => setState(() => _ordersFilter = 'remitted'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (filteredOrders.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Center(
                        child: Text(
                          'Aucun colis dans cette catégorie.',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredOrders.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final o = filteredOrders[index];
                        final tracking = o['tracking_number'] ?? '#AMX';
                        final customerName = o['customer_name'] ?? 'Client';
                        final codAmount = CaisseRemittanceHelper.getOrderCodAmount(o);
                        final driverFee = CaisseRemittanceHelper.getDriverCommission(o);
                        final isRemitted = CaisseRemittanceHelper.isRemitted(o);
                        final status = o['status'];
                        final isCompensated = status == 'cancelled';

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isRemitted || isCompensated ? const Color(0xFFE2E8F0) : const Color(0xFFFDE68A),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF5FF),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          tracking,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AmeexColors.primaryBlue,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        customerName,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0F172A)),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isCompensated
                                          ? const Color(0xFFFEF3C7)
                                          : isRemitted
                                              ? const Color(0xFFDCFCE7)
                                              : const Color(0xFFFFFBEB),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isCompensated
                                            ? const Color(0xFFFDE68A)
                                            : isRemitted
                                                ? const Color(0xFF86EFAC)
                                                : const Color(0xFFFCD34D),
                                      ),
                                    ),
                                    child: Text(
                                      isCompensated
                                          ? 'Indemnisé (>50%)'
                                          : isRemitted
                                              ? '✅ Caisse validée'
                                              : '⏳ Caisse à verser',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isCompensated
                                            ? const Color(0xFFB45309)
                                            : isRemitted
                                                ? const Color(0xFF16A34A)
                                                : const Color(0xFFD97706),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Caisse Encaissée (COD)', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${codAmount.toStringAsFixed(2)} MAD',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: isRemitted ? const Color(0xFF64748B) : const Color(0xFFD97706),
                                          ),
                                        ),
                                        Text(
                                          isRemitted ? 'Remis à l\'agence' : 'Pour l\'agence Ameex',
                                          style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
                                        ),
                                      ],
                                    ),
                                    Container(height: 26, width: 1, color: const Color(0xFFE2E8F0)),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text('Votre Rémunération', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                        const SizedBox(height: 2),
                                        Text(
                                          '+${driverFee.toStringAsFixed(2)} MAD',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF10B981),
                                          ),
                                        ),
                                        Text(
                                          isRemitted || isCompensated ? 'Débloqué (Disponible)' : 'Bloqué (Attente caisse)',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                            color: isRemitted || isCompensated ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// TAB 4: PROFIL DU LIVREUR
// ============================================================================
class DriverProfileTab extends StatefulWidget {
  const DriverProfileTab({super.key});

  @override
  State<DriverProfileTab> createState() => _DriverProfileTabState();
}

class _DriverProfileTabState extends State<DriverProfileTab> {
  final supabase = Supabase.instance.client;
  bool _isOnline = true;
  String _driverName = 'Livreur Ameex';
  String _email = '';
  String _vehicle = 'Moto / Scooter';
  String _zone = 'Casablanca - Maarif & Anfa';
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      _email = user.email ?? '';
      final profile = await supabase.from('profiles').select().eq('id', user.id).maybeSingle();
      if (mounted && profile != null) {
        setState(() {
          _profile = profile;
          _driverName = profile['full_name'] ?? 'Livreur Ameex';
          _vehicle = profile['vehicle_type'] ?? 'Moto / Scooter';
          _zone = profile['zone'] ?? 'Casablanca - Maarif & Anfa';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const deepNavy = AmeexColors.primaryBlue;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: deepNavy,
        elevation: 0,
        title: const Text('Mon Profil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: AmeexFadeSlideIn(
          child: Column(
          children: [
            Center(
              child: DriverAvatar(
                driverData: _profile,
                name: _driverName,
                radius: 46,
                borderColor: deepNavy,
                borderWidth: 3,
                showBadge: true,
                badgeColor: _isOnline ? const Color(0xFF10B981) : Colors.grey,
              ),
            ),
            const SizedBox(height: 14),
            Text(_driverName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 2),
            Text(_email, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isOnline ? Icons.power_rounded : Icons.power_off_rounded,
                        color: _isOnline ? const Color(0xFF10B981) : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isOnline ? 'Statut : Disponible (En Ligne)' : 'Statut : Hors Ligne',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ],
                  ),
                  Switch(
                    value: _isOnline,
                    activeColor: const Color(0xFF10B981),
                    onChanged: (val) => setState(() => _isOnline = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Véhicule', style: TextStyle(color: Color(0xFF64748B))),
                      Text(DriverAvatarHelper.cleanVehicle(_vehicle), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Zone d\'affectation', style: TextStyle(color: Color(0xFF64748B))),
                      Text(DriverAvatarHelper.cleanZone(_zone), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Déconnexion'),
                onPressed: () async {
                  await supabase.auth.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed('/login');
                  }
                },
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
