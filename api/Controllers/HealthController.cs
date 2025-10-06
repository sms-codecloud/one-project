using Microsoft.AspNetCore.Mvc;
using MySqlConnector;

namespace StudentApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class HealthController : ControllerBase
    {
        [HttpGet]
        public async Task<IActionResult> Get(CancellationToken ct)
        {
            // Prefer env override (systemd env file on EC2), else appsettings.json
            var conn = Environment.GetEnvironmentVariable("ConnectionStrings__Default")
                       ?? HttpContext.RequestServices
                                     .GetRequiredService<IConfiguration>()
                                     .GetConnectionString("Default");

            // Basic application liveness
            var result = new Dictionary<string, object?>
            {
                ["status"] = "Healthy",
                ["timestamp"] = DateTime.UtcNow
            };

            // Optional DB ping (doesn't fail app health if DB is briefly unavailable)
            try
            {
                using var con = new MySqlConnection(conn);
                await con.OpenAsync(ct);
                using var cmd = new MySqlCommand("SELECT 1;", con);
                var x = await cmd.ExecuteScalarAsync(ct);
                result["database"] = new { status = "Healthy", ping = x };
                return Ok(result);
            }
            catch (Exception ex)
            {
                // Mark as 503 so Jenkins health stage can flag UNSTABLE
                result["database"] = new { status = "Unhealthy", error = ex.Message };
                return StatusCode(StatusCodes.Status503ServiceUnavailable, result);
            }
        }
    }
}
