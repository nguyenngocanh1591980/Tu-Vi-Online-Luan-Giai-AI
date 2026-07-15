using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace data_service.Migrations
{
    /// <inheritdoc />
    public partial class AddUniqueConstraintToSavedChart : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_SavedCharts_UserId",
                table: "SavedCharts");

            migrationBuilder.CreateIndex(
                name: "IX_SavedCharts_UserId_ChartName",
                table: "SavedCharts",
                columns: new[] { "UserId", "ChartName" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_SavedCharts_UserId_ChartName",
                table: "SavedCharts");

            migrationBuilder.CreateIndex(
                name: "IX_SavedCharts_UserId",
                table: "SavedCharts",
                column: "UserId");
        }
    }
}
