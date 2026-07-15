using System;
using System.Threading.Tasks;
using data_service.Services;
using Microsoft.AspNetCore.Mvc;

namespace data_service.Controllers;

[ApiController]
[Route("api/v1/test-ai")]
public class AiTestController : ControllerBase
{
    private readonly IAiEngineClientService _aiEngineClientService;

    public AiTestController(IAiEngineClientService aiEngineClientService)
    {
        _aiEngineClientService = aiEngineClientService;
    }

    [HttpPost("{chartId}")]
    public IActionResult TriggerStream(string chartId)
    {
        if (!int.TryParse(chartId, out int parsedChartId))
        {
            return BadRequest(new { message = "Mã lá số (chartId) không hợp lệ." });
        }

        // Chạy ngầm tiến trình (không block HTTP response)
        _ = _aiEngineClientService.RequestChartAnalysisAsync("luangiai", parsedChartId);
        
        return Ok(new { message = "Real Stream started with DB data" });
    }
}
