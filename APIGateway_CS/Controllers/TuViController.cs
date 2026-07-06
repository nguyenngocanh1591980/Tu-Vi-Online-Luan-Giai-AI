using System.Text;
using System.Text.Json;
using APIGateway.Models;
using Microsoft.AspNetCore.Mvc;

namespace APIGateway.Controllers;

[ApiController]
[Route("api/[controller]")]
public class TuViController : ControllerBase
{
    private readonly IHttpClientFactory _httpClientFactory;

    public TuViController(IHttpClientFactory httpClientFactory)
    {
        _httpClientFactory = httpClientFactory;
    }

    [HttpPost("btn1-luangiai-12cung")]
    public async Task LuangGiaiCung([FromBody] TuViRequest request)
        => await StreamFromAIEngine(1, request.LaSoJson, request.ActionDetail);

    [HttpPost("btn2-luangiai-daihan")]
    public async Task LuangGiaiDaiHan([FromBody] TuViRequest request)
        => await StreamFromAIEngine(2, request.LaSoJson);

    [HttpPost("btn3-luangiai-chitiet-daihan")]
    public async Task LuangGiaiChiTietDaiHan([FromBody] TuViRequest request)
        => await StreamFromAIEngine(3, request.LaSoJson);

    [HttpPost("btn4-luangiai-nam")]
    public async Task LuangGiaiHanNam([FromBody] TuViRequest request)
        => await StreamFromAIEngine(4, request.LaSoJson);

    [HttpPost("btn5-giaiphap-nam")]
    public async Task GiaiPhapNam([FromBody] TuViRequest request)
        => await StreamFromAIEngine(5, request.LaSoJson);

    private async Task StreamFromAIEngine(int actionType, object laSoJson, string? actionDetail = null)
    {
        Response.Headers.Append("Content-Type", "text/event-stream");
        Response.Headers.Append("Cache-Control", "no-cache");
        Response.Headers.Append("Connection", "keep-alive");

        var client = _httpClientFactory.CreateClient("AIEngine");
        
        var payload = new { action_type = actionType, la_so = laSoJson, action_detail = actionDetail };
        var requestMsg = new HttpRequestMessage(HttpMethod.Post, "/api/ai/analyze")
        {
            Content = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json")
        };

        using var response = await client.SendAsync(requestMsg, HttpCompletionOption.ResponseHeadersRead);
        response.EnsureSuccessStatusCode();

        using var stream = await response.Content.ReadAsStreamAsync();
        using var reader = new StreamReader(stream);
        
        while (!reader.EndOfStream)
        {
            var line = await reader.ReadLineAsync();
            if (!string.IsNullOrWhiteSpace(line))
            {
                await Response.WriteAsync($"{line}\n\n");
                await Response.Body.FlushAsync();
            }
        }
    }
}
