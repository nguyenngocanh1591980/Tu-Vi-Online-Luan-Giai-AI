using data_service.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Mvc;

namespace data_service.Endpoints;

public static class UserEndpoints
{
    public static void MapUserEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/v1/users").RequireCors("AllowAll");

        group.MapDelete("/{id}", async (int id, [FromHeader(Name = "X-Secret-Passphrase")] string? passphrase, AppDbContext dbContext) =>
        {
            var user = await dbContext.Users.FindAsync(id);
            if (user == null)
            {
                return Results.NotFound("User not found.");
            }

            if (user.Email == "nguyenngocanh.1591980@gmail.com" || user.Username == "admin")
            {
                if (passphrase != "Ngocanh sửa")
                {
                    return Results.Json(new { message = "Hành vi trái phép: Không thể xóa tài khoản Root Admin." }, statusCode: 403);
                }
            }

            dbContext.Users.Remove(user);
            await dbContext.SaveChangesAsync();

            return Results.Ok(new { message = "User deleted successfully." });
        });
    }
}
