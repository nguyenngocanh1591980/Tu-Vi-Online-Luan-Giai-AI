import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../widgets/action_and_comment_widget.dart';
import '../widgets/tu_vi_chart.dart';
import '../utils/chart_generator.dart';
import 'package:provider/provider.dart';
import '../providers/horoscope_provider.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:file_saver/file_saver.dart';
import '../utils/web_save_helper.dart';
import '../models/saved_chart_model.dart';
import '../models/chart_model.dart';
import 'chart_screen.dart';
import 'create_post_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/pdf_generator.dart';

class HoroscopeInfoScreen extends StatefulWidget {
  @override
  _HoroscopeInfoScreenState createState() => _HoroscopeInfoScreenState();
}

class _HoroscopeInfoScreenState extends State<HoroscopeInfoScreen> {
  String _kieuSinh = 'Sinh Bình Thường';
  String _kieuAnSao = 'An Thông Thường';

  final _formKey = GlobalKey<FormState>();
  
  // Form controllers and state variables
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _currentAddressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _viewYearController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _gender = 'Nam';
  String _calendarType = 'Dương lịch';
  
  SavedChartModel? _quickViewData;
  bool _isSubmitting = false;
  int? _editingChartId;
  final GlobalKey _chartBoundaryKey = GlobalKey();

  String _userRole = 'User';

