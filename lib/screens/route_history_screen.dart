import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/ameex_theme.dart';
import '../widgets/driver_avatar.dart';
import '../widgets/ameex_animations.dart';
import '../widgets/ameex_ui.dart';
import '../widgets/parcel_scanner_dialog.dart';

class RouteHistoryScreen extends StatefulWidget {
  final Map<String, dynamic>? order;

  const RouteHistoryScreen({super.key, this.order});

  @override
  State<RouteHistoryScreen> createState() => _RouteHistoryScreenState();
}

class _RouteHistoryScreenState extends State<RouteHistoryScreen> {
  final supabase = Supabase.instance.client;
  final MapController _mapController = MapController();

  bool _isLoading = true;
  String _driverName = 'Noureddine';
  Map<String, dynamic>? _driverProfile;
  String _trackingNumber = '#AMX-9024';
  String _destination = 'Maarif';
  final String _totalDistance = '8.4 km';
  final String _duration = '51 min';

  // Historical Coordinates (Point A pickup to Point B dropoff around Casablanca Maarif)
  List<LatLng> _routeCoordinates = const [
    LatLng(33.5815, -7.6390), // Point A (Départ 10:14)
    LatLng(33.5835, -7.6350),
    LatLng(33.5880, -7.6310),
    LatLng(33.5930, -7.6250), // Point A Checkpoint
    LatLng(33.5960, -7.6180), // Noureddine current/mid position
    LatLng(33.5910, -7.6150),
    LatLng(33.5860, -7.6130), // Point B (Livré 11:05)
  ];

  LatLng _centerPoint = const LatLng(33.5885, -7.6260);

  @override
  void initState() {
    super.initState();
    _loadHistoricalRoute();
  }

