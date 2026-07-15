using Microsoft.EntityFrameworkCore;

namespace data_service.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
    }

    public DbSet<data_service.Models.User> Users { get; set; }
    public DbSet<data_service.Models.Contract> Contracts { get; set; }
    public DbSet<data_service.Models.SavedChart> SavedCharts { get; set; }
    public DbSet<data_service.Models.Post> Posts { get; set; }
    public DbSet<data_service.Models.Transaction> Transactions { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Configure relations and delete behaviors
        modelBuilder.Entity<data_service.Models.Post>()
            .HasOne(p => p.User)
            .WithMany(u => u.Posts)
            .HasForeignKey(p => p.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<data_service.Models.Post>()
            .HasOne(p => p.AttachedChart)
            .WithMany(c => c.Posts)
            .HasForeignKey(p => p.AttachedChartId)
            .OnDelete(DeleteBehavior.SetNull);

        modelBuilder.Entity<data_service.Models.Transaction>()
            .HasOne(t => t.User)
            .WithMany(u => u.Transactions)
            .HasForeignKey(t => t.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<data_service.Models.Transaction>()
            .HasOne(t => t.Chart)
            .WithMany(c => c.Transactions)
            .HasForeignKey(t => t.ChartId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<data_service.Models.SavedChart>()
            .HasIndex(h => new { h.UserId, h.ChartName })
            .IsUnique();
    }
}
