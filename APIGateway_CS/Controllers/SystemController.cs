using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using APIGateway_CS.Data;
using System.Diagnostics;
using System.Net.Sockets;
using System.Runtime.InteropServices;
using System.Security.Claims;
using System.Data;

namespace APIGateway_CS.Controllers
{
    [ApiController]
    [Route("api/v1/[controller]")]
    [Authorize(Roles = "Super_Admin,Admin")]
    public class SystemController : ControllerBase
    {
        private readonly AppDbContext _context;
        private static readonly DateTime _startTime = DateTime.UtcNow;

        public SystemController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet("status")]
        public async Task<IActionResult> GetSystemStatus()
        {
            // Chốt chặn 4: Chạy song song kiểm tra 4 cổng với CancellationTokenSource Timeout 500ms
            var t5000 = ProbePortAsync("127.0.0.1", 5000, 500);
            var t5169 = ProbePortAsync("127.0.0.1", 5169, 500);
            var t8000 = ProbePortAsync("127.0.0.1", 8000, 500);
            var t5432 = ProbePortAsync("127.0.0.1", 5432, 500);

            await Task.WhenAll(t5000, t5169, t8000, t5432);

            var p5000 = await t5000;
            var p5169 = await t5169;
            var p8000 = await t8000;
            var p5432 = await t5432;

            var uptime = DateTime.UtcNow - _startTime;
            var currentProcess = Process.GetCurrentProcess();
            var workingSetMb = Math.Round((double)currentProcess.WorkingSet64 / (1024 * 1024), 2);
            var privateMemoryMb = Math.Round((double)currentProcess.PrivateMemorySize64 / (1024 * 1024), 2);
            var managedHeapMb = Math.Round((double)GC.GetTotalMemory(false) / (1024 * 1024), 2);

            // Thông tin ổ đĩa chứa dự án
            string driveName = "E:\\";
            double freeSpaceGb = 0;
            double totalSpaceGb = 0;
            double usedDiskPercent = 0;
            try
            {
                var rootPath = Path.GetPathRoot(AppContext.BaseDirectory) ?? "E:\\";
                var driveInfo = new DriveInfo(rootPath);
                if (driveInfo.IsReady)
                {
                    driveName = driveInfo.Name;
                    freeSpaceGb = Math.Round((double)driveInfo.AvailableFreeSpace / (1024 * 1024 * 1024), 2);
                    totalSpaceGb = Math.Round((double)driveInfo.TotalSize / (1024 * 1024 * 1024), 2);
                    if (totalSpaceGb > 0)
                    {
                        usedDiskPercent = Math.Round(((totalSpaceGb - freeSpaceGb) / totalSpaceGb) * 100, 1);
                    }
                }
            }
            catch { }

            // Thông tin ThreadPool
            ThreadPool.GetAvailableThreads(out int availWorkers, out int availIo);
            ThreadPool.GetMaxThreads(out int maxWorkers, out int maxIo);

            // Thông tin Build Time
            var buildTimeVn = _startTime.AddHours(7).ToString("HH:mm:ss dd/MM/yyyy");
            try
            {
                var asmPath = typeof(SystemController).Assembly.Location;
                if (!string.IsNullOrEmpty(asmPath) && System.IO.File.Exists(asmPath))
                {
                    buildTimeVn = System.IO.File.GetLastWriteTimeUtc(asmPath).AddHours(7).ToString("HH:mm:ss dd/MM/yyyy");
                }
            }
            catch { }

            // Thông tin PostgreSQL & Row Counts
            bool canConnectDb = p5432.IsOnline;
            string dbSizePretty = "N/A";
            int activeDbConnections = 0;
            string dbUptimeStr = "N/A";
            long dbUptimeSeconds = 0;
            var tableRowCounts = new Dictionary<string, int>
            {
                ["Users"] = 0,
                ["Categories"] = 0,
                ["MasterProfiles"] = 0,
                ["Bookings"] = 0,
                ["RefundLogs"] = 0,
                ["AstrologyInterpretations"] = 0
            };

            var rbacMatrix = new List<object>();

            if (canConnectDb)
            {
                try
                {
                    tableRowCounts["Users"] = await _context.Users.CountAsync();
                    tableRowCounts["Categories"] = await _context.Categories.CountAsync();
                    tableRowCounts["MasterProfiles"] = await _context.MasterProfiles.CountAsync();
                    tableRowCounts["Bookings"] = await _context.Bookings.CountAsync();
                    tableRowCounts["RefundLogs"] = await _context.RefundLogs.CountAsync();
                    tableRowCounts["AstrologyInterpretations"] = await _context.AstrologyInterpretations.CountAsync();

                    var usersLite = await _context.Users
                        .AsNoTracking()
                        .Select(u => new { Role = u.Role ?? "User", u.IsActive })
                        .ToListAsync();

                    var rolesConfig = new (string Role, string Permissions)[]
                    {
                        ("Super_Admin", "Toàn quyền tối cao (Full System, RBAC, DB, Force GC)"),
                        ("Admin", "Quản trị hệ thống (Quản lý User, Chuyên mục, Đặt lịch, Tử vi)"),
                        ("Moderator", "Điều hành viên (Kiểm duyệt bài viết, Hỗ trợ thành viên)"),
                        ("User", "Thành viên tiêu chuẩn (Đọc/Viết bài, Lập lá số, Đặt lịch)")
                    };

                    foreach (var rc in rolesConfig)
                    {
                        var matched = usersLite.Where(u => u.Role.Equals(rc.Role, StringComparison.OrdinalIgnoreCase)).ToList();
                        rbacMatrix.Add(new
                        {
                            role = rc.Role,
                            total = matched.Count,
                            active = matched.Count(x => x.IsActive),
                            locked = matched.Count(x => !x.IsActive),
                            permissions = rc.Permissions
                        });
                    }

                    var conn = _context.Database.GetDbConnection();
                    if (conn.State != ConnectionState.Open)
                    {
                        await conn.OpenAsync();
                    }
                    using var cmd = conn.CreateCommand();
                    cmd.CommandText = @"
                        SELECT 
                            pg_size_pretty(pg_database_size(current_database())) AS db_size,
                            (SELECT count(*)::int FROM pg_stat_activity WHERE datname = current_database()) AS active_conns,
                            EXTRACT(EPOCH FROM (now() - pg_postmaster_start_time()))::bigint AS db_uptime_sec;";
                    using var reader = await cmd.ExecuteReaderAsync();
                    if (await reader.ReadAsync())
                    {
                        dbSizePretty = reader.IsDBNull(0) ? "N/A" : reader.GetString(0);
                        activeDbConnections = reader.IsDBNull(1) ? 1 : reader.GetInt32(1);
                        dbUptimeSeconds = reader.IsDBNull(2) ? 0 : reader.GetInt64(2);
                        var dbSpan = TimeSpan.FromSeconds(dbUptimeSeconds);
                        dbUptimeStr = $"{(int)dbSpan.TotalHours:D2}h {dbSpan.Minutes:D2}m {dbSpan.Seconds:D2}s";
                    }
                }
                catch { }
            }

            // Thông tin giải mã JWT của Admin đang đăng nhập
            var jwtUsername = User.Identity?.Name ?? User.FindFirstValue(ClaimTypes.Name) ?? "admin";
            var jwtRole = User.FindFirstValue(ClaimTypes.Role) ?? "Super_Admin";
            long nowEpoch = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
            long expEpoch = nowEpoch + 86400;
            long iatEpoch = nowEpoch;

            var expClaim = User.FindFirstValue("exp");
            var iatClaim = User.FindFirstValue("iat");
            if (long.TryParse(expClaim, out long parsedExp)) expEpoch = parsedExp;
            if (long.TryParse(iatClaim, out long parsedIat)) iatEpoch = parsedIat;
            else iatEpoch = expEpoch - 86400;

            long remainingTokenSeconds = Math.Max(0, expEpoch - nowEpoch);
            var issuedAtVn = DateTimeOffset.FromUnixTimeSeconds(iatEpoch).ToOffset(TimeSpan.FromHours(7)).ToString("HH:mm:ss dd/MM/yyyy");
            var expiresAtVn = DateTimeOffset.FromUnixTimeSeconds(expEpoch).ToOffset(TimeSpan.FromHours(7)).ToString("HH:mm:ss dd/MM/yyyy");

            var services = new List<object>
            {
                new { name = "API Gateway", port = 5000, protocol = "HTTP/REST", isOnline = true, status = "Online", latencyMs = p5000.LatencyMs },
                new { name = "Data Service", port = 5169, protocol = "HTTP/REST", isOnline = p5169.IsOnline, status = p5169.IsOnline ? "Online" : "Offline", latencyMs = p5169.LatencyMs },
                new { name = "Python AI Engine", port = 8000, protocol = "HTTP/FastAPI", isOnline = p8000.IsOnline, status = p8000.IsOnline ? "Online" : "Offline", latencyMs = p8000.LatencyMs },
                new { name = "PostgreSQL DB", port = 5432, protocol = "TCP/SQL", isOnline = canConnectDb, status = canConnectDb ? "Connected" : "Disconnected", latencyMs = p5432.LatencyMs },
            };

            var subsystems = new List<object>
            {
                new { name = "Admin Portal (Port 3000)", version = "v1.0.0+1", port = 3000, isOnline = true, isSynced = true },
                new { name = "User App (Frontend)", version = "v1.0.0+1", port = 8080, isOnline = true, isSynced = true },
                new { name = "C# API Gateway (Port 5000)", version = "v1.0.0+1", port = 5000, isOnline = true, isSynced = true },
                new { name = "Python AI Engine (Port 8000)", version = "v1.0.0+1", port = 8000, isOnline = p8000.IsOnline, isSynced = true },
            };

            return Ok(new
            {
                version = "v1.0.0+1 (Release Production)",
                environment = "Production",
                buildTime = buildTimeVn,
                subsystems,
                osVersion = Environment.OSVersion.ToString(),
                hostHardware = new
                {
                    machineName = Environment.MachineName,
                    osDescription = RuntimeInformation.OSDescription,
                    osArchitecture = RuntimeInformation.OSArchitecture.ToString(),
                    processArchitecture = RuntimeInformation.ProcessArchitecture.ToString(),
                    processorCount = Environment.ProcessorCount,
                    driveName,
                    freeSpaceGb,
                    totalSpaceGb,
                    usedDiskPercent,
                    processThreads = currentProcess.Threads.Count,
                    workingSetMb
                },
                runtime = $".NET {Environment.Version}",
                runtimeDetails = new
                {
                    frameworkDescription = RuntimeInformation.FrameworkDescription,
                    activeThreads = ThreadPool.ThreadCount,
                    completedWorkItems = ThreadPool.CompletedWorkItemCount,
                    pendingWorkItems = ThreadPool.PendingWorkItemCount,
                    availableWorkerThreads = availWorkers,
                    maxWorkerThreads = maxWorkers,
                    availableIoThreads = availIo,
                    maxIoThreads = maxIo
                },
                uptime = $"{(int)uptime.TotalHours:D2}h {uptime.Minutes:D2}m {uptime.Seconds:D2}s",
                uptimeSeconds = (long)uptime.TotalSeconds,
                startTimeUtc = _startTime.ToString("yyyy-MM-ddTHH:mm:ssZ"),
                startTimeVn = _startTime.AddHours(7).ToString("HH:mm:ss dd/MM/yyyy") + " (UTC+7)",
                dbUptime = dbUptimeStr,
                dbUptimeSeconds,
                pingTimestamp = DateTime.UtcNow.AddHours(7).ToString("HH:mm:ss.fff"),
                memoryUsage = $"{workingSetMb} MB",
                memoryDetails = new
                {
                    workingSetMb,
                    privateMemoryMb,
                    managedHeapMb,
                    gen0Collections = GC.CollectionCount(0),
                    gen1Collections = GC.CollectionCount(1),
                    gen2Collections = GC.CollectionCount(2)
                },
                databaseName = "TuviAIManagerDB",
                databaseHost = "localhost:5432",
                databaseDetails = new
                {
                    isOnline = canConnectDb,
                    latencyMs = p5432.LatencyMs,
                    databaseSize = dbSizePretty,
                    activeConnections = activeDbConnections,
                    rowCounts = tableRowCounts
                },
                rbacStatus = "Enforced (Super_Admin, Admin, Moderator, User)",
                rbacMatrix,
                securityDetails = new
                {
                    corsPolicy = "AllowAll (Origins: * | Methods: GET, POST, PUT, DELETE | Headers: *)",
                    jwtAlgorithm = "HMAC-SHA256",
                    tokenExpireConfig = "24h (86400s)",
                    username = jwtUsername,
                    role = jwtRole,
                    issuedAt = issuedAtVn,
                    expiresAt = expiresAtVn,
                    remainingSeconds = remainingTokenSeconds,
                    isValid = remainingTokenSeconds > 0
                },
                services
            });
        }

