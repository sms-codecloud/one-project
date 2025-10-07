using Microsoft.EntityFrameworkCore;
using StudentApi.Data;

var builder = WebApplication.CreateBuilder(args);

// Connection string from appsettings.json -> ConnectionStrings:Default
var connStr = builder.Configuration.GetConnectionString("Default") 
              ?? "Server=127.0.0.1;Port=3306;Database=StudentDb;User=student_user;Password=ChangeMe!234;TreatTinyAsBoolean=false;SslMode=None";

builder.Services.AddDbContext<AppDbContext>(options =>
{
    // Specify MySQL server version explicitly (8.0); avoids AutoDetect needing a live DB during build
    options.UseMySql(connStr, new MySqlServerVersion(new Version(8, 0, 0)));
});

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddCors(o =>
{
    o.AddDefaultPolicy(p => p.AllowAnyHeader().AllowAnyMethod().AllowAnyOrigin());
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors();
app.UseHttpsRedirection();
app.MapControllers();

app.Run();
