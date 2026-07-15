using data_service.Endpoints;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using data_service.Services;
using DotNetEnv;

Env.Load(Path.Combine(Directory.GetCurrentDirectory(), "..", ".env"));

var builder = WebApplication.CreateBuilder(args);

// Register services
builder.Services.AddScoped<IEmailService, SmtpEmailService>();
builder.Services.AddSingleton<ISignalRService, SignalRService>();
builder.Services.AddHttpClient<IAiEngineClientService, AiEngineClientService>();

// Add services to the container.
builder.Services.AddControllers();
builder.Services.AddSignalR();
builder.Services.AddOpenApi();

builder.Services.AddRateLimiter(options =>
{
    options.AddPolicy("UserRateLimit", context =>
    {
        var userId = context.User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value ?? "anonymous";
        return System.Threading.RateLimiting.RateLimitPartition.GetFixedWindowLimiter(userId, _ => new System.Threading.RateLimiting.FixedWindowRateLimiterOptions
        {
            PermitLimit = 1,
            Window = TimeSpan.FromSeconds(2),
            QueueProcessingOrder = System.Threading.RateLimiting.QueueProcessingOrder.OldestFirst,
            QueueLimit = 0
        });
    });
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
});

builder.Services.AddDbContext<data_service.Data.AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

var jwtKey = builder.Configuration["JwtSettings:Key"] ?? "super_secret_jwt_key_that_is_long_enough";
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["JwtSettings:Issuer"] ?? "TuvionlineAPI",
            ValidAudience = builder.Configuration["JwtSettings:Audience"] ?? "TuvionlineApp",
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey))
        };
    });
builder.Services.AddAuthorization();

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll",
        policy =>
        {
            policy.SetIsOriginAllowed(origin => true) // Bắt buộc cho SignalR khi dùng Credentials
                  .AllowAnyMethod()
                  .AllowAnyHeader()
                  .AllowCredentials();
        });
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseCors("AllowAll");

// app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();

var summaries = new[]
{
    "Freezing", "Bracing", "Chilly", "Cool", "Mild", "Warm", "Balmy", "Hot", "Sweltering", "Scorching"
};

app.MapGet("/weatherforecast", () =>
{
    var forecast =  Enumerable.Range(1, 5).Select(index =>
        new WeatherForecast
        (
            DateOnly.FromDateTime(DateTime.Now.AddDays(index)),
            Random.Shared.Next(-20, 55),
            summaries[Random.Shared.Next(summaries.Length)]
        ))
        .ToArray();
    return forecast;
})
.WithName("GetWeatherForecast");

app.UseRateLimiter();
app.MapAuthEndpoints(builder.Configuration);
app.MapContractEndpoints();
app.MapHoroscopeEndpoints();
app.MapControllers();
app.MapHub<data_service.Hubs.TuViHub>("/tuvihub");

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<data_service.Data.AppDbContext>();
    db.Database.EnsureCreated();
    if (!db.Users.Any(u => u.Username == "tester_vip_001"))
    {
        db.Users.Add(new data_service.Models.User
        {
            Username = "tester_vip_001",
            Email = "tester@vip.com",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword("123456"),
            IsEmailVerified = true,
            Role = "User"
        });
    }

    var rootAdmin = db.Users.FirstOrDefault(u => u.Username == "admin");
    if (rootAdmin == null)
    {
        db.Users.Add(new data_service.Models.User
        {
            Username = "admin",
            Email = "nguyenngocanh.1591980@gmail.com",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword("Ngocanh@admin1"), // Mật khẩu root admin
            IsEmailVerified = true,
            Role = "Admin"
        });
    }
    else
    {
        // Cơ chế Khóa Bất tử: luôn ép lại Role Admin cho root_admin
        rootAdmin.Role = "Admin";
        rootAdmin.PasswordHash = BCrypt.Net.BCrypt.HashPassword("Ngocanh@admin1");
    }

    db.SaveChanges();
}

app.MapUserEndpoints();

app.Run();

record WeatherForecast(DateOnly Date, int TemperatureC, string? Summary)
{
    public int TemperatureF => 32 + (int)(TemperatureC / 0.5556);
}
