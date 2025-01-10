import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/ameex_theme.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final supabase = Supabase.instance.client;
  final MapController _mapController = MapController();

  // Drivers Data: mapped by driver_id
  Map<String, Map<String, dynamic>> _driverProfiles = {};
  Map<String, LatLng> _driverPositions = {};
  Map<String, Map<String, dynamic>> _driverLocationsData = {};

  StreamSubscription? _locationsSubscription;
  String? _selectedDriverId;
  bool _isLoading = true;

  // Default initial center: Casablanca
  final LatLng _initialCenter = const LatLng(33.5892, -7.6324);

  // Decorative route polyline points around Casablanca Maarif / Anfa
  final List<LatLng> _sampleRoutePoints = const [
    LatLng(33.5950, -7.6180),
    LatLng(33.5880, -7.6250),
    LatLng(33.5830, -7.6380),
    LatLng(33.5780, -7.6320),
    LatLng(33.5750, -7.6220),
    LatLng(33.5820, -7.6150),
    LatLng(33.5950, -7.6180),
  ];

  @override
  void initState() {
    super.initState();
    _loadDriversAndListen();
  }

  @override
  void dispose() {
    _locationsSubscription?.cancel();
    super.dispose();
  }

  /// 1. Load Drivers Profiles & subscribe to Realtime location updates
  Future<void> _loadDriversAndListen() async {
    try {
      // Fetch all driver profiles
      final profilesData = await supabase
          .from('profiles')
          .select('id, full_name, phone')
          .eq('role', 'driver');

      final profilesMap = <String, Map<String, dynamic>>{};
      for (final p in profilesData) {
        profilesMap[p['id'] as String] = p;
      }

      // Fetch initial locations
      final locationsData = await supabase.from('driver_locations').select();

      final positions = <String, LatLng>{};
      final locDataMap = <String, Map<String, dynamic>>{};

      for (final loc in locationsData) {
        final driverId = loc['driver_id'] as String?;
        final lat = (loc['latitude'] as num?)?.toDouble();
        final lng = (loc['longitude'] as num?)?.toDouble();

        if (driverId != null && lat != null && lng != null) {
          positions[driverId] = LatLng(lat, lng);
          locDataMap[driverId] = loc;
        }
      }

      // If no locations exist yet in database, provide mock positions for display
      int index = 0;
      final defaultPositions = [
        const LatLng(33.5950, -7.6180), // Noureddine
        const LatLng(33.5830, -7.6380), // Youssef
      ];

      for (final driverId in profilesMap.keys) {
        if (!positions.containsKey(driverId)) {
          final mockPos = defaultPositions[index % defaultPositions.length];
          positions[driverId] = mockPos;
          locDataMap[driverId] = {
            'driver_id': driverId,
            'latitude': mockPos.latitude,
            'longitude': mockPos.longitude,
            'speed': 24.5,
          };
          index++;
        }
      }

      if (mounted) {
        setState(() {
          _driverProfiles = profilesMap;
          _driverPositions = positions;
          _driverLocationsData = locDataMap;
          if (_driverProfiles.isNotEmpty) {
            _selectedDriverId = _driverProfiles.keys.first;
          }
          _isLoading = false;
        });
      }

      // 2. Real-time Subscription to driver_locations table
      _locationsSubscription = supabase
          .from('driver_locations')
          .stream(primaryKey: ['id'])
          .listen((List<Map<String, dynamic>> data) {
            if (!mounted) return;

            setState(() {
              for (final loc in data) {
                final driverId = loc['driver_id'] as String?;
                final lat = (loc['latitude'] as num?)?.toDouble();
                final lng = (loc['longitude'] as num?)?.toDouble();

                if (driverId != null && lat != null && lng != null) {
                  _driverPositions[driverId] = LatLng(lat, lng);
                  _driverLocationsData[driverId] = loc;
                }
              }
            });
          });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _centerOnDriver(String driverId) {
    final pos = _driverPositions[driverId];
    if (pos != null) {
      setState(() => _selectedDriverId = driverId);
      _mapController.move(pos, 15.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    const deepNavy = Color(0xFF0A192F);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: deepNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Suivi en direct',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AmeexColors.primaryBlue))
          : Column(
              children: [
                // 1. TOP HALF: MAP WITH REAL-TIME DRIVER MARKERS
                Expanded(
                  flex: 5,
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _initialCenter,
                          initialZoom: 13.8,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.ameex.app',
                          ),

                          // Route Polyline connecting checkpoints
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _sampleRoutePoints,
                                strokeWidth: 4.0,
                                color: deepNavy,
                              ),
                            ],
                          ),

                          // Checkpoint stops on the route (e.g. 3, 4)
                          MarkerLayer(
                            markers: [
                              _buildCheckpointMarker(const LatLng(33.5820, -7.6150), '3'),
                              _buildCheckpointMarker(const LatLng(33.5750, -7.6220), '4'),
                            ],
                          ),

                          // Real-time Driver Markers with custom Callout Name & Avatar
                          MarkerLayer(
                            markers: _driverProfiles.entries.map((entry) {
                              final driverId = entry.key;
                              final profile = entry.value;
                              final name = profile['full_name'] as String? ?? 'Livreur';
                              final pos = _driverPositions[driverId] ?? _initialCenter;
                              final isSelected = _selectedDriverId == driverId;

                              return Marker(
                                point: pos,
                                width: 140,
                                height: 70,
                                child: GestureDetector(
                                  onTap: () => _centerOnDriver(driverId),
                                  child: _buildDriverMapMarker(
                                    name: name,
                                    isSelected: isSelected,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),

                      // Floating recenter button
                      Positioned(
                        right: 14,
                        bottom: 14,
                        child: FloatingActionButton.small(
                          heroTag: 'recenter_live_map',
                          backgroundColor: Colors.white,
                          onPressed: () {
                            if (_selectedDriverId != null && _driverPositions.containsKey(_selectedDriverId)) {
                              _mapController.move(_driverPositions[_selectedDriverId]!, 15.0);
                            } else {
                              _mapController.move(_initialCenter, 13.8);
                            }
                          },
                          child: const Icon(Icons.my_location, color: deepNavy),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. BOTTOM HALF: ACTIVE DRIVERS LIST
                Expanded(
                  flex: 5,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, -3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag handle line
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(top: 10, bottom: 8),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFCBD5E1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                        // Section Title: "Livreurs en Ligne"
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: Text(
                            'Livreurs en Ligne',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),

                        // Drivers List
                        Expanded(
                          child: _driverProfiles.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Aucun livreur enregistré',
                                    style: TextStyle(color: Color(0xFF94A3B8)),
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  itemCount: _driverProfiles.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final driverId = _driverProfiles.keys.elementAt(index);
                                    final profile = _driverProfiles[driverId]!;
                                    final name = profile['full_name'] as String? ?? 'Livreur';
                                    final isSelected = _selectedDriverId == driverId;

                                    return GestureDetector(
                                      onTap: () => _centerOnDriver(driverId),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFFF1F5F9)
                                              : const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isSelected
                                                ? deepNavy
                                                : const Color(0xFFE2E8F0),
                                            width: isSelected ? 1.5 : 1.0,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            // Avatar
                                            CircleAvatar(
                                              radius: 20,
                                              backgroundColor: deepNavy,
                                              child: Text(
                                                name.isNotEmpty ? name[0].toUpperCase() : 'L',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),

                                            // Name & City
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    name,
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF0F172A),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  const Text(
                                                    'Casablanca',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF64748B),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Status and ETA
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: const [
                                                Text(
                                                  'En Transit - 15m',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF0F172A),
                                                  ),
                                                ),
                                                SizedBox(height: 2),
                                                Text(
                                                  'Arrival 9m',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF94A3B8),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  /// Custom Driver Callout Marker matching the image
  Widget _buildDriverMapMarker({required String name, required bool isSelected}) {
    const deepNavy = Color(0xFF0A192F);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Name pill badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: deepNavy,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 8,
                backgroundColor: Colors.white,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'L',
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: deepNavy,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),

        // Pin pointer dot
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF10B981) : deepNavy,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
        ),
      ],
    );
  }

  /// Numbered Checkpoint Marker (e.g. 3, 4)
  Marker _buildCheckpointMarker(LatLng point, String number) {
    const deepNavy = Color(0xFF0A192F);

    return Marker(
      point: point,
      width: 22,
      height: 22,
      child: Container(
        decoration: BoxDecoration(
          color: deepNavy,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Center(
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
