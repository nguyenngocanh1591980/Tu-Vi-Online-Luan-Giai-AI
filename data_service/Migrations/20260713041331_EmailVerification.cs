using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace data_service.Migrations
{
    /// <inheritdoc />
    public partial class EmailVerification : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "VerificationToken",
                table: "Users",
                newName: "EmailVerificationToken");

            migrationBuilder.RenameColumn(
                name: "IsEmailConfirmed",
                table: "Users",
                newName: "IsEmailVerified");

            migrationBuilder.AddColumn<DateTime>(
                name: "EmailVerificationExpiry",
                table: "Users",
                type: "timestamp with time zone",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "EmailVerificationExpiry",
                table: "Users");

            migrationBuilder.RenameColumn(
                name: "IsEmailVerified",
                table: "Users",
                newName: "IsEmailConfirmed");

            migrationBuilder.RenameColumn(
                name: "EmailVerificationToken",
                table: "Users",
                newName: "VerificationToken");
        }
    }
}
