import re

def update_chart_model():
    path = 'e:/Tu vi online/frontend/lib/models/chart_model.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if 'final String thanCu;' not in content:
        content = content.replace('final String bodyLord; // Thân chủ', 'final String bodyLord; // Thân chủ\n  final String thanCu; // Thân cư')
        content = content.replace('required this.bodyLord,', 'required this.bodyLord,\n    required this.thanCu,')
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        print("Updated chart_model.dart")

def update_center_info():
    path = 'e:/Tu vi online/frontend/lib/widgets/center_info.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    content = content.replace("_buildRowText('', 'Thân cư Quan'", "_buildRowText('', info.thanCu")
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Updated center_info.dart")

def update_chart_screen():
    path = 'e:/Tu vi online/frontend/lib/screens/chart_screen.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Need to insert calculations before creating NativeInfo
    if 'int hourIndex =' not in content:
        calc_str = '''
    int hourIndex = ((widget.hour + 1) ~/ 2) % 12;
    int menhIndex = (2 + (lunarMonth - 1) - hourIndex + 12) % 12;
    int yearChiIndex = lunarYearVal % 12;

    List<String> destinyLords = ['Tham Lang', 'Cự Môn', 'Lộc Tồn', 'Văn Khúc', 'Liêm Trinh', 'Vũ Khúc', 'Phá Quân', 'Vũ Khúc', 'Liêm Trinh', 'Văn Khúc', 'Lộc Tồn', 'Cự Môn'];
    String calcDestinyLord = destinyLords[menhIndex];

    List<String> bodyLords = ['Hỏa Tinh', 'Thiên Tướng', 'Thiên Lương', 'Thiên Đồng', 'Văn Xương', 'Thiên Cơ', 'Hỏa Tinh', 'Thiên Tướng', 'Thiên Lương', 'Thiên Đồng', 'Văn Xương', 'Thiên Cơ'];
    String calcBodyLord = bodyLords[yearChiIndex];

    int distance = (2 * hourIndex) % 12;
    String calcThanCu = '';
    if (distance == 0) calcThanCu = 'Thân cư Mệnh';
    else if (distance == 2) calcThanCu = 'Thân cư Phúc Đức';
    else if (distance == 4) calcThanCu = 'Thân cư Quan Lộc';
    else if (distance == 6) calcThanCu = 'Thân cư Thiên Di';
    else if (distance == 8) calcThanCu = 'Thân cư Tài Bạch';
    else if (distance == 10) calcThanCu = 'Thân cư Phu Thê';

    final nativeInfo = NativeInfo('''
        content = content.replace('    final nativeInfo = NativeInfo(', calc_str)
        content = content.replace("destinyLord: 'Lộc Tồn',", "destinyLord: calcDestinyLord,")
        content = content.replace("bodyLord: 'Thiên Lương',", "bodyLord: calcBodyLord,\n      thanCu: calcThanCu,")
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        print("Updated chart_screen.dart")

update_chart_model()
update_center_info()
update_chart_screen()
