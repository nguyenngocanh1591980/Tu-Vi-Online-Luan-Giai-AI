import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/boxed_snack_bar.dart';

class ShareHelper {
  static Future<void> share(
    BuildContext context, {
    String? url,
    String? title,
  }) async {
    final shareUrl = url ?? (kIsWeb ? Uri.base.toString() : 'https://lyso.vn/forum.html');
    final shareTitle = title ?? 'Diễn đàn Tử Vi Online - AI';

    bool nativeHandled = false;
    try {
      final result = await Share.shareUri(Uri.parse(shareUrl));
      if (result.status == ShareResultStatus.success) {
        nativeHandled = true;
      }
    } catch (_) {
      nativeHandled = false;
    }

    if (!nativeHandled && context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => ShareDialog(url: shareUrl, title: shareTitle),
      );
    }
  }
}

class ShareDialog extends StatefulWidget {
  final String url;
  final String title;

  const ShareDialog({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<ShareDialog> {
  bool _copied = false;

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.url));
    if (mounted) {
      setState(() => _copied = true);
      showBoxedSnackBar(context, 'Đã sao chép liên kết vào bộ nhớ tạm');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _copied = false);
      });
    }
  }

  Future<void> _launchSocial(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, 'Không thể mở liên kết chia sẻ: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final encodedUrl = Uri.encodeComponent(widget.url);
    final encodedTitle = Uri.encodeComponent(widget.title);

    return Dialog(
      backgroundColor: const Color(0xFF1E2640),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFF2E3B5F), width: 1),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Chia sẻ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Color(0xFF2E3B5F), height: 1),
              const SizedBox(height: 16),

              // Link Copy Box (Hình 2 style)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF131A30),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF2E3B5F)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link, color: Colors.white70, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'lyso.vn',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            widget.url,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _copyToClipboard,
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _copied ? const Color(0xFF2E7D32) : const Color(0xFF1E2640),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF3B4874)),
                        ),
                        child: Icon(
                          _copied ? Icons.check : Icons.copy,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Social Sharing Grid
              Wrap(
                alignment: WrapAlignment.spaceAround,
                spacing: 12,
                runSpacing: 16,
                children: [
                  _buildSocialItem(
                    icon: Icons.facebook,
                    label: 'Facebook',
                    color: const Color(0xFF1877F2),
                    onTap: () => _launchSocial('https://www.facebook.com/sharer/sharer.php?u=$encodedUrl'),
                  ),
                  _buildSocialItem(
                    icon: Icons.chat_bubble_outline,
                    label: 'Twitter',
                    color: const Color(0xFF1DA1F2),
                    onTap: () => _launchSocial('https://twitter.com/intent/tweet?url=$encodedUrl&text=$encodedTitle'),
                  ),
                  _buildSocialItem(
                    icon: Icons.phone_android,
                    label: 'WhatsApp',
                    color: const Color(0xFF25D366),
                    onTap: () => _launchSocial('https://api.whatsapp.com/send?text=$encodedTitle%20$encodedUrl'),
                  ),
                  _buildSocialItem(
                    icon: Icons.mail_outline,
                    label: 'Gmail',
                    color: const Color(0xFFEA4335),
                    onTap: () => _launchSocial('https://mail.google.com/mail/?view=cm&fs=1&tf=1&su=$encodedTitle&body=$encodedUrl'),
                  ),
                  _buildSocialItem(
                    icon: Icons.business,
                    label: 'LinkedIn',
                    color: const Color(0xFF0A66C2),
                    onTap: () => _launchSocial('https://www.linkedin.com/sharing/share-offsite/?url=$encodedUrl'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.5)),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
