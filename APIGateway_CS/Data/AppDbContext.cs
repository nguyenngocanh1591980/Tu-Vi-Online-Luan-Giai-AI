using APIGateway_CS.Models;
using Microsoft.EntityFrameworkCore;

namespace APIGateway_CS.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

        public DbSet<User> Users { get; set; }
        public DbSet<Comment> Comments { get; set; }
        public DbSet<Chart> Charts { get; set; }
        public DbSet<Topic> Topics { get; set; }
        public DbSet<Category> Categories { get; set; }
        public DbSet<CategoryPermission> CategoryPermissions { get; set; }
        public DbSet<MasterProfile> MasterProfiles { get; set; }
        public DbSet<Booking> Bookings { get; set; }
        public DbSet<RefundLog> RefundLogs { get; set; }
        public DbSet<AstrologyInterpretation> AstrologyInterpretations { get; set; }
        public DbSet<BoardMember> BoardMembers { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);
        }
    }
}
