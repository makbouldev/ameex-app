import 'package:supabase_flutter/supabase_flutter.dart';

class DriverCaisseBalances {
  final double codToRemitToAgency;
  final double codRemittedToAgency;
  final double availableCommission;
  final double pendingCommission;
  final int deliveredCount;
  final int unremittedCount;
  final int compensatedCount;

  const DriverCaisseBalances({
    required this.codToRemitToAgency,
    required this.codRemittedToAgency,
    required this.availableCommission,
    required this.pendingCommission,
    required this.deliveredCount,
    required this.unremittedCount,
    required this.compensatedCount,
  });

  double get totalCommission => availableCommission + pendingCommission;
}

class CaisseRemittanceHelper {
  static const String remittedTag = '[CAISSE_REMITTED]';

  static bool isRemitted(Map<String, dynamic> order) {
    if (order['is_remitted'] == true) return true;
    final address = (order['delivery_address'] ?? '').toString();
    return address.contains(remittedTag);
  }

  static String markAddressRemitted(String currentAddress) {
    if (currentAddress.contains(remittedTag)) return currentAddress;
    return '$currentAddress $remittedTag';
  }

  static double getOrderCodAmount(Map<String, dynamic> order) {
    return (order['amount'] as num?)?.toDouble() ?? 0.0;
  }

  static double getDriverCommission(Map<String, dynamic> order) {
    return (order['driver_fee'] as num?)?.toDouble() ?? 25.0;
  }

  static DriverCaisseBalances calculateBalances(List<Map<String, dynamic>> orders) {
    double codToRemit = 0.0;
    double codRemitted = 0.0;
    double availableComm = 0.0;
    double pendingComm = 0.0;
    int delivered = 0;
    int unremitted = 0;
    int compensated = 0;

    for (final o in orders) {
      final status = o['status']?.toString();
      final address = (o['delivery_address'] ?? '').toString();
      final isCompensated = status == 'cancelled' && address.contains('[INDEMNISÉ >50%');

      if (status == 'delivered') {
        delivered++;
        final cod = getOrderCodAmount(o);
        final fee = getDriverCommission(o);
        final remitted = isRemitted(o);

        if (remitted) {
          codRemitted += cod;
          availableComm += fee;
        } else {
          codToRemit += cod;
          pendingComm += fee;
          unremitted++;
        }
      } else if (isCompensated) {
        compensated++;
        // Compensated deliveries are directly available because no customer COD was collected
        availableComm += getDriverCommission(o);
      }
    }

    return DriverCaisseBalances(
      codToRemitToAgency: codToRemit,
      codRemittedToAgency: codRemitted,
      availableCommission: availableComm,
      pendingCommission: pendingComm,
      deliveredCount: delivered,
      unremittedCount: unremitted,
      compensatedCount: compensated,
    );
  }

  /// Admin action: Validates that the driver remitted all pending cash to the agency
  static Future<int> validateDriverRemittance({
    required SupabaseClient supabase,
    required String driverId,
    required List<Map<String, dynamic>> orders,
  }) async {
    final toRemit = orders.where((o) =>
        o['assigned_driver_id'] == driverId &&
        o['status'] == 'delivered' &&
        !isRemitted(o)).toList();

    for (final order in toRemit) {
      final currentAddress = (order['delivery_address'] ?? '').toString();
      final updatedAddress = markAddressRemitted(currentAddress);

      try {
        await supabase.from('orders').update({
          'delivery_address': updatedAddress,
          'is_remitted': true,
        }).eq('id', order['id']);
      } catch (_) {
        await supabase.from('orders').update({
          'delivery_address': updatedAddress,
        }).eq('id', order['id']);
      }
    }

    return toRemit.length;
  }
}
