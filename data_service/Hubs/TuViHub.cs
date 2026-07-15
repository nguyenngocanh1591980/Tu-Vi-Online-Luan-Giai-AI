using Microsoft.AspNetCore.SignalR;

namespace data_service.Hubs;

public class TuViHub : Hub
{
    // Cấu hình Group cho từng lá số (để chỉ gửi text AI cho người đang xem lá số đó)
    public async Task JoinChartGroup(string chartId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"chart_{chartId}");
    }

    public async Task LeaveChartGroup(string chartId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"chart_{chartId}");
    }
}
