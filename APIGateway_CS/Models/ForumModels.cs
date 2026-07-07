using System;
using System.ComponentModel.DataAnnotations;

namespace APIGateway_CS.Models
{
    public class User
    {
        [Key]
        public int Id { get; set; }
        public string Username { get; set; } = string.Empty;
        public int Role { get; set; } = 0;
        public int CoinBalance { get; set; }
    }

    public class Comment
    {
        [Key]
        public int Id { get; set; }
        public int UserId { get; set; }
        public string Content { get; set; } = string.Empty;
        public bool IsAiGenerated { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }

    public class Chart
    {
        [Key]
        public int Id { get; set; }
        public int UserId { get; set; }
        
        [System.ComponentModel.DataAnnotations.Schema.Column(TypeName = "jsonb")]
        public string LaSoData { get; set; } = "{}";
    }

    public class AskAiRequest
    {
        public int UserId { get; set; }
        public int ActionType { get; set; }
        public object LaSo { get; set; } = new object();
        public string? ActionDetail { get; set; }
    }
}
