using Microsoft.AspNetCore.SignalR;
using System.Threading.Tasks;

namespace APIGateway_CS.Hubs
{
    public class ForumHub : Hub
    {
        public async Task JoinCategoryGroup(string categorySlug)
        {
            if (!string.IsNullOrEmpty(categorySlug))
            {
                await Groups.AddToGroupAsync(Context.ConnectionId, $"category_{categorySlug}");
            }
        }

        public async Task LeaveCategoryGroup(string categorySlug)
        {
            if (!string.IsNullOrEmpty(categorySlug))
            {
                await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"category_{categorySlug}");
            }
        }
    }
}
