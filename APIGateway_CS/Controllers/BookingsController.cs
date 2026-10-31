using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using APIGateway_CS.Data;
using APIGateway_CS.Models;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;

namespace APIGateway_CS.Controllers
{
    [ApiController]
    [Route("api/v1/[controller]")]
    public class BookingsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public BookingsController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        [Authorize(Roles = "Super_Admin,Admin")]
        public async Task<IActionResult> GetBookings()
        {
            var bookings = await _context.Bookings.ToListAsync();
            
            // Generate some dummy data if empty for testing the Kanban board
            if (bookings.Count == 0)
            {
                bookings = new List<Booking>
                {
                    new Booking { Id = 102, MasterId = 1, UserId = 2, CustomerName = "Nguyen A", MasterName = "Thiên Cơ", Amount = 500000, Status = "CHỜ XÁC NHẬN", PaymentStatus = "Đã thanh toán" },
                    new Booking { Id = 99, MasterId = 1, UserId = 3, CustomerName = "Le B", MasterName = "Thiên Cơ", Amount = 1000000, Status = "ĐANG TƯ VẤN", PaymentStatus = "Đã thanh toán" },
                    new Booking { Id = 50, MasterId = 2, UserId = 4, CustomerName = "Tran C", MasterName = "Thái Ất", Amount = 300000, Status = "HOÀN THÀNH", PaymentStatus = "Đã thanh toán" },
                    new Booking { Id = 88, MasterId = 3, UserId = 5, CustomerName = "Pham D", MasterName = "Lý Số", Amount = 800000, Status = "YÊU CẦU HOÀN TIỀN", PaymentStatus = "Đã thanh toán", Reason = "Thầy bận" }
                };
                _context.Bookings.AddRange(bookings);
                await _context.SaveChangesAsync();
            }

            return Ok(bookings);
        }

        [HttpPut("{id}/status")]
        [Authorize(Roles = "Super_Admin,Admin")]
        public async Task<IActionResult> UpdateStatus(int id, [FromBody] UpdateStatusDto dto)
        {
            var booking = await _context.Bookings.FindAsync(id);
            if (booking == null) return NotFound();

            booking.Status = dto.Status;
            await _context.SaveChangesAsync();

            return Ok(new { success = true });
        }

        [HttpPut("{id}/refund")]
        [Authorize(Roles = "Super_Admin,Admin")]
        public async Task<IActionResult> ApproveRefund(int id)
        {
            var booking = await _context.Bookings.FindAsync(id);
            if (booking == null) return NotFound();

            if (booking.Status == "YÊU CẦU HOÀN TIỀN" && booking.PaymentStatus != "Đã hoàn tiền")
            {
                booking.PaymentStatus = "Đã hoàn tiền";
                booking.Status = "HOÀN THÀNH"; // or maybe keep as "YÊU CẦU HOÀN TIỀN", but usually refunded is terminal

                var log = new RefundLog
                {
                    BookingId = id,
                    RefundAmount = booking.Amount,
                    ProcessedAt = DateTime.UtcNow
                };
                _context.RefundLogs.Add(log);

                await _context.SaveChangesAsync();
                return Ok(new { success = true });
            }
            
            return BadRequest(new { success = false, message = "Invalid state for refund" });
        }
    }

    public class UpdateStatusDto
    {
        public string Status { get; set; } = string.Empty;
    }
}
