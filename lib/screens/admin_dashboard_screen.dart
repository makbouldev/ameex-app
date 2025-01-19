import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/ameex_theme.dart';
import '../widgets/driver_avatar.dart';
import '../widgets/ameex_animations.dart';
import '../widgets/parcel_scanner_dialog.dart';
import 'add_order_screen.dart';
import 'add_driver_screen.dart';
import 'route_history_screen.dart';

class AdminDriverCache {
  static final Map<String, Map<String, dynamic>> _cache = {};

  static Future<Map<String, dynamic>?> getDriver(String driverId) async {
    if (_cache.containsKey(driverId)) return _cache[driverId];
    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', driverId)
          .maybeSingle();
      if (res != null) {
        _cache[driverId] = res;
      }
      return res;
    } catch (_) {
      return null;
    }
  }
}

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    const primaryBlue = AmeexColors.primaryBlue;

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedIndexedStack(
        index: _selectedNavIndex,
        children: const [
          AdminDashboardHomeTab(),
          AdminOrdersTab(),
          AdminLiveTrackingTab(),
          AdminNotificationsTab(),
          AdminProfileTab(),
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
          currentIndex: _selectedNavIndex,
          onTap: (index) => setState(() => _selectedNavIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: primaryBlue,
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              label: 'Commandes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              label: 'Suivi Direct',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              label: 'Alertes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// TAB 0: DASHBOARD ACCUEIL (STATS + RECHERCHE + DERNIÈRES COMMANDES)
// ============================================================================
class AdminDashboardHomeTab extends StatefulWidget {
  const AdminDashboardHomeTab({super.key});

  @override
  State<AdminDashboardHomeTab> createState() => _AdminDashboardHomeTabState();
}

class _AdminDashboardHomeTabState extends State<AdminDashboardHomeTab> {
  final supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = AmeexColors.primaryBlue;

    return Scaffold(
      backgroundColor: AmeexColors.surfaceGray,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: primaryBlue,
          elevation: 0,
          centerTitle: true,
          title: const AmeexLogo(isWhite: true, height: 30),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white70, size: 22),
              tooltip: 'Déconnexion',
              onPressed: () async {
                await supabase.auth.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AmeexColors.darkNavy,
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
        label: Text('Nouvelle Commande', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
        onPressed: () {
          Navigator.of(context).push(
            AmeexPageRoute(page: const AddOrderScreen()),
          );
        },
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('orders')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AmeexColors.primaryBlue));
          }

          final orders = snapshot.data ?? [];

          // Compute Dynamic Statistics
          final totalCount = orders.length;
          final inTransitCount = orders.where((o) => o['status'] == 'in_transit').length;
          final deliveredCount = orders.where((o) => o['status'] == 'delivered').length;
          final pendingCount = orders.where((o) => o['status'] == 'pending').length;

          // Filter by search query
          final filteredOrders = orders.where((order) {
            if (_searchQuery.isEmpty) return true;
            final name = (order['customer_name'] ?? '').toString().toLowerCase();
            final tracking = (order['tracking_number'] ?? '').toString().toLowerCase();
            final city = (order['destination_city'] ?? '').toString().toLowerCase();
            final query = _searchQuery.toLowerCase();
            return name.contains(query) || tracking.contains(query) || city.contains(query);
          }).toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Official Slogan Badge
                      const AmeexSloganBadge(),
                      const SizedBox(height: 10),

                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dashboard Admin',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AmeexColors.textDark,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Vue globale & Statuts en direct',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AmeexColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AmeexColors.lightBlue,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.today, size: 14, color: AmeexColors.primaryBlue),
                                const SizedBox(width: 6),
                                Text(
                                  'Aujourd\'hui',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AmeexColors.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // 4 Top Statistic Cards (Ameex Brand Palette)
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: 'Total Commandes',
                              value: totalCount.toString(),
                              bgColor: AmeexColors.primaryBlue,
                              textColor: Colors.white,
                              labelColor: Colors.white70,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildStatCard(
                              title: 'En Transit',
                              value: inTransitCount.toString(),
                              bgColor: AmeexColors.lightBlue,
                              textColor: AmeexColors.primaryBlue,
                              labelColor: AmeexColors.primaryBlue.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: 'Livré',
                              value: deliveredCount.toString(),
                              bgColor: const Color(0xFF10B981),
                              textColor: Colors.white,
                              labelColor: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildStatCard(
                              title: 'En Attente',
                              value: pendingCount.toString(),
                              bgColor: const Color(0xFFFB923C),
                              textColor: Colors.white,
                              labelColor: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // SECTION: EQUIPE DES LIVREURS AMEEX (DATA LIVREURS EN DIRECT)
                      _buildDriversSection(context, primaryBlue, orders),

                      const SizedBox(height: 24),

                      // Section Title
                      const Text(
                        'Commandes Récentes',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Search bar
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: const InputDecoration(
                            hintText: 'Rechercher par client, tracking ou ville...',
                            hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                            prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),

              // Orders List
              filteredOrders.isEmpty
                  ? const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Center(
                          child: Text(
                            'Aucune commande trouvée',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                          ),
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final order = filteredOrders[index];
                            return _buildOrderCard(context, order, primaryBlue);
                          },
                          childCount: filteredOrders.length,
                        ),
                      ),
                    ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color bgColor,
    required Color textColor,
    required Color labelColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: labelColor),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildDriversSection(BuildContext context, Color primaryBlue, List<Map<String, dynamic>> orders) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('profiles')
          .stream(primaryKey: ['id'])
          .eq('role', 'driver'),
      builder: (context, snapshot) {
        final drivers = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AmeexColors.lightBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.two_wheeler_rounded, color: AmeexColors.primaryBlue, size: 18),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Équipe des Livreurs',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF5FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Text(
                        '${drivers.length} livreur(s)',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AmeexColors.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  icon: const Icon(Icons.person_add_rounded, size: 16),
                  label: const Text('Ajouter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: AmeexColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    backgroundColor: const Color(0xFFEFF5FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      AmeexPageRoute(page: const AddDriverScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (drivers.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Center(
                  child: Text(
                    'Aucun livreur enregistré pour le moment.\nCliquez sur "+ Ajouter" pour créer un profil livreur.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                ),
              )
            else
              SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: drivers.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final d = drivers[index];
                    final name = d['full_name'] ?? 'Livreur';
                    final phone = d['phone'] ?? 'Non renseigné';
                    final vehicle = DriverAvatarHelper.cleanVehicle(d['vehicle_type']);
                    final zone = DriverAvatarHelper.cleanZone(d['zone']);
                    final dId = d['id'];

                    // Calculate active orders for this driver
                    final activeMissions = orders.where((o) =>
                        o['assigned_driver_id'] == dId &&
                        o['status'] != 'delivered' &&
                        o['status'] != 'cancelled').length;

                    return Container(
                      width: 260,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              DriverAvatar(
                                driverData: d,
                                radius: 20,
                                borderColor: AmeexColors.primaryBlue,
                                borderWidth: 1.5,
                                showBadge: true,
                                badgeColor: const Color(0xFF10B981),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      phone,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: activeMissions > 0 ? const Color(0xFFEFF5FF) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '$activeMissions mission(s)',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: activeMissions > 0 ? AmeexColors.primaryBlue : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.two_wheeler_rounded, size: 13, color: Color(0xFF475569)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '$vehicle • $zone',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 10, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// TAB 1: GESTION COMPLÈTE DES COMMANDES (FILTRE PAR STATUT & MOTIF ANNULATION)
// ============================================================================
class AdminOrdersTab extends StatefulWidget {
  const AdminOrdersTab({super.key});

  @override
  State<AdminOrdersTab> createState() => _AdminOrdersTabState();
}

class _AdminOrdersTabState extends State<AdminOrdersTab> {
  final supabase = Supabase.instance.client;
  String _selectedStatusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    const deepNavy = AmeexColors.primaryBlue;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: deepNavy,
        elevation: 0,
        title: const Text('Gestion des Commandes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip('Toutes', 'all'),
                _buildFilterChip('En Attente', 'pending'),
                _buildFilterChip('En Transit', 'in_transit'),
                _buildFilterChip('Livrées', 'delivered'),
                _buildFilterChip('Annulées', 'cancelled'),
              ],
            ),
          ),

          // Orders Stream
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase
                  .from('orders')
                  .stream(primaryKey: ['id'])
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AmeexColors.primaryBlue));
                }

                final orders = snapshot.data ?? [];
                final filtered = orders.where((o) {
                  if (_selectedStatusFilter == 'all') return true;
                  return o['status'] == _selectedStatusFilter;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('Aucune commande dans cette catégorie', style: TextStyle(color: Color(0xFF94A3B8))),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final order = filtered[index];
                    return _buildOrderCard(context, order, deepNavy);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    const deepNavy = Color(0xFF0A192F);
    final isSelected = _selectedStatusFilter == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: deepNavy,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF475569),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        onSelected: (selected) {
          if (selected) setState(() => _selectedStatusFilter = value);
        },
      ),
    );
  }
}

