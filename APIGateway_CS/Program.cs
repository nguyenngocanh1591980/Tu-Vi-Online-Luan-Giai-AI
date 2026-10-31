using APIGateway_CS.Data;
using APIGateway_CS.Models;
using APIGateway_CS.Hubs;
using Microsoft.EntityFrameworkCore;
AppContext.SetSwitch("Npgsql.EnableLegacyTimestampBehavior", true);

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.SetIsOriginAllowed(_ => true)
              .AllowAnyMethod()
              .AllowAnyHeader()
              .AllowCredentials();
    });
});

builder.Services.AddControllers();
builder.Services.AddSignalR();

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection") ?? "Host=localhost;Port=5432;Database=TuviAIManagerDB;Username=postgres;Password=postgres"));

var jwtKey = builder.Configuration["JwtSettings:Key"] ?? "tuvi_online_manager_super_secret_key_1234567890";
builder.Services.AddAuthentication(Microsoft.AspNetCore.Authentication.JwtBearer.JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new Microsoft.IdentityModel.Tokens.TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["JwtSettings:Issuer"] ?? "TuvionlineAPI",
            ValidAudience = builder.Configuration["JwtSettings:Audience"] ?? "TuvionlineApp",
            IssuerSigningKey = new Microsoft.IdentityModel.Tokens.SymmetricSecurityKey(System.Text.Encoding.UTF8.GetBytes(jwtKey))
        };
    });
builder.Services.AddAuthorization();

