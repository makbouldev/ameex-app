import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/ameex_theme.dart';

class ParcelHelper {
  static String getParcelNumber(Map<String, dynamic> order) {
    if (order['parcel_number'] != null &&
        order['parcel_number'].toString().trim().isNotEmpty) {
      return order['parcel_number'].toString().trim();
    }

    final address = order['delivery_address']?.toString() ?? '';
    final match = RegExp(r'\[COLIS:\s*([^\]]+)\]').firstMatch(address);
    if (match != null) return match.group(1)!.trim();

    final tracking = order['tracking_number']?.toString() ?? '';
    final trackingMatch = RegExp(r'\[COLIS:\s*([^\]]+)\]').firstMatch(tracking);
    if (trackingMatch != null) return trackingMatch.group(1)!.trim();

    // Default parcel format based on tracking number
    final cleanTrack = tracking.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    return 'CLS-${cleanTrack.isNotEmpty ? cleanTrack : "AMX9021"}';
  }

  static String cleanAddress(String? address) {
    if (address == null) return '';
    return address
        .replaceAll(RegExp(r'\[COLIS:[^\]]+\]'), '')
        .replaceAll(RegExp(r'\[ETAT:[^\]]+\]'), '')
        .replaceAll(RegExp(r'\[COLIS_REMIS_PAR_ADMIN\]'), '')
        .replaceAll(RegExp(r'\[INDEMNISÉ[^\]]+\]'), '')
        .replaceAll(RegExp(r'\[MOTIF[^\]]+\]'), '')
        .replaceAll(RegExp(r'\[Type:[^\]]+\]'), '')
        .trim();
  }

  static String formatWithParcel(String originalAddress, String parcelNumber) {
    final clean = cleanAddress(originalAddress);
    return '$clean [COLIS: $parcelNumber]';
  }
}

/// A realistic Barcode & QR Code visual display widget for Shipping Labels
class ParcelBarcodeWidget extends StatelessWidget {
  final String parcelNumber;
  final double height;
  final bool isDark;

  const ParcelBarcodeWidget({
    super.key,
    required this.parcelNumber,
    this.height = 48,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    final seed = parcelNumber.hashCode.abs();
    final random = Random(seed);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.transparent : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barcode Vertical Bars Simulation
          SizedBox(
            height: height * 0.55,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(28, (index) {
                final isThick = random.nextBool();
                final isGap = index % 5 == 0;
                if (isGap) return const SizedBox(width: 2.5);
                return Container(
                  width: isThick ? 3.0 : 1.5,
                  margin: const EdgeInsets.symmetric(horizontal: 1.0),
                  color: isDark ? Colors.white70 : Colors.black87,
                );
              }),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            parcelNumber,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFF93C5FD) : AmeexColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }
}

/// Fullscreen / Modal Scanner with Laser Animation & Auto-Detection
class ParcelScannerDialog extends StatefulWidget {
  const ParcelScannerDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const ParcelScannerDialog(),
    );
  }

  @override
  State<ParcelScannerDialog> createState() => _ParcelScannerDialogState();
}

class _ParcelScannerDialogState extends State<ParcelScannerDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  final TextEditingController _manualInputController = TextEditingController();
  bool _isSuccess = false;
  String _scannedCode = '';

  final List<String> _sampleBarcodes = [
    'AMX-COL-89241-CAS',
    'CLS-MAARIF-0928-MA',
    'AMEEX-PKG-55104',
    'COL-RBT-77291',
    'AMX-EXP-30192-TNG',
  ];

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _laserController.dispose();
    _manualInputController.dispose();
    super.dispose();
  }

  void _triggerSuccess(String code) {
    setState(() {
      _isSuccess = true;
      _scannedCode = code;
    });

    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) {
        Navigator.of(context).pop(code);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 25, offset: Offset(0, 10)),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 14, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF60A5FA), size: 22),
                        SizedBox(width: 10),
                        Text(
                          'Scanner de Colis Ameex',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: Color(0xFF334155)),

              // Scanner Viewfinder Area
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      _isSuccess
                          ? '✅ Code-barres scanné avec succès !'
                          : 'Pointez la caméra ou scannez l\'étiquette du colis',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _isSuccess ? const Color(0xFF86EFAC) : Colors.white70,
                        fontSize: 13,
                        fontWeight: _isSuccess ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Viewfinder Box
                    Container(
                      width: 260,
                      height: 160,
                      decoration: BoxDecoration(
                        color: const Color(0xFF020617),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isSuccess ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(
                          children: [
                            // Sample Barcode in Background
                            Center(
                              child: Opacity(
                                opacity: 0.35,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.qr_code_2_rounded, size: 70, color: Colors.white),
                                    const SizedBox(height: 4),
                                    Text(
                                      _isSuccess ? _scannedCode : 'AMEEX-LOGISTICS-BARCODE',
                                      style: const TextStyle(color: Colors.white, fontSize: 10, letterSpacing: 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Corner Viewfinder Brackets
                            ..._buildViewfinderCorners(),

                            // Oscillating Laser Beam
                            if (!_isSuccess)
                              AnimatedBuilder(
                                animation: _laserAnimation,
                                builder: (context, _) {
                                  return Positioned(
                                    top: _laserAnimation.value * 140 + 8,
                                    left: 12,
                                    right: 12,
                                    child: Container(
                                      height: 3,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFEF4444).withValues(alpha: 0.8),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                            // Success Overlay
                            if (_isSuccess)
                              Container(
                                color: const Color(0xFF10B981).withValues(alpha: 0.25),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 48),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.black87,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          _scannedCode,
                                          style: const TextStyle(
                                            color: Color(0xFF86EFAC),
                                            fontFamily: 'monospace',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Quick Instant Scan Presets
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Simuler un scan instantané :',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _sampleBarcodes.map((barcode) {
                        return InkWell(
                          onTap: () => _triggerSuccess(barcode),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF334155)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.barcode_reader, size: 14, color: Color(0xFF60A5FA)),
                                const SizedBox(width: 6),
                                Text(
                                  barcode,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // Manual Input Option
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF334155)),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: TextField(
                              controller: _manualInputController,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: const InputDecoration(
                                hintText: 'Ou saisir manuellement...',
                                hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AmeexColors.primaryBlue,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            final code = _manualInputController.text.trim();
                            if (code.isNotEmpty) {
                              _triggerSuccess(code);
                            }
                          },
                          child: const Text('Valider', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildViewfinderCorners() {
    const size = 18.0;
    const thickness = 3.0;
    const color = Color(0xFF38BDF8);

    return [
      // Top-left
      Positioned(
        top: 8,
        left: 8,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: thickness),
              left: BorderSide(color: color, width: thickness),
            ),
          ),
        ),
      ),
      // Top-right
      Positioned(
        top: 8,
        right: 8,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: thickness),
              right: BorderSide(color: color, width: thickness),
            ),
          ),
        ),
      ),
      // Bottom-left
      Positioned(
        bottom: 8,
        left: 8,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: thickness),
              left: BorderSide(color: color, width: thickness),
            ),
          ),
        ),
      ),
      // Bottom-right
      Positioned(
        bottom: 8,
        right: 8,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: thickness),
              right: BorderSide(color: color, width: thickness),
            ),
          ),
        ),
      ),
    ];
  }
}
