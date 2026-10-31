import 'package:flutter/material.dart';

/// Widget hiển thị Huy hiệu Thành viên & Đẳng vị chuẩn xác theo Hình 6 & Hình 8
class UserRankBadgeWidget extends StatelessWidget {
  final dynamic userId;
  final String rankTitle;
  final int starLevel;
  final String? badgeType;
  final String? ribbonAsset;
  final double width;
  final double height;

  const UserRankBadgeWidget({
    super.key,
    this.userId,
    required this.rankTitle,
    this.starLevel = 1,
    this.badgeType,
    this.ribbonAsset,
    this.width = 118,
    this.height = 42,
  });

  bool get _isDangVi {
    final lower = rankTitle.toLowerCase();
    return lower.contains('đẳng') ||
        lower.contains('nhất đẳng') ||
        lower.contains('nhị đẳng') ||
        lower.contains('tam đẳng') ||
        lower.contains('tứ đẳng') ||
        lower.contains('ngũ đẳng') ||
        lower.contains('lục đẳng') ||
        lower.contains('thất đẳng') ||
        lower.contains('bát đẳng') ||
        lower.contains('cửu đẳng');
  }

  bool get _isBqt {
    if (ribbonAsset != null && ribbonAsset!.isNotEmpty) return true;
    final lower = rankTitle.toLowerCase();
    return lower.contains('sáng lập') ||
        lower.contains('quản lý') ||
        lower.contains('hội viên') ||
        lower.contains('điều hành') ||
        lower.contains('tư vấn') ||
        lower.contains('superadmin') ||
        lower.contains('super admin') ||
        lower.contains('admin');
  }

  String _getBqtBadgePath() {
    if (ribbonAsset != null && ribbonAsset!.isNotEmpty) {
      final lower = ribbonAsset!.toLowerCase();
      if (lower.contains('superadmin') || lower.contains('super_admin')) return 'assets/images/badge_super_admin.png';
      if (lower.contains('admin')) return 'assets/images/badge_admin.png';
      if (lower.contains('sang_lap') || lower.contains('sáng lập')) return 'assets/images/badge_sang_lap.png';
      if (lower.contains('quan_ly') || lower.contains('quản lý')) return 'assets/images/badge_quan_ly.png';
      if (lower.contains('hoi_vien') || lower.contains('hội viên')) return 'assets/images/badge_hoi_vien.png';
      if (lower.contains('dieu_hanh') || lower.contains('điều hành')) return 'assets/images/badge_dieu_hanh.png';
      if (lower.contains('tu_van') || lower.contains('tư vấn')) return 'assets/images/badge_tu_van.png';
      final fileName = ribbonAsset!.split('/').last;
      return 'assets/images/$fileName';
    }
    final lower = rankTitle.toLowerCase();
    if (lower.contains('superadmin') || lower.contains('super admin')) return 'assets/images/badge_super_admin.png';
    if (lower.contains('admin')) return 'assets/images/badge_admin.png';
    if (lower.contains('sáng lập')) return 'assets/images/badge_sang_lap.png';
    if (lower.contains('quản lý')) return 'assets/images/badge_quan_ly.png';
    if (lower.contains('hội viên')) return 'assets/images/badge_hoi_vien.png';
    if (lower.contains('điều hành')) return 'assets/images/badge_dieu_hanh.png';
    if (lower.contains('tư vấn')) return 'assets/images/badge_tu_van.png';
    return 'assets/images/badge_quan_ly.png';
  }

  @override
  Widget build(BuildContext context) {
    // 1. Huy hiệu Ban Quản Trị (Sáng Lập, Quản Lý, Hội Viên, Điều Hành, Tư Vấn, Admin, SuperAdmin)
    if (_isBqt && !rankTitle.toLowerCase().contains('thành viên') && !_isDangVi) {
      final assetPath = _getBqtBadgePath();
      final fileName = assetPath.split('/').last;
      return Image.asset(
        assetPath,
        key: ValueKey('badge_bqt_${userId}_${rankTitle}_v4'),
        width: width,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Image.network(
            'http://localhost:5000/images/$fileName',
            key: ValueKey('net_badge_bqt_${userId}_${rankTitle}_v4'),
            width: width,
            height: height,
            fit: BoxFit.contain,
            errorBuilder: (c, e, s) => const SizedBox.shrink(),
          );
        },
      );
    }

    // 2. Huy hiệu Đẳng vị Đại Sư (Chuẩn Hình 8: Nhất Đẳng -> Cửu Đẳng, sao đỏ)
    if (_isDangVi) {
      final safeStars = starLevel.clamp(1, 9);
      final assetPath = 'assets/images/badge_dai_su_$safeStars.png';
      final fileName = 'badge_dai_su_$safeStars.png';

      return Image.asset(
        assetPath,
        key: ValueKey('badge_master_v3_${userId}_$safeStars'),
        width: width,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Image.network(
            'http://localhost:5000/images/$fileName',
            key: ValueKey('net_badge_master_v3_${userId}_$safeStars'),
            width: width,
            height: height,
            fit: BoxFit.contain,
            errorBuilder: (c, e, s) => const SizedBox.shrink(),
          );
        },
      );
    }

    // 3. Huy hiệu Cấp bậc Thành viên (Chuẩn Hình 6: 1 -> 9 sao tím)
    final safeStars = starLevel.clamp(1, 9);
    final assetPath = 'assets/images/badge_thanh_vien_$safeStars.png';
    final fileName = 'badge_thanh_vien_$safeStars.png';

    return Image.asset(
      assetPath,
      key: ValueKey('v2_badge_tv_${userId}_${safeStars}_$rankTitle'),
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Image.network(
          'http://localhost:5000/images/$fileName',
          key: ValueKey('v2_net_badge_tv_${userId}_${safeStars}_$rankTitle'),
          width: width,
          height: height,
          fit: BoxFit.contain,
          errorBuilder: (c, e, s) => _buildMemberVector(safeStars),
        );
      },
    );
  }

  /// Huy hiệu Thành viên fallback an toàn
  Widget _buildMemberVector(int safeStars) => const SizedBox();
}

