import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/ameex_theme.dart';
import '../widgets/driver_avatar.dart';
import '../widgets/ameex_animations.dart';
import '../widgets/ameex_ui.dart';
import '../widgets/parcel_scanner_dialog.dart';
import 'add_order_screen.dart';
import 'add_driver_screen.dart';
import 'route_history_screen.dart';
import '../widgets/caisse_remittance_helper.dart';

class AdminDriverCache {
  static final Map<String, Map<String, dynamic>> _cache = {};

  static void invalidate(String driverId) => _cache.remove(driverId);
  static void clear() => _cache.clear();

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
  final Map<int, int> _tabVisitKeys = {};

  void _onNavTap(int index) {
    if (index == _selectedNavIndex) return;
    setState(() {
      _selectedNavIndex = index;
      _tabVisitKeys[index] = (_tabVisitKeys[index] ?? 0) + 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = AmeexColors.primaryBlue;

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedIndexedStack(
        index: _selectedNavIndex,
        children: [
          AdminDashboardHomeTab(key: ValueKey('home_${_tabVisitKeys[0] ?? 0}')),
          AdminOrdersTab(key: ValueKey('orders_${_tabVisitKeys[1] ?? 0}')),
          AdminLiveTrackingTab(key: ValueKey('tracking_${_tabVisitKeys[2] ?? 0}')),
          AdminNotificationsTab(key: ValueKey('notif_${_tabVisitKeys[3] ?? 0}')),
          AdminProfileTab(key: ValueKey('profile_${_tabVisitKeys[4] ?? 0}')),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AmeexColors.divider, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedNavIndex,
          onTap: _onNavTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: primaryBlue,
          unselectedItemColor: AmeexColors.textFaint,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11.5),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 2), child: Icon(Icons.dashboard_outlined, size: 22)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 2), child: Icon(Icons.dashboard_rounded, size: 22)),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 2), child: Icon(Icons.inventory_2_outlined, size: 22)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 2), child: Icon(Icons.inventory_2_rounded, size: 22)),
              label: 'Commandes',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 2), child: Icon(Icons.map_outlined, size: 22)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 2), child: Icon(Icons.map_rounded, size: 22)),
              label: 'Suivi',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 2), child: Icon(Icons.notifications_none_rounded, size: 22)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 2), child: Icon(Icons.notifications_rounded, size: 22)),
              label: 'Alertes',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 2), child: Icon(Icons.person_outline_rounded, size: 22)),
              activeIcon: Padding(padding: EdgeInsets.only(bottom: 2), child: Icon(Icons.person_rounded, size: 22)),
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
      backgroundColor: AmeexColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        toolbarHeight: 60,
        title: const AmeexLogo(height: 24),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded,
                color: AmeexColors.textDark, size: 22),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded,
                  color: AmeexColors.textMuted, size: 20),
              tooltip: 'Déconnexion',
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AmeexColors.primaryBlue,
        elevation: 2,
        highlightElevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
        label: const Text('Nouvelle commande',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 14)),
        onPressed: () {
          Navigator.of(context).push(
            AmeexPageRoute(page: const AddOrderScreen()),
          );
        },
      ),
      body: AmeexInitialLoad(
        minDuration: const Duration(seconds: 3),
        skeleton: _buildDashboardSkeleton(),
        child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('orders')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return _buildDashboardSkeleton();
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

          // Revenue calculations
                      final totalRevenue = orders.fold<num>(0, (sum, o) {
                        if (o['status'] == 'delivered') {
                          return sum + ((o['amount'] as num?) ?? 0);
                        }
                        return sum;
                      });
                      final activeToday = orders.where((o) =>
                        o['status'] == 'in_transit' || o['status'] == 'accepted' || o['status'] == 'pending'
                      ).length;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting
                      Row(
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'En ligne · ${_todayLabel()}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AmeexColors.textMuted,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Tableau de bord',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.9,
                          color: AmeexColors.textDark,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$activeToday livraisons actives · $totalCount au total',
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AmeexColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 22),

                      // SIGNATURE HERO CARD — bank-card style with animated balance
                      _buildHeroCard(
                        revenue: totalRevenue.toDouble(),
                        total: totalCount,
                        inTransit: inTransitCount,
                        delivered: deliveredCount,
                      ),

                      const SizedBox(height: 14),

                      // ==== DATA STRIP with sparklines ====
                      _buildDataStrip(
                        orders: orders,
                        inTransit: inTransitCount,
                        delivered: deliveredCount,
                        pending: pendingCount,
                      ),

                      const SizedBox(height: 24),

                      // SECTION: EQUIPE DES LIVREURS AMEEX (DATA LIVREURS EN DIRECT)
                      _buildDriversSection(context, primaryBlue, orders),

                      const SizedBox(height: 28),

                      // Section header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Commandes récentes',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: AmeexColors.textDark,
                            ),
                          ),
                          Text(
                            '${filteredOrders.length}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AmeexColors.textFaint,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Clean search bar — filled gray, no border
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AmeexColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AmeexColors.textDark,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Rechercher client, tracking, ville…',
                            hintStyle: TextStyle(
                              color: AmeexColors.textFaint,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            prefixIcon: Icon(Icons.search_rounded,
                                color: AmeexColors.textMuted, size: 20),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Orders List
              filteredOrders.isEmpty
                  ? const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: AmeexEmptyState(
                          icon: Icons.inbox_outlined,
                          title: 'Aucune commande',
                          hint: 'Aucune commande ne correspond à votre recherche.',
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
      ),
    );
  }

  /// Full-screen skeleton shown for first 3s + while waiting for stream.
  Widget _buildDashboardSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AmeexSkeleton(width: 140, height: 12, radius: 6),
          const SizedBox(height: 12),
          const AmeexSkeleton(width: 220, height: 26, radius: 8),
          const SizedBox(height: 8),
          const AmeexSkeleton(width: 180, height: 12, radius: 6),
          const SizedBox(height: 22),

          // Hero card skeleton
          Container(
            height: 230,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: AmeexDesign.shadowCard,
            ),
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    AmeexSkeleton(width: 140, height: 12, radius: 6),
                    AmeexSkeleton(width: 40, height: 12, radius: 6),
                  ],
                ),
                const SizedBox(height: 28),
                const AmeexSkeleton(width: 180, height: 36, radius: 10),
                const SizedBox(height: 10),
                const AmeexSkeleton(width: 140, height: 12, radius: 6),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    AmeexSkeleton(width: 60, height: 32, radius: 8),
                    AmeexSkeleton(width: 60, height: 32, radius: 8),
                    AmeexSkeleton(width: 60, height: 32, radius: 8),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Data strip skeleton
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AmeexDesign.shadowCard,
            ),
            child: Row(
              children: List.generate(4, (i) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 3 ? 12 : 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        AmeexSkeleton(width: 40, height: 10, radius: 4),
                        SizedBox(height: 8),
                        AmeexSkeleton(width: 48, height: 20, radius: 6),
                        SizedBox(height: 8),
                        AmeexSkeleton(width: double.infinity, height: 22, radius: 6),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 24),

          // Drivers section skeleton
          const AmeexSkeleton(width: 160, height: 18, radius: 6),
          const SizedBox(height: 14),
          SizedBox(
            height: 168,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => Container(
                width: 260,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AmeexDesign.shadowCard,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        AmeexSkeleton(width: 42, height: 42, radius: 999),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AmeexSkeleton(width: 120, height: 14, radius: 6),
                              SizedBox(height: 6),
                              AmeexSkeleton(width: 80, height: 11, radius: 6),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: const [
                        AmeexSkeleton(width: 80, height: 30, radius: 10),
                        SizedBox(width: 10),
                        AmeexSkeleton(width: 80, height: 30, radius: 10),
                      ],
                    ),
                    const Spacer(),
                    const AmeexSkeleton(width: 160, height: 12, radius: 6),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Section header
          const AmeexSkeleton(width: 180, height: 17, radius: 6),
          const SizedBox(height: 14),
          const AmeexSkeleton(width: double.infinity, height: 48, radius: 14),
          const SizedBox(height: 16),

          // Order list skeleton
          ...List.generate(3, (_) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AmeexDesign.shadowCard,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AmeexSkeleton(width: 42, height: 42, radius: 999),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      AmeexSkeleton(width: 140, height: 14, radius: 6),
                      SizedBox(height: 7),
                      AmeexSkeleton(width: 180, height: 11, radius: 6),
                    ],
                  ),
                ),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AmeexSkeleton(width: 60, height: 16, radius: 6),
                    SizedBox(height: 10),
                    AmeexSkeleton(width: 54, height: 20, radius: 999),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  String _todayLabel() {
    const months = [
      'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
    ];
    final now = DateTime.now();
    return '${now.day} ${months[now.month - 1]}';
  }

  /// 14-day trend series for the sparkline, based on orders createdAt
  /// and a simple status filter. Returns at least 2 points.
  List<double> _buildSparkSeries(List<Map<String, dynamic>> orders, bool Function(Map<String, dynamic>) match) {
    const days = 14;
    final now = DateTime.now();
    final buckets = List<double>.filled(days, 0);
    for (final o in orders) {
      if (!match(o)) continue;
      final created = DateTime.tryParse((o['created_at'] ?? '').toString());
      if (created == null) continue;
      final diff = now.difference(created).inDays;
      if (diff < 0 || diff >= days) continue;
      buckets[days - 1 - diff] += 1;
    }
    if (buckets.every((v) => v == 0)) {
      return const [0.2, 0.4, 0.3, 0.5, 0.6, 0.4, 0.7, 0.5, 0.8, 0.6, 0.9, 0.7, 1.0, 0.8];
    }
    return buckets;
  }

  /// Compare last 7 days vs previous 7 days → percentage change
  double _trendDelta(List<double> series) {
    if (series.length < 14) return 0;
    final recent = series.sublist(7).fold<double>(0, (a, b) => a + b);
    final past = series.sublist(0, 7).fold<double>(0, (a, b) => a + b);
    if (past == 0) return recent > 0 ? 100 : 0;
    return ((recent - past) / past) * 100;
  }

  Widget _buildDataStrip({
    required List<Map<String, dynamic>> orders,
    required int inTransit,
    required int delivered,
    required int pending,
  }) {
    final transitSeries = _buildSparkSeries(orders, (o) => o['status'] == 'in_transit');
    final deliveredSeries = _buildSparkSeries(orders, (o) => o['status'] == 'delivered');
    final pendingSeries = _buildSparkSeries(orders, (o) => o['status'] == 'pending');
    final totalSeries = _buildSparkSeries(orders, (o) => true);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AmeexDesign.shadowCard,
      ),
      child: Row(
        children: [
          Expanded(
            child: _sparkCell(
              label: 'Transit',
              value: inTransit,
              series: transitSeries,
              color: AmeexColors.primaryBlue,
              style: AmeexSparklineStyle.bars,
            ),
          ),
          _vDivider(),
          Expanded(
            child: _sparkCell(
              label: 'Livré',
              value: delivered,
              series: deliveredSeries,
              color: const Color(0xFF10B981),
              style: AmeexSparklineStyle.area,
            ),
          ),
          _vDivider(),
          Expanded(
            child: _sparkCell(
              label: 'Attente',
              value: pending,
              series: pendingSeries,
              color: const Color(0xFFF59E0B),
              style: AmeexSparklineStyle.bars,
            ),
          ),
          _vDivider(),
          Expanded(
            child: _sparkCell(
              label: 'Total',
              value: orders.length,
              series: totalSeries,
              color: AmeexColors.primaryBlue,
              style: AmeexSparklineStyle.area,
            ),
          ),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(
        width: 1,
        height: 56,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: AmeexColors.divider,
      );

  Widget _sparkCell({
    required String label,
    required int value,
    required List<double> series,
    required Color color,
    required AmeexSparklineStyle style,
  }) {
    final delta = _trendDelta(series);
    final up = delta >= 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: AmeexColors.textMuted,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AmeexAnimatedNumber(
              value: value.toDouble(),
              format: (v) => v.toStringAsFixed(0),
              style: const TextStyle(
                fontFamily: AmeexTheme.fontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: AmeexColors.textDark,
                height: 1,
              ),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  Icon(
                    up ? Icons.north_rounded : Icons.south_rounded,
                    size: 9,
                    color: up ? const Color(0xFF10B981) : const Color(0xFFDC2626),
                  ),
                  const SizedBox(width: 1),
                  Text(
                    '${delta.abs().toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: up ? const Color(0xFF10B981) : const Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AmeexSparkline(
          values: series,
          color: color,
          height: 28,
          style: style,
        ),
      ],
    );
  }

  Widget _buildHeroCard({
    required double revenue,
    required int total,
    required int inTransit,
    required int delivered,
  }) {
    final rate = total == 0 ? 0 : ((delivered / total) * 100).round();
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF17378C),
            Color(0xFF14307A),
            Color(0xFF071A4A),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14307A).withValues(alpha: 0.10),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: const Color(0xFF14307A).withValues(alpha: 0.28),
            blurRadius: 40,
            offset: const Offset(0, 18),
            spreadRadius: -10,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: CustomPaint(painter: _HeroArcPainter()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.trending_up_rounded,
                          size: 16,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Revenus encaissés',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'MAD',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                AmeexAnimatedNumber(
                  value: revenue,
                  format: _formatMoney,
                  style: const TextStyle(
                    fontFamily: AmeexTheme.fontFamily,
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.5,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4ADE80),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      '$rate% de livraisons réussies',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.08),
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: _heroMetric(label: 'Total', value: '$total'),
                    ),
                    Expanded(
                      child: _heroMetric(label: 'En transit', value: '$inTransit'),
                    ),
                    Expanded(
                      child: _heroMetric(label: 'Livré', value: '$delivered'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroGlow(double size, Color color) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withValues(alpha: 0)],
            ),
          ),
        ),
      );

  Widget _heroMetric({required String label, required String value}) {
    final n = double.tryParse(value) ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        AmeexAnimatedNumber(
          value: n,
          format: (v) => v.toStringAsFixed(0),
          style: const TextStyle(
            fontFamily: AmeexTheme.fontFamily,
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  String _formatMoney(double value) {
    final s = value.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  Widget _driverMetric({
    required IconData icon,
    required String value,
    required String label,
    Color accent = AmeexColors.primaryBlue,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AmeexColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: AmeexColors.textDark,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AmeexColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  void _showValidateRemittanceDialog(
    BuildContext context,
    Map<String, dynamic> driver,
    DriverCaisseBalances balances,
    List<Map<String, dynamic>> driverOrders,
  ) {
    final name = driver['full_name'] ?? 'Livreur';
    final driverId = driver['id'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Validation Versement Caisse',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DriverAvatar(
                  driverData: driver,
                  radius: 20,
                  borderColor: AmeexColors.primaryBlue,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('${balances.unremittedCount} colis livré(s) à encaisser', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Montant d\'espèces reçu du livreur (COD) :', style: TextStyle(fontSize: 12, color: Color(0xFF92400E))),
                  const SizedBox(height: 4),
                  Text(
                    '${balances.codToRemitToAgency.toStringAsFixed(2)} MAD',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF5FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_rounded, color: AmeexColors.primaryBlue, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'En confirmant la réception de ces espèces, la commission de +${balances.pendingCommission.toStringAsFixed(2)} MAD sera automatiquement débloquée pour $name.',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF1E3A8A)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.verified_rounded, size: 18),
            label: const Text('Confirmer la Réception', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                final count = await CaisseRemittanceHelper.validateDriverRemittance(
                  supabase: supabase,
                  driverId: driverId,
                  orders: driverOrders,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Versement de ${balances.codToRemitToAgency.toStringAsFixed(2)} MAD validé pour $name ($count colis) ! Commission débloquée.'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur lors de la validation: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
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
                    const Text(
                      'Équipe de livreurs',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AmeexColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${drivers.length}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AmeexColors.textFaint,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AmeexColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      AmeexPageRoute(page: const AddDriverScreen()),
                    );
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 16),
                      SizedBox(width: 4),
                      Text('Ajouter',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (drivers.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0E1116).withValues(alpha: 0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Aucun livreur enregistré pour le moment.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AmeexColors.textMuted, fontSize: 13.5, fontWeight: FontWeight.w500),
                  ),
                ),
              )
            else
              SizedBox(
                height: 168,
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

                    final activeMissions = orders.where((o) =>
                        o['assigned_driver_id'] == dId &&
                        o['status'] != 'delivered' &&
                        o['status'] != 'cancelled').length;

                    final driverOrders = orders.where((o) => o['assigned_driver_id'] == dId).toList();
                    final balances = CaisseRemittanceHelper.calculateBalances(driverOrders);
                    final needsRemittance = balances.codToRemitToAgency > 0;

                    return Container(
                      width: 260,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AmeexDesign.shadowCard,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Avatar with soft brand ring
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AmeexColors.primaryBlue.withValues(alpha: 0.35),
                                      AmeexColors.primaryBlue.withValues(alpha: 0.08),
                                    ],
                                  ),
                                ),
                                child: DriverAvatar(
                                  driverData: d,
                                  radius: 19,
                                  borderColor: Colors.white,
                                  borderWidth: 1.5,
                                  showBadge: true,
                                  badgeColor: const Color(0xFF10B981),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14.5,
                                        letterSpacing: -0.2,
                                        color: AmeexColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      phone,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AmeexColors.textMuted,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Inline metrics row
                          Row(
                            children: [
                              _driverMetric(
                                icon: Icons.local_shipping_outlined,
                                value: '$activeMissions',
                                label: 'En cours',
                              ),
                              const SizedBox(width: 12),
                              _driverMetric(
                                icon: Icons.account_balance_wallet_outlined,
                                value: needsRemittance
                                    ? '${balances.codToRemitToAgency.toStringAsFixed(0)}'
                                    : '0',
                                label: needsRemittance ? 'Caisse MAD' : 'À jour',
                                accent: needsRemittance
                                    ? const Color(0xFFD97706)
                                    : const Color(0xFF10B981),
                              ),
                            ],
                          ),

                          const Spacer(),

                          // Footer — vehicle/zone + action
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(Icons.place_outlined, size: 13, color: AmeexColors.textFaint),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '$vehicle · $zone',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: AmeexColors.textMuted,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (needsRemittance)
                                InkWell(
                                  borderRadius: BorderRadius.circular(999),
                                  onTap: () => _showValidateRemittanceDialog(context, d, balances, driverOrders),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AmeexColors.primaryBlue,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Text(
                                      'Valider',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                                    ),
                                  ),
                                ),
                            ],
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
      backgroundColor: AmeexColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        toolbarHeight: 60,
        title: const Text(
          'Commandes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: AmeexColors.textDark,
          ),
        ),
      ),
      body: AmeexInitialLoad(
        minDuration: const Duration(seconds: 3),
        skeleton: _buildOrdersSkeleton(),
        child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('orders')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildOrdersSkeleton();
          }

          final orders = snapshot.data ?? [];
          final acceptedCount = orders.where((o) {
            final rawAddr = o['delivery_address']?.toString() ?? '';
            return o['status'] == 'accepted' ||
                rawAddr.contains('[ETAT: ACCEPTE_ATTENTE_AGENCE]') ||
                rawAddr.contains('ACCEPTE_ATTENTE_AGENCE');
          }).length;

          final counts = <String, int>{
            'all': orders.length,
            'accepted': acceptedCount,
            'pending': orders.where((o) {
              final rawAddr = o['delivery_address']?.toString() ?? '';
              final isAcc = o['status'] == 'accepted' ||
                  rawAddr.contains('[ETAT: ACCEPTE_ATTENTE_AGENCE]') ||
                  rawAddr.contains('ACCEPTE_ATTENTE_AGENCE');
              return o['status'] == 'pending' && !isAcc;
            }).length,
            'in_transit': orders.where((o) => o['status'] == 'in_transit').length,
            'delivered': orders.where((o) => o['status'] == 'delivered').length,
            'cancelled': orders.where((o) => o['status'] == 'cancelled').length,
          };
          final filtered = orders.where((o) {
            if (_selectedStatusFilter == 'all') return true;
            final rawAddr = o['delivery_address']?.toString() ?? '';
            final isAcc = o['status'] == 'accepted' ||
                rawAddr.contains('[ETAT: ACCEPTE_ATTENTE_AGENCE]') ||
                rawAddr.contains('ACCEPTE_ATTENTE_AGENCE');
            if (_selectedStatusFilter == 'accepted') return isAcc;
            if (_selectedStatusFilter == 'pending') return o['status'] == 'pending' && !isAcc;
            return o['status'] == _selectedStatusFilter;
          }).toList();

          return Column(
            children: [
              // Clean filter pills
              Container(
                height: 54,
                color: Colors.white,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  children: [
                    _buildFilterChip('Toutes',                 'all',        counts['all']!),
                    _buildFilterChip('À l\'agence (Acceptées)', 'accepted',   counts['accepted']!),
                    _buildFilterChip('En attente',             'pending',    counts['pending']!),
                    _buildFilterChip('En transit',             'in_transit', counts['in_transit']!),
                    _buildFilterChip('Livrées',                'delivered',  counts['delivered']!),
                    _buildFilterChip('Annulées',               'cancelled',  counts['cancelled']!),
                  ],
                ),
              ),
              const Divider(height: 1, color: AmeexColors.divider),

              Expanded(
                child: filtered.isEmpty
                    ? const AmeexEmptyState(
                        icon: Icons.inbox_outlined,
                        title: 'Aucune commande',
                        hint: 'Aucune commande dans cette catégorie.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final order = filtered[index];
                          return _buildOrderCard(context, order, deepNavy);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      ),
    );
  }

  Widget _buildOrdersSkeleton() {
    return Column(
      children: [
        // Filter pills row
        Container(
          height: 54,
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: Row(
            children: const [
              AmeexSkeleton(width: 80, height: 32, radius: 999),
              SizedBox(width: 8),
              AmeexSkeleton(width: 100, height: 32, radius: 999),
              SizedBox(width: 8),
              AmeexSkeleton(width: 110, height: 32, radius: 999),
              SizedBox(width: 8),
              AmeexSkeleton(width: 90, height: 32, radius: 999),
            ],
          ),
        ),
        const Divider(height: 1, color: AmeexColors.divider),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: 6,
            itemBuilder: (_, __) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AmeexDesign.shadowCard,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AmeexSkeleton(width: 42, height: 42, radius: 999),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        AmeexSkeleton(width: 140, height: 14, radius: 6),
                        SizedBox(height: 8),
                        AmeexSkeleton(width: 180, height: 11, radius: 6),
                      ],
                    ),
                  ),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AmeexSkeleton(width: 60, height: 16, radius: 6),
                      SizedBox(height: 10),
                      AmeexSkeleton(width: 54, height: 20, radius: 999),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _selectedStatusFilter == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => setState(() => _selectedStatusFilter = value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AmeexColors.primaryBlue : AmeexColors.surfaceAlt,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AmeexColors.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.22)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: isSelected ? Colors.white : AmeexColors.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
      backgroundColor: AmeexColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        toolbarHeight: 60,
        title: const Text(
          'Suivi en direct',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: AmeexColors.textDark,
          ),
        ),
      ),
      body: AmeexInitialLoad(
        skeleton: _buildLiveTrackingSkeleton(),
        child: Column(
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
      ),
    );
  }

  Widget _buildLiveTrackingSkeleton() {
    return Column(
      children: [
        Expanded(
          flex: 6,
          child: Container(
            color: const Color(0xFFF1F5F9),
            child: const Center(child: AmeexLoading(size: 44)),
          ),
        ),
        Expanded(
          flex: 4,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    AmeexSkeleton(width: 110, height: 32, radius: 999),
                    SizedBox(width: 8),
                    AmeexSkeleton(width: 130, height: 32, radius: 999),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: 3,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, __) => Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: const [
                          AmeexSkeleton(width: 40, height: 40, radius: 999),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AmeexSkeleton(width: 120, height: 14, radius: 6),
                                SizedBox(height: 6),
                                AmeexSkeleton(width: 160, height: 11, radius: 6),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
      backgroundColor: AmeexColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        toolbarHeight: 60,
        title: const Text(
          'Activité & alertes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: AmeexColors.textDark,
          ),
        ),
      ),
      body: AmeexInitialLoad(
        minDuration: const Duration(seconds: 3),
        skeleton: _notificationsSkeleton(),
        child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('orders')
            .stream(primaryKey: ['id'])
            .order('updated_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return _notificationsSkeleton();
          }
          final orders = snapshot.data ?? [];

          // Show notifications of delivered, cancelled (with motif), or in_transit
          final events = orders.where((o) => o['status'] != 'pending').toList();

          if (events.isEmpty) {
            return const AmeexEmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'Aucune activité récente',
              hint: 'Les livraisons terminées et annulations apparaîtront ici.',
            );
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
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: AmeexDesign.shadowCard,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: iconColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              letterSpacing: -0.1,
                              color: AmeexColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AmeexColors.textMuted,
                              fontWeight: FontWeight.w500,
                              height: 1.35,
                            ),
                          ),
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
      ),
    );
  }

  Widget _notificationsSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AmeexDesign.shadowCard,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AmeexSkeleton(width: 38, height: 38, radius: 999),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  AmeexSkeleton(width: 220, height: 14, radius: 6),
                  SizedBox(height: 8),
                  AmeexSkeleton(width: double.infinity, height: 11, radius: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// TAB 4: PROFIL ADMIN & GESTION DE L'ÉQUIPE DES LIVREURS
// ============================================================================
class AdminProfileTab extends StatefulWidget {
  const AdminProfileTab({super.key});

  @override
  State<AdminProfileTab> createState() => _AdminProfileTabState();
}

class _AdminProfileTabState extends State<AdminProfileTab> {
  String _selectedFilter = 'all'; // 'all', 'online', 'offline', 'caisse'

  Widget _buildFilterChip(String label, String value, int count, Color color, IconData icon) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => setState(() => _selectedFilter = value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AmeexColors.primaryBlue : AmeexColors.surfaceAlt,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isSelected ? AmeexColors.primaryBlue : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isSelected ? Colors.white : color,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AmeexColors.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.22)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: isSelected ? Colors.white : AmeexColors.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 10.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
      backgroundColor: AmeexColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        toolbarHeight: 60,
        title: const Text(
          'Profil',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: AmeexColors.textDark,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded,
                  color: AmeexColors.textMuted, size: 20),
              tooltip: 'Déconnexion',
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
      body: AmeexInitialLoad(
        minDuration: const Duration(seconds: 3),
        skeleton: _profileSkeleton(),
        child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admin Profile Hero
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AmeexDesign.heroGradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: AmeexDesign.shadowHero,
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -30, right: -20,
                    child: Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.10),
                            Colors.white.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 58, height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                            width: 1.2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.shield_outlined,
                            size: 26, color: Colors.white),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ADMINISTRATEUR',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.6,
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              user?.email?.split('@').first ?? 'Admin',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.email ?? 'admin@ameex.ma',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // BUTTON: AJOUTER UN LIVREUR
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AmeexColors.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text(
                  'Ajouter un nouveau livreur',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    AmeexPageRoute(page: const AddDriverScreen()),
                  );
                },
              ),
            ),

            const SizedBox(height: 28),

            // Drivers List Header
            const Text(
              'Équipe de livreurs',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: AmeexColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Gérez votre équipe et les caisses en attente',
              style: TextStyle(
                fontSize: 13,
                color: AmeexColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),

            // Drivers List Stream
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase
                  .from('orders')
                  .stream(primaryKey: ['id']),
              builder: (context, ordersSnap) {
                final allOrders = ordersSnap.data ?? [];

                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: supabase
                      .from('driver_locations')
                      .stream(primaryKey: ['id']),
                  builder: (context, locSnap) {
                    final locations = locSnap.data ?? [];
                    final now = DateTime.now().toUtc();
                    final activeGpsDriverIds = <String>{};
                    for (final l in locations) {
                      final dId = l['driver_id'] as String?;
                      final dtStr = l['updated_at'] as String?;
                      if (dId != null && dtStr != null) {
                        final dt = DateTime.tryParse(dtStr);
                        if (dt != null && now.difference(dt.toUtc()).inMinutes.abs() < 20) {
                          activeGpsDriverIds.add(dId);
                        }
                      }
                    }

                    return StreamBuilder<List<Map<String, dynamic>>>(
                      stream: supabase
                          .from('profiles')
                          .stream(primaryKey: ['id'])
                          .eq('role', 'driver'),
                      builder: (context, snapshot) {
                        final drivers = snapshot.data ?? [];

                        if (drivers.isEmpty) {
                          return const AmeexEmptyState(
                            icon: Icons.two_wheeler_rounded,
                            title: 'Aucun livreur',
                            hint: 'Ajoutez votre premier livreur pour commencer à distribuer des commandes.',
                          );
                        }

                        // Helper to check if driver is online
                        bool isDriverOnline(Map<String, dynamic> d) {
                          final dId = d['id'];
                          if (d['is_online'] == true || d['status'] == 'online') return true;
                          final z = (d['zone'] ?? '').toString();
                          if (z.contains('[STATUS:online]') || z.contains('[ONLINE]')) return true;
                          if (activeGpsDriverIds.contains(dId)) return true;
                          final hasActiveOrder = allOrders.any((o) =>
                              o['assigned_driver_id'] == dId &&
                              (o['status'] == 'in_transit' || o['status'] == 'accepted'));
                          if (hasActiveOrder) return true;
                          return false;
                        }

                        // Filter Counts
                        int onlineCount = 0;
                        int offlineCount = 0;
                        int caissePendingCount = 0;

                        for (final d in drivers) {
                          final dId = d['id'];
                          final dOrders = allOrders.where((o) => o['assigned_driver_id'] == dId).toList();
                          final b = CaisseRemittanceHelper.calculateBalances(dOrders);

                          if (isDriverOnline(d)) {
                            onlineCount++;
                          } else {
                            offlineCount++;
                          }

                          if (b.codToRemitToAgency > 0) {
                            caissePendingCount++;
                          }
                        }

                        // Filtered Drivers list based on _selectedFilter
                        final filteredDrivers = drivers.where((d) {
                          final isOnline = isDriverOnline(d);
                          final dOrders = allOrders.where((o) => o['assigned_driver_id'] == d['id']).toList();
                          final b = CaisseRemittanceHelper.calculateBalances(dOrders);
                          final needsRemittance = b.codToRemitToAgency > 0;

                          if (_selectedFilter == 'online') return isOnline;
                          if (_selectedFilter == 'offline') return !isOnline;
                          if (_selectedFilter == 'caisse') return needsRemittance;
                          return true;
                        }).toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Filter Pills Bar (Tous, En ligne / Disponibles, Hors ligne, Caisse à verser)
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: [
                                  _buildFilterChip('Tous', 'all', drivers.length, AmeexColors.primaryBlue, Icons.people_alt_rounded),
                                  _buildFilterChip('En ligne (Disponibles)', 'online', onlineCount, const Color(0xFF10B981), Icons.check_circle_rounded),
                                  _buildFilterChip('Hors ligne', 'offline', offlineCount, const Color(0xFF94A3B8), Icons.pause_circle_filled_rounded),
                                  _buildFilterChip('Caisse à verser', 'caisse', caissePendingCount, const Color(0xFFD97706), Icons.monetization_on_rounded),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            if (filteredDrivers.isEmpty)
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(top: 8, bottom: 20),
                                padding: const EdgeInsets.all(28),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: AmeexDesign.shadowCard,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _selectedFilter == 'caisse'
                                          ? Icons.check_circle_rounded
                                          : (_selectedFilter == 'online' ? Icons.wifi_off_rounded : Icons.people_outline_rounded),
                                      size: 40,
                                      color: _selectedFilter == 'caisse' ? const Color(0xFF10B981) : Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _selectedFilter == 'caisse'
                                          ? 'Toutes les caisses sont à jour !'
                                          : (_selectedFilter == 'online'
                                              ? 'Aucun livreur actuellement en ligne'
                                              : 'Aucun livreur dans cette catégorie'),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AmeexColors.textDark),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _selectedFilter == 'caisse'
                                          ? 'Aucun encaissement en attente pour le moment.'
                                          : 'Sélectionnez "Tous" pour voir l\'ensemble des livreurs.',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filteredDrivers.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                              final d = filteredDrivers[index];
                              final name = d['full_name'] ?? 'Livreur';
                              final phone = d['phone'] ?? 'Non renseigné';
                              final vehicle = d['vehicle_type'] ?? 'Moto / Scooter';
                              final zone = d['zone'] ?? 'Casablanca';
                              final dId = d['id'];

                              final isOnline = isDriverOnline(d);

                              final driverOrders = allOrders.where((o) => o['assigned_driver_id'] == dId).toList();
                              final balances = CaisseRemittanceHelper.calculateBalances(driverOrders);
                              final needsRemittance = balances.codToRemitToAgency > 0;
                              final activeOrders = driverOrders.where((o) =>
                                  o['status'] != 'delivered' && o['status'] != 'cancelled').length;

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: AmeexDesign.shadowCard,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                (isOnline ? const Color(0xFF10B981) : AmeexColors.primaryBlue).withValues(alpha: 0.35),
                                                (isOnline ? const Color(0xFF10B981) : AmeexColors.primaryBlue).withValues(alpha: 0.08),
                                              ],
                                            ),
                                          ),
                                          child: DriverAvatar(
                                            driverData: d,
                                            radius: 20,
                                            borderColor: Colors.white,
                                            borderWidth: 1.5,
                                            showBadge: true,
                                            badgeColor: isOnline ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                  letterSpacing: -0.2,
                                                  color: AmeexColors.textDark,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Row(
                                                children: [
                                                  const Icon(Icons.phone_outlined, size: 12, color: AmeexColors.textMuted),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    phone,
                                                    style: const TextStyle(
                                                      color: AmeexColors.textMuted,
                                                      fontSize: 12.5,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 5),
                                              Row(
                                                children: [
                                                  Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      borderRadius: BorderRadius.circular(6),
                                                      onTap: () async {
                                                        final nextStatus = !isOnline;
                                                        final currentZone = (d['zone'] ?? '').toString();
                                                        final cleanZone = currentZone
                                                            .replaceAll(RegExp(r'\[STATUS:[^\]]+\]'), '')
                                                            .replaceAll('[ONLINE]', '')
                                                            .replaceAll('[OFFLINE]', '')
                                                            .trim();
                                                        final newZone = ' [STATUS:]';

                                                        try {
                                                          try {
                                                            await supabase.from('profiles').update({
                                                              'is_online': nextStatus,
                                                              'status': nextStatus ? 'online' : 'offline',
                                                              'zone': newZone,
                                                            }).eq('id', dId);
                                                          } catch (_) {
                                                            await supabase.from('profiles').update({
                                                              'zone': newZone,
                                                            }).eq('id', dId);
                                                          }

                                                          if (context.mounted) {
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              SnackBar(
                                                                content: Text(nextStatus
                                                                    ? ' est maintenant En ligne (Disponible) !'
                                                                    : ' est maintenant Hors ligne.'),
                                                                backgroundColor: nextStatus ? const Color(0xFF10B981) : const Color(0xFF64748B),
                                                                duration: const Duration(seconds: 2),
                                                                behavior: SnackBarBehavior.floating,
                                                              ),
                                                            );
                                                          }
                                                        } catch (_) {}
                                                      },
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                                        decoration: BoxDecoration(
                                                          color: isOnline ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                                                          borderRadius: BorderRadius.circular(6),
                                                          border: Border.all(
                                                            color: isOnline ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1),
                                                          ),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              Icons.circle,
                                                              size: 6,
                                                              color: isOnline ? const Color(0xFF15803D) : const Color(0xFF64748B),
                                                            ),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              isOnline ? 'En ligne · Disponible' : 'Hors ligne',
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                fontWeight: FontWeight.bold,
                                                                color: isOnline ? const Color(0xFF15803D) : const Color(0xFF64748B),
                                                              ),
                                                            ),
                                                            const SizedBox(width: 4),
                                                            Icon(
                                                              Icons.touch_app_outlined,
                                                              size: 10,
                                                              color: isOnline ? const Color(0xFF15803D).withValues(alpha: 0.7) : const Color(0xFF64748B).withValues(alpha: 0.7),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                  // Direct delete button
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(999),
                                      onTap: () => _confirmDeleteDriver(
                                        context: context,
                                        driverId: dId,
                                        driverName: name,
                                        activeOrders: activeOrders,
                                      ),
                                      child: Container(
                                        width: 36, height: 36,
                                        decoration: BoxDecoration(
                                          color: AmeexColors.dangerRed.withValues(alpha: 0.08),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: AmeexColors.dangerRed,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              // Meta row
                              Row(
                                children: [
                                  const Icon(Icons.place_outlined, size: 13, color: AmeexColors.textFaint),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${DriverAvatarHelper.cleanVehicle(vehicle)} · ${DriverAvatarHelper.cleanZone(zone)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AmeexColors.textMuted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Dual Financial Metrics Box (Revenus vs Caisse Agence)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        // 1. Solde Revenus du livreur
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF0FDF4),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: const Color(0xFFBBF7D0)),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Row(
                                                  children: [
                                                    Icon(Icons.account_balance_wallet_rounded, size: 14, color: Color(0xFF16A34A)),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'Solde Revenus',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w700,
                                                        color: Color(0xFF166534),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  '${balances.totalCommission.toStringAsFixed(2)} MAD',
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w800,
                                                    color: Color(0xFF15803D),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${balances.availableCommission.toStringAsFixed(0)} MAD dispo · ${balances.pendingCommission.toStringAsFixed(0)} MAD attente',
                                                  style: const TextStyle(fontSize: 9.5, color: Color(0xFF166534)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),

                                        // 2. Caisse à verser à l'agence
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: needsRemittance ? const Color(0xFFFFFBEB) : const Color(0xFFF8FAFC),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(
                                                color: needsRemittance ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.storefront_rounded,
                                                      size: 14,
                                                      color: needsRemittance ? const Color(0xFFD97706) : Colors.grey,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Caisse à verser',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w700,
                                                        color: needsRemittance ? const Color(0xFF92400E) : Colors.grey.shade700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  '${balances.codToRemitToAgency.toStringAsFixed(2)} MAD',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w800,
                                                    color: needsRemittance ? const Color(0xFFB45309) : const Color(0xFF475569),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  needsRemittance ? '${balances.unremittedCount} colis à verser' : 'Caisse à jour',
                                                  style: TextStyle(
                                                    fontSize: 9.5,
                                                    color: needsRemittance ? const Color(0xFFB45309) : Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Action bar if needs remittance
                                    if (needsRemittance) ...[
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () async {
                                            final ok = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                title: const Text('Valider versement caisse ?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                content: Text('Confirmez-vous que le livreur $name a remis la somme de ${balances.codToRemitToAgency.toStringAsFixed(2)} MAD à l\'agence ?\n\nCette action débloquera +${balances.pendingCommission.toStringAsFixed(2)} MAD sur son solde retirable.'),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
                                                  ElevatedButton(
                                                    onPressed: () => Navigator.of(ctx).pop(true),
                                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                                                    child: const Text('Confirmer l\'encaissement'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (ok == true) {
                                              await CaisseRemittanceHelper.validateDriverRemittance(
                                                supabase: supabase,
                                                driverId: dId,
                                                orders: driverOrders,
                                              );
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Caisse validée pour $name.'),
                                                    backgroundColor: const Color(0xFF10B981),
                                                    behavior: SnackBarBehavior.floating,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          icon: const Icon(Icons.check_circle_rounded, size: 16),
                                          label: Text('Valider encaissement caisse (${balances.codToRemitToAgency.toStringAsFixed(0)} MAD)'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFD97706),
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                );
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
      ),
    );
  }

  Widget _profileSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: AmeexDesign.shadowCard,
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const AmeexSkeleton(width: 58, height: 58, radius: 999),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      AmeexSkeleton(width: 100, height: 11, radius: 6),
                      SizedBox(height: 10),
                      AmeexSkeleton(width: 160, height: 20, radius: 6),
                      SizedBox(height: 8),
                      AmeexSkeleton(width: 140, height: 12, radius: 6),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const AmeexSkeleton(width: double.infinity, height: 52, radius: 14),
          const SizedBox(height: 28),
          const AmeexSkeleton(width: 180, height: 17, radius: 6),
          const SizedBox(height: 14),
          ...List.generate(3, (_) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AmeexDesign.shadowCard,
            ),
            child: Column(
              children: [
                Row(
                  children: const [
                    AmeexSkeleton(width: 44, height: 44, radius: 999),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AmeexSkeleton(width: 140, height: 14, radius: 6),
                          SizedBox(height: 8),
                          AmeexSkeleton(width: 120, height: 11, radius: 6),
                        ],
                      ),
                    ),
                    AmeexSkeleton(width: 36, height: 36, radius: 999),
                  ],
                ),
                const SizedBox(height: 14),
                const AmeexSkeleton(width: double.infinity, height: 12, radius: 6),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteDriver({
    required BuildContext context,
    required String driverId,
    required String driverName,
    required int activeOrders,
  }) async {
    final supabase = Supabase.instance.client;

    if (activeOrders > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible de supprimer $driverName : $activeOrders commande(s) en cours.',
          ),
          backgroundColor: AmeexColors.dangerRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final ok = await AmeexDialog.confirm(
      context,
      title: 'Supprimer ce livreur ?',
      message: 'Vous allez supprimer le profil de $driverName. Cette action est irréversible.',
      icon: Icons.delete_outline_rounded,
      confirmLabel: 'Supprimer',
      destructive: true,
    );

    if (ok != true) return;

    try {
      // 1. Unassign all orders assigned to this driver to satisfy any foreign keys
      try {
        await supabase
            .from('orders')
            .update({'assigned_driver_id': null})
            .eq('assigned_driver_id', driverId);
      } catch (_) {}

      // 2. Try server-side RPC if defined
      bool rpcSuccess = false;
      try {
        await supabase.rpc('delete_driver', params: {'driver_id': driverId});
        rpcSuccess = true;
      } catch (_) {}

      // 3. If RPC is not available, delete or deactivate the profile directly
      if (!rpcSuccess) {
        bool deleted = false;
        try {
          await supabase.from('profiles').delete().eq('id', driverId);
          deleted = true;
        } catch (_) {}

        // Fallback: If hard delete is restricted by RLS, set role to 'deleted'
        // This instantly removes the driver from all active queries and prevents login.
        if (!deleted) {
          await supabase.from('profiles').update({
            'role': 'deleted',
            'full_name': '[Supprimé] $driverName',
            'phone': '',
            'zone': 'Désactivé',
          }).eq('id', driverId);
        }
      }

      // 4. Invalidate local cache
      AdminDriverCache.invalidate(driverId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Le compte de $driverName a été supprimé avec succès.'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final clean = e.toString().replaceAll(RegExp(r'[{}"]'), '').trim();
        final msg = clean.length > 140 ? '${clean.substring(0, 140)}…' : clean;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: $msg'),
            backgroundColor: AmeexColors.dangerRed,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}

/// Soft embossed arcs on the dark hero card (bank-card aesthetic).
class _HeroArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.05);

    final center = Offset(size.width + 40, size.height + 20);
    for (int i = 0; i < 3; i++) {
      final r = 160.0 + i * 40;
      canvas.drawCircle(center, r, paint);
    }

    final paintLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = Colors.white.withValues(alpha: 0.03);
    canvas.drawLine(
      Offset(0, size.height * 0.35),
      Offset(size.width, size.height * 0.25),
      paintLine,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
  final bool isAcceptedWaitingAgency = status == 'accepted' ||
      rawAddress.toString().contains('[ETAT: ACCEPTE_ATTENTE_AGENCE]') ||
      rawAddress.toString().contains('ACCEPTE_ATTENTE_AGENCE');
  final effectiveStatus = isAcceptedWaitingAgency ? 'accepted' : status;

  return AmeexFadeSlideIn(
    child: AmeexPressable(
      onTap: () {
        Navigator.of(context).push(
          AmeexPageRoute(page: RouteHistoryScreen(order: order)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0E1116).withValues(alpha: 0.025),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
            BoxShadow(
              color: const Color(0xFF0E1116).withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row — avatar + name/meta + amount & status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AmeexColors.primaryBlue.withValues(alpha: 0.08),
                          AmeexColors.primaryBlue.withValues(alpha: 0.02),
                        ],
                      ),
                      border: Border.all(
                        color: AmeexColors.primaryBlue.withValues(alpha: 0.12),
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      customerName.isNotEmpty ? customerName[0].toUpperCase() : 'C',
                      style: const TextStyle(
                        color: AmeexColors.primaryBlue,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                            color: Color(0xFF0E1116),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              tracking,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                                color: AmeexColors.primaryBlue,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 3, height: 3,
                              decoration: const BoxDecoration(
                                color: AmeexColors.textFaint,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                city,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: AmeexColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      RichText(
                        textAlign: TextAlign.right,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$amount',
                              style: const TextStyle(
                                fontFamily: AmeexTheme.fontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.4,
                                color: Color(0xFF0E1116),
                              ),
                            ),
                            const TextSpan(
                              text: ' MAD',
                              style: TextStyle(
                                fontFamily: AmeexTheme.fontFamily,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: AmeexColors.textFaint,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 7),
                      _buildStatusBadge(effectiveStatus),
                    ],
                  ),
                ],
              ),

              // Address line (muted, icon-led) — only if meaningful
              if (address.toString().trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 14, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        address.toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.qr_code_2_rounded, size: 13, color: Color(0xFF9CA3AF)),
                        const SizedBox(width: 4),
                        Text(
                          parcelNumber,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],

              // Divider when we have extra sections
              if (order['assigned_driver_id'] != null ||
                  (order['dest_latitude'] != null && order['dest_longitude'] != null) ||
                  isAcceptedWaitingAgency ||
                  status == 'delivered' ||
                  (isCancelled && address.toString().contains('[MOTIF:')))
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, color: Color(0xFFF0F1F4)),
                ),

              // Driver line — single compact row, no pill
              if (order['assigned_driver_id'] != null)
                FutureBuilder<Map<String, dynamic>?>(
                  future: AdminDriverCache.getDriver(order['assigned_driver_id']),
                  builder: (context, snapshot) {
                    final driver = snapshot.data;
                    if (driver == null) return const SizedBox.shrink();
                    final dName = driver['full_name'] ?? 'Livreur';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: [
                          DriverAvatar(
                            driverData: driver,
                            radius: 11,
                            borderColor: Colors.transparent,
                            borderWidth: 0,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Livreur',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              dName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0E1116),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

              // Client location — subtle neutral row with "Voir" link
              if (order['dest_latitude'] != null && order['dest_longitude'] != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.gps_fixed_rounded, size: 14, color: Color(0xFF10B981)),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Position client synchronisée',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    Text(
                      'Voir la carte',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AmeexColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded,
                        size: 14, color: AmeexColors.primaryBlue),
                  ],
                ),
              ],

          // ACTION BOUTON POUR L'ADMIN : CONFIRMER LA REMISE DU COLIS À L'AGENCE
          if (isAcceptedWaitingAgency) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFD97706),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.handshake_rounded, size: 16, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Livreur prêt pour récupérer le colis à l\'agence',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Le livreur a accepté la commande. Dès que vous lui remettez le colis, validez ci-dessous pour qu\'il puisse démarrer sa course vers le client.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF78350F), height: 1.3),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.check_circle_rounded, size: 20),
                      label: const Text(
                        'Confirmer la remise du colis au livreur',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                      onPressed: () async {
                        try {
                          final cleanRaw = rawAddress.toString()
                              .replaceAll('[ETAT: ACCEPTE_ATTENTE_AGENCE]', '')
                              .replaceAll('  ', ' ')
                              .trim();
                          await supabase.from('orders').update({
                            'status': 'in_transit',
                            'delivery_address': '$cleanRaw [COLIS_REMIS_PAR_ADMIN]',
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

          // CAISSE ENCAISSEMENT ADMIN ACTION (COD REMITTANCE VALIDATION)
          if (status == 'delivered') ...[
            const SizedBox(height: 10),
            Builder(
              builder: (context) {
                final isRemitted = CaisseRemittanceHelper.isRemitted(order);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            isRemitted ? Icons.check_circle_outline_rounded : Icons.schedule_rounded,
                            size: 14,
                            color: isRemitted ? const Color(0xFF10B981) : const Color(0xFFD97706),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              isRemitted
                                  ? 'Caisse validée'
                                  : 'Caisse en attente · $amount MAD',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                      if (!isRemitted && order['assigned_driver_id'] != null)
                        InkWell(
                          onTap: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: const Text('Valider encaissement caisse ?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                content: Text('Confirmez-vous que le livreur vous a remis la somme de $amount MAD pour ce colis ?\n\nCette action débloquera automatiquement sa commission.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                                    onPressed: () => Navigator.of(ctx).pop(true),
                                    child: const Text('Confirmer la Réception', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );
                            if (ok == true) {
                              await CaisseRemittanceHelper.validateDriverRemittance(
                                supabase: supabase,
                                driverId: order['assigned_driver_id'],
                                orders: [order],
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✅ Caisse validée ! Commission du livreur débloquée.'),
                                    backgroundColor: Color(0xFF10B981),
                                  ),
                                );
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: AmeexColors.primaryBlue,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Valider',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ),
                        ),
                  ],
                );
              },
            ),
          ],

          // If cancelled, show motif alert banner (subtle)
          if (isCancelled && address.toString().contains('[MOTIF:')) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFDC2626)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    address.toString().substring(address.toString().indexOf('[MOTIF:')),
                    style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
    ),
    ),
  );
}

Widget _buildStatusBadge(String status) {
  Color dot;
  String label;

  switch (status) {
    case 'delivered':
      dot = const Color(0xFF10B981);
      label = 'Livré';
      break;
    case 'in_transit':
      dot = AmeexColors.primaryBlue;
      label = 'En transit';
      break;
    case 'accepted':
      dot = const Color(0xFFF59E0B);
      label = 'À l\'agence · Remise colis';
      break;
    case 'cancelled':
      dot = const Color(0xFFDC2626);
      label = 'Annulé';
      break;
    default:
      dot = const Color(0xFF9CA3AF);
      label = 'En attente';
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: dot.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6, height: 6,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: dot),
        ),
      ],
    ),
  );
}