  Future<void> _loadHistoricalRoute() async {
    if (widget.order != null) {
      final o = widget.order!;
      _trackingNumber = o['tracking_number'] ?? '#AMX-9024';
      _destination = o['destination_city'] ?? 'Maarif';

      final driverId = o['assigned_driver_id'] as String?;
      if (driverId != null) {
        try {
          // Fetch driver name
          final profile = await supabase
              .from('profiles')
              .select()
              .eq('id', driverId)
              .maybeSingle();

          if (profile != null) {
            _driverProfile = profile;
            if (profile['full_name'] != null) {
              _driverName = profile['full_name'];
            }
          }

          // Fetch GPS history if available
          final locData = await supabase
              .from('driver_locations')
              .select('latitude, longitude')
              .eq('driver_id', driverId);

          if (locData.isNotEmpty) {
            final List<LatLng> fetchedPoints = [];
            for (final item in locData) {
              final lat = (item['latitude'] as num?)?.toDouble();
              final lng = (item['longitude'] as num?)?.toDouble();
              if (lat != null && lng != null) {
                fetchedPoints.add(LatLng(lat, lng));
              }
            }
            if (fetchedPoints.length >= 2) {
              setState(() {
                _routeCoordinates = fetchedPoints;
              });
            }
          }
        } catch (_) {}
      }

      // If client destination was pinned by the driver, anchor Point B directly to it!
      if (o['dest_latitude'] != null && o['dest_longitude'] != null) {
        final destLat = (o['dest_latitude'] as num).toDouble();
        final destLng = (o['dest_longitude'] as num).toDouble();
        final destPin = LatLng(destLat, destLng);

        LatLng startPin = const LatLng(33.5870, -7.6350); // Agency Hub
        if (_routeCoordinates.isNotEmpty) {
          startPin = _routeCoordinates.first;
        }

        final midLat = (startPin.latitude + destPin.latitude) / 2;
        final midLng = (startPin.longitude + destPin.longitude) / 2;
        final midPin = LatLng(midLat + 0.003, midLng + 0.002);

        setState(() {
          _routeCoordinates = [startPin, midPin, destPin];
          _centerPoint = LatLng(midLat, midLng);
        });
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const deepNavy = AmeexColors.primaryBlue;

    final LatLng startPoint = _routeCoordinates.first;
    final LatLng midPoint = _routeCoordinates[_routeCoordinates.length ~/ 2];
    final LatLng endPoint = _routeCoordinates.last;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: deepNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: const [
            Text(
              'Historique du trajet',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Trajet d\'une ancienne commande',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: AmeexLoading())
          : Column(
              children: [
                // 1. TOP HALF: MAP WITH HISTORICAL POLYLINE
                Expanded(
                  flex: 5,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _centerPoint,
                      initialZoom: 13.9,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.ameex.app',
                      ),

                      // Solid Deep Navy Route Polyline connecting Point A to Point B
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routeCoordinates,
                            strokeWidth: 4.5,
                            color: deepNavy,
                          ),
                        ],
                      ),

                      // Markers on Route: Point A, Midpoint (Driver), Point B
                      MarkerLayer(
                        markers: [
                          // Point A: "Départ 10:14"
                          Marker(
                            point: startPoint,
                            width: 120,
                            height: 65,
                            child: _buildCalloutMarker(
                              label: 'Départ 10:14',
                              circleText: 'A',
                              circleColor: const Color(0xFF10B981), // Green dot
                            ),
                          ),

                          // Midpoint: Driver Badge
                          Marker(
                            point: midPoint,
                            width: 140,
                            height: 65,
                            child: _buildDriverCalloutMarker(name: _driverName),
                          ),

                          // Point B: Customer Destination Marker
                          Marker(
                            point: endPoint,
                            width: 140,
                            height: 65,
                            child: _buildCalloutMarker(
                              label: widget.order?['customer_name'] != null
                                  ? 'Client: ${widget.order!['customer_name']}'
                                  : 'Livré 11:05',
                              circleText: 'B',
                              circleColor: const Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 2. BOTTOM HALF: DRIVER DETAILS & TIMELINE WIDGET
                Expanded(
                  flex: 5,
                  child: AmeexFadeSlideIn(
                    beginOffset: const Offset(0.0, 0.08),
                    duration: const Duration(milliseconds: 320),
                    child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, -3),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Drag handle
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: const Color(0xFFCBD5E1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Driver Header Row
                          Row(
                            children: [
                              DriverAvatar(
                                driverData: _driverProfile,
                                name: _driverName,
                                radius: 22,
                                borderColor: deepNavy,
                                borderWidth: 2,
                                showBadge: true,
                                badgeColor: const Color(0xFF10B981),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Chauffeur : $_driverName',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Summary Card Box
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '$_trackingNumber $_destination',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF5FF),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFFBFDBFE)),
                                      ),
                                      child: Text(
                                        widget.order != null
                                            ? ParcelHelper.getParcelNumber(widget.order!)
                                            : 'CLS-CAS-9024-MA',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.bold,
                                          color: AmeexColors.primaryBlue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Distance totale : $_totalDistance',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Durée : $_duration',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                                if (widget.order?['dest_latitude'] != null) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 14, color: Color(0xFF16A34A)),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'GPS Client : ${(widget.order!['dest_latitude'] as num).toDouble().toStringAsFixed(4)}, ${(widget.order!['dest_longitude'] as num).toDouble().toStringAsFixed(4)} (Choisi par livreur)',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Delivery Timeline Steps
                          _buildTimelineStep(
                            timeAndTitle: '10:14 - Colis récupéré',
                            isCompleted: true,
                            isFirst: true,
                            isLast: false,
                          ),
                          _buildTimelineStep(
                            timeAndTitle: '10:35 - En route',
                            isCompleted: true,
                            isFirst: false,
                            isLast: false,
                          ),
                          _buildTimelineStep(
                            timeAndTitle: '11:05 - Livré au client',
                            isCompleted: true,
                            isFirst: false,
                            isLast: true,
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  ),
                ),
              ],
            ),
    );
  }

  /// Custom Callout Marker (for Départ and Livré)
  Widget _buildCalloutMarker({
    required String label,
    required String circleText,
    required Color circleColor,
  }) {
    const deepNavy = Color(0xFF0A192F);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: deepNavy,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Center(
            child: Text(
              circleText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Driver Name Pin on Route
  Widget _buildDriverCalloutMarker({required String name}) {
    const deepNavy = Color(0xFF0A192F);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: deepNavy,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 7,
                backgroundColor: Colors.white,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'N',
                  style: const TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                    color: deepNavy,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: deepNavy,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ],
    );
  }

  /// Timeline step item matching the exact design
  Widget _buildTimelineStep({
    required String timeAndTitle,
    required bool isCompleted,
    required bool isFirst,
    required bool isLast,
  }) {
    const deepNavy = Color(0xFF0A192F);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Dot & Vertical Line
        SizedBox(
          width: 24,
          child: Column(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: isCompleted ? deepNavy : const Color(0xFFCBD5E1),
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 32,
                  color: const Color(0xFFE2E8F0),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Middle: Step Title
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 0),
            child: Text(
              timeAndTitle,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ),

        // Right: Completed Checkmark Icon
        Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: deepNavy,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.check, color: Colors.white, size: 12),
          ),
        ),
      ],
    );
  }
}
