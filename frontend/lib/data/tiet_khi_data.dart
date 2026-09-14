/// File: frontend/lib/data/tiet_khi_data.dart
/// CSDL Diễn giải 24 Tiết Khí chuẩn hóa 100% nguyên văn từ tài liệu gốc:
/// E:\Tu vi online\AI học tử vi\Thư Viện cho AI Học\Tầng 1- Dữ Liệu Chuẩn Hóa\Cách tính và ý nghĩa 24 tiết khí trong 1 năm(đã chỉnh lý).docx

const List<String> kSolarTermsOrder = [
  'Lập Xuân', 'Vũ Thủy', 'Kinh Trập', 'Xuân Phân', 'Thanh Minh', 'Cốc Vũ',
  'Lập Hạ', 'Tiểu Mãn', 'Mang Chủng', 'Hạ Chí', 'Tiểu Thử', 'Đại Thử',
  'Lập Thu', 'Xử Thử', 'Bạch Lộ', 'Thu Phân', 'Hàn Lộ', 'Sương Giáng',
  'Lập Đông', 'Tiểu Tuyết', 'Đại Tuyết', 'Đông Chí', 'Tiểu Hàn', 'Đại Hàn'
];

const Map<String, String> kTietKhiMeanings = {
  "Lập Xuân": "Với tiết khí này, mặt trời sẽ ở vị trí 315 độ. Tiết lập xuân sẽ bắt đầu vào ngày 4, 5 tháng 2 hàng năm. Đây là một tiết khí báo hiệu một năm mới cùng với một mùa màng mới. Tất cả mọi sự vật, hiện tượng, vũ trụ sẽ bắt đầu bước vào một chu kỳ mới.\nNgày Lập xuân rơi vào tầm ngày 4 tháng 2 dương lịch hoặc 5 tháng 2 dương lịch. Mặt trời ở mức 315 độ.",
  "Vũ Thủy": "Tiết khí liên quan tới mưa, nước nên thời gian này chính là mùa mưa nhiều và ẩm ướt trong năm. Khoảng tiết Vũ Thủy thì trời quang mây tạnh. Gió xuân xuất hiện mang theo nhiều hơi ẩm dẫn tới mưa, lụt, ngập nước, độ ẩm trong không khí luôn cao. Tượng trưng cho sự sinh sôi, nảy mầm của sự vật.\nNgày Vũ Thủy có thể rơi vào ngày 18 tháng 2 dương lịch hoặc ngày 19 tháng 2 dương lịch hoặc 20 tháng 2 dương lịch hàng năm. Mặt trời ở mức 330 độ.",
  "Kinh Trập": "Tiết khí này tượng trưng cho sự sinh sôi, nảy nở của các loài côn trùng. Khi mà cây lá thay nhau đâm chồi, nảy mầm thì cũng là lúc những loài côn trùng xuất hiện.\nBài học về màn trập: Tên gọi cực kỳ lạ mang ý nghĩa là con sâu thức dậy. Lúc này, không khí thời tiết đã thuận lợi, mùa xuân đến bắt đầu sự sống mới, cây cối đâm chồi nảy lộc và sâu bọ sinh sôi, phát triển.\nNgày Kinh Trập (Màn Trập) rơi vào tầm ngày 5 tháng 3 dương lịch hoặc ngày 6 tháng 3 dương lịch hoặc ngày 7 tháng 3 dương lịch hàng năm. Mặt trời ở mức 345 độ.",
  "Xuân Phân": "Thời điểm rất có ý nghĩa trong nông nghiệp,có nghĩa là giữa mùa xuân. Sau ngày này, vị trí của Mặt Trời chuyển dần về phía Bắc bán cầu. Đây được xem như là một thời điểm mà nửa bán cầu Bắc của Trái Đất sẽ nhận được lượng nhiệt nhiều nhất từ mặt trời. Vào thời điểm này, nhiệt độ của bán cầu Bắc chỉ ấm áp chứ không quá nóng bức.Ngày cảm thấy dài hơn, đêm ngắn lại. Thời tiết chuyển dần nắng ấm, không còn cái rét của mùa đông nữa.\nNgày Xuân Phân có thể rơi vào ngày 20 tháng 3 dương lịch hoặc ngày 21 tháng 3 dương lịch hoặc ngày 22 tháng 3 dương lịch hàng năm. Mặt trời ở 0 độ.",
  "Thanh Minh": "Thanh minh còn được biết đến như là sự quang đãng, thoáng mát. Vậy nên, khi vào thời điểm này, nửa bán cầu bắc sẽ không còn mây mù hay các cơn mưa nhỏ. Lúc này, các loài động vật như rắn, ếch cũng sẽ bắt đầu xuất hiện.\nLễ hội viếng mộ: Nghĩa là trời quang mây tạnh, thời tiết đẹp để mọi người đi cúng Thanh minh. Khí hậu lý tưởng, ấm áp, mát mẻ, mọi sự sống đều đang rất tươi mới, cây cối đâm chồi nảy lộc.\nNgày Thanh Minh (Tết Thanh minh) có thể rơi vào ngày 4 tháng 4 dương lịch hoặc ngày 5 tháng 4 dương lịch hàng năm. Mặt trời ở mức 15 độ.",
  "Cốc Vũ": "Cốc Vũ là giai đoạn của những trận mưa như trút nước. Lúc này khí hậu có thay đổi, biểu hiện của tiết trời sắp chuyển hè. Những trận mựa lớn làm vạn vật sinh sôi, cây cối tươi tốt, đất đai màu mỡ, tươi xốp. Những trận mưa rào lúc này vô cùng tốt cho sự sinh sôi, nảy nở của các loại hoa màu, ngũ cốc.\nNgày Cốc Vũ có thể rơi vào ngày 20 tháng 4 dương lịch hoặc ngày 21 tháng 4 dương lịch hàng năm. Mặt trời ở mức 30 độ.",
  "Lập Hạ": "Lập Hạ là đầu mùa hè, bắt đầu mùa hè với nhiệt độ tăng nhanh. Lúc này, mặt trời lên cao vậy nên nhiệt độ và ánh sáng từ mặt trời sẽ rất cao. Trời nắng nóng gay gắt, nhiều nơi bắt đầu xuất hiện mưa bão, sấm chớp do sự thay đổi nhiệt độ. Cây cối vào mùa này cũng lớn nhanh và phát triển tốt.\nNgày Lập Hạ có thể rơi vào ngày 5 tháng 5 dương lịch hoặc ngày 6 tháng 5 dương lịch hoặc ngày 7 tháng 5 dương lịch hàng năm. Mặt trời ở góc 45 độ.",
  "Tiểu Mãn": "Mang ý nghĩa khác hoàn toàn với cái tên, Tiểu mãn được dịch theo tiếng Hán nghĩa là lũ nhỏ, nhóm nhỏ. Ở thời điểm này, đó chính là những nhóm nhỏ của mưa mùa hạ và những trận lũ, lụt ngập nhỏ.\nNgày Tiểu Mãn có thể rơi vào ngày 21 tháng 5 dương lịch hoặc ngày 22 tháng 5 dương lịch Mặt trời ở góc 60 độ.",
  "Mang Chủng": "Thời điểm hoa màu được mùa, nông nghiệp phát triển tốt, lúa, ngũ cốc tràn đầy sức sống. Thời tiết thì nắng nóng, thỉnh thoảng ẩm ương có mưa bất chợt. Lúc này thì mọi người có thể thấy những đường vân đang lên của các ngôi sao.Trên trời sẽ xuất hiện chòm sao tua rua. Đây cũng là dấu hiệu cho thấy người nông dân nên tranh thủ canh tác, thu hoạch để không bị trễ.\nNgày Mang chủng có thể rơi vào ngày 5 tháng 6 dương lịch hoặc 6 tháng 6 dương lịch hàng năm. Mặt trời ở 75 độ.",
  "Hạ Chí": "Nắng hạ chí, nắng giữa mùa hè. Vào thời gian này, ánh sáng và nhiệt độ của mặt trời sẽ rất cao và vô cùng khó chịu. Thời tiết nắng nóng ẩm kéo dài, ngày dài, đêm rất ngắn. Vì vậy mới có câu: “Đêm tháng năm chưa nằm đã sáng, ngày tháng mười chưa cười đã tối”\nNgày Hạ Chí có thể rơi vào ngày 21 tháng 6 dương lịch hoặc ngày 22 tháng 6 dương lịch hàng năm. Mặt trời ở góc 90 độ.",
  "Tiểu Thử": "Lúc này thời tiết có vẻ dịu hơn được chút, nắng nhẹ. Nhưng cảm giác vẫn là nắng nóng nhưng chưa đến mức nóng nhất. Đây là thời điểm có không khí khá oi nóng, có thể đi kèm lũ lụt, sấm sét\nNgày Tiểu Thử có thể rơi vào ngày 7 tháng 7 dương lịch hoặc ngày 8 tháng 7 dương lịch hàng năm. Mặt trời ở 105 độ.",
  "Đại Thử": "Đại thử theo tiếng Hán có nghĩa là nắng oi. Đây là thời điểm khí hậu khá gay gắt, vô cùng nóng ẩm dẫn tới nhiều các cơn bão và áp thấp nhiệt đới đổ xuống.\nNgày Đại Thử có thể rơi vào ngày 22 tháng 7 dương lịch hoặc 23 tháng 7 dương lịch hàng năm. Mặt trời ở nhiệt độ 120 độ.",
  "Lập Thu": "Cũng như lập Xuân, lập Hạ, tiết Lập Thu nghĩa là đầu mùa thu. Khi mà thời tiết vào thu, ánh sáng và nhiệt độ của mặt trời sẽ giảm bớt. Tiết trời cũng sẽ se lạnh vào khoảng thời gian này. Thời tiết cực kỳ đẹp, mát mẻ, gió nhè nhè hiu hiu và mát hơn vào buổi tối. Đây là tiết bắt đầu làm người ta nhớ đến hương cốm và hoa cúc của mùa thu.\nNgày Lập Thu có thể rơi vào ngày 7 tháng 8 dương lịch hoặc ngày 8 tháng 8 dương lịch hàng năm. Mặt trời ở góc 135 độ.",
  "Xử Thử": "Mang ý nghĩa mưa lớn. Khi nhiệt độ nắng nóng của mùa hè dần tan biến và khí hậu mát mẻ của mùa thu dẫn hiện rõ. Thời điểm này, ánh sáng và nhiệt độ sẽ trở nên vô cùng dễ chịu.\nNgày Xử Thử có thể rơi vào ngày 22 tháng 8 dương lịch hoặc ngày 23 tháng 8 dương lịch hoặc ngày 24 tháng 8 dương lịch hàng năm. Mặt trời ở mức 150 độ.",
  "Bạch Lộ": "Lúc này, mặt trời sẽ nghiêng về phía nửa cầu Nam. Vậy nên, nửa cầu Bắc sẽ nhận ít ánh sáng và nhiệt độ của mặt trời hơn. Bạch Lộ theo tiếng Hán nghĩa là nắng nhạt. Trời mát mẻ hơn, nắng nhẹ nhàng. Tối có thể hơi gió và se lạnh sương đêm.\nNgày Bạch Lộ có thể rơi vào ngày 7 tháng 9 dương lịch hoặc ngày 8 tháng 9 dương lịch hoặc ngày 9 tháng 9 dương lịch hàng năm. Mặt trời ở mức 165 độ.",
  "Thu Phân": "Nghĩa là giữa mùa thu. Lúc này, nhiệt độ và ánh sáng cũng sẽ có dấu hiệu giảm dần. Không còn cảm giác nắng nóng cuối hạ đầu thu mà là khí hậu mùa thu thực sự. Nhiều cây cối bắt đầu vào mùa thay lá, Lá cây có dấu nhiệu chuyển vàng và rụng xuống, cảnh tượng yên bình, đẹp mắt.\nNgày Thu Phân có thể rơi vào ngày 21 tháng 9 dương lịch hoặc ngày 22 tháng 9 dương lịch hoặc 23 tháng 9 dương lịch hàng năm. Mặt trời ở mức 180 độ.",
  "Hàn Lộ": "Còn gọi là Tiết Hàn lộ - có nghĩa là thời tiết mát mẻ. Mặt trời lúc này sẽ nghiêng hoàn toàn về phía của nửa bán cầu Nam. Nửa bán cầu Bắc sẽ nhận được rất ít ánh sáng và không khí từ mặt trời. Tuy nhiên, vì vẫn còn tồn một lượng nhiệt khá lớn từ mùa hạ, vậy nên nhiệt độ vẫn chưa quá lạnh lẽo. Với các nước ở Bắc bán cầu như Việt Nam lúc này sẽ xa mặt trời, ít nhận được ánh sáng mặt trời nên khí hậu dần chuyển lạnh, trời tối sớm hơn.\nNgày Hàn Lộ có thể rơi vào ngày 8 tháng 10 dương lịch hoặc ngày 9 tháng 10 dương lịch hàng năm. Mặt trời ở mức 195 độ.",
  "Sương Giáng": "Tuyết rơi: Có nghĩa là bắt đầu thời điểm có sương mù. Chiều tối, đêm và sáng sớm là những thời điểm trong ngày có nhiều sương, có cả sương muối nên gây hại cho việc gieo cây trồng.\nNgày Sương Giáng có thể rơi vào ngày 23 tháng 10 dương lịch hoặc ngày 24 tháng 10 dương lịch hàng năm. Mặt trời ở 210 độ.",
  "Lập Đông": "Lúc này, nửa bán cầu Bắc nhiệt độ và ánh sáng sẽ giảm vô cùng mạnh. Bắt đầu mùa đông, thời điểm này bắt đầu xuất hiện nhiều đợt không khí lạnh từ phía Bắc tràn xuống. Nhiệt độ xuống thấp, lạnh dần và ngày ngắn, đêm dài.\nNgày Lập Đông có thể rơi vào ngày 7 tháng 11 dương lịch hoặc ngày 8 tháng 11 dương lịch hàng năm. Mặt trời ở mức 225 độ.",
  "Tiểu Tuyết": "Ở thời điểm này, những khu vực có vĩ độ cao sẽ có dấu hiệu có tuyết rơi. Trời bắt đầu có tuyết nhưng ít, không nhiều, rơi lất phất vừa phải. Ở Việt Nam thì không có tuyết nên không thể thấy rõ hiện tượng này như ở Trung quốc và Hàn quốc.\nNgày Tiểu Tuyết có thể rơi vào ngày 22 tháng 11 dương lịch hoặc ngày 23 tháng 11 dương lịch hàng năm. Mặt trời ở mức 240 độ.",
  "Đại Tuyết": "Dịch ra cũng dễ hiểu tức là tuyết rơi nhiều, rất dày. Những khu vực hàn đới, vĩ độ cao sẽ có mật độ tuyết phủ dày. Những nơi ở vĩ độ thấp tuy không có tuyết những nhiệt độ vẫn giảm xuống cực nhanh. Lúc này, mùa đông thực sự tới với nhiệt độ cực thấp, không khí lạnh với cường độ mạnh, các quốc gia phía Bắc sẽ bị tuyết bao phủ khắp nơi.\nNgày Đại Tuyết có thể rơi vào ngày 7 tháng 12 dương lịch hoặc ngày 8 tháng 12 dương lịch hàng năm. Mặt trời ở 255 độ.",
  "Đông Chí": "Đây là thời điểm mà mùa đông đi vào thời kỳ giữa mùa. Sáng rất muộn, 6-7 giờ trời rét lạnh và không thấy mặt trời. Tối đến nhanh hơn và nhiệt độ cũng giảm xuống nhanh chóng.\nNgày Đông Chí có thể vào ngày 21 tháng 12 dương lịch hoặc 22 tháng 12 dương lịch hàng năm. Mặt trời ở 270 độ.",
  "Tiểu Hàn": "Tiểu Hàn theo tiếng Hán có nghĩa là rét nhẹ, không quá buốt giá. Lúc này, nhiệt độ và ánh sáng của các khu vực ở bán cầu Bắc vẫn chưa nhận được quá nhiều từ mặt trời. Thời tiết vẫn có những đợt rét đậm nhưng dễ chịu hơn. Cường độ không khí lạnh chưa dồn dập đến mức cực đoan.\nNgày Tiểu Hàn có thể vào ngày 5 tháng 1 dương lịch hoặc ngày 6 tháng 1 dương lịch hàng năm. Mặt trời ở mức 285 độ.",
  "Đại Hàn": "Theo tiếng Hán, Đại Hàn còn có nghĩa là rét đậm, rét hại. Tức, nhiệt độ của khu vực bán cầu Bắc lúc này sẽ vô cùng lạnh lẽo. Khí hậu lạnh giá, nhiệt độ xuống thấp nhất, lạnh tới thấu xương. Cây cối và súc vật vì vậy cũng bị ảnh hưởng nhiều, có đợt lạnh quá khiến chúng chết rất nhiều.\nNgày Đại Hàn bắt đầu từ các ngày 20 tháng 1 dương lịch hoặc 21 tháng 1 dương lịch hàng năm. Mặt trời sẽ nằm ở vị trí xích kinh 300 độ. Đây cũng là đoạn khí cuối cùng, hoàn thành chu kỳ 24 tiết khí. Rồi lại bắt đầu một chu kỳ với với Kỳ nghỉ Xuân. Vạn vật lại bắt đầu một năm mới, một chu kỳ mới với sức sống mãnh liệt vào thời điểm này."
};