// ============================================================================
// TAB 2: SUIVI DIRECT SUR LA CARTE (LIVE TRACKING EMBEDDED)
// ============================================================================
class AdminLiveTrackingTab extends StatefulWidget {
  const AdminLiveTrackingTab({super.key});

  @override
  State<AdminLiveTrackingTab> createState() => _AdminLiveTrackingTabState();
}

class _AdminLiveTrackingTabState extends State<AdminLiveTrackingTab> {
  final supabase = Supabase.instance.client;
  final MapController _mapController = MapController();

  Map<String, Map<String, dynamic>> _drivers = {};
  Map<String, LatLng> _driverPositions = {};
  List<Map<String, dynamic>> _activeOrders = [];
  int _selectedTrackingTab = 0; // 0 = Livreurs, 1 = Cartes Clients
  final LatLng _center = const LatLng(33.5892, -7.6324);

  @override
  void initState() {
    super.initState();
    _loadDriversAndLocations();
  }

  Future<void> _loadDriversAndLocations() async {
    try {
      final profiles = await supabase.from('profiles').select().eq('role', 'driver');
      final pMap = <String, Map<String, dynamic>>{};
      for (final p in profiles) {
        pMap[p['id'] as String] = p;
      }

      final locs = await supabase.from('driver_locations').select();
      final posMap = <String, LatLng>{};
      for (final l in locs) {
        final dId = l['driver_id'] as String?;
        final lat = (l['latitude'] as num?)?.toDouble();
        final lng = (l['longitude'] as num?)?.toDouble();
        if (dId != null && lat != null && lng != null) {
          posMap[dId] = LatLng(lat, lng);
        }
      }

      // Fetch all relevant orders (active missions or any order with a pinned client location)
      final orders = await supabase
          .from('orders')
          .select()
          .order('created_at', ascending: false);

      final activeOrLocated = orders.where((o) {
        final st = o['status']?.toString();
        final hasLocation = o['dest_latitude'] != null && o['dest_longitude'] != null;
        return st == 'in_transit' || st == 'accepted' || st == 'pending' || hasLocation;
      }).toList();

      if (mounted) {
        setState(() {
          _drivers = pMap;
          _driverPositions = posMap;
          _activeOrders = List<Map<String, dynamic>>.from(activeOrLocated);
        });
      }

      // Live subscription to driver locations
      supabase.from('driver_locations').stream(primaryKey: ['id']).listen((data) {
        if (!mounted) return;
        setState(() {
          for (final l in data) {
            final dId = l['driver_id'] as String?;
            final lat = (l['latitude'] as num?)?.toDouble();
            final lng = (l['longitude'] as num?)?.toDouble();
            if (dId != null && lat != null && lng != null) {
              _driverPositions[dId] = LatLng(lat, lng);
            }
          }
        });
      });

      // Live subscription to orders (reflects new orders & driver pinpointing client location in real time!)
      supabase.from('orders').stream(primaryKey: ['id']).listen((data) {
        if (!mounted) return;
        setState(() {
          _activeOrders = data.where((o) {
            final st = o['status']?.toString();
            final hasLocation = o['dest_latitude'] != null && o['dest_longitude'] != null;
            return st == 'in_transit' || st == 'accepted' || st == 'pending' || hasLocation;
          }).toList();
        });
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    const deepNavy = AmeexColors.primaryBlue;

    // Active orders with valid client destination coordinates
    final ordersWithDestination = _activeOrders.where((o) =>
        o['dest_latitude'] != null && o['dest_longitude'] != null).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: deepNavy,
        elevation: 0,
        title: const Text('Suivi en direct & Carte Client', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Map View with Drivers, Client Destination Pins, and Trajectory Polylines
          Expanded(
            flex: 6,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _center,
                initialZoom: 13.5,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.ameex.app',
                ),

                // POLYLINES CONNECTING DRIVER TO CLIENT DESTINATION
                PolylineLayer(
                  polylines: ordersWithDestination
                      .where((o) => _driverPositions.containsKey(o['assigned_driver_id']))
                      .map((o) {
                    final dPos = _driverPositions[o['assigned_driver_id']]!;
                    final cPos = LatLng(
                      (o['dest_latitude'] as num).toDouble(),
                      (o['dest_longitude'] as num).toDouble(),
                    );
                    return Polyline(
                      points: [dPos, cPos],
                      strokeWidth: 4.5,
                      color: const Color(0xFF10B981),
                    );
                  }).toList(),
                ),

                MarkerLayer(
                  markers: [
                    // DRIVER MARKERS WITH AVATAR PHOTOS
                    ..._driverPositions.entries.map((entry) {
                      final dId = entry.key;
                      final pos = entry.value;
                      final dData = _drivers[dId];
                      final name = dData?['full_name'] ?? 'Livreur';

                      return Marker(
                        point: pos,
                        width: 90,
                        height: 75,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: deepNavy,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                              ),
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                DriverAvatar(
                                  driverData: dData,
                                  radius: 18,
                                  borderColor: const Color(0xFFFA5A1E),
                                  borderWidth: 2.5,
                                ),
                                Positioned(
                                  right: -3,
                                  bottom: -3,
                                  child: Container(
                                    padding: const EdgeInsets.all(2.5),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFA5A1E),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.delivery_dining_rounded, size: 11, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),

                    // EXACT CLIENT DESTINATION MARKERS (Pointed by Driver on Map)
                    ...ordersWithDestination.map((o) {
                      final cPos = LatLng(
                        (o['dest_latitude'] as num).toDouble(),
                        (o['dest_longitude'] as num).toDouble(),
                      );
                      final customerName = o['customer_name'] ?? 'Client';

                      return Marker(
                        point: cPos,
                        width: 140,
                        height: 65,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC2626),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
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
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Icon(Icons.location_on, color: Color(0xFFDC2626), size: 34),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),

          // Drivers & Clients Bottom Panel (Dual Tab View)
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(14),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dual Selector: Livreurs vs Cartes Clients
                  Row(
                    children: [
                      ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.two_wheeler_rounded, size: 14),
                            const SizedBox(width: 4),
                            Text('Livreurs (${_drivers.length})'),
                          ],
                        ),
                        selected: _selectedTrackingTab == 0,
                        selectedColor: deepNavy,
                        backgroundColor: const Color(0xFFF1F5F9),
                        labelStyle: TextStyle(
                          color: _selectedTrackingTab == 0 ? Colors.white : const Color(0xFF334155),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        onSelected: (_) => setState(() => _selectedTrackingTab = 0),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_rounded, size: 14),
                            const SizedBox(width: 4),
                            Text('Cartes Clients (${_activeOrders.length})'),
                          ],
                        ),
                        selected: _selectedTrackingTab == 1,
                        selectedColor: deepNavy,
                        backgroundColor: const Color(0xFFF1F5F9),
                        labelStyle: TextStyle(
                          color: _selectedTrackingTab == 1 ? Colors.white : const Color(0xFF334155),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        onSelected: (_) => setState(() => _selectedTrackingTab = 1),
                      ),
                      const Spacer(),
                      if (ordersWithDestination.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: Text(
                            '${ordersWithDestination.length} sur la carte',
                            style: const TextStyle(color: Color(0xFF166534), fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // TAB CONTENT
                  Expanded(
                    child: _selectedTrackingTab == 0
                        ? _buildDriversTrackingList(deepNavy)
                        : _buildClientCardsTrackingList(deepNavy),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriversTrackingList(Color deepNavy) {
    if (_drivers.isEmpty) {
      return const Center(child: Text('Aucun livreur connecté', style: TextStyle(color: Colors.grey)));
    }

    return ListView.separated(
      itemCount: _drivers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final dId = _drivers.keys.elementAt(index);
        final p = _drivers[dId]!;
        final name = p['full_name'] ?? 'Livreur';
        final hasGps = _driverPositions.containsKey(dId);

        // Check if driver has an active assigned order
        final matchingOrders = _activeOrders.where((o) => o['assigned_driver_id'] == dId).toList();
        final Map<String, dynamic>? activeOrder = matchingOrders.isNotEmpty ? matchingOrders.first : null;
        final bool hasClientPin = activeOrder != null &&
            activeOrder['dest_latitude'] != null &&
            activeOrder['dest_longitude'] != null;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DriverAvatar(
                    driverData: p,
                    radius: 20,
                    borderColor: deepNavy,
                    borderWidth: 1.5,
                    showBadge: true,
                    badgeColor: hasGps ? const Color(0xFF10B981) : Colors.orange,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(
                          hasGps ? 'GPS Livreur actif' : 'En attente de signal GPS',
                          style: TextStyle(
                            color: hasGps ? const Color(0xFF10B981) : Colors.orange,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.gps_fixed, color: AmeexColors.primaryBlue, size: 20),
                    tooltip: 'Centrer sur le livreur',
                    onPressed: () {
                      if (hasGps) {
                        _mapController.move(_driverPositions[dId]!, 15.5);
                      }
                    },
                  ),
                ],
              ),

              // ACTIVE MISSION DETAILS & CLIENT PIN STATUS
              if (activeOrder != null) ...[
                const Divider(height: 14, color: Color(0xFFE2E8F0)),
                Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 16, color: AmeexColors.primaryBlue),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Mission : ${activeOrder['customer_name'] ?? 'Client'} (${activeOrder['tracking_number'] ?? '#AMX'})',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AmeexColors.primaryBlue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Adresse : ${activeOrder['delivery_address'] ?? 'Non spécifiée'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 6),
                if (hasClientPin) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, size: 12, color: Color(0xFF16A34A)),
                            const SizedBox(width: 4),
                            Text(
                              'Point Client : ${(activeOrder['dest_latitude'] as num).toDouble().toStringAsFixed(4)}, ${(activeOrder['dest_longitude'] as num).toDouble().toStringAsFixed(4)}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                        icon: const Icon(Icons.alt_route_rounded, size: 16, color: Color(0xFF1D4ED8)),
                        label: const Text('Voir le trajet', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
                        onPressed: () {
                          final cPos = LatLng(
                            (activeOrder['dest_latitude'] as num).toDouble(),
                            (activeOrder['dest_longitude'] as num).toDouble(),
                          );
                          if (hasGps) {
                            final dPos = _driverPositions[dId]!;
                            final midLat = (dPos.latitude + cPos.latitude) / 2;
                            final midLng = (dPos.longitude + cPos.longitude) / 2;
                            _mapController.move(LatLng(midLat, midLng), 14.5);
                          } else {
                            _mapController.move(cPos, 16.0);
                          }
                        },
                      ),
                    ],
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '⏳ En attente du pointage de destination sur la carte',
                      style: TextStyle(fontSize: 10, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildClientCardsTrackingList(Color deepNavy) {
    if (_activeOrders.isEmpty) {
      return const Center(
        child: Text(
          'Aucune commande client enregistrée.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      );
    }

    return ListView.separated(
      itemCount: _activeOrders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final order = _activeOrders[index];
        final customerName = order['customer_name'] ?? 'Client';
        final phone = order['customer_phone'] ?? 'Non renseigné';
        final rawAddress = order['delivery_address'] ?? 'Casablanca';
        final address = ParcelHelper.cleanAddress(rawAddress.toString());
        final parcelNumber = ParcelHelper.getParcelNumber(order);
        final tracking = order['tracking_number'] ?? '#AMX';
        final amount = order['amount'] ?? 0;
        final status = order['status'] ?? 'pending';
        final dId = order['assigned_driver_id'];
        final dData = dId != null ? _drivers[dId] : null;
        final hasPin = order['dest_latitude'] != null && order['dest_longitude'] != null;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hasPin ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
              width: hasPin ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Client Header: Name, Tracking, Amount & Status
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AmeexColors.lightBlue,
                    child: Text(
                      customerName.isNotEmpty ? customerName[0].toUpperCase() : 'C',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AmeexColors.primaryBlue),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$customerName ($tracking)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          'Tél : $phone',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$amount MAD',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AmeexColors.primaryBlue),
                      ),
                      const SizedBox(height: 2),
                      _buildStatusBadge(status),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Address & Parcel Number
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF5FF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      parcelNumber,
                      style: const TextStyle(fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold, color: AmeexColors.primaryBlue),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Adresse : $address',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Assigned Driver & Map Pin Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Driver Info
                  if (dData != null)
                    Row(
                      children: [
                        DriverAvatar(
                          driverData: dData,
                          radius: 11,
                          borderColor: AmeexColors.primaryBlue,
                          borderWidth: 1,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          dData['full_name'] ?? 'Livreur',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                        ),
                      ],
                    )
                  else
                    const Text('Non assigné', style: TextStyle(fontSize: 11, color: Colors.grey)),

                  // Pinned Status & Button
                  if (hasPin) ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.my_location_rounded, size: 14),
                      label: const Text('Voir sur la carte', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        final lat = (order['dest_latitude'] as num).toDouble();
                        final lng = (order['dest_longitude'] as num).toDouble();
                        _mapController.move(LatLng(lat, lng), 16.5);
                      },
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'En attente GPS',
                        style: TextStyle(fontSize: 10, color: Color(0xFF92400E), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// TAB 3: ALERTES & NOTIFICATIONS (MOTIFS D'ANNULATION & LIVRAISONS)
// ============================================================================
class AdminNotificationsTab extends StatelessWidget {
  const AdminNotificationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    const deepNavy = AmeexColors.primaryBlue;
    final supabase = Supabase.instance.client;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: deepNavy,
        elevation: 0,
        title: const Text('Fil d\'Activité & Alertes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('orders')
            .stream(primaryKey: ['id'])
            .order('updated_at', ascending: false),
        builder: (context, snapshot) {
          final orders = snapshot.data ?? [];

          // Show notifications of delivered, cancelled (with motif), or in_transit
          final events = orders.where((o) => o['status'] != 'pending').toList();

          if (events.isEmpty) {
            return const Center(child: Text('Aucune activité récente', style: TextStyle(color: Colors.grey)));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final o = events[index];
              final status = o['status'];
              final tracking = o['tracking_number'] ?? '#AMX';
              final customer = o['customer_name'] ?? 'Client';
              final address = o['delivery_address'] ?? '';

              Color iconColor;
              IconData icon;
              String title;
              String subtitle;

              if (status == 'delivered') {
                iconColor = const Color(0xFF10B981);
                icon = Icons.check_circle_rounded;
                title = 'Colis livré avec succès !';
                subtitle = '$tracking pour $customer a été remis au client.';
              } else if (status == 'cancelled') {
                iconColor = Colors.redAccent;
                icon = Icons.error_rounded;
                title = 'Commande Annulée par le livreur';
                subtitle = '$tracking • $address';
              } else {
                iconColor = const Color(0xFF3B82F6);
                icon = Icons.local_shipping_rounded;
                title = 'Commande prise en charge (En transit)';
                subtitle = '$tracking est en cours d\'acheminement vers $customer.';
              }

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: iconColor, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 3),
                          Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                        ],
                      ),
                    ),
                  ],
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
// TAB 4: PROFIL ADMIN & GESTION DE L'ÉQUIPE DES LIVREURS
// ============================================================================
class AdminProfileTab extends StatelessWidget {
  const AdminProfileTab({super.key});

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
        title: const Text('Administration & Équipe', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admin Profile Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: deepNavy,
                    child: Icon(Icons.admin_panel_settings, size: 30, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Administrateur Ameex',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        Text(user?.email ?? 'admin@ameex.ma', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    tooltip: 'Déconnexion',
                    onPressed: () async {
                      await supabase.auth.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushReplacementNamed('/login');
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // BUTTON: AJOUTER UN LIVREUR
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text(
                  '+ Ajouter un Nouveau Livreur',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    AmeexPageRoute(page: const AddDriverScreen()),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Drivers List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Équipe des Livreurs Enregistrés',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Drivers List Stream
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase
                  .from('profiles')
                  .stream(primaryKey: ['id'])
                  .eq('role', 'driver'),
              builder: (context, snapshot) {
                final drivers = snapshot.data ?? [];

                if (drivers.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('Aucun livreur enregistré pour le moment.'),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: drivers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final d = drivers[index];
                    final name = d['full_name'] ?? 'Livreur';
                    final phone = d['phone'] ?? 'Non renseigné';
                    final vehicle = d['vehicle_type'] ?? 'Moto / Scooter';
                    final zone = d['zone'] ?? 'Casablanca';

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          DriverAvatar(
                            driverData: d,
                            radius: 22,
                            borderColor: deepNavy,
                            borderWidth: 2,
                            showBadge: true,
                            badgeColor: const Color(0xFF10B981),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 2),
                                Text(
                                  '${DriverAvatarHelper.cleanVehicle(vehicle)} • ${DriverAvatarHelper.cleanZone(zone)}',
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                ),
                                const SizedBox(height: 2),
                                Text('📞 $phone', style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// HELPER: ORDER CARD (WITH CANCEL MOTIF & ADMIN HANDOVER ACTION)
// ============================================================================
Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order, Color deepNavy) {
  final supabase = Supabase.instance.client;
  final orderId = order['id'];
  final customerName = order['customer_name'] ?? 'Client';
  final city = order['destination_city'] ?? 'Casablanca';
  final rawAddress = order['delivery_address'] ?? 'Maarif / Anfa';
  final address = ParcelHelper.cleanAddress(rawAddress.toString());
  final parcelNumber = ParcelHelper.getParcelNumber(order);
  final amount = order['amount'] ?? 0;
  final status = order['status'] ?? 'pending';
  final tracking = order['tracking_number'] ?? '#AMX';

  final bool isCancelled = status == 'cancelled';
  final bool isAcceptedWaitingAgency = status == 'accepted' || address.toString().contains('[ETAT: ACCEPTE_ATTENTE_AGENCE]');

  return AmeexFadeSlideIn(
    child: AmeexPressable(
      onTap: () {
        Navigator.of(context).push(
          AmeexPageRoute(page: RouteHistoryScreen(order: order)),
        );
      },
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAcceptedWaitingAgency
              ? Colors.amber.shade600
              : isCancelled
                  ? Colors.redAccent.withValues(alpha: 0.5)
                  : const Color(0xFFF1F5F9),
          width: (isAcceptedWaitingAgency || isCancelled) ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFE2E8F0),
                child: Text(
                  customerName.isNotEmpty ? customerName[0].toUpperCase() : 'C',
                  style: TextStyle(color: deepNavy, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$customerName ($tracking)',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF5FF),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.inventory_2_outlined, size: 11, color: AmeexColors.primaryBlue),
                              const SizedBox(width: 3),
                              Text(
                                parcelNumber,
                                style: const TextStyle(fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold, color: AmeexColors.primaryBlue),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '$city • $address',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$amount MAD',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 4),
                  _buildStatusBadge(isAcceptedWaitingAgency ? 'accepted' : status),
                ],
              ),
            ],
          ),

          // ASSIGNED DRIVER AVATAR BADGE
          if (order['assigned_driver_id'] != null)
            FutureBuilder<Map<String, dynamic>?>(
              future: AdminDriverCache.getDriver(order['assigned_driver_id']),
              builder: (context, snapshot) {
                final driver = snapshot.data;
                if (driver == null) return const SizedBox.shrink();
                final dName = driver['full_name'] ?? 'Livreur';
                return Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF5FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AmeexColors.primaryBlue.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DriverAvatar(
                        driverData: driver,
                        radius: 10,
                        borderColor: AmeexColors.primaryBlue,
                        borderWidth: 1,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Livreur : $dName',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AmeexColors.primaryBlue),
                      ),
                    ],
                  ),
                );
              },
            ),

          // SYNCHRONIZED CLIENT LOCATION BADGE (Pointed by Driver on Map)
          if (order['dest_latitude'] != null && order['dest_longitude'] != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Color(0xFF16A34A)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Position client synchronisée : ${(order['dest_latitude'] as num).toDouble().toStringAsFixed(4)}, ${(order['dest_longitude'] as num).toDouble().toStringAsFixed(4)}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                    ),
                  ),
                  const Text('Carte ➔', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                ],
              ),
            ),
          ],

          // ACTION BOUTON POUR L'ADMIN : CONFIRMER LA REMISE DU COLIS À L'AGENCE
          if (isAcceptedWaitingAgency) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📍 Le livreur a accepté la mission et se dirige vers l\'agence pour récupérer le colis.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF92400E), fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.inventory_rounded, size: 18),
                      label: const Text(
                        'Confirmer la remise du colis au livreur',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      onPressed: () async {
                        try {
                          await supabase.from('orders').update({
                            'status': 'in_transit',
                            'delivery_address': address.toString().replaceAll('[ETAT: ACCEPTE_ATTENTE_AGENCE]', '') + ' [COLIS_REMIS_PAR_ADMIN]',
                          }).eq('id', orderId);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Colis remis avec succès ! Le livreur peut maintenant pointer l\'adresse client et démarrer.'),
                                backgroundColor: Color(0xFF10B981),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.redAccent),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],

          // If cancelled, show motif alert banner!
          if (isCancelled && address.toString().contains('[MOTIF:')) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                address.toString().substring(address.toString().indexOf('[MOTIF:')),
                style: const TextStyle(color: Color(0xFF991B1B), fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    ),
    ),
  );
}

Widget _buildStatusBadge(String status) {
  Color bg;
  Color text;
  String label;

  switch (status) {
    case 'delivered':
      bg = const Color(0xFFD1FAE5);
      text = const Color(0xFF065F46);
      label = 'Livré';
      break;
    case 'in_transit':
      bg = const Color(0xFFDBEAFE);
      text = const Color(0xFF1E40AF);
      label = 'En transit';
      break;
    case 'accepted':
      bg = const Color(0xFFFEF3C7);
      text = const Color(0xFF92400E);
      label = 'En attente agence';
      break;
    case 'cancelled':
      bg = const Color(0xFFFEE2E2);
      text = const Color(0xFF991B1B);
      label = 'Annulé';
      break;
    default:
      bg = const Color(0xFFFFEDD5);
      text = const Color(0xFF9A3412);
      label = 'En attente';
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: text),
    ),
  );
}
