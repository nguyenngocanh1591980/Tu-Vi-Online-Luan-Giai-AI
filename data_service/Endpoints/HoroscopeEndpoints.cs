using data_service.Data;
using data_service.Models;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.DataProtection;
using System.Security.Claims;
using System.Text.Json;
using System.Text.Json.Serialization;
using System;

namespace data_service.Endpoints;

public static class HoroscopeEndpoints
{
    public static void MapHoroscopeEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/v1/horoscope")
            .RequireAuthorization()
            .RequireRateLimiting("UserRateLimit");

        group.MapPost("/create", async (AppDbContext db, ClaimsPrincipal user, HoroscopeCreateRequest req) =>
        {
            var userIdString = user.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdString, out int userId))
            {
                return Results.Unauthorized();
            }

            var newChartName = (req.Name ?? "Chưa đặt tên").Trim();

            bool exists = await db.SavedCharts.AnyAsync(h => 
                h.UserId == userId && 
                h.ChartName.ToLower() == newChartName.ToLower());
            
            if (exists)
            {
                return Results.Conflict(new { message = "Tên lá số này đã tồn tại trong danh sách của bạn. Vui lòng nhập một tên khác để phân biệt." });
            }

            var savedChart = new SavedChart
            {
                UserId = userId,
                ChartName = newChartName,
                Gender = req.Gender ?? "Nam",
                Dob = req.Dob.ToUniversalTime(),
                ChartJsonData = JsonSerializer.Serialize(req.ChartData ?? new object()),
                CreatedAt = DateTime.UtcNow
            };

            db.SavedCharts.Add(savedChart);
            await db.SaveChangesAsync();

