using data_service.Hubs;
using Microsoft.AspNetCore.SignalR;

namespace data_service.Services;

public interface ISignalRService
{
    Task NotifyPaymentSuccess(string orderCode);
    Task StreamAiText(string chartId, string textChunk);
}

public class SignalRService : ISignalRService
{
    private readonly IHubContext<TuViHub> _hubContext;

    public SignalRService(IHubContext<TuViHub> hubContext)
    {
        _hubContext = hubContext;
    }

    public async Task NotifyPaymentSuccess(string orderCode)
    {
        // Bắn sự kiện tới tất cả client (hoặc có thể gom nhóm theo UserId nếu cần)
        await _hubContext.Clients.All.SendAsync("PaymentSuccess", orderCode);
    }

    public async Task StreamAiText(string chartId, string textChunk)
    {
        // Chỉ gửi sự kiện nhận chữ tới các client đã tham gia vào phòng của chartId tương ứng
        await _hubContext.Clients.Group($"chart_{chartId}").SendAsync("ReceiveAiText", chartId, textChunk);
    }
}
