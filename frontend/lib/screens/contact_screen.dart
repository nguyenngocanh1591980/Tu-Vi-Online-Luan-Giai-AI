import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _sendCopy = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _submitContactForm() {
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();

    if (subject.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tiêu đề email.'),
          backgroundColor: Color(0xFFC62828),
        ),
      );
      return;
    }

    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập nội dung email.'),
          backgroundColor: Color(0xFFC62828),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _subjectController.clear();
      _messageController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF009688),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Email của bạn đã được gửi thành công tới Ban quản trị diễn đàn!',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Tiêu đề khối
              _buildPageHeader(),
              const SizedBox(height: 16),

              // 2. Khối thông tin liên hệ (Trụ sở, Tổng đài, Zalo, FB, Email)
              _buildContactInfoBox(),
              const SizedBox(height: 16),

              // 3. Khung Form Nhập Liệu
              _buildContactFormBox(),
              const SizedBox(height: 24),

              // 4. Khối Khám phá thêm
              _buildExploreMore(),
              const SizedBox(height: 24),

              // 5. Footer Diễn Đàn
              _buildForumFooter(),
            ],
          ),
        ),
    );
  }

  // --- 1. Tiêu Đề Màn Hình ---
  Widget _buildPageHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF131A30),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2A3450), width: 1),
      ),
      child: const Row(
        children: [
          Icon(Icons.contact_mail_outlined, color: Color(0xFFFFD700), size: 22),
          SizedBox(width: 10),
          Text(
            'Liên lạc với ban quản trị.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFD700),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. Khối Thông Tin Liên Hệ ---
  Widget _buildContactInfoBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF161F36),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2E3B5F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            icon: Icons.language,
            iconColor: const Color(0xFF64B5F6),
            label: 'Trụ sở: ',
            value: 'Tử vi Online - AI',
            isBold: true,
            extraText: ' - Địa chỉ: ',
            extraValue: '2417 Hemisco - Hà Đông - Hà Nội',
            isExtraBold: false,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.smartphone,
            iconColor: const Color(0xFFEF5350),
            label: 'Điện thoại liên hệ: ',
            value: '0867.186.288',
            isBold: true,
            extraText: ' hoặc ',
            extraValue: '0988.927.838',
            isExtraBold: true,
            onTap: () => _launchUrl('tel:0867186288'),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.smartphone,
            iconColor: const Color(0xFFEF5350),
            label: 'Điện thoại khiếu nại: ',
            value: '0867.186.288',
            isBold: true,
            extraText: ' hoặc ',
            extraValue: '0988.927.838',
            isExtraBold: true,
            onTap: () => _launchUrl('tel:0867186288'),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.email_outlined,
            iconColor: const Color(0xFF80D8FF),
            label: 'Email tư vấn: ',
            value: 'bantuvan.tuvionlineai@gmail.com',
            valueColor: const Color(0xFF80D8FF),
            onTap: () => _launchUrl('mailto:bantuvan.tuvionlineai@gmail.com'),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.chat_bubble_outline,
            iconColor: const Color(0xFF29B6F6),
            label: 'Zalo: ',
            value: 'zalo.me/tuvionlineai',
            valueColor: const Color(0xFF29B6F6),
            onTap: () => _launchUrl('https://zalo.me/tuvionlineai'),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.thumb_up_alt_outlined,
            iconColor: const Color(0xFF42A5F5),
            label: 'Facebook: ',
            value: 'facebook.com/tuvionlineai',
            valueColor: const Color(0xFF42A5F5),
            onTap: () => _launchUrl('https://facebook.com/tuvionlineai'),
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24, height: 1, thickness: 1),
          const SizedBox(height: 12),
          const Text(
            'Nếu bạn có các yêu cầu khác, vui lòng để lại lời nhắn cho Ban quản trị diễn đàn ở dưới đây:',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
    String? extraText,
    String? extraValue,
    Color? extraValueColor,
    bool isExtraBold = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.4),
                children: [
                  TextSpan(text: label),
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      color: valueColor ?? Colors.white,
                      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                      decoration: onTap != null ? TextDecoration.underline : null,
                      decorationColor: valueColor,
                    ),
                  ),
                  if (extraText != null)
                    TextSpan(
                      text: extraText,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  if (extraValue != null)
                    TextSpan(
                      text: extraValue,
                      style: TextStyle(
                        color: extraValueColor ?? Colors.white,
                        fontWeight: isExtraBold ? FontWeight.bold : FontWeight.normal,
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

  // --- 3. Khung Form Nhập Liệu ---
  Widget _buildContactFormBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF161F36),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2E3B5F)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth >= 650;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hàng 1: Người nhận
              if (isWide)
                Row(
                  children: [
                    const SizedBox(
                      width: 140,
                      child: Text(
                        'Người nhận:',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    const Text(
                      'Quản trị viên',
                      style: TextStyle(color: Colors.white, fontSize: 13.5),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Người nhận:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Quản trị viên',
                      style: TextStyle(color: Colors.white, fontSize: 13.5),
                    ),
                  ],
                ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: Colors.white24, height: 1, thickness: 1),
              ),

              // Hàng 2: Tiêu đề
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 140,
                      child: Text(
                        'Tiêu đề:',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    Expanded(child: _buildTextField(_subjectController, maxLines: 1)),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tiêu đề:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildTextField(_subjectController, maxLines: 1),
                  ],
                ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: Colors.white24, height: 1, thickness: 1),
              ),

              // Hàng 3: Phần nội dung
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 180,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Phần nội dung:',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Email này sẽ được gửi dưới dạng văn bản thuần túy, vì thế bạn đừng sử dụng bất cứ thẻ lệnh HTML hay BBCode nào trong nội dung email này. Địa chỉ hồi âm của email này sẽ được thiết lập là địa chỉ email của bạn.',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11.5,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField(_messageController, maxLines: 9)),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Phần nội dung:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Email này sẽ được gửi dưới dạng văn bản thuần túy, vì thế bạn đừng sử dụng bất cứ thẻ lệnh HTML hay BBCode nào trong nội dung email này. Địa chỉ hồi âm của email này sẽ được thiết lập là địa chỉ email của bạn.',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11.5,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(_messageController, maxLines: 7),
                  ],
                ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: Colors.white24, height: 1, thickness: 1),
              ),

              // Hàng 4: Checkbox Gửi bản sao
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _sendCopy,
                      onChanged: (v) => setState(() => _sendCopy = v ?? false),
                      activeColor: const Color(0xFF009688),
                      side: const BorderSide(color: Colors.white54),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _sendCopy = !_sendCopy),
                    child: const Text(
                      'Gửi bản sao của email này cho chính bạn.',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Hàng 5: Nút Gửi email
              Center(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitContactForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF263252),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: const BorderSide(color: Color(0xFF3E4E77)),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Gửi email',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 13.5),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white12,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFFD4AF37)),
        ),
      ),
    );
  }

  // --- 4. Khối Khám Phá Thêm ---
  Widget _buildExploreMore() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131A30),
        border: Border.all(color: const Color(0xFF2E3B5F)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF131A30),
              borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
              border: Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
            ),
            width: double.infinity,
            child: const Text(
              'Khám phá thêm',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFFFFD700),
              ),
            ),
          ),
          _buildExploreItem('Lịch sử'),
          _buildExploreItem('Nhà cung cấp dịch vụ diễn đàn và trò chuyện'),
          _buildExploreItem('Từ điển & Bách khoa toàn thư', isLast: true),
        ],
      ),
    );
  }

  Widget _buildExploreItem(String title, {bool isLast = false}) {
    return InkWell(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(bottom: BorderSide(color: Colors.white12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54, size: 18),
          ],
        ),
      ),
    );
  }

  // --- 5. Footer Diễn Đàn ---
  Widget _buildForumFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF161F36),
            border: Border.all(color: const Color(0xFF2E3B5F)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 10,
            children: [
              // Trái: Breadcrumb mini
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.home, color: Color(0xFFEF5350), size: 16),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => context.go('/'),
                    child: const Text(
                      'Trang chủ',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF5350)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('<', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => context.go('/forum'),
                    child: const Text(
                      'Diễn đàn',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF5350)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('<', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  const SizedBox(width: 6),
                  const Text('Liên hệ', style: TextStyle(color: Colors.white70)),
                ],
              ),
              // Phải: Các liên kết chức năng
              Wrap(
                spacing: 12,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildFooterLink(Icons.email, 'Liên hệ', onTap: () => context.go('/contact')),
                  _buildFooterLink(Icons.share, 'Chia sẻ'),
                  _buildFooterLink(Icons.security, 'Chúng tôi'),
                  _buildFooterLink(Icons.group, 'Thành viên'),
                  _buildFooterLink(Icons.delete, 'Xóa hết cookie'),
                  const Text('Múi giờ UTC+07:00', style: TextStyle(fontSize: 12, color: Colors.white54)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Powered by phpBB® Forum Software © phpBB Limited',
          style: TextStyle(fontSize: 12, color: Colors.white38),
        ),
        const SizedBox(height: 6),
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 12, color: Color(0xFFEF5350)),
            children: [
              TextSpan(text: 'Chính sách bảo mật'),
              TextSpan(text: ' | ', style: TextStyle(color: Colors.white38)),
              TextSpan(text: 'Điều khoản tham gia'),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFooterLink(IconData icon, String text, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () {},
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFEF5350)),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12.5, color: Color(0xFFEF5350))),
        ],
      ),
    );
  }
}