            return Results.Created($"/api/v1/horoscope/{savedChart.Id}", savedChart);
        });
        
        group.MapGet("/list", async (AppDbContext db, ClaimsPrincipal user, ILoggerFactory loggerFactory) =>
        {
            var logger = loggerFactory.CreateLogger("HoroscopeEndpoints");
            var userIdString = user.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdString, out int userId))
            {
                return Results.Unauthorized();
            }

            var charts = await db.SavedCharts
                .Where(c => c.UserId == userId)
                .OrderByDescending(c => c.CreatedAt)
                .ToListAsync();

            var role = user.FindFirst(ClaimTypes.Role)?.Value ?? "User";
            if (role == "Admin" || role == "Expert")
            {
                return Results.Ok(charts);
            }
            else
            {
                var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
                var safeCharts = new List<HoroscopeUserViewDTO>();
                foreach (var chart in charts)
                {
                    try
                    {
                        var fullData = JsonSerializer.Deserialize<SafeChartDataDTO>(chart.ChartJsonData, options);
                        var fullDataJson = JsonSerializer.Serialize(fullData, new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase });
                        safeCharts.Add(new HoroscopeUserViewDTO
                        {
                            Id = chart.Id,
                            UserId = chart.UserId,
                            HasAiReport = chart.HasAiReport,
                            ChartName = chart.ChartName,
                            Gender = chart.Gender,
                            Dob = chart.Dob,
                            CreatedAt = chart.CreatedAt,
                            ChartJsonData = fullDataJson
                        });
                    }
                    catch (Exception ex)
                    {
                        logger.LogWarning(ex, "Lỗi phân tích cú pháp ChartJsonData cho HoroscopeId: {HoroscopeId}", chart.Id);
                    }
                }
                return Results.Ok(safeCharts);
            }
        });

        group.MapGet("/{id}", async (int id, AppDbContext db, ClaimsPrincipal user) =>
        {
            var userIdString = user.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdString, out int userId))
            {
                return Results.Unauthorized();
            }

            var chart = await db.SavedCharts.SingleOrDefaultAsync(c => c.Id == id && c.UserId == userId);
            if (chart == null)
            {
                return Results.NotFound();
            }

            var role = user.FindFirst(ClaimTypes.Role)?.Value ?? "User";
            
            if (role == "Admin" || role == "Expert")
            {
                // Trả về toàn bộ dữ liệu (Bao gồm dữ liệu ẩn của Admin)
                return Results.Ok(chart);
            }
            else
            {
                // DTO Whitelist (Data Sanitization)
                var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
                var fullData = JsonSerializer.Deserialize<SafeChartDataDTO>(chart.ChartJsonData, options);
                
                // Trả về DTO sạch sẽ
                var safeDto = new HoroscopeUserViewDTO
                {
                    Id = chart.Id,
                    UserId = chart.UserId,
                    HasAiReport = chart.HasAiReport,
                    ChartName = chart.ChartName,
                    Gender = chart.Gender,
                    Dob = chart.Dob,
                    CreatedAt = chart.CreatedAt,
                    ChartJsonData = JsonSerializer.Serialize(fullData) // Re-serialize safe data
                };
                return Results.Ok(safeDto);
            }
        });

        group.MapPut("/update/{id}", async (int id, AppDbContext db, ClaimsPrincipal user, HoroscopeCreateRequest req) =>
        {
            var userIdString = user.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdString, out int userId))
            {
                return Results.Unauthorized();
            }

            var role = user.FindFirst(ClaimTypes.Role)?.Value ?? "User";
            var chart = await db.SavedCharts.FirstOrDefaultAsync(c => c.Id == id);
            
            if (chart == null)
            {
                return Results.NotFound();
            }

            // Only owner or Admin can update
            if (chart.UserId != userId && role != "Admin")
            {
                return Results.Forbid();
            }

            var newChartName = (req.Name ?? "Chưa đặt tên").Trim();

            // Check if name exists for this user (excluding current chart)
            bool exists = await db.SavedCharts.AnyAsync(h => 
                h.UserId == chart.UserId && 
                h.Id != id &&
                h.ChartName.ToLower() == newChartName.ToLower());
            
            if (exists)
            {
                return Results.Conflict(new { message = "Tên lá số này đã tồn tại trong danh sách của bạn. Vui lòng nhập một tên khác để phân biệt." });
            }

            chart.ChartName = newChartName;
            if (req.Gender != null) chart.Gender = req.Gender;
            if (req.Dob != default) chart.Dob = req.Dob.ToUniversalTime();
            if (req.ChartData != null) chart.ChartJsonData = JsonSerializer.Serialize(req.ChartData);

            await db.SaveChangesAsync();

            return Results.Ok(chart);
        });

        group.MapDelete("/{id}", async (int id, AppDbContext db, ClaimsPrincipal user) =>
        {
            var userIdString = user.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdString, out int userId))
            {
                return Results.Unauthorized();
            }

            var role = user.FindFirst(ClaimTypes.Role)?.Value ?? "User";
            var chart = await db.SavedCharts.FirstOrDefaultAsync(c => c.Id == id);
            
            if (chart == null)
            {
                return Results.NotFound();
            }

            // Only owner or Admin can delete
            if (chart.UserId != userId && role != "Admin")
            {
                return Results.Forbid();
            }

            db.SavedCharts.Remove(chart);
            await db.SaveChangesAsync();

            return Results.Ok(new { message = "Xóa lá số thành công" });
        });

        group.MapGet("/generate-share-token", async (int id, bool hideName, bool hideDob, AppDbContext db, ClaimsPrincipal user, IDataProtectionProvider dataProtectionProvider) =>
        {
            var userIdString = user.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!int.TryParse(userIdString, out int userId)) return Results.Unauthorized();

            var chart = await db.SavedCharts.FirstOrDefaultAsync(c => c.Id == id && c.UserId == userId);
            if (chart == null) return Results.NotFound();

            var protector = dataProtectionProvider.CreateProtector("ChartShare");
            var payload = JsonSerializer.Serialize(new ChartSharePayload { Id = id, HideName = hideName, HideDob = hideDob });
            var token = protector.Protect(payload);
            
            return Results.Ok(new { token });
        });

        app.MapGet("/api/v1/horoscope/public-read", async (string token, AppDbContext db, IDataProtectionProvider dataProtectionProvider) =>
        {
            try
            {
                var protector = dataProtectionProvider.CreateProtector("ChartShare");
                var payload = protector.Unprotect(token);
                
                var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
                var shareData = JsonSerializer.Deserialize<ChartSharePayload>(payload, options);
                
                if (shareData == null) return Results.BadRequest(new { message = "Invalid token payload" });

                var chart = await db.SavedCharts.FirstOrDefaultAsync(c => c.Id == shareData.Id);
                if (chart == null) return Results.NotFound(new { message = "Không tìm thấy lá số" });

                var fullData = JsonSerializer.Deserialize<SafeChartDataDTO>(chart.ChartJsonData, options);
                
                if (fullData != null)
                {
                    if (shareData.HideName)
                    {
                        fullData.Native.Name = "[Tên đã được ẩn]";
                    }
                    if (shareData.HideDob)
                    {
                        fullData.Native.BirthYearStr = "***";
                        fullData.Native.BirthMonthStr = "**";
                        fullData.Native.BirthDayStr = "**";
                        fullData.Native.BirthTimeStr = "**";
                        fullData.Native.LunarMonthStr = "**";
                        fullData.Native.LunarDayStr = "**";
                        fullData.Native.LunarTimeStr = "**";
                        fullData.Native.LunarYear = 0;
                    }
                }

                return Results.Ok(fullData);
            }
            catch
            {
                return Results.BadRequest(new { message = "Invalid or corrupted token" });
            }
        });
    }
}

