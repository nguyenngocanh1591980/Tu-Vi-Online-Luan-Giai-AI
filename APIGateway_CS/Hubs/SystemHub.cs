using Microsoft.AspNetCore.SignalR;
using System.Threading.Tasks;

namespace APIGateway_CS.Hubs
{
    public class SystemHub : Hub
    {
        public async Task JoinSystemGroup(string groupName)
        {
            if (!string.IsNullOrEmpty(groupName))
            {
                await Groups.AddToGroupAsync(Context.ConnectionId, groupName);
            }
        }

        public async Task LeaveSystemGroup(string groupName)
        {
            if (!string.IsNullOrEmpty(groupName))
            {
                await Groups.RemoveFromGroupAsync(Context.ConnectionId, groupName);
            }
        }
    }
}
