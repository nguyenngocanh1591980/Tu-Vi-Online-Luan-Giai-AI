using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace data_service.Migrations
{
    /// <inheritdoc />
    public partial class AddIsInvisibleToUser : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "IsInvisible",
                table: "Users",
                type: "boolean",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IsInvisible",
                table: "Users");
        }
    }
}