        [HttpPost("gc-collect")]
        public IActionResult ForceGcCollect()
        {
            var beforeProc = Process.GetCurrentProcess();
            var beforeWorkingSetMb = Math.Round((double)beforeProc.WorkingSet64 / (1024 * 1024), 2);
            var beforeManagedMb = Math.Round((double)GC.GetTotalMemory(false) / (1024 * 1024), 2);

            GC.Collect();
            GC.WaitForPendingFinalizers();
            GC.Collect();

            var afterProc = Process.GetCurrentProcess();
            var afterWorkingSetMb = Math.Round((double)afterProc.WorkingSet64 / (1024 * 1024), 2);
            var afterPrivateMb = Math.Round((double)afterProc.PrivateMemorySize64 / (1024 * 1024), 2);
            var afterManagedMb = Math.Round((double)GC.GetTotalMemory(true) / (1024 * 1024), 2);

            return Ok(new
            {
                message = "Đã giải phóng bộ nhớ đệm (Force GC Collect) thành công",
                beforeWorkingSetMb,
                afterWorkingSetMb,
                beforeManagedMb,
                afterManagedMb,
                memoryUsage = $"{afterWorkingSetMb} MB",
                memoryDetails = new
                {
                    workingSetMb = afterWorkingSetMb,
                    privateMemoryMb = afterPrivateMb,
                    managedHeapMb = afterManagedMb,
                    gen0Collections = GC.CollectionCount(0),
                    gen1Collections = GC.CollectionCount(1),
                    gen2Collections = GC.CollectionCount(2)
                }
            });
        }

        private static async Task<(bool IsOnline, long LatencyMs)> ProbePortAsync(string host, int port, int timeoutMs = 500)
        {
            var sw = Stopwatch.StartNew();
            using var cts = new CancellationTokenSource(TimeSpan.FromMilliseconds(timeoutMs));
            try
            {
                using var client = new TcpClient();
                await client.ConnectAsync(host, port, cts.Token);
                sw.Stop();
                return (true, Math.Max(1, sw.ElapsedMilliseconds));
            }
            catch
            {
                sw.Stop();
                return (false, sw.ElapsedMilliseconds);
            }
        }
    }
}
