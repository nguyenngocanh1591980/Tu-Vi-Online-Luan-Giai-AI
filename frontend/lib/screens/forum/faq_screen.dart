import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/mobile_bottom_nav.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  int _currentMobileIndex = 2; // Tab Diễn đàn
  final ScrollController _scrollController = ScrollController();
  String _selectedJumpCategory = 'Chuyển đến';

  final List<String> _jumpCategories = [
    'Chuyển đến',
    'Thông báo - Sự kiện',
    'Kiến thức Cơ bản',
    'Kiến thức Tử vi',
    'Kiến thức Tứ trụ',
    'Kiến thức Độn toán',
    'Kiến thức Phong thủy',
    'Kiến thức Sinh trắc',
    'Lý số Phương Tây',
    'Kiến thức Lý số khác',
    'Thư ngỏ - Ý kiến',
    'Lớp học Lý số',
    '↳  Lớp học tử vi',
    '↳  Lớp học tứ trụ',
    '↳  Lớp học chiêm tinh',
    '↳  Lớp học Phong thủy',
    '↳  Lớp học tổng hợp',
    '↳  Lớp học Dịch lý',
    'Hướng nghiệp',
    'Xem Tử vi',
    'Xem Tứ trụ',
    'Xem quẻ',
    'Xem Phong thủy',
    'Xem ngày, luận tuổi',
    'Xem Lý số Phương tây',
    'Xem tướng, đặt tên, sinh trắc',
    'Xem bằng các môn khác',
    'Cổ học - Văn hóa - Tín ngưỡng',
    'Cuộc sống muôn màu',
    'Câu lạc bộ - Giao lưu - Kết bạn',
  ];

  // Map chứa GlobalKey cho từng câu hỏi để scroll mượt
  final Map<String, GlobalKey> _questionKeys = {};

  // Dữ liệu 11 nhóm FAQ chuẩn hóa 100% từ phpBB
  final List<Map<String, dynamic>> _faqData = [
    {
      'category': 'Các vấn đề khi đăng nhập và đăng ký',
      'items': [
        {
          'id': 'cat_0_q_0',
          'q': 'Tại sao tôi không thể đăng nhập?',
          'a': 'Có một số nguyên nhân khiến bạn không thể đăng nhập. Trước hết, hãy chắc chắn rằng tên người dùng và mật khẩu của bạn là chính xác. Nếu thông tin đã chính xác, hãy liên hệ với Quản trị viên để chắc chắn rằng tài khoản của bạn không bị khóa hoặc bị xóa. Cũng có thể do cấu hình máy chủ gặp sự cố từ phía quản trị viên.',
        },
        {
          'id': 'cat_0_q_1',
          'q': 'Tại sao tôi phải đăng ký?',
          'a': 'Bạn có thể không bắt buộc phải đăng ký; Quản trị viên có thể cho phép khách gửi bài viết mà không cần đăng ký tài khoản. Tuy nhiên, việc đăng ký sẽ cung cấp cho bạn quyền truy cập vào các tính năng bổ sung mà khách không thể sử dụng, chẳng hạn như hình ảnh đại diện, tin nhắn cá nhân, gửi email cho thành viên khác, gia nhập các nhóm người dùng và theo dõi chủ đề.',
        },
        {
          'id': 'cat_0_q_2',
          'q': 'Tại sao tôi không thể đăng ký?',
          'a': 'Có thể Quản trị viên đã vô hiệu hóa tính năng đăng ký tài khoản mới để ngăn chặn người dùng mới tham gia tạm thời. Ngoài ra, địa chỉ IP hoặc tên miền email của bạn có thể đã bị cấm đăng ký trên hệ thống. Vui lòng liên hệ với Quản trị viên để được hỗ trợ giải quyết.',
        },
        {
          'id': 'cat_0_q_3',
          'q': 'Tôi đã đăng ký nhưng không thể đăng nhập!',
          'a': 'Trước tiên, hãy kiểm tra xem tên người dùng và mật khẩu đã nhập chính xác chưa. Tiếp theo, kiểm tra xem tài khoản của bạn có yêu cầu kích hoạt hay không. Một số diễn đàn yêu cầu xác thực qua email kích hoạt được gửi đến hộp thư của bạn, hoặc cần sự phê duyệt thủ công từ Quản trị viên trước khi bạn có thể đăng nhập.',
        },
        {
          'id': 'cat_0_q_4',
          'q': 'Tôi đã đăng ký trước đây nhưng hiện tại không thể đăng nhập được nữa?!',
          'a': 'Nguyên nhân có thể là do Quản trị viên đã vô hiệu hóa hoặc xóa tài khoản của bạn vì lý do không hoạt động trong một thời gian dài. Nhiều diễn đàn định kỳ dọn dẹp các tài khoản không đăng bài viết hoặc không trực tuyến trong nhiều tháng để giảm kích thước cơ sở dữ liệu.',
        },
        {
          'id': 'cat_0_q_5',
          'q': 'Tôi bị mất mật khẩu của mình!',
          'a': 'Đừng lo lắng! Mặc dù mật khẩu của bạn không thể khôi phục lại trực tiếp (do đã được mã hóa một chiều), nhưng bạn có thể đặt lại mật khẩu mới một cách dễ dàng. Hãy nhấn vào liên kết "Quên mật khẩu" trên trang đăng nhập và làm theo các hướng dẫn gửi về email của bạn.',
        },
        {
          'id': 'cat_0_q_6',
          'q': 'Tại sao tôi bị tự động đăng xuất?',
          'a': 'Nếu bạn không đánh dấu vào ô "Ghi nhớ đăng nhập" khi đăng nhập, hệ thống sẽ chỉ lưu phiên làm việc của bạn trong một khoảng thời gian nhất định. Điều này nhằm bảo vệ tài khoản của bạn, ngăn người khác sử dụng tài khoản khi bạn rời khỏi máy tính.',
        },
      ],
    },
    {
      'category': 'Các thiết lập và tùy chọn người dùng',
      'items': [
        {
          'id': 'cat_1_q_0',
          'q': 'Làm sao để tôi thay đổi các thiết lập của mình?',
          'a': 'Tất cả các thiết lập của bạn (nếu bạn là thành viên đã đăng ký) đều được lưu trữ an toàn trong cơ sở dữ liệu. Để thay đổi chúng, hãy truy cập vào Bảng điều khiển cá nhân (UCP) bằng cách bấm vào liên kết tên tài khoản hoặc liên kết "Thiết lập cá nhân" ở góc trên của diễn đàn.',
        },
        {
          'id': 'cat_1_q_1',
          'q': 'Múi giờ hiển thị không chính xác!',
          'a': 'Có thể múi giờ hiển thị trên diễn đàn đang khác với múi giờ thực tế tại nơi bạn sinh sống. Nếu gặp tình trạng này, bạn hãy vào Bảng điều khiển cá nhân (UCP) -> Thiết lập diễn đàn và chọn lại múi giờ phù hợp với khu vực địa phương của bạn (ví dụ: GMT+7 đối với Việt Nam).',
        },
        {
          'id': 'cat_1_q_2',
          'q': 'Tôi đã đổi múi giờ nhưng thời gian hiển thị vẫn không đúng!',
          'a': 'Nếu bạn chắc chắn rằng mình đã thiết lập múi giờ chính xác nhưng thời gian vẫn bị lệch, nguyên nhân phổ biến nhất là do quy ước giờ mùa hè (DST - Daylight Saving Time). Hãy kiểm tra lại tùy chọn giờ mùa hè trong phần thiết lập cá nhân của bạn.',
        },
        {
          'id': 'cat_1_q_3',
          'q': 'Ngôn ngữ của tôi không có trong danh sách!',
          'a': 'Quản trị viên có thể chưa cài đặt gói ngôn ngữ của bạn, hoặc chưa có bản dịch hoàn chỉnh cho ngôn ngữ đó. Bạn có thể liên hệ với Quản trị viên diễn đàn để đề xuất cài đặt thêm gói ngôn ngữ mà bạn mong muốn.',
        },
        {
          'id': 'cat_1_q_4',
          'q': 'Làm thế nào để tôi hiển thị hình đại diện (Avatar)?',
          'a': 'Trong Bảng điều khiển cá nhân (UCP), mục "Hồ sơ cá nhân" -> "Thay đổi ảnh đại diện", bạn có thể tải lên ảnh đại diện từ máy tính cá nhân, nhập đường dẫn hình ảnh từ internet hoặc chọn một hình có sẵn từ thư viện ảnh đại diện của diễn đàn (nếu tính năng này được kích hoạt).',
        },
        {
          'id': 'cat_1_q_5',
          'q': 'Cấp bậc của tôi là gì và làm thế nào để thay đổi?',
          'a': 'Cấp bậc hiển thị bên dưới tên người dùng của bạn cho biết số lượng bài viết mà bạn đã đóng góp cho diễn đàn, hoặc thể hiện vai trò đặc biệt như Điều hành viên hay Quản trị viên. Bạn không thể trực tiếp tự thay đổi cấp bậc của mình vì hệ thống sẽ tự động cập nhật dựa trên số lượng bài viết hoặc do Quản trị viên chỉ định.',
        },
        {
          'id': 'cat_1_q_6',
          'q': 'Khi tôi nhấn vào liên kết email của một người dùng, tại sao hệ thống yêu cầu đăng nhập?',
          'a': 'Chỉ những thành viên đã đăng ký và đăng nhập mới có thể gửi email cho thành viên khác thông qua biểu mẫu email tích hợp sẵn của diễn đàn (nếu Quản trị viên kích hoạt tính năng này). Điều này nhằm ngăn chặn thư rác và bảo vệ thông tin liên lạc riêng tư của người dùng.',
        },
      ],
    },
    {
      'category': 'Đăng bài viết',
      'items': [
        {
          'id': 'cat_2_q_0',
          'q': 'Làm thế nào để gửi bài viết mới hoặc trả lời bài viết?',
          'a': 'Để đăng một chủ đề mới trong một chuyên mục, hãy nhấn vào nút "Gửi đề tài mới". Để trả lời một bài viết trong chủ đề đã có, hãy nhấn vào nút "Trả lời". Bạn có thể cần phải đăng ký tài khoản trước khi có thể thực hiện đăng bài.',
        },
        {
          'id': 'cat_2_q_1',
          'q': 'Làm thế nào để tôi sửa hoặc xóa một bài viết?',
          'a': 'Trừ khi bạn là Quản trị viên hoặc Điều hành viên, bạn chỉ có thể chỉnh sửa hoặc xóa bài viết của chính mình. Bạn có thể sửa bài bằng cách nhấn vào nút "Sửa" tại bài viết đó. Nếu ai đó đã gửi phản hồi vào chủ đề sau bài của bạn, một thông báo nhỏ ghi nhận lần sửa cuối cùng sẽ xuất hiện phía dưới bài viết.',
        },
        {
          'id': 'cat_2_q_2',
          'q': 'Làm sao để thêm chữ ký vào bài viết của mình?',
          'a': 'Để thêm chữ ký vào bài viết, trước tiên bạn cần tạo chữ ký trong Bảng điều khiển cá nhân (UCP) -> Hồ sơ cá nhân -> Chữ ký. Sau khi tạo xong, bạn có thể đánh dấu vào ô "Đính kèm chữ ký" khi soạn thảo bài viết.',
        },
        {
          'id': 'cat_2_q_3',
          'q': 'Làm thế nào để tạo một cuộc bình chọn?',
          'a': 'Khi đăng một chủ đề mới hoặc chỉnh sửa bài viết đầu tiên của chủ đề, hãy nhấn vào tab "Tạo bình chọn" nằm phía dưới khung soạn thảo chính. Nhập câu hỏi bình chọn và các lựa chọn trả lời (mỗi lựa chọn trên một dòng), sau đó thiết lập số ngày bình chọn nếu cần.',
        },
        {
          'id': 'cat_2_q_4',
          'q': 'Làm sao để sửa hoặc xóa một cuộc bình chọn?',
          'a': 'Cũng giống như bài viết, cuộc bình chọn chỉ có thể được chỉnh sửa bởi người tạo ra nó, Điều hành viên hoặc Quản trị viên. Để sửa bình chọn, hãy nhấn sửa bài viết đầu tiên của chủ đề, nơi chứa các thiết lập của cuộc bình chọn.',
        },
        {
          'id': 'cat_2_q_5',
          'q': 'Tại sao tôi không thể truy cập vào một chuyên mục?',
          'a': 'Một số chuyên mục có thể bị giới hạn chỉ dành riêng cho những người dùng hoặc nhóm thành viên nhất định. Để xem, đọc, đăng bài hoặc thực hiện các thao tác trong chuyên mục đó, bạn cần có quyền hạn đặc biệt do Quản trị viên cấp phép.',
        },
        {
          'id': 'cat_2_q_6',
          'q': 'Tại sao tôi không thể bình chọn trong các cuộc thăm dò ý kiến?',
          'a': 'Chỉ những thành viên đã đăng ký và có đủ quyền hạn trong chuyên mục mới có thể tham gia bình chọn. Ngoài ra, nếu cuộc bình chọn đã hết hạn hoặc bạn đã từng bỏ phiếu trước đó (đối với bình chọn không cho phép đổi phiếu), bạn sẽ không thể bình chọn lại.',
        },
      ],
    },
    {
      'category': 'Các mức độ định dạng và loại bài viết',
      'items': [
        {
          'id': 'cat_3_q_0',
          'q': 'BBCode là gì?',
          'a': 'BBCode là một dạng thẻ định dạng văn bản đặc biệt tương tự HTML, cho phép bạn tạo kiểu chữ đậm, nghiêng, gạch chân, màu sắc, chèn liên kết, hình ảnh và trích dẫn trong bài viết. Bạn có thể sử dụng các nút bấm trên thanh công cụ soạn thảo để chèn nhanh các thẻ BBCode.',
        },
        {
          'id': 'cat_3_q_1',
          'q': 'Tôi có thể sử dụng mã HTML không?',
          'a': 'Không. Vì lý do an toàn bảo mật hệ thống, mã HTML bị vô hiệu hóa khi đăng bài viết trên diễn đàn. Hầu hết các định dạng bạn cần đều có thể thực hiện thông qua BBCode thay thế.',
        },
        {
          'id': 'cat_3_q_2',
          'q': 'Mặt cười (Smilies / Biểu tượng cảm xúc) là gì?',
          'a': 'Mặt cười là những hình ảnh đồ họa nhỏ thể hiện cảm xúc, ví dụ :) biểu thị vui vẻ, :( biểu thị buồn bã. Danh sách đầy đủ các biểu tượng cảm xúc có thể được xem ngay bên cạnh hoặc bên dưới khung soạn thảo bài viết.',
        },
        {
          'id': 'cat_3_q_3',
          'q': 'Tôi có thể chèn hình ảnh vào bài viết không?',
          'a': 'Có, hình ảnh có thể hiển thị trong bài viết của bạn. Nếu Quản trị viên cho phép tải tệp đính kèm, bạn có thể tải trực tiếp hình ảnh lên diễn đàn. Ngoài ra, bạn có thể liên kết đến một hình ảnh trên internet bằng cách sử dụng thẻ BBCode [img]http://example.com/image.jpg[/img].',
        },
        {
          'id': 'cat_3_q_4',
          'q': 'Thông báo toàn cầu (Global Announcements) là gì?',
          'a': 'Thông báo toàn cầu chứa các thông tin quan trọng của toàn bộ hệ thống diễn đàn và xuất hiện ở vị trí trên cùng của tất cả các chuyên mục. Quyền tạo thông báo toàn cầu do Quản trị viên thiết lập.',
        },
        {
          'id': 'cat_3_q_5',
          'q': 'Thông báo (Announcements) là gì?',
          'a': 'Thông báo thường chứa các thông tin quan trọng dành riêng cho chuyên mục hiện tại mà bạn đang xem. Thông báo luôn hiển thị ở phần trên cùng của chuyên mục đó trước các chủ đề thông thường.',
        },
        {
          'id': 'cat_3_q_6',
          'q': 'Chủ đề chú ý (Sticky topics) là gì?',
          'a': 'Chủ đề chú ý hiển thị ngay bên dưới các thông báo và được ghim cố định ở trang đầu tiên của chuyên mục. Đây thường là các chủ đề quy định, hướng dẫn hoặc tài liệu tham khảo quan trọng.',
        },
        {
          'id': 'cat_3_q_7',
          'q': 'Chủ đề bị khóa (Locked topics) là gì?',
          'a': 'Chủ đề bị khóa là những chủ đề mà thành viên không thể gửi thêm bài trả lời mới và mọi cuộc bình chọn bên trong đều tự động dừng lại. Chủ đề bị khóa bởi Điều hành viên hoặc Quản trị viên diễn đàn khi kết thúc thảo luận hoặc vi phạm quy định.',
        },
        {
          'id': 'cat_3_q_8',
          'q': 'Biểu tượng chủ đề là gì?',
          'a': 'Biểu tượng chủ đề là hình ảnh nhỏ do tác giả chọn khi đăng bài nhằm biểu thị nội dung hoặc tính chất của chủ đề đó (như câu hỏi, chú ý, thảo luận vui). Khả năng sử dụng biểu tượng chủ đề tùy thuộc vào cấu hình của Quản trị viên.',
        },
      ],
    },
    {
      'category': 'Vai trò người dùng và nhóm',
      'items': [
        {
          'id': 'cat_4_q_0',
          'q': 'Quản trị viên (Administrators) là gì?',
          'a': 'Quản trị viên là những người có quyền hạn cao nhất trên toàn bộ diễn đàn. Họ quản lý mọi hoạt động của hệ thống, bao gồm phân quyền thành viên, quản lý danh mục, xử lý vi phạm, thiết lập giao diện và cài đặt các tính năng diễn đàn.',
        },
        {
          'id': 'cat_4_q_1',
          'q': 'Điều hành viên (Moderators) là gì?',
          'a': 'Điều hành viên là những người chăm sóc, theo dõi các chuyên mục hàng ngày. Họ có quyền sửa, xóa, khóa, mở khóa, di chuyển và chia tách các chủ đề trong chuyên mục mà họ được phân công phụ trách.',
        },
        {
          'id': 'cat_4_q_2',
          'q': 'Nhóm người dùng (Usergroups) là gì?',
          'a': 'Nhóm người dùng là tập hợp các thành viên được chia theo từng vai trò để Quản trị viên dễ dàng quản lý quyền hạn. Mỗi người dùng có thể thuộc nhiều nhóm khác nhau và mỗi nhóm có thể được cấp các quyền truy cập riêng biệt.',
        },
        {
          'id': 'cat_4_q_3',
          'q': 'Làm thế nào để tôi tham gia vào một nhóm người dùng?',
          'a': 'Bạn có thể xem danh sách tất cả các nhóm thông qua liên kết "Nhóm người dùng" trong Bảng điều khiển cá nhân (UCP). Nếu bạn muốn tham gia một nhóm, hãy bấm nút đăng ký tham gia. Một số nhóm có thể yêu cầu sự phê duyệt từ Trưởng nhóm trước khi bạn được kết nạp.',
        },
        {
          'id': 'cat_4_q_4',
          'q': 'Làm thế nào để tôi trở thành người lãnh đạo nhóm?',
          'a': 'Trưởng nhóm người dùng (Group Leader) do Quản trị viên chỉ định khi tạo nhóm hoặc bổ nhiệm sau đó. Nếu bạn có nguyện vọng làm trưởng nhóm, hãy liên hệ với Quản trị viên diễn đàn.',
        },
        {
          'id': 'cat_4_q_5',
          'q': 'Tại sao một số nhóm người dùng lại xuất hiện với màu sắc khác nhau?',
          'a': 'Quản trị viên có thể gán màu sắc đặc trưng cho các thành viên của một nhóm để người xem dễ dàng phân biệt vai trò của họ trên diễn đàn (ví dụ: Quản trị viên màu đỏ, Điều hành viên màu xanh lá cây).',
        },
        {
          'id': 'cat_4_q_6',
          'q': '“Nhóm người dùng mặc định” là gì?',
          'a': 'Nếu bạn là thành viên của nhiều nhóm, nhóm mặc định sẽ quyết định màu tên và danh hiệu cấp bậc hiển thị của bạn trên diễn đàn. Bạn có thể thay đổi nhóm mặc định trong Bảng điều khiển cá nhân.',
        },
        {
          'id': 'cat_4_q_7',
          'q': 'Liên kết “Nhóm điều hành” (The team) là gì?',
          'a': 'Trang "Nhóm điều hành" cung cấp cho bạn danh sách đầy đủ ban quản trị diễn đàn, bao gồm các Quản trị viên và Điều hành viên cùng thông tin về các chuyên mục mà họ đang phụ trách.',
        },
      ],
    },
    {
      'category': 'Bạn bè và kẻ thù',
      'items': [
        {
          'id': 'cat_5_q_0',
          'q': 'Danh sách Bạn bè và Kẻ thù là gì?',
          'a': 'Bạn có thể sử dụng danh sách này để tổ chức và quản lý các mối liên hệ trên diễn đàn. Các thành viên trong danh sách Bạn bè sẽ hiển thị trạng thái trực tuyến và cho phép gửi tin nhắn nhanh. Nếu bạn thêm ai đó vào danh sách Kẻ thù, các bài viết của họ sẽ tự động bị ẩn đi khi bạn xem chủ đề.',
        },
        {
          'id': 'cat_5_q_1',
          'q': 'Làm thế nào để thêm hoặc xóa người dùng khỏi danh sách Bạn bè hoặc Kẻ thù?',
          'a': 'Bạn có thể thêm người dùng vào danh sách bằng hai cách: truy cập vào trang hồ sơ của thành viên đó và bấm nút "Thêm vào danh sách bạn bè/kẻ thù", hoặc nhập trực tiếp tên người dùng trong Bảng điều khiển cá nhân (UCP) -> Bạn bè & Kẻ thù.',
        },
      ],
    },
    {
      'category': 'Theo dõi và đánh dấu',
      'items': [
        {
          'id': 'cat_6_q_0',
          'q': 'Sự khác biệt giữa đánh dấu trang (Bookmark) và theo dõi (Subscribe) là gì?',
          'a': 'Đánh dấu trang giúp bạn lưu lại một chủ đề để dễ dàng mở lại sau này từ Bảng điều khiển cá nhân. Còn theo dõi một chủ đề hoặc chuyên mục sẽ gửi thông báo đến bạn mỗi khi có bài viết mới được đăng trong đó.',
        },
        {
          'id': 'cat_6_q_1',
          'q': 'Làm thế nào để tôi đánh dấu hoặc theo dõi một chủ đề cụ thể?',
          'a': 'Bạn có thể đánh dấu hoặc theo dõi một chủ đề bằng cách nhấn vào liên kết tương ứng trong menu "Công cụ chủ đề" ở đầu hoặc cuối trang thảo luận của chủ đề đó.',
        },
        {
          'id': 'cat_6_q_2',
          'q': 'Làm thế nào để tôi theo dõi các diễn đàn chuyên mục cụ thể?',
          'a': 'Để theo dõi một chuyên mục, hãy bấm vào liên kết "Theo dõi diễn đàn này" ở góc dưới trang khi bạn truy cập vào chuyên mục đó.',
        },
        {
          'id': 'cat_6_q_3',
          'q': 'Làm thế nào để tôi hủy bỏ việc theo dõi?',
          'a': 'Để hủy bỏ việc theo dõi các chủ đề hoặc chuyên mục, hãy truy cập Bảng điều khiển cá nhân (UCP) -> Quản lý theo dõi, chọn các mục cần hủy và bấm xác nhận.',
        },
      ],
    },
    {
      'category': 'Tập tin đính kèm',
      'items': [
        {
          'id': 'cat_7_q_0',
          'q': 'Những loại tập tin đính kèm nào được cho phép trên diễn đàn?',
          'a': 'Mỗi Quản trị viên diễn đàn có thể cho phép hoặc hạn chế các định dạng tệp đính kèm nhất định (như hình ảnh, văn bản, tệp nén). Nếu bạn không chắc chắn loại tệp nào được phép tải lên, hãy liên hệ với Quản trị viên để được hướng dẫn.',
        },
        {
          'id': 'cat_7_q_1',
          'q': 'Làm thế nào để tôi tìm thấy tất cả các tập tin đính kèm của mình?',
          'a': 'Để xem danh sách tất cả các tập tin đính kèm mà bạn đã tải lên diễn đàn, hãy vào Bảng điều khiển cá nhân (UCP) và mở mục "Quản lý tập tin đính kèm".',
        },
      ],
    },
    {
      'category': 'Tin nhắn cá nhân',
      'items': [
        {
          'id': 'cat_8_q_0',
          'q': 'Tại sao tôi không thể gửi tin nhắn cá nhân?',
          'a': 'Có ba nguyên nhân phổ biến: bạn chưa đăng ký hoặc chưa đăng nhập; Quản trị viên đã tắt tính năng tin nhắn cá nhân trên toàn hệ thống; hoặc nhóm người dùng của bạn không được cấp quyền sử dụng tin nhắn cá nhân.',
        },
        {
          'id': 'cat_8_q_1',
          'q': 'Tôi nhận được thư rác hoặc tin nhắn xúc phạm từ ai đó trên diễn đàn!',
          'a': 'Bạn có thể báo cáo tin nhắn vi phạm cho Điều hành viên bằng nút "Báo cáo" có sẵn trong tin nhắn. Ngoài ra, bạn có thể thêm người gửi vào danh sách Kẻ thù để chặn nhận thêm tin nhắn từ họ trong tương lai.',
        },
        {
          'id': 'cat_8_q_2',
          'q': 'Tôi liên tục nhận được các tin nhắn cá nhân không mong muốn!',
          'a': 'Bạn có thể thiết lập quy tắc lọc tin nhắn tự động trong Bảng điều khiển cá nhân (UCP) -> Tin nhắn cá nhân -> Quy tắc thư mục, hoặc đưa người gửi đó vào danh sách Kẻ thù để hệ thống tự động chặn tin nhắn.',
        },
      ],
    },
    {
      'category': 'Thông báo',
      'items': [
        {
          'id': 'cat_9_q_0',
          'q': 'Thông báo trên trình duyệt (Web Push) là gì?',
          'a': 'Thông báo Web Push giúp nâng cao trải nghiệm bằng cách gửi thông báo trực tiếp đến trình duyệt máy tính hoặc thiết bị di động của bạn ngay khi có người trả lời bài viết, trích dẫn hoặc gửi tin nhắn riêng cho bạn.',
        },
        {
          'id': 'cat_9_q_1',
          'q': 'Làm thế nào để nhận thông báo đẩy trên máy tính hoặc điện thoại?',
          'a': 'Hãy truy cập vào Bảng điều khiển cá nhân (UCP) -> Thiết lập thông báo và chọn "Bật thông báo đẩy". Trình duyệt của bạn sẽ hiển thị hộp thoại yêu cầu cấp quyền nhận thông báo, hãy chọn "Cho phép" để hoàn tất.',
        },
      ],
    },
    {
      'category': 'Lưu trữ thông tin và Bản quyền',
      'items': [
        {
          'id': 'cat_10_q_0',
          'q': 'Ai đã phát triển hệ thống phần mềm diễn đàn này?',
          'a': 'Phần mềm diễn đàn này (ở phiên bản nguyên gốc) được sản xuất, phát hành và giữ bản quyền bởi phpBB Limited (https://www.phpbb.com). Phần mềm được phát hành theo Giấy phép Công cộng GNU phiên bản 2 (GPL-2.0).',
        },
        {
          'id': 'cat_10_q_1',
          'q': 'Tôi cần liên hệ với ai về các vấn đề bản quyền hoặc pháp lý liên quan đến diễn đàn?',
          'a': 'Bất kỳ Quản trị viên nào có tên trong trang "Nhóm điều hành" đều là người tiếp nhận các phản hồi hoặc khiếu nại của bạn. Nếu vẫn không nhận được phản hồi, bạn có thể liên hệ với chủ sở hữu tên miền hoặc nhà cung cấp máy chủ lưu trữ diễn đàn.',
        },
        {
          'id': 'cat_10_q_2',
          'q': 'Diễn đàn này lưu trữ những thông tin gì của tôi?',
          'a': 'Diễn đàn lưu trữ các thông tin bạn tự nguyện cung cấp trong quá trình đăng ký (chẳng hạn như tên người dùng, địa chỉ email, mật khẩu đã mã hóa) và các bài viết, tin nhắn bạn đăng tải. Hệ thống cũng sử dụng cookies để duy trì phiên đăng nhập của bạn.',
        },
        {
          'id': 'cat_10_q_3',
          'q': 'Làm thế nào để tôi liên hệ với Quản trị viên diễn đàn?',
          'a': 'Bạn có thể sử dụng liên kết "Liên hệ" hoặc trang "Ban điều hành" ở chân trang để gửi biểu mẫu liên hệ trực tiếp đến Quản trị viên diễn đàn.',
        },
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    // Khởi tạo GlobalKey cho từng câu hỏi
    for (final cat in _faqData) {
      final items = cat['items'] as List<Map<String, dynamic>>;
      for (final item in items) {
        _questionKeys[item['id'] as String] = GlobalKey();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToQuestion(String questionId) {
    final key = _questionKeys[questionId];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
  }

  void _onMobileNavTapped(int index) {
    setState(() {
      _currentMobileIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Material(
      color: Colors.transparent,
      child: ResponsiveLayout(
        mobileBody: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBody(context),
            MobileBottomNavBar(
              currentIndex: _currentMobileIndex,
              onTap: _onMobileNavTapped,
            ),
          ],
        ),
        desktopBody: SingleChildScrollView(child: _buildBody(context)),
      ),
    );
  }

  // --- Layout Tổng Thể ---
  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Tiêu đề khối Hỏi Đáp
          _buildPageHeader(),
          const SizedBox(height: 16),

          // 2. Mục Lục FAQ (Index) dạng 2 cột đồng bộ phpBB gốc
          _buildFaqIndex(context),
          const SizedBox(height: 24),

          // 3. Danh sách Chi Tiết 11 Nhóm Câu Hỏi & Trả Lời
          _buildFaqContent(),
          const SizedBox(height: 24),

          // 4. Footer diễn đàn đồng bộ phpBB
          _buildForumFooter(),
        ],
      ),
    );
  }

  // --- 1. Tiêu Đề Màn Hình ---
  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF5350).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.help_outline,
                color: Color(0xFFEF5350),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Những câu hỏi thường gặp (FAQ)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Giải đáp các thắc mắc về cách sử dụng diễn đàn, quản lý tài khoản và gửi bài viết',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(color: Color(0xFF2E3B5F), thickness: 1),
      ],
    );
  }

  // --- 2. Mục Lục FAQ (Index) 2 Cột ---
  Widget _buildFaqIndex(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    // Chia 11 danh mục thành 2 cột: Cột trái (5 nhóm đầu), Cột phải (6 nhóm sau)
    final leftCategories = _faqData.sublist(0, 5);
    final rightCategories = _faqData.sublist(5);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF131A30), // Nền xanh đen sâu cho khối mục lục
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2E3B5F)),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.list_alt, color: Color(0xFFEF5350), size: 18),
              const SizedBox(width: 8),
              Text(
                'MỤC LỤC CÁC CHỦ ĐỀ HỎI ĐÁP',
                style: TextStyle(
                  color: Colors.grey[200],
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF2E3B5F), thickness: 1),
          const SizedBox(height: 12),
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: leftCategories
                        .map((cat) => _buildIndexCategoryBlock(cat))
                        .toList(),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: rightCategories
                        .map((cat) => _buildIndexCategoryBlock(cat))
                        .toList(),
                  ),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _faqData
                  .map((cat) => _buildIndexCategoryBlock(cat))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildIndexCategoryBlock(Map<String, dynamic> category) {
    final title = category['category'] as String;
    final items = category['items'] as List<Map<String, dynamic>>;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          ...items.map((item) {
            final qText = item['q'] as String;
            final qId = item['id'] as String;
            return Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
              child: InkWell(
                onTap: () => _scrollToQuestion(qId),
                hoverColor: Colors.white10,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '• ',
                        style: TextStyle(color: Color(0xFFEF5350), fontSize: 13),
                      ),
                      Expanded(
                        child: Text(
                          qText,
                          style: const TextStyle(
                            color: Color(0xFFEF5350),
                            fontSize: 12.5,
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFFEF5350),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- 3. Danh Sách Chi Tiết Toàn Bộ 11 Nhóm Câu Hỏi & Trả Lời ---
  Widget _buildFaqContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _faqData.map((cat) => _buildCategoryDetail(cat)).toList(),
    );
  }

  Widget _buildCategoryDetail(Map<String, dynamic> category) {
    final title = category['category'] as String;
    final items = category['items'] as List<Map<String, dynamic>>;

    return Container(
      margin: const EdgeInsets.only(bottom: 24.0),
      decoration: BoxDecoration(
        color: const Color(0xFF131A30),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2E3B5F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề phân nhóm FAQ
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: const BoxDecoration(
              color: Color(0xFF182242),
              borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
              border: Border(
                bottom: BorderSide(color: Color(0xFF2E3B5F), width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.bookmark_outline, color: Color(0xFFEF5350), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Danh sách các cặp Hỏi - Đáp
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  _buildQuestionAnswerItem(items[i]),
                  if (i < items.length - 1)
                    const Divider(
                      color: Color(0xFF2E3B5F),
                      height: 28,
                      thickness: 1,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionAnswerItem(Map<String, dynamic> item) {
    final qText = item['q'] as String;
    final aText = item['a'] as String;
    final qId = item['id'] as String;
    final key = _questionKeys[qId];

    return Container(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Câu hỏi (in đậm, màu vàng hổ phách nhạt hoặc trắng)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Q: ',
                style: TextStyle(
                  color: Color(0xFFEF5350),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Text(
                  qText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Câu trả lời (chữ sáng, dễ đọc)
          Padding(
            padding: const EdgeInsets.only(left: 18.0),
            child: Text(
              aText,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 13.5,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Nút "Lên trên" màu đỏ
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: _scrollToTop,
              hoverColor: Colors.white10,
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_upward,
                      color: Color(0xFFEF5350),
                      size: 13,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Lên trên',
                      style: TextStyle(
                        color: Color(0xFFEF5350),
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFFEF5350),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. Footer Diễn Đàn Chuẩn Hóa ---
  Widget _buildForumFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dropdown Chuyển đến
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text(
              'Chuyển đến: ',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(width: 8),
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF131A30),
                border: Border.all(color: const Color(0xFF2E3B5F)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedJumpCategory,
                  dropdownColor: const Color(0xFF131A30),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  items: _jumpCategories.map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat,
                      child: Text(cat),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedJumpCategory = val;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 6),
            ElevatedButton(
              onPressed: () {
                context.go('/forum');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E3B5F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                minimumSize: const Size(40, 36),
              ),
              child: const Text('Đi', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Divider(color: Color(0xFF2E3B5F), thickness: 1),
        const SizedBox(height: 12),

        // phpBB Copyright
        const Center(
          child: Column(
            children: [
              Text(
                'Powered by phpBB® Forum Software © phpBB Limited',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Bản quyền tiếng Việt bởi vietphpbb.org',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
