using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace APIGateway_CS.Models
{
    public class User
    {
        [Key]
        public int Id { get; set; }
        public string Username { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Role { get; set; } = "User"; // "Admin", "Super_Admin", "Moderator", "User"
        public int RoleId { get; set; } = 4; // 1: Super_Admin, 2: Admin, 3: Moderator, 4: User
        public int StarLevel { get; set; } = 1; // 1 -> 10
        public string? RankTitle { get; set; } = "Thành viên";
        public bool IsActive { get; set; } = true;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        public int CoinBalance { get; set; } = 100;
        
        public string PasswordHash { get; set; } = string.Empty; // Added for Auth
        
        public string? Badge { get; set; } = "Thành viên - 1 sao";
        public string? BadgeType { get; set; } = "badge_yellow";
        public string? TitleLogo { get; set; } = "/images/logo_thanh_vien_1.png";
        public int PostCount { get; set; } = 0;
        public string? Website { get; set; }
        public DateTime? DateOfBirth { get; set; }
        public string? FromLocation { get; set; }
        public string? PhoneNumber { get; set; }
        public string? SecondaryEmail { get; set; }
        public string? FullName { get; set; }
        public string? Gender { get; set; } = "male";
        public string? BirthPlace { get; set; }
        public int? BirthHour { get; set; } = 21;
        public int? BirthMinute { get; set; } = 45;
        public string? Interests { get; set; }
        public string? Occupation { get; set; }
        public string? Facebook { get; set; }
        public string? Skype { get; set; }
        public string? Twitter { get; set; }
        public string? YouTube { get; set; }
        public string? UserGroups { get; set; } = "Thành viên";
        public string? Signature { get; set; } = "Ánh Dương văn võ ngàn năm tỏa\nPhẩm giá thanh cao rạng núi sông";
    }

    public class Comment
    {
        [Key]
        public int Id { get; set; }
        public int UserId { get; set; }
        public string Content { get; set; } = string.Empty;
        public bool IsAiGenerated { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }

    public class Chart
    {
        [Key]
        public int Id { get; set; }
        public int UserId { get; set; }
        
        [Column(TypeName = "jsonb")]
        public string LaSoData { get; set; } = "{}";
    }

    public class AskAiRequest
    {
        public int UserId { get; set; }
        public int ActionType { get; set; }
        public object LaSo { get; set; } = new object();
        public string? ActionDetail { get; set; }
    }

    public class Category
    {
        [Key]
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Slug { get; set; } = string.Empty;
        public string ReadRoles { get; set; } = "User,Moderator,Admin,Super_Admin";
        public string WriteRoles { get; set; } = "Admin,Super_Admin";
        public bool IsSeed { get; set; } = false;
        public bool IsLocked { get; set; } = false;
    }

    public class Topic
    {
        [Key]
        public int Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
        public string AuthorUsername { get; set; } = string.Empty;
        public int CategoryId { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public bool IsLocked { get; set; } = false;
    }

    public class CategoryPermission
    {
        [Key]
        public int Id { get; set; }
        public int CategoryId { get; set; }
        public string Role { get; set; } = "User";
        public bool CanCreateTopic { get; set; } = true;
        public bool CanReply { get; set; } = true;
        public bool CanEditOwnPost { get; set; } = true;
        public bool CanDeleteOwnPost { get; set; } = true;
    }

    public class MasterProfile
    {
        [Key]
        public int Id { get; set; }
        public int UserId { get; set; }
        public string MasterName { get; set; } = string.Empty;
        public string Specialization { get; set; } = string.Empty;
        public string RevenueShareRatio { get; set; } = "7/3";
        public double MasterShare { get; set; } = 0.7;
        public double PlatformShare { get; set; } = 0.3;
        public bool IsApproved { get; set; } = false;
        public bool IsSeed { get; set; } = false;
        public int StarLevel { get; set; } = 1;
        public string? RankTitle { get; set; } = "Nhất Đẳng";
        public string? Username { get; set; } = string.Empty;
        public string? TitleLogo { get; set; } = "/images/logo_dai_su.png";
        public DateTime JoinDate { get; set; } = DateTime.UtcNow;
        public int OnlineBookingDays { get; set; } = 0;
        public int OfflineBookingDays { get; set; } = 0;
        public int CancelledBookingDays { get; set; } = 0;
        public int TotalBookedClients { get; set; } = 0;
        public decimal WeeklyEarnings { get; set; } = 0;
        public int ThanksCount { get; set; } = 0;
        public bool IsActive { get; set; } = true;
    }

    public class Booking
    {
        [Key]
        public int Id { get; set; }
        public int MasterId { get; set; }
        public int UserId { get; set; }
        public string CustomerName { get; set; } = string.Empty;
        public string MasterName { get; set; } = string.Empty;
        public string Status { get; set; } = "CHỜ XÁC NHẬN"; // "CHỜ XÁC NHẬN", "ĐANG TƯ VẤN", "HOÀN THÀNH", "YÊU CẦU HOÀN TIỀN"
        public decimal Amount { get; set; }
        public string PaymentStatus { get; set; } = "Đã thanh toán"; // "Chờ thanh toán", "Đã thanh toán", "Đã hoàn tiền"
        public string? Reason { get; set; }
        public bool IsSeed { get; set; } = false;
    }

    public class RefundLog
    {
        [Key]
        public int Id { get; set; }
        public int BookingId { get; set; }
        public decimal RefundAmount { get; set; }
        public DateTime ProcessedAt { get; set; } = DateTime.UtcNow;
    }

    public class AstrologyInterpretation
    {
        [Key]
        public int Id { get; set; }
        public string Star { get; set; } = string.Empty;
        public string Palace { get; set; } = string.Empty;
        public string State { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
    }

    public class BoardMember
    {
        [Key]
        public int Id { get; set; }
        public string Username { get; set; } = string.Empty;
        public string GroupLevel { get; set; } = string.Empty; // "Quản trị viên", "Siêu quản lý", "Quản lý", "Điều hành", "Ban tư vấn"
        public string RankBadge { get; set; } = string.Empty;  // "Sáng Lập", "Quản Lý", "Hội Viên", "Điều Hành", "Tư Vấn"
        public string PrimaryGroup { get; set; } = string.Empty;
        public string NameColor { get; set; } = "#FFFFFF";
        public string PrimaryGroupColor { get; set; } = "#EF5350";
        public string ManagedCategories { get; set; } = "Tất cả chuyên mục";
        public string ManagedTopics { get; set; } = "Tất cả chủ đề";
        public string ManagementPermission { get; set; } = "Toàn quyền hệ thống";
        public string RibbonAsset { get; set; } = string.Empty;
        public string LogoAsset { get; set; } = string.Empty;
        public int SortOrder { get; set; } = 0;
    }
}
