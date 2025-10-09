var builder = WebApplication.CreateBuilder(args);

// pulls from appsettings + ENV overrides (ASPNETCORE_ConnectionStrings__Default)
var connStr = builder.Configuration.GetConnectionString("Default");

builder.Services.AddDbContext<AppDbContext>(opts =>
    opts.UseMySql(connStr, ServerVersion.AutoDetect(connStr)));

builder.Services.AddControllers();
var app = builder.Build();
app.MapControllers();
app.Run();
