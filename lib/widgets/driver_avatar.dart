import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/ameex_theme.dart';

class DriverPreset {
  final String id;
  final String label;
  final String url;
  final String role;

  const DriverPreset({
    required this.id,
    required this.label,
    required this.url,
    required this.role,
  });
}

class DriverAvatarHelper {
  static const List<DriverPreset> defaultPresets = [
    DriverPreset(
      id: 'yassine',
      label: 'Yassine',
      role: 'Moto Express',
      url: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=256&q=80',
    ),
    DriverPreset(
      id: 'hamza',
      label: 'Hamza',
      role: 'Livreur Moto',
      url: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=256&q=80',
    ),
    DriverPreset(
      id: 'karim',
      label: 'Karim',
      role: 'Chauffeur Van',
      url: 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?auto=format&fit=crop&w=256&q=80',
    ),
    DriverPreset(
      id: 'mehdi',
      label: 'Mehdi',
      role: 'Coursier Rapide',
      url: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=256&q=80',
    ),
    DriverPreset(
      id: 'amine',
      label: 'Amine',
      role: 'Livreur Urbain',
      url: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&w=256&q=80',
    ),
    DriverPreset(
      id: 'omar',
      label: 'Omar',
      role: 'Scooter Maxi',
      url: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?auto=format&fit=crop&w=256&q=80',
    ),
    DriverPreset(
      id: 'rachid',
      label: 'Rachid',
      role: 'Fourgonnette',
      url: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=256&q=80',
    ),
    DriverPreset(
      id: 'sara',
      label: 'Sara',
      role: 'Livreuse Express',
      url: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?auto=format&fit=crop&w=256&q=80',
    ),
    DriverPreset(
      id: 'fatima',
      label: 'Fatima',
      role: 'Livreuse Ameex',
      url: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=256&q=80',
    ),
    DriverPreset(
      id: 'ayoub',
      label: 'Ayoub',
      role: 'Vélo Cargo',
      url: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=256&q=80',
    ),
  ];

  static String getAvatarUrl(dynamic data, {String? defaultName}) {
    if (data == null) {
      return _generateInitialsAvatar(defaultName ?? 'Livreur');
    }

    if (data is String) {
      if (data.startsWith('http://') || data.startsWith('https://') || data.startsWith('data:image')) {
        return data;
      }
      final tagMatch = RegExp(r'\[AVATAR:([^\]]+)\]').firstMatch(data);
      if (tagMatch != null) {
        return tagMatch.group(1)!;
      }
      return _generateInitialsAvatar(defaultName ?? data);
    }

    if (data is Map) {
      if (data['avatar_url'] != null && data['avatar_url'].toString().trim().isNotEmpty) {
        return data['avatar_url'].toString().trim();
      }

      final rawMeta = data['raw_user_meta_data'];
      if (rawMeta is Map && rawMeta['avatar_url'] != null) {
        final url = rawMeta['avatar_url'].toString().trim();
        if (url.isNotEmpty) return url;
      }

      final zone = data['zone']?.toString() ?? '';
      final zoneMatch = RegExp(r'\[AVATAR:([^\]]+)\]').firstMatch(zone);
      if (zoneMatch != null) {
        return zoneMatch.group(1)!;
      }

      final vehicle = data['vehicle_type']?.toString() ?? '';
      final vehicleMatch = RegExp(r'\[AVATAR:([^\]]+)\]').firstMatch(vehicle);
      if (vehicleMatch != null) {
        return vehicleMatch.group(1)!;
      }

      final name = data['full_name']?.toString() ?? defaultName ?? 'Livreur';
      return _generateInitialsAvatar(name);
    }

    return _generateInitialsAvatar(defaultName ?? 'Livreur');
  }

  static String cleanZone(String? zone) {
    if (zone == null) return 'Casablanca';
    return zone.replaceAll(RegExp(r'\s*\[AVATAR:[^\]]+\]'), '').trim();
  }

  static String cleanVehicle(String? vehicle) {
    if (vehicle == null) return 'Moto / Scooter';
    return vehicle.replaceAll(RegExp(r'\s*\[AVATAR:[^\]]+\]'), '').trim();
  }

  static String formatWithAvatar(String baseText, String avatarUrl) {
    final clean = baseText.replaceAll(RegExp(r'\s*\[AVATAR:[^\]]+\]'), '').trim();
    return '$clean [AVATAR:$avatarUrl]';
  }

  static String _generateInitialsAvatar(String name) {
    final encoded = Uri.encodeComponent(name.trim().isEmpty ? 'L' : name.trim());
    return 'https://ui-avatars.com/api/?name=$encoded&background=14307A&color=ffffff&bold=true&size=256';
  }
}

class DriverAvatar extends StatelessWidget {
  final dynamic driverData;
  final String? avatarUrl;
  final String? name;
  final double radius;
  final Color? borderColor;
  final double borderWidth;
  final bool showBadge;
  final Color? badgeColor;

  const DriverAvatar({
    super.key,
    this.driverData,
    this.avatarUrl,
    this.name,
    this.radius = 20,
    this.borderColor,
    this.borderWidth = 1.5,
    this.showBadge = false,
    this.badgeColor,
  });

  Widget _buildFallback(String effectiveName) {
    final initial = effectiveName.trim().isNotEmpty
        ? effectiveName.trim()[0].toUpperCase()
        : 'L';
    return Container(
      color: AmeexColors.primaryBlue,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.9,
        ),
      ),
    );
  }

  Widget _buildImageContent(String effectiveUrl, String effectiveName) {
    if (effectiveUrl.startsWith('data:image')) {
      try {
        final commaIdx = effectiveUrl.indexOf(',');
        final b64 = commaIdx != -1 ? effectiveUrl.substring(commaIdx + 1) : effectiveUrl;
        final bytes = base64Decode(b64);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: radius * 2,
          height: radius * 2,
          errorBuilder: (context, error, stackTrace) => _buildFallback(effectiveName),
        );
      } catch (_) {
        return _buildFallback(effectiveName);
      }
    }

    return Image.network(
      effectiveUrl,
      fit: BoxFit.cover,
      width: radius * 2,
      height: radius * 2,
      errorBuilder: (context, error, stackTrace) => _buildFallback(effectiveName),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: const Color(0xFFEFF5FF),
          child: Center(
            child: SizedBox(
              width: radius,
              height: radius,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                color: AmeexColors.primaryBlue,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveName = name ??
        (driverData is Map ? (driverData['full_name']?.toString() ?? 'L') : 'L');
    final effectiveUrl = avatarUrl ??
        DriverAvatarHelper.getAvatarUrl(driverData, defaultName: effectiveName);

    final avatarWidget = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor ?? AmeexColors.primaryBlue.withValues(alpha: 0.25),
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: _buildImageContent(effectiveUrl, effectiveName),
      ),
    );

    if (!showBadge) return avatarWidget;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatarWidget,
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: radius * 0.65,
            height: radius * 0.65,
            decoration: BoxDecoration(
              color: badgeColor ?? const Color(0xFF10B981),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