/// Widget hiển thị Logo Danh hiệu Đại Sư chuẩn xác theo Hình 9
/// Khung dọc viền đỏ, vòng tròn Bát Quái Âm Dương "TỬ VI ONLINE AI", phía dưới gắn thẻ Đẳng vị 1 - 9 sao đỏ
class MasterTitleLogoWidget extends StatelessWidget {
  final dynamic userId;
  final int starLevel;
  final String rankTitle;
  final double width;
  final double height;

  const MasterTitleLogoWidget({
    super.key,
    this.userId,
    required this.starLevel,
    required this.rankTitle,
    this.width = 44,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final safeStar = starLevel.clamp(1, 9);
    final assetPath = 'assets/images/logo_dai_su_$safeStar.png';
    final fileName = 'logo_dai_su_$safeStar.png';

    return Image.asset(
      assetPath,
      key: ValueKey('logo_master_${userId}_${safeStar}_v3'),
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Image.network(
          'http://localhost:5000/images/$fileName',
          key: ValueKey('net_logo_master_${userId}_${safeStar}_v3'),
          width: width,
          height: height,
          fit: BoxFit.contain,
          errorBuilder: (c, e, s) => const SizedBox.shrink(),
        );
      },
    );
  }
}


/// Widget hiển thị Logo Danh hiệu Thành viên chuẩn xác theo Hình 7
/// Khung dọc viền đỏ, vòng tròn Bát Quái Âm Dương "TỬ VI ONLINE AI", phía dưới gắn thẻ "Thành viên" 1 - 9 sao tím
class MemberTitleLogoWidget extends StatelessWidget {
  final dynamic userId;
  final int starLevel;
  final String rankTitle;
  final double width;
  final double height;

  const MemberTitleLogoWidget({
    super.key,
    this.userId,
    required this.starLevel,
    this.rankTitle = 'Thành viên',
    this.width = 44,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final safeStar = starLevel.clamp(1, 9);
    final assetPath = 'assets/images/logo_thanh_vien_$safeStar.png';
    final fileName = 'logo_thanh_vien_$safeStar.png';

    return Image.asset(
      assetPath,
      key: ValueKey('logo_v2_${userId}_$safeStar'),
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Image.network(
          'http://localhost:5000/images/$fileName',
          key: ValueKey('logo_v2_net_${userId}_$safeStar'),
          width: width,
          height: height,
          fit: BoxFit.contain,
          errorBuilder: (c, e, s) => const SizedBox.shrink(),
        );
      },
    );
  }
}

/// Widget hiển thị Logo Danh hiệu Ban Quản Trị (Sáng Lập, Quản Lý, Hội Viên, Điều Hành, Tư Vấn, Admin, SuperAdmin)
class BqtTitleLogoWidget extends StatelessWidget {
  final dynamic userId;
  final String role;
  final double width;
  final double height;

  const BqtTitleLogoWidget({
    super.key,
    this.userId,
    required this.role,
    this.width = 44,
    this.height = 52,
  });

  String _getLogoPath() {
    final lower = role.toLowerCase();
    if (lower.contains('superadmin') || lower.contains('super admin') || lower.contains('super_admin')) return 'assets/images/logo_super_admin.png';
    if (lower.contains('admin') || lower.contains('quản trị')) return 'assets/images/logo_admin.png';
    if (lower.contains('sáng lập')) return 'assets/images/logo_sang_lap.png';
    if (lower.contains('quản lý')) return 'assets/images/logo_quan_ly.png';
    if (lower.contains('hội viên')) return 'assets/images/logo_hoi_vien.png';
    if (lower.contains('điều hành') || lower.contains('moderator')) return 'assets/images/logo_dieu_hanh.png';
    if (lower.contains('tư vấn')) return 'assets/images/logo_tu_van.png';
    return 'assets/images/logo_quan_ly.png';
  }

  @override
  Widget build(BuildContext context) {
    final assetPath = _getLogoPath();
    final fileName = assetPath.split('/').last;

    return Image.asset(
      assetPath,
      key: ValueKey('logo_bqt_${userId}_${role}_v5'),
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Image.network(
          'http://localhost:5000/images/$fileName',
          key: ValueKey('net_logo_bqt_${userId}_${role}_v5'),
          width: width,
          height: height,
          fit: BoxFit.contain,
          errorBuilder: (c, e, s) => const SizedBox.shrink(),
        );
      },
    );
  }
}