  @override
  void initState() {
    super.initState();
    _loadRole();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HoroscopeProvider>().fetchHoroscopes();
    });
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('role') ?? 'User';
    });
  }

  String? _selectedHour;
  String? _selectedMinute;
  String? _selectedDay;
  String? _selectedMonth;

  String? _selectedDateError;
  String? _selectedTimeError;
  String? _nameErrorText;

  // Autocomplete Geocoding State
  bool _isAddressSelected = false;
  Map<String, dynamic>? _selectedLocationData;
  Timer? _debounce;

  // Track if user has confirmed to hide inputs
  bool _hideName = false;
  bool _hideBirthday = false;
  bool _lunarGmt8 = false;

  int _validationFailCount = 0;

  String _viewPermission = 'Tất cả mọi người';
  String _discussPermission = 'Tất cả mọi người';

  bool _isConfirmed = false;
  String? _selectedCung;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _currentAddressController.dispose();
    _phoneController.dispose();
    _yearController.dispose();
    _viewYearController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool _isDownloadingImage = false;

  Future<void> _downloadChartImage() async {
    if (_isDownloadingImage) return;
    
    setState(() {
      _isDownloadingImage = true;
    });

    try {
      if (_chartBoundaryKey.currentContext == null) return;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đang chuẩn bị ảnh, vui lòng chọn nơi lưu...')),
        );
      }

      RenderRepaintBoundary boundary =
          _chartBoundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        Uint8List pngBytes = byteData.buffer.asUint8List();
        String fileName = 'La_So_${_quickViewData?.chartName ?? "Export"}';
        
        try {
          String? resultPath = await FileSaver.instance.saveAs(
            name: fileName,
            bytes: pngBytes,
            ext: 'png',
            mimeType: MimeType.png,
          );
          
          if (mounted && resultPath != null && resultPath.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tải ảnh thành công!')),
            );
          }
        } catch (saveError) {
          if (kIsWeb) {
            debugPrint('FileSaver saveAs failed on Web, using File System Access API fallback: $saveError');
            await saveFileAs('$fileName.png', pngBytes, 'image/png');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tải ảnh thành công!')),
              );
            }
          } else {
            rethrow;
          }
        }
      }
    } catch (e) {
      debugPrint('Lỗi tải ảnh: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Không thể tải ảnh. Vui lòng kiểm tra quyền trình duyệt!'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadingImage = false;
        });
      }
    }
  }

  void _deleteChart(int chartId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa lá số này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await context.read<HoroscopeProvider>().deleteHoroscope(chartId);
                setState(() {
                  _quickViewData = null;
                  _editingChartId = null;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa lá số')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: $e')),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Map<String, int> _extractDobPartsFromChart(SavedChartModel chart) {
    try {
      final oldChart = ChartData.fromJson(jsonDecode(chart.chartJsonData));
      final native = oldChart.native;
      final localDob = chart.dob.toLocal();
      final hour = localDob.hour;
      final minute = localDob.minute;
      final day = localDob.day;
      final month = localDob.month;
      final year = localDob.year;
      return {
        'hour': hour,
        'minute': minute,
        'day': day,
        'month': month,
        'year': year,
      };
    } catch (_) {
      final localDob = chart.dob.toLocal();
      return {
        'hour': localDob.hour,
        'minute': localDob.minute,
        'day': localDob.day,
        'month': localDob.month,
        'year': localDob.year,
      };
    }
  }

  void _editChart() {
    if (_quickViewData == null) return;
    try {
      final chartData = ChartData.fromJson(jsonDecode(_quickViewData!.chartJsonData));
      final native = chartData.native;
      final dobParts = _extractDobPartsFromChart(_quickViewData!);

      setState(() {
        _editingChartId = _quickViewData!.id;
        _nameController.text = _quickViewData!.chartName;
        _gender = _quickViewData!.gender;
        _yearController.text = dobParts['year']!.toString();
        _selectedMonth = dobParts['month']!.toString().padLeft(2, '0');
        _selectedDay = dobParts['day']!.toString().padLeft(2, '0');
        _selectedHour = dobParts['hour']!.toString().padLeft(2, '0');
        _selectedMinute = dobParts['minute']!.toString().padLeft(2, '0');

        _addressController.text = native.address;
        _currentAddressController.text = native.currentAddress;
        _phoneController.text = native.phone;
        _descriptionController.text = native.description;

        _kieuAnSao = native.kieuAnSao.isNotEmpty ? native.kieuAnSao : 'An Thông Thường';
        _kieuSinh = native.kieuSinh.isNotEmpty ? native.kieuSinh : 'Sinh Bình Thường';

        if (native.lat != null && native.lon != null) {
          _selectedLocationData = {
            'lat': native.lat.toString(),
            'lon': native.lon.toString(),
            'display_name': native.address,
          };
          _isAddressSelected = true;
        } else {
          _selectedLocationData = null;
          _isAddressSelected = false;
        }

        _quickViewData = null; // Clear view to show form
      });
    } catch (e) {
      debugPrint('Error editing chart: $e');
      final dobParts = _extractDobPartsFromChart(_quickViewData!);
      setState(() {
        _editingChartId = _quickViewData!.id;
        _nameController.text = _quickViewData!.chartName;
        _gender = _quickViewData!.gender;
        _yearController.text = dobParts['year']!.toString();
        _selectedMonth = dobParts['month']!.toString().padLeft(2, '0');
        _selectedDay = dobParts['day']!.toString().padLeft(2, '0');
        _selectedHour = dobParts['hour']!.toString().padLeft(2, '0');
        _selectedMinute = dobParts['minute']!.toString().padLeft(2, '0');
        _quickViewData = null;
      });
    }
  }

  Future<void> _handleAiAction(String actionType, [String? actionDetail]) async {
    if (!_isConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xin vui lòng bấm vào nút Xác Nhận trước')),
      );
      return;
    }

    final hour = int.tryParse(_selectedHour ?? '0') ?? 0;
    final minute = int.tryParse(_selectedMinute ?? '0') ?? 0;
    final day = int.tryParse(_selectedDay ?? '1') ?? 1;
    final month = int.tryParse(_selectedMonth ?? '1') ?? 1;
    final year = int.tryParse(_yearController.text) ?? DateTime.now().year;
    final viewYear = int.tryParse(_viewYearController.text) ?? DateTime.now().year;

    // Generate ChartData using ChartGenerator
    final chartData = await ChartGenerator.generateAsync(
      isFullMode: true, // Always full mode for AI to get maximum info
      name: _nameController.text,
      gender: _gender,
      calendarType: _calendarType,
      hour: hour,
      minute: minute,
      day: day,
      month: month,
      year: year,
      viewYear: viewYear,
      kieuAnSao: _kieuAnSao,
      kieuSinh: _kieuSinh,
      address: _addressController.text,
      currentAddress: _currentAddressController.text,
      phone: _phoneController.text,
      description: _descriptionController.text,
    );

    // Map actionType to proper C# API Endpoint
    String endpoint = 'http://localhost:5000/api/TuVi/btn1-luangiai-12cung';
    if (actionType == 'luan_giai_dai_han_12') {
      endpoint = 'http://localhost:5000/api/TuVi/btn2-luangiai-daihan';
    } else if (actionType == 'luan_giai_chi_tiet_dai_han') {
      endpoint = 'http://localhost:5000/api/TuVi/btn3-luangiai-chitiet-daihan';
    } else if (actionType == 'luan_giai_han_nam') {
      endpoint = 'http://localhost:5000/api/TuVi/btn4-luangiai-nam';
    } else if (actionType == 'giai_phap_nam') {
      endpoint = 'http://localhost:5000/api/TuVi/btn5-giaiphap-nam';
    }

    String interpretationText = 'Đang kết nối AI...';
    StateSetter? updateDialogState;

    // Show dialog immediately
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            updateDialogState = setState;
            return AlertDialog(
              title: const Text('Kết quả luận giải AI'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Text(interpretationText),
                ),
              ),
              actions: [
                if (interpretationText.length > 50 && !interpretationText.startsWith('Đang kết nối AI'))
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      String snippet = interpretationText.length > 150 
                          ? interpretationText.substring(0, 150) + '...' 
                          : interpretationText;
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CreatePostScreen(
                          chartData: chartData.toJson(),
                          initialContent: snippet,
                        ))
                      );
                    },
                    child: const Text('Chia sẻ lên Cộng Đồng'),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Đóng'),
                ),
              ],
            );
          },
        );
      },
    );

    try {
      final request = http.Request('POST', Uri.parse(endpoint));
      request.headers['Content-Type'] = 'application/json';
      request.body = json.encode({
        'laSoJson': chartData.toJson(),
        if (actionDetail != null) 'actionDetail': actionDetail,
      });

      final response = await http.Client().send(request);
      
      if (response.statusCode != 200) {
        if (updateDialogState != null) {
          updateDialogState!(() {
            interpretationText = 'Lỗi từ Server: ${response.statusCode}';
          });
        }
        return;
      }
      
      interpretationText = ''; // Clear initial message

      response.stream.transform(utf8.decoder).listen((data) {
        final lines = data.split('\n');
        for (var line in lines) {
          if (line.startsWith('data: ')) {
            final payload = line.substring(6).trim();
            if (payload == '[DONE]') continue;
            if (payload.isEmpty) continue;
            try {
              final parsed = json.decode(payload);
              if (parsed['text'] != null) {
                if (updateDialogState != null) {
                  updateDialogState!(() {
                    interpretationText += parsed['text'];
                  });
                }
              }
              if (parsed['error'] != null) {
                if (updateDialogState != null) {
                  updateDialogState!(() {
                    interpretationText += '\n[LỖI]: ' + parsed['error'];
                  });
                }
              }
            } catch (e) {
              // ignore parse errors for partial chunks
            }
          }
        }
      }, onError: (e) {
         if (updateDialogState != null) {
           updateDialogState!(() {
             interpretationText += '\n[Lỗi Stream: $e]';
           });
         }
      });
    } catch (e) {
       if (updateDialogState != null) {
          updateDialogState!(() {
            interpretationText = 'Lỗi kết nối: $e';
          });
       }
    }
  }



  InputDecoration _buildInputDecoration({String? hintText, String? errorText, int? errorMaxLines}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white12,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 13, color: Colors.white38),
      errorText: errorText,
      errorMaxLines: errorMaxLines,
      errorStyle: const TextStyle(color: Color(0xFFEF5350)),
      border: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFFFD700))),
    );
  }

  Widget _buildFormRow(String label, Widget content, {String? hint, Color labelColor = Colors.white}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: labelColor,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                content,
                if (hint != null) ...[
                  const SizedBox(height: 4),
                  Text(hint, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFFFD700)),
      ),
    );
  }

  Widget _buildPageBtn(String text, {bool isActive = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF8B0000) : const Color(0xFF131A30),
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.white70,
          fontSize: 12,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  void _showPrintFullScreen() {
    if (_quickViewData == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.grey.shade200,
          appBar: AppBar(
            backgroundColor: Colors.red.shade900,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Tử Vi AI - Chuyên Gia Luận Giải',
              style: TextStyle(color: Colors.white),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.print, color: Colors.white),
                onPressed: () async {
                  final data = ChartData.fromJson(jsonDecode(_quickViewData!.chartJsonData));
                  final isAdmin = _userRole == 'Admin' || _userRole == 'Expert';
                  await PdfGenerator.printChart(data, isAdmin: isAdmin);
                },
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16.0),
                child: TuViChart(
                  data: ChartData.fromJson(jsonDecode(_quickViewData!.chartJsonData)),
                  isFullMode: _userRole == 'Admin' || _userRole == 'Expert',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1024),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 0, bottom: 24.0),
              decoration: const BoxDecoration(
                color: Color(0xFF1E2640),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14000000),
                    spreadRadius: 1,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title Bar chuẩn Dark Navy mép-tới-mép 1024px
                    Container(
                      width: double.infinity,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                      decoration: const BoxDecoration(
                        color: Color(0xFF131A30),
                        border: Border(bottom: BorderSide(color: Colors.white24, width: 1)),
                      ),
                      child: const Text(
                        'Lá Số Tử Vi Online - AI',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFD700),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                    const Text(
                      'Tử vi - Xem tử vi - Lá số tử vi - Luận giải, tư vấn tử vi trực tuyến',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFFD700)),
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.star_border, color: Color(0xFFFFD700), size: 18),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Dịch vụ lấy lá số tử vi nhanh, hiệu quả, đẹp, chính xác và miễn phí. Tư vấn, luận giải tử vi bằng AI chuẩn xác. Đội ngũ Chuyên Gia Tử Vi có uy tín, xem tử vi trọn đời, vận hạn từng năm. Có thể quản lý danh sách lá số của mình và chia sẻ lá số thuận tiện.',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LEFT SIDEBAR
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.only(right: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Ứng dụng Lý số', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                              const SizedBox(height: 24),
                              InkWell(
                                onTap: () {
                                  context.go('/almanac');
                                },
                                child: const Text('Lịch vạn sự', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFEF5350))),
                              ),
                              const SizedBox(height: 16),
                              const Text('Lá số Tử vi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFEF5350))),
                              const SizedBox(height: 16),
                              InkWell(
                                onTap: () {
                                  context.go('/almanac');
                                },
                                child: const Text('Đối Lịch Âm Dương', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFEF5350))),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 32,
                                      child: TextField(
                                        style: const TextStyle(fontSize: 13, color: Colors.white),
                                        decoration: _buildInputDecoration(hintText: 'Tìm kiếm...'),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    height: 32,
                                    child: ElevatedButton(
                                      onPressed: (){},
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF8B0000),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        minimumSize: const Size(50, 32),
                                      ),
                                      child: const Text('Tìm', style: TextStyle(color: Colors.white)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Consumer<HoroscopeProvider>(
                                builder: (context, provider, child) {
                                  if (provider.isLoading) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
                                  if (provider.horoscopes.isEmpty) {
                                    return const Text('Chưa có lá số nào', style: TextStyle(color: Colors.white70));
                                  }
                                  return ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: provider.horoscopes.length > 5 ? 5 : provider.horoscopes.length,
                                    itemBuilder: (context, index) {
                                      final chart = provider.horoscopes[index];
                                      final dateStr = "${chart.createdAt.hour.toString().padLeft(2, '0')}:${chart.createdAt.minute.toString().padLeft(2, '0')} ${chart.createdAt.day.toString().padLeft(2, '0')}/${chart.createdAt.month.toString().padLeft(2, '0')}/${chart.createdAt.year}";
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            InkWell(
                                              onTap: () {
                                                setState(() {
                                                  _quickViewData = chart;
                                                });
                                              },
                                              child: Text(chart.chartName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFD700), decoration: TextDecoration.underline)),
                                            ),
                                            const SizedBox(height: 4),
                                            Wrap(
                                              spacing: 4.0,
                                              children: [
                                                InkWell(
                                                  onTap: () {
                                                    try {
                                                      final dobParts = _extractDobPartsFromChart(chart);
                                                      String kieuAnSao = 'An Thông Thường';
                                                      double? latVal;
                                                      double? lonVal;
                                                      try {
                                                        final cData = ChartData.fromJson(jsonDecode(chart.chartJsonData));
                                                        kieuAnSao = cData.native.kieuAnSao;
                                                        latVal = cData.native.lat;
                                                        lonVal = cData.native.lon;
                                                      } catch (_) {}
                                                      Navigator.push(context, MaterialPageRoute(
                                                        builder: (context) => ChartScreen(
                                                          initialIsFullMode: true,
                                                          name: chart.chartName,
                                                          gender: chart.gender,
                                                          calendarType: 'Dương lịch',
                                                          hour: dobParts['hour']!,
                                                          minute: dobParts['minute']!,
                                                          day: dobParts['day']!,
                                                          month: dobParts['month']!,
                                                          year: dobParts['year']!,
                                                          viewYear: DateTime.now().year,
                                                          kieuAnSao: kieuAnSao,
                                                          lat: latVal,
                                                          lon: lonVal,
                                                        )
                                                      ));
                                                    } catch(e) {
                                                      print(e);
                                                    }
                                                  },
                                                  child: Text('$dateStr [Tử vi]', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                                                ),
                                                InkWell(
                                                  onTap: () {
                                                    // Placeholder cho Bình Giải AI
                                                  },
                                                  child: const Text('[Bình Giải AI]', style: TextStyle(fontSize: 12, color: Color(0xFF64B5F6))),
                                                ),
                                                InkWell(
                                                  onTap: () {
                                                    // Placeholder cho Đặt Lịch Xem
                                                  },
                                                  child: const Text('[Đặt Lịch Xem]', style: TextStyle(fontSize: 12, color: Color(0xFF81C784))),
                                                ),
                                              ],
                                            ),
                                          ]
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _buildPageBtn('<-'),
                                  _buildPageBtn('1', isActive: true),
                                  _buildPageBtn('2'),
                                  _buildPageBtn('3'),
                                  const Text(' ... ', style: TextStyle(fontSize: 12, color: Colors.white70)),
                                  _buildPageBtn('7'),
                                  _buildPageBtn('->'),
                                ]
                              )
                            ]
                          )
                        ),
                        ),
                        
                        // RIGHT FORM
                        Expanded(
                          flex: 3,
                          child: _quickViewData != null 
                            ? SingleChildScrollView(
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Xem nhanh lá số: ${_quickViewData!.chartName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                                        IconButton(
                                          icon: const Icon(Icons.close, color: Color(0xFFEF5350)),
                                          onPressed: () => setState(() => _quickViewData = null),
                                        ),
                                      ]
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 16.0),
                                      child: RepaintBoundary(
                                        key: _chartBoundaryKey,
                                        child: Container(
                                          color: Colors.white, // Cần màu nền trắng khi xuất ảnh
                                          child: TuViChart(
                                            data: ChartData.fromJson(jsonDecode(_quickViewData!.chartJsonData)),
                                            isFullMode: _userRole == 'Admin' || _userRole == 'Expert',
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 16.0, bottom: 32.0),
                                      child: ActionAndCommentWidget(
                                        chartId: _quickViewData!.id,
                                        chartName: _quickViewData!.chartName,
                                        onNewChart: () {
                                          setState(() {
                                            _quickViewData = null;
                                            _editingChartId = null;
                                            _nameController.clear();
                                            _yearController.clear();
                                            _descriptionController.clear();
                                            _isConfirmed = false;
                                          });
                                        },
                                        onEditChart: _editChart,
                                        onDeleteChart: () => _deleteChart(_quickViewData!.id),
                                        onDownloadImage: _downloadChartImage,
                                        onPrintFullScreen: _showPrintFullScreen,
                                        isAdmin: _userRole == 'Admin' || _userRole == 'Expert',
                                        onViewFullChart: () {
                                          try {
                                            final dobParts = _extractDobPartsFromChart(_quickViewData!);
                                            String kieuAnSao = 'An Thông Thường';
                                            double? latVal;
                                            double? lonVal;
                                            ChartData? pData;
                                            try {
                                              pData = ChartData.fromJson(jsonDecode(_quickViewData!.chartJsonData));
                                              kieuAnSao = pData.native.kieuAnSao;
                                              latVal = pData.native.lat;
                                              lonVal = pData.native.lon;
                                            } catch (_) {}
                                            Navigator.push(context, MaterialPageRoute(
                                              builder: (context) => ChartScreen(
                                                initialIsFullMode: true,
                                                name: _quickViewData!.chartName,
                                                gender: _quickViewData!.gender,
                                                calendarType: 'Dương lịch',
                                                hour: dobParts['hour']!,
                                                minute: dobParts['minute']!,
                                                day: dobParts['day']!,
                                                month: dobParts['month']!,
                                                year: dobParts['year']!,
                                                viewYear: DateTime.now().year,
                                                kieuAnSao: kieuAnSao,
                                                lat: latVal,
                                                lon: lonVal,
                                                preloadedData: pData,
                                              )
                                            ));
                                          } catch(e) {
                                            print(e);
                                          }
                                        },
                                        onViewYearChange: (int year) async {
                                             final oldChart = ChartData.fromJson(jsonDecode(_quickViewData!.chartJsonData));
                                             final dobParts = _extractDobPartsFromChart(_quickViewData!);
                                             final hour = dobParts['hour']!;
                                             final minute = dobParts['minute']!;
                                             final day = dobParts['day']!;
                                             final month = dobParts['month']!;
                                             final dobYear = dobParts['year']!;
                                             final chartData = await ChartGenerator.generateAsync(
                                               isFullMode: _userRole == 'Admin' || _userRole == 'Expert',
                                               name: _quickViewData!.chartName,
                                               gender: _quickViewData!.gender,
                                               calendarType: 'Dương lịch',
                                               hour: hour,
                                               minute: minute,
                                               day: day,
                                               month: month,
                                               year: dobYear,
                                               viewYear: year,
                                               kieuAnSao: oldChart.native.kieuAnSao,
                                               kieuSinh: oldChart.native.kieuSinh,
                                               address: oldChart.native.address,
                                               currentAddress: oldChart.native.currentAddress,
                                               phone: oldChart.native.phone,
                                               description: oldChart.native.description,
                                             );
                                            setState(() {
                                              _quickViewData = SavedChartModel(
                                              id: _quickViewData!.id,
                                              userId: _quickViewData!.userId,
                                              chartName: _quickViewData!.chartName,
                                              dob: _quickViewData!.dob,
                                              gender: _quickViewData!.gender,
                                              hasAiReport: _quickViewData!.hasAiReport,
                                              createdAt: _quickViewData!.createdAt,
                                              chartJsonData: jsonEncode(chartData.toJson()),
                                            );
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Form(
                                key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Nhập thông tin đầy đủ rồi bấm vào nút xác nhận. Sau đó có thể chia sẻ thông tin hoặc dịch vụ luận giải. Nếu muốn bạn có thể đặt lịch để xem trực tiếp từ các chuyên gia Tử Vi.',
                                  style: TextStyle(fontSize: 13, color: Colors.white70),
                                ),
                                const SizedBox(height: 24),
                                
                                _buildFormRow(
                                  'Họ tên',
                                  SizedBox(
                                    width: 250,
                                    child: TextFormField(
                                      controller: _nameController,
                                      style: const TextStyle(fontSize: 13, color: Colors.white),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Vui lòng nhập họ tên để lưu và quản lý lá số.';
                                        }
                                        return null;
                                      },
                                      onChanged: (val) {
                                        if (_nameErrorText != null) {
                                          setState(() => _nameErrorText = null);
                                        }
                                      },
                                      decoration: _buildInputDecoration(errorText: _nameErrorText),
                                    ),
                                  ),
                                  hint: '(Có thể ẩn thông tin này)',
                                ),

                                _buildFormRow(
                                  'Địa Chỉ Nơi Sinh Ra',
                                  SizedBox(
                                    width: 250,
                                    child: Autocomplete<Map<String, dynamic>>(
                                      optionsBuilder: (TextEditingValue textEditingValue) async {
                                        if (textEditingValue.text.length < 2) {
                                          return const Iterable<Map<String, dynamic>>.empty();
                                        }
                                        
                                        // Handle debounce
                                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                                        
                                        Completer<Iterable<Map<String, dynamic>>> completer = Completer();
                                        
                                        _debounce = Timer(const Duration(milliseconds: 800), () async {
                                          try {
                                            final response = await http.get(
                                              Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(textEditingValue.text)}&format=json&addressdetails=1&limit=5'),
                                              headers: {'User-Agent': 'TuViOnlineApp/1.0'}
                                            );
                                            if (response.statusCode == 200) {
                                              final List<dynamic> data = jsonDecode(response.body);
                                              final results = data.map((e) => e as Map<String, dynamic>).toList();
                                              completer.complete(results);
                                            } else {
                                              completer.complete(const Iterable<Map<String, dynamic>>.empty());
                                            }
                                          } catch (e) {
                                            completer.complete(const Iterable<Map<String, dynamic>>.empty());
                                          }
                                        });
                                        
                                        return completer.future;
                                      },
                                      displayStringForOption: (Map<String, dynamic> option) => option['display_name'] ?? '',
                                      onSelected: (Map<String, dynamic> selection) {
                                        _isAddressSelected = true;
                                        _selectedLocationData = selection;
                                        _addressController.text = selection['display_name'] ?? '';
                                      },
                                      fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                                        if (_addressController.text.isNotEmpty && textEditingController.text.isEmpty) {
                                          textEditingController.text = _addressController.text;
                                        }
                                        textEditingController.addListener(() {
                                          _addressController.text = textEditingController.text;
                                        });
                                        return TextFormField(
                                          controller: textEditingController,
                                          focusNode: focusNode,
                                          style: const TextStyle(fontSize: 13, color: Colors.white),
                                          onChanged: (val) {
                                            _isAddressSelected = false;
                                            _addressController.text = val;
                                          },
                                          validator: (value) {
                                            if (value == null || value.trim().isEmpty) {
                                              return 'Vui lòng nhập địa chỉ nơi sinh ra.';
                                            }
                                            return null;
                                          },
                                          decoration: _buildInputDecoration(hintText: 'Nhập địa chỉ...'),
                                        );
                                      },
                                      optionsViewBuilder: (context, onSelected, options) {
                                        return Align(
                                          alignment: Alignment.topLeft,
                                          child: Material(
                                            elevation: 4.0,
                                            color: const Color(0xFF131A30),
                                            borderRadius: BorderRadius.circular(4),
                                            child: ConstrainedBox(
                                              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 250),
                                              child: ListView.builder(
                                                padding: EdgeInsets.zero,
                                                shrinkWrap: true,
                                                itemCount: options.length,
                                                itemBuilder: (BuildContext context, int index) {
                                                  final option = options.elementAt(index);
                                                  return InkWell(
                                                    onTap: () {
                                                      onSelected(option);
                                                    },
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(12.0),
                                                      child: Text(option['display_name'] ?? '', style: const TextStyle(fontSize: 13, color: Colors.white)),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  hint: '(Chỉ mình bạn biết)',
                                ),

                                _buildFormRow(
                                  'Địa Chỉ Hiện Tại',
                                  SizedBox(
                                    width: 250,
                                    child: TextFormField(
                                      controller: _currentAddressController,
                                      style: const TextStyle(fontSize: 13, color: Colors.white),
                                      decoration: _buildInputDecoration(),
                                    ),
                                  ),
                                  hint: '(Chỉ mình bạn biết)',
                                ),

                                _buildFormRow(
                                  'Điện thoại',
                                  SizedBox(
                                    width: 250,
                                    child: TextFormField(
                                      controller: _phoneController,
                                      style: const TextStyle(fontSize: 13, color: Colors.white),
                                      decoration: _buildInputDecoration(),
                                    ),
                                  ),
                                  hint: '(Chỉ mình bạn biết)',
                                ),

                                _buildFormRow(
                                  'Kiểu an sao',
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      const Text('An Thông Thường', style: TextStyle(fontSize: 13, color: Colors.white)),
                                      Radio<String>(value: 'An Thông Thường', activeColor: const Color(0xFFFFD700), groupValue: _kieuAnSao, onChanged: (val) => setState(() => _kieuAnSao = val!)),
                                      const SizedBox(width: 8),
                                      const Text('An Đặc Biệt', style: TextStyle(fontSize: 13, color: Colors.white)),
                                      Radio<String>(value: 'An Đặc Biệt', activeColor: const Color(0xFFFFD700), groupValue: _kieuAnSao, onChanged: (val) => setState(() => _kieuAnSao = val!)),
                                    ],
                                  ),
                                  labelColor: const Color(0xFFEF5350),
                                ),

                                _buildFormRow(
                                  'Giới tính',
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      const Text('Nam', style: TextStyle(fontSize: 13, color: Colors.white)),
                                      Radio<String>(value: 'Nam', activeColor: const Color(0xFFFFD700), groupValue: _gender, onChanged: (val) => setState(() => _gender = val!)),
                                      const SizedBox(width: 8),
                                      const Text('Nữ', style: TextStyle(fontSize: 13, color: Colors.white)),
                                      Radio<String>(value: 'Nữ', activeColor: const Color(0xFFFFD700), groupValue: _gender, onChanged: (val) => setState(() => _gender = val!)),
                                    ],
                                  ),
                                ),

                                _buildFormRow(
                                  'Kiểu Sinh',
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      const Text('Sinh Bình Thường', style: TextStyle(fontSize: 13, color: Colors.white)),
                                      Radio<String>(value: 'Sinh Bình Thường', activeColor: const Color(0xFFFFD700), groupValue: _kieuSinh, onChanged: (val) => setState(() => _kieuSinh = val!)),
                                      const SizedBox(width: 8),
                                      const Text('Sinh Đôi Long Phụng', style: TextStyle(fontSize: 13, color: Colors.white)),
                                      Radio<String>(value: 'Sinh Đôi Long Phụng', activeColor: const Color(0xFFFFD700), groupValue: _kieuSinh, onChanged: (val) => setState(() => _kieuSinh = val!)),
                                      const SizedBox(width: 8),
                                      const Text('Sinh Đôi Cùng Giới Ra Trước', style: TextStyle(fontSize: 13, color: Colors.white)),
                                      Radio<String>(value: 'Sinh Đôi Cùng Giới Ra Trước', activeColor: const Color(0xFFFFD700), groupValue: _kieuSinh, onChanged: (val) => setState(() => _kieuSinh = val!)),
                                      const SizedBox(width: 8),
                                      const Text('Sinh Đôi Cùng Giới Ra Sau', style: TextStyle(fontSize: 13, color: Colors.white)),
                                      Radio<String>(value: 'Sinh Đôi Cùng Giới Ra Sau', activeColor: const Color(0xFFFFD700), groupValue: _kieuSinh, onChanged: (val) => setState(() => _kieuSinh = val!)),
                                    ],
                                  ),
                                  labelColor: const Color(0xFF64B5F6),
                                ),

                                _buildFormRow(
                                  'Loại lịch',
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      const Text('Dương lịch:', style: TextStyle(fontSize: 13, color: Colors.white)),
                                      Radio<String>(value: 'Dương lịch', activeColor: const Color(0xFFFFD700), groupValue: _calendarType, onChanged: (val) => setState(() => _calendarType = val!)),
                                      const SizedBox(width: 8),
                                      const Text('Âm lịch:', style: TextStyle(fontSize: 13, color: Colors.white)),
                                      Radio<String>(value: 'Âm lịch', activeColor: const Color(0xFFFFD700), groupValue: _calendarType, onChanged: (val) => setState(() => _calendarType = val!)),
                                    ],
                                  ),
                                ),

                                _buildFormRow(
                                  'Ngày sinh',
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 4,
                                    runSpacing: 8,
                                    children: [
                                      const Text('Giờ', style: TextStyle(fontSize: 13, color: Colors.white)),
                                      SizedBox(
                                        width: 75,
                                        child: DropdownButtonFormField<String>(
                                          decoration: _buildInputDecoration(),
                                          dropdownColor: const Color(0xFF131A30),
                                          iconEnabledColor: Colors.white70,
                                          style: const TextStyle(fontSize: 13, color: Colors.white),
                                          value: _selectedHour,
                                          items: List.generate(24, (index) => index.toString().padLeft(2, '0')).map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13, color: Colors.white)))).toList(),
                                          onChanged: (val) => setState(() => _selectedHour = val),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text('Phút', style: TextStyle(fontSize: 13, color: Colors.white)),
                                      SizedBox(
                                        width: 75,
                                        child: DropdownButtonFormField<String>(
                                          decoration: _buildInputDecoration(),
                                          dropdownColor: const Color(0xFF131A30),
                                          iconEnabledColor: Colors.white70,
                                          style: const TextStyle(fontSize: 13, color: Colors.white),
                                          value: _selectedMinute,
                                          items: List.generate(60, (index) => index.toString().padLeft(2, '0')).map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13, color: Colors.white)))).toList(),
                                          onChanged: (val) => setState(() => _selectedMinute = val),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text('Ngày', style: TextStyle(fontSize: 13, color: Colors.white)),
                                      SizedBox(
                                        width: 75,
                                        child: DropdownButtonFormField<String>(
                                          decoration: _buildInputDecoration(),
                                          dropdownColor: const Color(0xFF131A30),
                                          iconEnabledColor: Colors.white70,
                                          style: const TextStyle(fontSize: 13, color: Colors.white),
                                          value: _selectedDay,
                                          items: List.generate(31, (index) => (index + 1).toString().padLeft(2, '0')).map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13, color: Colors.white)))).toList(),
                                          onChanged: (val) => setState(() => _selectedDay = val),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text('Tháng', style: TextStyle(fontSize: 13, color: Colors.white)),
                                      SizedBox(
                                        width: 75,
                                        child: DropdownButtonFormField<String>(
                                          decoration: _buildInputDecoration(),
                                          dropdownColor: const Color(0xFF131A30),
                                          iconEnabledColor: Colors.white70,
                                          style: const TextStyle(fontSize: 13, color: Colors.white),
                                          value: _selectedMonth,
                                          items: List.generate(12, (index) => (index + 1).toString().padLeft(2, '0')).map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13, color: Colors.white)))).toList(),
                                          onChanged: (val) => setState(() => _selectedMonth = val),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text('Năm', style: TextStyle(fontSize: 13, color: Colors.white)),
                                      SizedBox(
                                        width: 80,
                                        child: TextFormField(
                                          controller: _yearController,
                                          decoration: _buildInputDecoration(errorMaxLines: 5),
                                          style: const TextStyle(fontSize: 13, color: Colors.white),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Vui lòng nhập năm sinh là số nguyên dương hợp lệ.';
                                            }
                                            final year = int.tryParse(value);
                                            if (year == null || year <= 0) {
                                              return 'Vui lòng nhập năm sinh là số nguyên dương hợp lệ.';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                _buildFormRow(
                                  'Năm xem',
                                  SizedBox(
                                    width: 100,
                                    child: TextFormField(
                                      controller: _viewYearController,
                                      decoration: _buildInputDecoration(errorMaxLines: 5),
                                      style: const TextStyle(fontSize: 13, color: Colors.white),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Vui lòng nhập năm xem hợp lệ.';
                                        }
                                        final viewYear = int.tryParse(value);
                                        if (viewYear == null || viewYear <= 0) {
                                          return 'Vui lòng nhập năm xem hợp lệ.';
                                        }
                                        final birthYear = int.tryParse(_yearController.text);
                                        if (birthYear != null) {
                                          if (viewYear < birthYear) {
                                            return 'Năm xem không được nhỏ hơn năm sinh.';
                                          }
                                          if (viewYear - birthYear > 120) {
                                            return 'Tuổi xem không hợp lý (không được vượt quá 120 tuổi).';
                                          }
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  hint: '(Nhập năm xem dương lịch hoặc tuổi âm lịch)',
                                ),



                                _buildSectionTitle('Mô tả bản thân'),
                                const Text('Thông tin về hình dáng, tính tình, gia cảnh, một số vận hạn đã trải qua. Nêu câu hỏi cần giải đáp', style: TextStyle(fontSize: 13, color: Colors.white70)),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _descriptionController,
                                  maxLines: 5,
                                  decoration: _buildInputDecoration(),
                                  style: const TextStyle(fontSize: 13, color: Colors.white),
                                ),

                                _buildSectionTitle('Phân quyền xem'),
                                SizedBox(
                                  width: 200,
                                  child: DropdownButtonFormField<String>(
                                    decoration: _buildInputDecoration(),
                                    dropdownColor: const Color(0xFF131A30),
                                    iconEnabledColor: Colors.white70,
                                    style: const TextStyle(fontSize: 13, color: Colors.white),
                                    value: _viewPermission,
                                    items: ['Tất cả mọi người', 'Chỉ mình tôi'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13, color: Colors.white)))).toList(),
                                    onChanged: (val) => setState(() => _viewPermission = val!),
                                  ),
                                ),

                                _buildSectionTitle('Phân quyền luận'),
                                SizedBox(
                                  width: 200,
                                  child: DropdownButtonFormField<String>(
                                    decoration: _buildInputDecoration(),
                                    dropdownColor: const Color(0xFF131A30),
                                    iconEnabledColor: Colors.white70,
                                    style: const TextStyle(fontSize: 13, color: Colors.white),
                                    value: _discussPermission,
                                    items: ['Tất cả mọi người', 'Chỉ mình tôi'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13, color: Colors.white)))).toList(),
                                    onChanged: (val) => setState(() => _discussPermission = val!),
                                  ),
                                ),

                                const SizedBox(height: 32),
                                
                                // Bottom Buttons
                                Container(
                                  alignment: Alignment.center,
                                  child: Wrap(
                                    spacing: 16,
                                    runSpacing: 16,
                                    alignment: WrapAlignment.center,
                                    children: [
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B0000), foregroundColor: Colors.white),
                                        onPressed: _isSubmitting ? null : () async {
                                          if (!_formKey.currentState!.validate()) {
                                            _validationFailCount++;
                                            if (_validationFailCount >= 3) {
                                              Navigator.of(context).popUntil((route) => route.isFirst);
                                            }
                                            return;
                                          }
                                          _validationFailCount = 0;
                                          setState(() {
                                            _isSubmitting = true;
                                          });
                                            try {
                                              final hour = int.tryParse(_selectedHour ?? '0') ?? 0;
                                              final minute = int.tryParse(_selectedMinute ?? '0') ?? 0;
                                              final day = int.tryParse(_selectedDay ?? '1') ?? 1;
                                              final month = int.tryParse(_selectedMonth ?? '1') ?? 1;
                                              final year = int.tryParse(_yearController.text) ?? DateTime.now().year;
                                              final viewYear = int.tryParse(_viewYearController.text) ?? DateTime.now().year;

                                              if (!_isAddressSelected && _addressController.text.isNotEmpty) {
                                                try {
                                                  final response = await http.get(
                                                    Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(_addressController.text)}&format=json&limit=1'),
                                                    headers: {'User-Agent': 'TuViOnline/1.0'},
                                                  );
                                                  if (response.statusCode == 200) {
                                                    final List<dynamic> results = jsonDecode(response.body);
                                                    if (results.isNotEmpty) {
                                                      _selectedLocationData = results.first as Map<String, dynamic>;
                                                      _isAddressSelected = true;
                                                    }
                                                  }
                                                } catch (_) {}
                                              }

                                              if (_kieuAnSao == 'An Đặc Biệt') {
                                                if (_selectedLocationData == null || _selectedLocationData!['lat'] == null || _selectedLocationData!['lon'] == null) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('Không tìm thấy toạ độ cho địa chỉ này. Vui lòng chọn lại địa chỉ Nơi Sinh Ra từ danh sách gợi ý để sử dụng tính năng An Đặc Biệt!'),
                                                      backgroundColor: Colors.red,
                                                      duration: Duration(seconds: 4),
                                                    ),
                                                  );
                                                  return;
                                                }
                                              }

                                              final chartData = await ChartGenerator.generateAsync(
                                                isFullMode: true,
                                                name: _nameController.text,
                                                gender: _gender,
                                                calendarType: _calendarType,
                                                hour: hour,
                                                minute: minute,
                                                day: day,
                                                month: month,
                                                year: year,
                                                viewYear: viewYear,
                                                kieuAnSao: _kieuAnSao,
                                                kieuSinh: _kieuSinh,
                                                address: _addressController.text,
                                                currentAddress: _currentAddressController.text,
                                                phone: _phoneController.text,
                                                description: _descriptionController.text,
                                                lat: _selectedLocationData != null ? double.tryParse(_selectedLocationData!['lat']?.toString() ?? '') : null,
                                                lon: _selectedLocationData != null ? double.tryParse(_selectedLocationData!['lon']?.toString() ?? '') : null,
                                              );
                                              
                                              final dob = DateTime(year, month, day, hour, minute);

                                              bool saveSuccess = false;
                                              SavedChartModel? savedChart;
                                              try {
                                                if (_editingChartId != null) {
                                                  savedChart = await context.read<HoroscopeProvider>().updateHoroscope(
                                                    _editingChartId!,
                                                    _nameController.text,
                                                    _gender,
                                                    dob,
                                                    chartData
                                                  );
                                                } else {
                                                  savedChart = await context.read<HoroscopeProvider>().createHoroscope(
                                                    _nameController.text,
                                                    _gender,
                                                    dob,
                                                    chartData
                                                  );
                                                }
                                                saveSuccess = true;
                                              } catch (saveError) {
                                                final cleanSaveError = saveError.toString().replaceFirst('Exception: ', '');
                                                if (cleanSaveError.contains('đã tồn tại')) {
                                                  setState(() => _nameErrorText = cleanSaveError);
                                                  rethrow;
                                                } else {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('$cleanSaveError (Bạn vẫn có thể xem lá số)'),
                                                      backgroundColor: Colors.orange.shade800,
                                                      duration: const Duration(seconds: 4),
                                                    ),
                                                  );
                                                }
                                              }

                                              setState(() {
                                                _isConfirmed = true;
                                                _editingChartId = null; // Clean up after success
                                                if (saveSuccess && savedChart != null) {
                                                  _quickViewData = savedChart;
                                                }
                                              });
                                              if (saveSuccess) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Xác nhận thành công. Thông tin đã được lưu lại.')),
                                                );
                                              }
                                            } catch (e) {
                                              if (_nameErrorText == null) {
                                                final cleanError = e.toString().replaceFirst('Exception: ', '');
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text(cleanError), backgroundColor: Colors.red.shade900),
                                                );
                                              }
                                            } finally {
                                              if (mounted) {
                                                setState(() {
                                                  _isSubmitting = false;
                                                });
                                              }
                                            }
                                          },
                                        child: _isSubmitting 
                                            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                            : Text('Xác nhận'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
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
    ),
  ),
),
);
  }
}
