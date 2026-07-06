using Microsoft.EntityFrameworkCore;

namespace data_service.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
    }

    public DbSet<data_service.Models.User> Users { get; set; }
    public DbSet<data_service.Models.Contract> Contracts { get; set; }
}