/// Lấy đoạn văn bản diễn giải ý nghĩa của Tiết Khí từ CSDL chuẩn hóa
String getTietKhiMeaning(String termName) {
  final clean = termName.replaceAll('Tiết khí:', '').replaceAll('Tiết', '').trim();
  return kTietKhiMeanings[clean] ??
      kTietKhiMeanings[termName] ??
      '';
}

class SolarTermFlowResult {
  final String currentTerm;
  final String currentStatusText;
  final String currentMeaning;
  final String nextTerm;
  final String nextStatusText;
  final String nextMeaning;
  final String tietKhiDisplay;

  SolarTermFlowResult({
    required this.currentTerm,
    required this.currentStatusText,
    required this.currentMeaning,
    required this.nextTerm,
    required this.nextStatusText,
    required this.nextMeaning,
    required this.tietKhiDisplay,
  });
}

/// Mốc ngày bắt đầu tiêu chuẩn của 24 tiết khí trong năm
const List<Map<String, dynamic>> kSolarTermsStandardTimeline = [
  {'name': 'Đông Chí', 'month': 12, 'day': 22, 'prevYear': true},
  {'name': 'Tiểu Hàn', 'month': 1, 'day': 5},
  {'name': 'Đại Hàn', 'month': 1, 'day': 20},
  {'name': 'Lập Xuân', 'month': 2, 'day': 4},
  {'name': 'Vũ Thủy', 'month': 2, 'day': 18},
  {'name': 'Kinh Trập', 'month': 3, 'day': 5},
  {'name': 'Xuân Phân', 'month': 3, 'day': 20},
  {'name': 'Thanh Minh', 'month': 4, 'day': 5},
  {'name': 'Cốc Vũ', 'month': 4, 'day': 20},
  {'name': 'Lập Hạ', 'month': 5, 'day': 5},
  {'name': 'Tiểu Mãn', 'month': 5, 'day': 21},
  {'name': 'Mang Chủng', 'month': 6, 'day': 5},
  {'name': 'Hạ Chí', 'month': 6, 'day': 21},
  {'name': 'Tiểu Thử', 'month': 7, 'day': 7},
  {'name': 'Đại Thử', 'month': 7, 'day': 23},
  {'name': 'Lập Thu', 'month': 8, 'day': 7},
  {'name': 'Xử Thử', 'month': 8, 'day': 23},
  {'name': 'Bạch Lộ', 'month': 9, 'day': 7},
  {'name': 'Thu Phân', 'month': 9, 'day': 23},
  {'name': 'Hàn Lộ', 'month': 10, 'day': 8},
  {'name': 'Sương Giáng', 'month': 10, 'day': 23},
  {'name': 'Lập Đông', 'month': 11, 'day': 7},
  {'name': 'Tiểu Tuyết', 'month': 11, 'day': 22},
  {'name': 'Đại Tuyết', 'month': 12, 'day': 7},
  {'name': 'Đông Chí', 'month': 12, 'day': 22},
  {'name': 'Tiểu Hàn', 'month': 1, 'day': 5, 'nextYear': true},
];