builder.Services.AddHttpClient("AIEngine", client =>
{
    client.BaseAddress = new Uri("http://127.0.0.1:8000");
    client.Timeout = TimeSpan.FromMinutes(5);
});

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    db.Database.EnsureCreated();

    Console.WriteLine("==========================================================");
    Console.WriteLine("[DATABASE SEEDING] Bat dau kiem tra va seed du lieu test...");

    // 1. Data Seeding for Users: DA TAT THEO GIAO THUC THUC THI KIEN TRUC LOI (CHAM DUT MOCK DATA)

    // 2. Data Seeding for Categories (Module 3 - Đỏ)
    if (!db.Categories.Any())
    {
        var seededCategories = new List<Category>
        {
            new Category { Name = "Thông báo chung", Slug = "thong-bao-chung", ReadRoles = "User,Moderator,Admin,Super_Admin", WriteRoles = "Admin,Super_Admin", IsSeed = true },
            new Category { Name = "Lớp học Lý số", Slug = "lop-hoc-ly-so", ReadRoles = "User,Moderator,Admin,Super_Admin", WriteRoles = "Moderator,Admin,Super_Admin", IsSeed = true },
            new Category { Name = "Trà đá vỉa hè", Slug = "tra-da-via-he", ReadRoles = "User,Moderator,Admin,Super_Admin", WriteRoles = "User,Moderator,Admin,Super_Admin", IsSeed = true }
        };
        db.Categories.AddRange(seededCategories);
        db.SaveChanges();
        Console.WriteLine("[SEED] -> Da tao 3 Chuyen muc gia lap (Thong bao chung, Lop hoc Ly so, Tra da via he)");
    }

    // 3. Data Seeding for MasterProfiles (Module 4 - Đỏ)
    if (!db.MasterProfiles.Any())
    {
        var seededMasters = new List<MasterProfile>
        {
            new MasterProfile { MasterName = "Thầy Thiên Cơ", Specialization = "Tử Vi Đẩu Số, Bát Tự", RevenueShareRatio = "7/3", MasterShare = 0.7, PlatformShare = 0.3, IsApproved = true, IsSeed = true },
            new MasterProfile { MasterName = "Thầy Thái Dương", Specialization = "Kinh Dịch, Phong Thủy Địa Lý", RevenueShareRatio = "6/4", MasterShare = 0.6, PlatformShare = 0.4, IsApproved = false, IsSeed = true }
        };
        db.MasterProfiles.AddRange(seededMasters);
        db.SaveChanges();
        Console.WriteLine("[SEED] -> Da tao 2 Ho so chuyen gia gia lap (Thay Thien Co, Thay Thai Duong)");
    }

    // 4. Data Seeding for Bookings (Module 5 - Đỏ)
    if (!db.Bookings.Any())
    {
        var seededBookings = new List<Booking>
        {
            new Booking { Id = 101, MasterId = 1, UserId = 2, CustomerName = "Nguyễn Văn An", MasterName = "Thầy Thiên Cơ", Amount = 500000, Status = "CHỜ XÁC NHẬN", PaymentStatus = "Đã thanh toán", IsSeed = true },
            new Booking { Id = 102, MasterId = 2, UserId = 3, CustomerName = "Trần Thị Bích", MasterName = "Thầy Thái Dương", Amount = 1200000, Status = "ĐANG TƯ VẤN", PaymentStatus = "Đã thanh toán", IsSeed = true },
            new Booking { Id = 103, MasterId = 1, UserId = 4, CustomerName = "Lê Hoàng Nam", MasterName = "Thầy Thiên Cơ", Amount = 800000, Status = "HOÀN THÀNH", PaymentStatus = "Đã thanh toán", IsSeed = true },
            new Booking { Id = 104, MasterId = 2, UserId = 5, CustomerName = "Phạm Thu Hà", MasterName = "Thầy Thái Dương", Amount = 1000000, Status = "YÊU CẦU HOÀN TIỀN", PaymentStatus = "Chờ hoàn tiền", Reason = "Thầy bận đột xuất", IsSeed = true }
        };
        db.Bookings.AddRange(seededBookings);
        db.SaveChanges();
        Console.WriteLine("[SEED] -> Da tao 4 Tickets lich hen gia lap cho 4 cot Kanban");
    }

    // 5. Data Seeding for Astrology Interpretation (Module 6 - Trắng)
    var sampleInterpretation = db.AstrologyInterpretations.FirstOrDefault(x => x.Star == "Tử Vi" && x.Palace == "Mệnh" && x.State == "Miếu địa");
    if (sampleInterpretation == null)
    {
        sampleInterpretation = new AstrologyInterpretation
        {
            Star = "Tử Vi",
            Palace = "Mệnh",
            State = "Miếu địa",
            Content = "Tử Vi miếu địa tại Mệnh: Là cách cục Đế Tinh tọa thủ, chủ về thông minh đĩnh ngộ, uy nghi đường bệ, có tài lãnh đạo và quản lý xuất chúng. Hưởng phúc thọ song toàn, quý nhân phù trợ trọn đời, hậu vận đại phú đại quý."
        };
        db.AstrologyInterpretations.Add(sampleInterpretation);
        db.SaveChanges();
        Console.WriteLine("[SEED] -> Da nap loi luan giai mau thuc te cho Toa do Tu Vi - Menh - Mieu dia");
    }

    // 6. Data Seeding for BoardMembers (Ban Quản Trị - 7 Cột Phân Quyền)
    if (!db.BoardMembers.Any())
    {
        var seededBoard = new List<BoardMember>
        {
            // 1. Quản trị viên
            new BoardMember { Username = "Admin", GroupLevel = "Quản trị viên", RankBadge = "Quản Lý", PrimaryGroup = "Quản trị viên", NameColor = "#EF5350", PrimaryGroupColor = "#EF5350", ManagedCategories = "Tất cả chuyên mục", ManagedTopics = "Tất cả chủ đề", ManagementPermission = "Toàn quyền hệ thống", RibbonAsset = "/images/ribbon_quan_ly.png", LogoAsset = "/images/logo_quan_ly.png", SortOrder = 1 },
            new BoardMember { Username = "nncuong", GroupLevel = "Quản trị viên", RankBadge = "Sáng Lập", PrimaryGroup = "Quản trị viên", NameColor = "#EF5350", PrimaryGroupColor = "#EF5350", ManagedCategories = "Tất cả chuyên mục", ManagedTopics = "Tất cả chủ đề", ManagementPermission = "Toàn quyền sáng lập & hệ thống", RibbonAsset = "/images/ribbon_sang_lap.png", LogoAsset = "/images/logo_sang_lap.png", SortOrder = 2 },

            // 2. Siêu quản lý: Trống đúng thiết kế

            // 3. Quản lý
            new BoardMember { Username = "lysoVN", GroupLevel = "Quản lý", RankBadge = "Quản Lý", PrimaryGroup = "Quản lý", NameColor = "#42A5F5", PrimaryGroupColor = "#42A5F5", ManagedCategories = "Tất cả chuyên mục", ManagedTopics = "Tất cả chủ đề", ManagementPermission = "Toàn quyền chuyên mục & thành viên", RibbonAsset = "/images/ribbon_quan_ly.png", LogoAsset = "/images/logo_quan_ly.png", SortOrder = 10 },
            new BoardMember { Username = "phudongsoft", GroupLevel = "Quản lý", RankBadge = "Quản Lý", PrimaryGroup = "Quản lý", NameColor = "#42A5F5", PrimaryGroupColor = "#42A5F5", ManagedCategories = "Tất cả chuyên mục", ManagedTopics = "Tất cả chủ đề", ManagementPermission = "Toàn quyền chuyên mục & kỹ thuật", RibbonAsset = "/images/ribbon_quan_ly.png", LogoAsset = "/images/logo_quan_ly.png", SortOrder = 11 },
            new BoardMember { Username = "Quản lý", GroupLevel = "Quản lý", RankBadge = "Quản Lý", PrimaryGroup = "Quản lý", NameColor = "#42A5F5", PrimaryGroupColor = "#42A5F5", ManagedCategories = "Tất cả chuyên mục", ManagedTopics = "Tất cả chủ đề", ManagementPermission = "Quản lý vận hành & kiểm duyệt", RibbonAsset = "/images/ribbon_quan_ly.png", LogoAsset = "/images/logo_quan_ly.png", SortOrder = 12 },

            // 4. Điều hành
            new BoardMember { Username = "Điều hành 2", GroupLevel = "Điều hành", RankBadge = "Điều Hành", PrimaryGroup = "Điều hành", NameColor = "#42A5F5", PrimaryGroupColor = "#42A5F5", ManagedCategories = "Tất cả chuyên mục", ManagedTopics = "Tất cả chủ đề", ManagementPermission = "Kiểm duyệt & Quản trị bài viết", RibbonAsset = "/images/ribbon_dieu_hanh.png", LogoAsset = "/images/logo_dieu_hanh.png", SortOrder = 20 },
            new BoardMember { Username = "Điều hành 4", GroupLevel = "Điều hành", RankBadge = "Điều Hành", PrimaryGroup = "Điều hành", NameColor = "#42A5F5", PrimaryGroupColor = "#42A5F5", ManagedCategories = "Tất cả chuyên mục", ManagedTopics = "Tất cả chủ đề", ManagementPermission = "Kiểm duyệt & Quản trị bài viết", RibbonAsset = "/images/ribbon_dieu_hanh.png", LogoAsset = "/images/logo_dieu_hanh.png", SortOrder = 21 },
            new BoardMember { Username = "Điều hành 5", GroupLevel = "Điều hành", RankBadge = "Điều Hành", PrimaryGroup = "Điều hành", NameColor = "#42A5F5", PrimaryGroupColor = "#42A5F5", ManagedCategories = "Tất cả chuyên mục", ManagedTopics = "Tất cả chủ đề", ManagementPermission = "Kiểm duyệt & Quản trị bài viết", RibbonAsset = "/images/ribbon_dieu_hanh.png", LogoAsset = "/images/logo_dieu_hanh.png", SortOrder = 22 },
            new BoardMember { Username = "Điều hành 6", GroupLevel = "Điều hành", RankBadge = "Điều hành", PrimaryGroup = "Điều hành", NameColor = "#42A5F5", PrimaryGroupColor = "#42A5F5", ManagedCategories = "Tất cả chuyên mục", ManagedTopics = "Tất cả chủ đề", ManagementPermission = "Kiểm duyệt & Quản trị bài viết", RibbonAsset = "/images/ribbon_dieu_hanh.png", LogoAsset = "/images/logo_dieu_hanh.png", SortOrder = 23 },
            new BoardMember { Username = "Điều hành 7", GroupLevel = "Điều hành", RankBadge = "Điều Hành", PrimaryGroup = "Điều hành", NameColor = "#42A5F5", PrimaryGroupColor = "#42A5F5", ManagedCategories = "Tất cả chuyên mục", ManagedTopics = "Tất cả chủ đề", ManagementPermission = "Kiểm duyệt & Quản trị bài viết", RibbonAsset = "/images/ribbon_dieu_hanh.png", LogoAsset = "/images/logo_dieu_hanh.png", SortOrder = 24 },
            new BoardMember { Username = "Điều hành 8", GroupLevel = "Điều hành", RankBadge = "Điều Hành", PrimaryGroup = "Điều hành", NameColor = "#42A5F5", PrimaryGroupColor = "#42A5F5", ManagedCategories = "Tất cả chuyên mục", ManagedTopics = "Tất cả chủ đề", ManagementPermission = "Kiểm duyệt & Quản trị bài viết", RibbonAsset = "/images/ribbon_dieu_hanh.png", LogoAsset = "/images/logo_dieu_hanh.png", SortOrder = 25 },
            new BoardMember { Username = "Điều hành 9", GroupLevel = "Điều hành", RankBadge = "Điều Hành", PrimaryGroup = "Điều hành", NameColor = "#42A5F5", PrimaryGroupColor = "#42A5F5", ManagedCategories = "Tất cả chuyên mục", ManagedTopics = "Tất cả chủ đề", ManagementPermission = "Kiểm duyệt & Quản trị bài viết", RibbonAsset = "/images/ribbon_dieu_hanh.png", LogoAsset = "/images/logo_dieu_hanh.png", SortOrder = 26 },

            // 5. Ban tư vấn
            new BoardMember { Username = "Ban tư vấn", GroupLevel = "Ban tư vấn", RankBadge = "Tư Vấn", PrimaryGroup = "Ban tư vấn", NameColor = "#FFA726", PrimaryGroupColor = "#FFA726", ManagedCategories = "Tất cả chuyên mục", ManagedTopics = "Tất cả chủ đề", ManagementPermission = "Tư vấn & Giải đáp lý số", RibbonAsset = "/images/ribbon_tu_van.png", LogoAsset = "/images/logo_tu_van.png", SortOrder = 30 },
            new BoardMember { Username = "dungtamchin", GroupLevel = "Ban tư vấn", RankBadge = "Tư Vấn", PrimaryGroup = "Ban tư vấn", NameColor = "#FFA726", PrimaryGroupColor = "#FFA726", ManagedCategories = "-", ManagedTopics = "-", ManagementPermission = "Tư vấn & Giải đáp học thuật", RibbonAsset = "/images/ribbon_tu_van.png", LogoAsset = "/images/logo_tu_van.png", SortOrder = 31 },
            new BoardMember { Username = "Kim Hải Đông", GroupLevel = "Ban tư vấn", RankBadge = "Tư Vấn", PrimaryGroup = "Trao đổi học thuật", NameColor = "#66BB6A", PrimaryGroupColor = "#66BB6A", ManagedCategories = "-", ManagedTopics = "-", ManagementPermission = "Cố vấn học thuật chuyên sâu", RibbonAsset = "/images/ribbon_tu_van.png", LogoAsset = "/images/logo_tu_van.png", SortOrder = 32 },
            new BoardMember { Username = "Lão Nông", GroupLevel = "Ban tư vấn", RankBadge = "Tư Vấn", PrimaryGroup = "Ban tư vấn", NameColor = "#FFA726", PrimaryGroupColor = "#FFA726", ManagedCategories = "-", ManagedTopics = "-", ManagementPermission = "Tư vấn & Hỗ trợ thành viên", RibbonAsset = "/images/ribbon_tu_van.png", LogoAsset = "/images/logo_tu_van.png", SortOrder = 33 },
            new BoardMember { Username = "phonglan", GroupLevel = "Ban tư vấn", RankBadge = "Tư Vấn", PrimaryGroup = "Ban tư vấn", NameColor = "#FFA726", PrimaryGroupColor = "#FFA726", ManagedCategories = "-", ManagedTopics = "-", ManagementPermission = "Tư vấn & Giải đáp học thuật", RibbonAsset = "/images/ribbon_tu_van.png", LogoAsset = "/images/logo_tu_van.png", SortOrder = 34 },
            new BoardMember { Username = "Quang lan", GroupLevel = "Ban tư vấn", RankBadge = "Tư Vấn", PrimaryGroup = "Ban tư vấn", NameColor = "#FFA726", PrimaryGroupColor = "#FFA726", ManagedCategories = "-", ManagedTopics = "-", ManagementPermission = "Tư vấn & Hướng dẫn luận giải", RibbonAsset = "/images/ribbon_tu_van.png", LogoAsset = "/images/logo_tu_van.png", SortOrder = 35 },
            new BoardMember { Username = "QuangMuongThuy", GroupLevel = "Ban tư vấn", RankBadge = "Tư Vấn", PrimaryGroup = "Ban tư vấn", NameColor = "#FFA726", PrimaryGroupColor = "#FFA726", ManagedCategories = "-", ManagedTopics = "-", ManagementPermission = "Tư vấn & Luận giải chuyên môn", RibbonAsset = "/images/ribbon_tu_van.png", LogoAsset = "/images/logo_tu_van.png", SortOrder = 36 },
            new BoardMember { Username = "TRƯỜNG GIANG", GroupLevel = "Ban tư vấn", RankBadge = "Tư Vấn", PrimaryGroup = "Ban tư vấn", NameColor = "#FFA726", PrimaryGroupColor = "#FFA726", ManagedCategories = "-", ManagedTopics = "-", ManagementPermission = "Tư vấn & Trả lời diễn đàn", RibbonAsset = "/images/ribbon_tu_van.png", LogoAsset = "/images/logo_tu_van.png", SortOrder = 37 }
        };
        db.BoardMembers.AddRange(seededBoard);
        db.SaveChanges();
        Console.WriteLine("[SEED] -> Da nap 20 thanh vien Ban Quan Tri voi 7 cot phan quyen day du!");
    }

    // Auto-migrate MasterProfiles & Users for Task 3 (Hình 3, 5, 6, 7, 8, 9)
    var dangViTitles = new[] {
        "Nhất Đẳng", "Nhị Đẳng", "Tam Đẳng", "Tứ Đẳng", "Ngũ Đẳng",
        "Lục Đẳng", "Thất Đẳng", "Bát Đẳng", "Cửu Đẳng", "Thập Đẳng"
    };
    var allMasters = db.MasterProfiles.ToList();
    bool mastersChanged = false;
    foreach (var m in allMasters)
    {
        int safeStar = Math.Clamp(m.StarLevel > 0 ? m.StarLevel : 1, 1, 10);
        string properTitle = dangViTitles[safeStar - 1];
        string properLogo = $"/images/logo_dai_su_{safeStar}.png";
        if (m.StarLevel != safeStar || m.RankTitle != properTitle || m.TitleLogo != properLogo)
        {
            m.StarLevel = safeStar;
            m.RankTitle = properTitle;
            m.TitleLogo = properLogo;
            mastersChanged = true;
        }
    }
    if (mastersChanged)
    {
        db.SaveChanges();
        Console.WriteLine("[MIGRATION] -> Da tu dong chuan hoa MasterProfiles theo Hinh 8 & Hinh 9!");
    }

    Console.WriteLine("[DATABASE SEEDING] Hoan tat toan bo du lieu Seed!");
    Console.WriteLine("==========================================================");
}

app.UseCors("AllowAll");

app.UseStaticFiles();

app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.MapHub<ForumHub>("/forumhub");
app.MapHub<SystemHub>("/systemhub");

app.Run();
