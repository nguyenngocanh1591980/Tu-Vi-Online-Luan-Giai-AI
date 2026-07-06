import 'package:flutter/material.dart';
import '../models/chart_model.dart';
import 'palace_cell.dart';
import 'center_info.dart';

class TuViChart extends StatelessWidget {
  final ChartData data;
  final bool isFullMode;

  const TuViChart({Key? key, required this.data, this.isFullMode = true}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sắp xếp 12 cung theo đúng thứ tự (Tý, Sửu, Dần... Hợi) 0-11
    // Layout 4x4:
    // Row 1: Tỵ (5), Ngọ (6), Mùi (7), Thân (8)
    // Row 2: Thìn (4), Center (Thiên Bàn), Dậu (9)
    // Row 3: Mão (3), Center (Thiên Bàn), Tuất (10)
    // Row 4: Dần (2), Sửu (1), Tý (0), Hợi (11)
    
    // Giả định data.palaces đã được sắp xếp từ 0 đến 11 tương ứng Tý -> Hợi
    Palace getPalace(int index) {
      return data.palaces.firstWhere((p) => p.index == index, orElse: () => data.palaces[0]);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Cố gắng giữ tỷ lệ khổ A4 ngang hoặc vuông (tuỳ màn hình)
        // Trừ đi 4 pixel cho viền (2 border * 2 pixel) để không bị overflow
        final cellWidth = (constraints.maxWidth - 4) / 4;
        // Cố gắng giữ tỷ lệ khổ A4 dọc (297 / 210 = 1.414)
        final cellHeight = isFullMode ? cellWidth * (297 / 210) : cellWidth * 1.2;
        
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                children: [
                  // Row 1 (Top)
                  Row(
                    children: [
                      _buildCell(getPalace(5), cellWidth, cellHeight), // Tỵ
                      _buildCell(getPalace(6), cellWidth, cellHeight), // Ngọ
                      _buildCell(getPalace(7), cellWidth, cellHeight), // Mùi
                      _buildCell(getPalace(8), cellWidth, cellHeight), // Thân
                    ],
                  ),
                  // Row 2 & 3 (Middle)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column (Thìn, Mão)
                      Column(
                        children: [
                          _buildCell(getPalace(4), cellWidth, cellHeight), // Thìn
                          _buildCell(getPalace(3), cellWidth, cellHeight), // Mão
                        ],
                      ),
                      // Center Info (Thiên Bàn) - Kích thước bằng 2x2 cung
                      SizedBox(
                        width: cellWidth * 2,
                        height: cellHeight * 2,
                        child: CenterInfo(info: data.native, isFullMode: isFullMode, palaces: data.palaces),
                      ),
                      // Right Column (Dậu, Tuất)
                      Column(
                        children: [
                          _buildCell(getPalace(9), cellWidth, cellHeight), // Dậu
                          _buildCell(getPalace(10), cellWidth, cellHeight), // Tuất
                        ],
                      ),
                    ],
                  ),
                  // Row 4 (Bottom)
                  Row(
                    children: [
                      _buildCell(getPalace(2), cellWidth, cellHeight), // Dần
                      _buildCell(getPalace(1), cellWidth, cellHeight), // Sửu
                      _buildCell(getPalace(0), cellWidth, cellHeight), // Tý
                      _buildCell(getPalace(11), cellWidth, cellHeight), // Hợi
                    ],
                  ),
                ],
              ),
              
              // Global Tuần/Triệt boxes across boundaries
              if (getPalace(0).tuanTriet.isNotEmpty) _buildTuanTrietBox(getPalace(0).tuanTriet, cellWidth * 2, cellHeight * 3),
              if (getPalace(2).tuanTriet.isNotEmpty) _buildTuanTrietBox(getPalace(2).tuanTriet, cellWidth * 0.5, cellHeight * 3),
              if (getPalace(4).tuanTriet.isNotEmpty) _buildTuanTrietBox(getPalace(4).tuanTriet, cellWidth * 0.5, cellHeight * 1),
              if (getPalace(6).tuanTriet.isNotEmpty) _buildTuanTrietBox(getPalace(6).tuanTriet, cellWidth * 2, cellHeight * 1),
              if (getPalace(8).tuanTriet.isNotEmpty) _buildTuanTrietBox(getPalace(8).tuanTriet, cellWidth * 3.5, cellHeight * 1),
              if (getPalace(10).tuanTriet.isNotEmpty) _buildTuanTrietBox(getPalace(10).tuanTriet, cellWidth * 3.5, cellHeight * 3),
            ],
          ),
        );
      }
    );
  }

  Widget _buildCell(Palace palace, double width, double height) {
    return SizedBox(
      width: width,
      height: height,
      child: PalaceCell(palace: palace, isFullMode: isFullMode),
    );
  }

  Widget _buildTuanTrietBox(String text, double x, double y) {
    return Positioned(
      left: x,
      top: y,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: Container(
          color: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, fontFamily: 'Arial', color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
