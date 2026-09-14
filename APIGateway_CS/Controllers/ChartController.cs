using Microsoft.AspNetCore.Mvc;

namespace APIGateway_CS.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ChartController : ControllerBase
{
    private readonly IWebHostEnvironment _env;

    public ChartController(IWebHostEnvironment env)
    {
        _env = env;
    }

    [HttpPost("upload-image")]
    public async Task<IActionResult> UploadImage(IFormFile file)
    {
        if (file == null || file.Length == 0)
        {
            return BadRequest(new { message = "Không tìm thấy file ảnh" });
        }

        try
        {
            var fileName = $"chart_{Guid.NewGuid():N}.png";
            var uploadPath = Path.Combine(_env.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot"), "charts");

            if (!Directory.Exists(uploadPath))
            {
                Directory.CreateDirectory(uploadPath);
            }

            var filePath = Path.Combine(uploadPath, fileName);

            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await file.CopyToAsync(stream);
            }

            var url = $"{Request.Scheme}://{Request.Host}/charts/{fileName}";

            return Ok(new { url = url });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Lỗi khi lưu file: " + ex.Message });
        }
    }
}
