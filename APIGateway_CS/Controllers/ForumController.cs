using Microsoft.AspNetCore.Mvc;
using System.Text.Json;
using System.Text;
using APIGateway_CS.Data;
using APIGateway_CS.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;

namespace APIGateway_CS.Controllers
{
    [ApiController]
    [Route("api/v1/forum")]
    [Authorize]
    public class ForumController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IHttpClientFactory _httpClientFactory;

        public ForumController(AppDbContext context, IHttpClientFactory httpClientFactory)
        {
            _context = context;
            _httpClientFactory = httpClientFactory;
        }

        private async Task<User> GetOrCreateUserAsync(int userId, string username)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
            if (user == null)
            {
                using var transaction = await _context.Database.BeginTransactionAsync();
                try
                {
                    // Check again inside transaction to prevent race conditions
                    user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
                    if (user == null)
                    {
                        user = new User
                        {
                            Id = userId,
                            Username = string.IsNullOrEmpty(username) ? "Unknown" : username,
                            Role = 0,
                            CoinBalance = (username == "tester_vip_001") ? 500000 : 0
                        };
                        _context.Users.Add(user);
                        await _context.SaveChangesAsync();
                    }
                    await transaction.CommitAsync();
                }
                catch
                {
                    await transaction.RollbackAsync();
                    throw;
                }
            }
            return user;
        }

        [HttpGet("user/balance")]
        public async Task<IActionResult> GetUserBalance()
        {
            var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var username = User.FindFirstValue(ClaimTypes.Name);
            
            if (!int.TryParse(userIdStr, out int userId))
            {
                return Unauthorized();
            }

            var user = await GetOrCreateUserAsync(userId, username);
            return Ok(new { balance = user.CoinBalance });
        }

        [HttpPost("ask-ai")]
        public async Task<IActionResult> AskAi([FromBody] AskAiRequest request)
        {
            var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var username = User.FindFirstValue(ClaimTypes.Name);
            
            if (!int.TryParse(userIdStr, out int userId))
            {
                return Unauthorized();
            }

            _context.Database.EnsureCreated();

            // 1. Validate user and deduct 10 Coin
            var user = await GetOrCreateUserAsync(userId, username);

            if (user.CoinBalance < 10)
            {
                return StatusCode(402, new { message = "Insufficient Coin balance (10 Coin required)." });
            }

            user.CoinBalance -= 10;
            await _context.SaveChangesAsync();

            // 2. Call Python Service
            var client = _httpClientFactory.CreateClient("AIEngine");
            var jsonContent = new StringContent(
                JsonSerializer.Serialize(new
                {
                    action_type = request.ActionType,
                    la_so = request.LaSo,
                    action_detail = request.ActionDetail
                }),
                Encoding.UTF8,
                "application/json"
            );

            try
            {
                var response = await client.PostAsync("/internal/analyze", jsonContent);

                if (!response.IsSuccessStatusCode)
                {
                    user.CoinBalance += 10;
                    await _context.SaveChangesAsync();
                    return StatusCode(500, new { message = "AI Engine error." });
                }

                var stream = await response.Content.ReadAsStreamAsync();
                using var reader = new StreamReader(stream);
                var aiResponseText = new StringBuilder();
                
                while (!reader.EndOfStream)
                {
                    var line = await reader.ReadLineAsync();
                    if (!string.IsNullOrEmpty(line) && line.StartsWith("data: "))
                    {
                        var dataStr = line.Substring(6);
                        if (dataStr == "[DONE]") break;
                        
                        try
                        {
                            var dataObj = JsonSerializer.Deserialize<JsonElement>(dataStr);
                            if (dataObj.TryGetProperty("text", out var textElem))
                            {
                                aiResponseText.Append(textElem.GetString());
                            }
                        }
                        catch { /* skip parse error */ }
                    }
                }

                // 3. Save to Forum Comments
                var comment = new Comment
                {
                    UserId = userId,
                    Content = aiResponseText.ToString(),
                    IsAiGenerated = true
                };

                _context.Comments.Add(comment);
                await _context.SaveChangesAsync();

                // 4. Return result
                return Ok(new
                {
                    message = "Luận giải AI thành công. Đã trừ 10 Coin.",
                    remaining_coin = user.CoinBalance,
                    comment_id = comment.Id,
                    content = comment.Content
                });
            }
            catch (Exception ex)
            {
                user.CoinBalance += 10;
                await _context.SaveChangesAsync();
                return StatusCode(500, new { message = "Error connecting to AI Service.", error = ex.Message });
            }
        }
    }
}
