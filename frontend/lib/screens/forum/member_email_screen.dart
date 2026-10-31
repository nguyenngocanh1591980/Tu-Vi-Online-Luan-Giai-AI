import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/boxed_snack_bar.dart';

/// Màn hình Gửi Email cho Thành viên (Hình 5)
/// Thiết kế Boxed Layout chuẩn mực nền tím đen Color(0xFF1E2640),
/// trường nhập liệu đồng nhất 100% với phong cách Soạn tin nhắn (Hình 7).
class MemberEmailScreen extends StatefulWidget {
  final String targetUsername;

  const MemberEmailScreen({
    super.key,
    required this.targetUsername,
  });

  @override
  State<MemberEmailScreen> createState() => _MemberEmailScreenState();
}

class _MemberEmailScreenState extends State<MemberEmailScreen> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _sendCopy = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _handleSendEmail() {
    final subject = _subjectController.text.trim();
    final content = _contentController.text.trim();

    if (subject.isEmpty) {
      showErrorSnackBar(context, 'Vui lòng nhập tiêu đề email');
      return;
    }

    if (content.isEmpty) {
      showErrorSnackBar(context, 'Vui lòng nhập nội dung email');
      return;
    }

    setState(() => _isSubmitting = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      showSuccessSnackBar(context, 'Đã gửi email thành công tới ${widget.targetUsername}!');
      _subjectController.clear();
      _contentController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFormContainer(context),
          const SizedBox(height: 24),
          _buildForumFooter(context),
        ],
      ),
    );
  }

  Widget _buildFormContainer(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2640),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2E3B5F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tiêu đề Khối: Gửi email cho
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF131A30),
              borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
              border: Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
            ),
            child: const Text(
              'Gửi email cho',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ),

          // Nội dung Form nhập liệu chuẩn Hình 7
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Dòng Người nhận: ${user.username}
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    if (isMobile) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Người nhận:',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.targetUsername,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFEF5350),
                            ),
                          ),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 140,
                          child: Text(
                            'Người nhận:',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        Text(
                          widget.targetUsername,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFEF5350),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFF2E3B5F), height: 1),
                const SizedBox(height: 16),

                // 2. Dòng Tiêu đề:
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    if (isMobile) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tiêu đề:',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildTextField(_subjectController),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 140,
                          child: Text(
                            'Tiêu đề:',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        Expanded(child: _buildTextField(_subjectController)),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFF2E3B5F), height: 1),
                const SizedBox(height: 16),

                // 3. Dòng Phần nội dung:
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    final infoWidget = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Phần nội dung:',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Email này sẽ được gửi dưới dạng văn bản thuần túy, vì thế bạn đừng sử dụng bất cứ thẻ lệnh HTML hay BBCode nào trong nội dung email này. Địa chỉ hồi âm của email này sẽ được thiết lập là địa chỉ email của bạn.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.white60,
                            height: 1.45,
                          ),
                        ),
                      ],
                    );

                    if (isMobile) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          infoWidget,
                          const SizedBox(height: 12),
                          _buildTextField(_contentController, minLines: 8, maxLines: 12),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 180, child: infoWidget),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(_contentController, minLines: 8, maxLines: 12),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFF2E3B5F), height: 1),
                const SizedBox(height: 16),

                // 4. Checkbox Gửi bản sao của email này cho chính bạn
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _sendCopy,
                        activeColor: const Color(0xFFEF5350),
                        checkColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF2E3B5F), width: 1.5),
                        onChanged: (val) {
                          setState(() {
                            _sendCopy = val ?? false;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _sendCopy = !_sendCopy;
                        });
                      },
                      child: const Text(
                        'Gửi bản sao của email này cho chính bạn.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 5. Nút Gửi email căn giữa theo phong cách Hình 7
                Center(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSendEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E3B5F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      side: const BorderSide(color: Color(0xFF3F51B5)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Gửi email',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, {
    int minLines = 1,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF131A30),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF2E3B5F)),
          borderRadius: BorderRadius.circular(4),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF2E3B5F)),
          borderRadius: BorderRadius.circular(4),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF3F51B5)),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildForumFooter(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0xFF2E3B5F)),
              bottom: BorderSide(color: Color(0xFF2E3B5F)),
            ),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              // Trái: Breadcrumb mini
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.home, color: Color(0xFFEF5350), size: 16),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => context.go('/'),
                    child: const Text('Trang chủ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF5350))),
                  ),
                  const SizedBox(width: 6),
                  const Text('<', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => context.go('/forum'),
                    child: const Text('Diễn đàn', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF5350))),
                  ),
                ],
              ),
              // Phải: Các liên kết chức năng
              Wrap(
                spacing: 12,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildFooterLink(Icons.email, 'Liên hệ'),
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

  Widget _buildFooterLink(IconData icon, String text) {
    return InkWell(
      onTap: () {},
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFEF5350)),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }
}
