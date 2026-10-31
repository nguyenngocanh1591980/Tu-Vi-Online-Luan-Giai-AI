using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using APIGateway_CS.Data;
using APIGateway_CS.Models;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;

namespace APIGateway_CS.Controllers
{
    [ApiController]
    [Route("api/v1/[controller]")]
    public class AstrologyController : ControllerBase
    {
        private readonly AppDbContext _context;

        public AstrologyController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet("interpretation")]
        [Authorize(Roles = "Super_Admin,Admin")]
        public async Task<IActionResult> GetInterpretation([FromQuery] string star, [FromQuery] string palace, [FromQuery] string state)
        {
            var interpretation = await _context.AstrologyInterpretations
                .FirstOrDefaultAsync(x => x.Star == star && x.Palace == palace && x.State == state);

            if (interpretation != null)
            {
                return Ok(new { content = interpretation.Content });
            }
            
            return Ok(new { content = "" });
        }

        [HttpPost("interpretation")]
        [Authorize(Roles = "Super_Admin,Admin")]
        public async Task<IActionResult> SaveInterpretation([FromBody] SaveInterpretationDto dto)
        {
            var interpretation = await _context.AstrologyInterpretations
                .FirstOrDefaultAsync(x => x.Star == dto.Star && x.Palace == dto.Palace && x.State == dto.State);

            if (interpretation == null)
            {
                interpretation = new AstrologyInterpretation
                {
                    Star = dto.Star,
                    Palace = dto.Palace,
                    State = dto.State,
                    Content = dto.Content
                };
                _context.AstrologyInterpretations.Add(interpretation);
            }
            else
            {
                interpretation.Content = dto.Content;
            }

            await _context.SaveChangesAsync();
            return Ok(new { success = true });
        }
    }

    public class SaveInterpretationDto
    {
        public string Star { get; set; } = string.Empty;
        public string Palace { get; set; } = string.Empty;
        public string State { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
    }
}
