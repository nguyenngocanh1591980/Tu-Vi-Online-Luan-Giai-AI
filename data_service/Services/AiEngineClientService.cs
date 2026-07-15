using System.Text;
using System.Text.Json;
using data_service.Data;
using Microsoft.EntityFrameworkCore;

namespace data_service.Services;

public interface IAiEngineClientService
{
    Task RequestChartAnalysisAsync(string actionType, int chartId);
}

public class AiEngineClientService : IAiEngineClientService
{
    private readonly AppDbContext _dbContext;
    private readonly ISignalRService _signalRService;
    private readonly HttpClient _httpClient;
    private readonly ILogger<AiEngineClientService> _logger;

    public AiEngineClientService(
        AppDbContext dbContext,
        ISignalRService signalRService,
        HttpClient httpClient,
        ILogger<AiEngineClientService> logger)
    {
        _dbContext = dbContext;
        _signalRService = signalRService;
        _httpClient = httpClient;
        _logger = logger;

        // Đọc cổng AI Engine từ biến môi trường
        var pythonPort = Environment.GetEnvironmentVariable("PYTHON_API_PORT") ?? "8000";
        _httpClient.BaseAddress = new Uri($"http://localhost:{pythonPort}");
        
        // Disable timeout for long streaming requests
        _httpClient.Timeout = Timeout.InfiniteTimeSpan;
    }

    public async Task RequestChartAnalysisAsync(string actionType, int chartId)
    {
        try
        {
            // 1. Lấy thông tin lá số và ngôn ngữ người dùng từ Database
            var chart = await _dbContext.SavedCharts
                .Include(c => c.User)
                .FirstOrDefaultAsync(c => c.Id == chartId);

            if (chart == null)
            {
                _logger.LogWarning("Không tìm thấy lá số với ID: {ChartId}", chartId);
                return;
            }

            // 2. Đóng gói Payload
            var payload = new
            {
                action_type = actionType,
                laso_data = chart.ChartJsonData, // JSON nội dung lá số
                target_language = chart.User?.LanguageCode ?? "vi" // Mặc định là Tiếng Việt
            };

            var jsonContent = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json");

            // 3. Gửi Request lấy dữ liệu dạng luồng (Stream) không chờ đợi
            using var request = new HttpRequestMessage(HttpMethod.Post, "/api/v1/analyze/stream");
            request.Content = jsonContent;

            using var response = await _httpClient.SendAsync(request, HttpCompletionOption.ResponseHeadersRead);
            response.EnsureSuccessStatusCode();

            // 4. Xử lý Streaming (Đọc chunk by chunk)
            using var stream = await response.Content.ReadAsStreamAsync();
            using var reader = new StreamReader(stream);

            char[] buffer = new char[128]; // Đọc từng cụm nhỏ (128 ký tự) để stream mượt mà
            int bytesRead;

            while ((bytesRead = await reader.ReadAsync(buffer, 0, buffer.Length)) > 0)
            {
                var chunk = new string(buffer, 0, bytesRead);
                
                // 5. Đẩy lập tức đoạn text vừa nhận xuống Flutter qua SignalR
                await _signalRService.StreamAiText(chartId.ToString(), chunk);
            }

            // 6. Cập nhật cờ hiệu đã có bài luận giải
            chart.HasAiReport = true;
            await _dbContext.SaveChangesAsync();
            
            _logger.LogInformation("Phân tích AI hoàn tất cho lá số {ChartId}.", chartId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi gọi AI Engine cho lá số {ChartId}.", chartId);
            // Gửi thông báo lỗi xuống App
            await _signalRService.StreamAiText(chartId.ToString(), "\n\n[Lỗi: Máy chủ AI hiện đang quá tải hoặc mất kết nối. Vui lòng thử lại sau.]");
        }
    }
}
