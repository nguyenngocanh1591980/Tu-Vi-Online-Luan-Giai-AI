import 'package:flutter/material.dart';
import '../../services/admin_repository.dart';
import '../../theme/admin_colors.dart';

class AstrologyEditorScreen extends StatefulWidget {
  const AstrologyEditorScreen({super.key});

  @override
  State<AstrologyEditorScreen> createState() => _AstrologyEditorScreenState();
}

class _AstrologyEditorScreenState extends State<AstrologyEditorScreen> {
  final AdminRepository _repo = AdminRepository();

  String _selectedStar = 'Tử Vi';
  String _selectedPalace = 'Mệnh';
  String _selectedState = 'Miếu địa';

  // 14 Chính Tinh & các Phụ Tinh tiêu biểu
  final List<String> _stars = [
    'Tử Vi', 'Liêm Trinh', 'Thiên Đồng', 'Vũ Khúc', 'Thái Dương', 'Thiên Cơ',
    'Thiên Phủ', 'Thái Âm', 'Tham Lang', 'Cự Môn', 'Thiên Tướng', 'Thiên Lương',
    'Thất Sát', 'Phá Quân', 'Văn Xương', 'Văn Khúc', 'Tả Phù', 'Hữu Bật',
    'Thiên Khôi', 'Thiên Việt', 'Hóa Lộc', 'Hóa Quyền', 'Hóa Khoa', 'Hóa Kỵ'
  ];

  // 12 Cung
  final List<String> _palaces = [
    'Mệnh', 'Phụ Mẫu', 'Phúc Đức', 'Điền Trạch', 'Quan Lộc', 'Giao Hữu',
    'Thiên Di', 'Tật Ách', 'Tài Bạch', 'Tử Tức', 'Phu Thê', 'Huynh Đệ'
  ];

  // Trạng thái đắc hãm
  final List<String> _states = [
    'Miếu địa', 'Vượng địa', 'Đắc địa', 'Bình hòa', 'Hãm địa', 'Không rõ'
  ];

  final TextEditingController _contentController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Tự động tải dữ liệu mẫu khi mở màn hình
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final content = await _repo.fetchAstrologyInterpretation(_selectedStar, _selectedPalace, _selectedState);
    _contentController.text = content.isNotEmpty 
        ? content 
        : 'Chưa có dữ liệu luận giải cho $_selectedStar tại cung $_selectedPalace ($_selectedState). Bạn có thể soạn thảo và bấm "Lưu Cấu Hình Đồng Bộ AI".';
    setState(() => _isLoading = false);
  }

  Future<void> _saveData() async {
    setState(() => _isLoading = true);
    final success = await _repo.saveAstrologyInterpretation(
      _selectedStar,
      _selectedPalace,
      _selectedState,
      _contentController.text,
    );
    setState(() => _isLoading = false);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đồng bộ dữ liệu Lý số thành công vào Database'),
          backgroundColor: AdminColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lưu dữ liệu thất bại'),
          backgroundColor: AdminColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header & Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Quản lý Lời luận giải JSON',
                  style: TextStyle(color: AdminColors.realDataText, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AdminColors.realDataText, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      const Text(
                        'Dữ liệu THỰC TẾ từ Database / AI Engine (Chữ Trắng #FFFFFF)',
                        style: TextStyle(color: AdminColors.realDataText, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Khu vực Chọn Tọa độ
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AdminColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AdminColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Chọn tọa độ', style: TextStyle(color: AdminColors.realDataText, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 24),
                          _buildDropdown('Chính tinh/Phụ tinh', _stars, _selectedStar, (val) {
                            if (val != null) setState(() => _selectedStar = val);
                          }),
                          const SizedBox(height: 16),
                          _buildDropdown('Cung', _palaces, _selectedPalace, (val) {
                            if (val != null) setState(() => _selectedPalace = val);
                          }),
                          const SizedBox(height: 16),
                          _buildDropdown('Trạng thái', _states, _selectedState, (val) {
                            if (val != null) setState(() => _selectedState = val);
                          }),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _loadData,
                              icon: const Icon(Icons.download, color: Colors.white),
                              label: const Text('Tải Dữ Liệu', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AdminColors.cardBackground,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(color: AdminColors.border),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  
                  // Khu vực Soạn Thảo (Chữ Trắng Thực Tế)
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AdminColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AdminColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Nội dung luận giải: $_selectedStar @ $_selectedPalace ($_selectedState)',
                                style: const TextStyle(color: AdminColors.realDataText, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              if (_isLoading) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AdminColors.primary)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: TextField(
                              controller: _contentController,
                              maxLines: 15,
                              style: const TextStyle(color: AdminColors.realDataText, height: 1.6, fontSize: 15), // CHỮ TRẮNG THỰC TẾ
                              decoration: InputDecoration(
                                hintText: 'Nhập nội dung luận giải...',
                                hintStyle: const TextStyle(color: AdminColors.textMuted),
                                filled: true,
                                fillColor: AdminColors.cardBackground,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: AdminColors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: AdminColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: AdminColors.primary),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _saveData,
                              icon: const Icon(Icons.save, color: Colors.white),
                              label: const Text('Lưu Cấu Hình Đồng Bộ AI', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AdminColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value, void Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AdminColors.textMuted)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AdminColors.cardBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AdminColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AdminColors.cardBackground,
              icon: const Icon(Icons.arrow_drop_down, color: AdminColors.realDataText),
              style: const TextStyle(color: AdminColors.realDataText),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