public class ChartSharePayload
{
    public int Id { get; set; }
    public bool HideName { get; set; }
    public bool HideDob { get; set; }
}

public class HoroscopeUserViewDTO
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public string ChartName { get; set; } = string.Empty;
    public string Gender { get; set; } = string.Empty;
    public DateTime Dob { get; set; }
    public bool HasAiReport { get; set; }
    public DateTime CreatedAt { get; set; }
    public string ChartJsonData { get; set; } = string.Empty;
}

// Whitelist DTOs for safe data transfer
public class SafeChartDataDTO
{
    public SafeNativeInfoDTO Native { get; set; } = new();
    public List<SafePalaceDTO> Palaces { get; set; } = new();
    
    [JsonExtensionData]
    public Dictionary<string, JsonElement>? ExtensionData { get; set; }
}

public class SafeNativeInfoDTO
{
    public string Name { get; set; } = string.Empty;
    public string BirthYearStr { get; set; } = string.Empty;
    public string BirthMonthStr { get; set; } = string.Empty;
    public string BirthDayStr { get; set; } = string.Empty;
    public string BirthTimeStr { get; set; } = string.Empty;
    public string LunarMonthStr { get; set; } = string.Empty;
    public string LunarDayStr { get; set; } = string.Empty;
    public string LunarTimeStr { get; set; } = string.Empty;
    public int LunarYear { get; set; }
    public string Gender { get; set; } = string.Empty;
    public string YinYang { get; set; } = string.Empty;
    public string Element { get; set; } = string.Empty;
    public string Destiny { get; set; } = string.Empty;
    public string LifeRule { get; set; } = string.Empty;
    public string DestinyLord { get; set; } = string.Empty;
    public string BodyLord { get; set; } = string.Empty;
    public string ThanCu { get; set; } = string.Empty;
    public string BoneWeight { get; set; } = string.Empty;
    public string TimeViolation { get; set; } = string.Empty;
    public string ElementMeaning { get; set; } = string.Empty;

    [JsonExtensionData]
    public Dictionary<string, JsonElement>? ExtensionData { get; set; }
}

public class SafePalaceDTO
{
    public string Name { get; set; } = string.Empty;
    public string Branch { get; set; } = string.Empty;
    public string Stem { get; set; } = string.Empty;
    public string Element { get; set; } = string.Empty;
    public int Index { get; set; }
    public string TuanTriet { get; set; } = string.Empty;
    public string DaiHan { get; set; } = string.Empty;
    public string CungChi { get; set; } = string.Empty;
    public string NguHanhCung { get; set; } = string.Empty;
    public string VongNhanSinh { get; set; } = string.Empty;
    public string VongNhanSinhElement { get; set; } = string.Empty;
    public string ThangSinh { get; set; } = string.Empty;
    public List<SafeStarDTO> Stars { get; set; } = new();

    [JsonExtensionData]
    public Dictionary<string, JsonElement>? ExtensionData { get; set; }
}

public class SafeStarDTO
{
    public string Name { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string Element { get; set; } = string.Empty;
    public bool IsMajor { get; set; }
    public bool IsItalic { get; set; }
    public bool IsLeft { get; set; }

    [JsonExtensionData]
    public Dictionary<string, JsonElement>? ExtensionData { get; set; }
}

public class HoroscopeCreateRequest
{
    public string? Name { get; set; }
    public string? Gender { get; set; }
    public DateTime Dob { get; set; }
    public object? ChartData { get; set; }
}