/// Hàm tính toán phân luồng 24 Tiết Khí (Hiện tại & Sắp tới) chuẩn hóa
SolarTermFlowResult getSolarTermsFlowInfo(int year, int month, int day) {
  final curDate = DateTime(year, month, day);

  int activeIdx = 0;
  for (int i = 0; i < kSolarTermsStandardTimeline.length - 1; i++) {
    final item = kSolarTermsStandardTimeline[i];
    final nextItem = kSolarTermsStandardTimeline[i + 1];

    final int itemYear = item['prevYear'] == true ? year - 1 : (item['nextYear'] == true ? year + 1 : year);
    final int nextYear = nextItem['prevYear'] == true ? year - 1 : (nextItem['nextYear'] == true ? year + 1 : year);

    final dStart = DateTime(itemYear, item['month'] as int, item['day'] as int);
    final dNext = DateTime(nextYear, nextItem['month'] as int, nextItem['day'] as int);

    if (!curDate.isBefore(dStart) && curDate.isBefore(dNext)) {
      activeIdx = i;
      break;
    }
  }

  final curr = kSolarTermsStandardTimeline[activeIdx];
  final next = kSolarTermsStandardTimeline[activeIdx + 1];

  final String currName = curr['name'] as String;
  final String nextName = next['name'] as String;

  final int currYear = curr['prevYear'] == true ? year - 1 : (curr['nextYear'] == true ? year + 1 : year);
  final dCurr = DateTime(currYear, curr['month'] as int, curr['day'] as int);

  final String currStatusText;
  if (curDate.year == dCurr.year && curDate.month == dCurr.month && curDate.day == dCurr.day) {
    currStatusText = '☼ Hiện tại là ngày $currName.';
  } else {
    currStatusText = '☼ Hiện tại bạn đang nằm trong Tiết khí $currName.';
  }

  final String nextMonthStr = (next['month'] as int).toString().padLeft(2, '0');
  final String nextDayStr = (next['day'] as int).toString().padLeft(2, '0');
  final String nextDateStr = '$nextDayStr/$nextMonthStr';
  final String nextStatusText = '☼ Sắp tới là Tiết $nextName ($nextDateStr).';

  return SolarTermFlowResult(
    currentTerm: currName,
    currentStatusText: currStatusText,
    currentMeaning: getTietKhiMeaning(currName),
    nextTerm: nextName,
    nextStatusText: nextStatusText,
    nextMeaning: getTietKhiMeaning(nextName),
    tietKhiDisplay: '$currName - $nextName',
  );
}

