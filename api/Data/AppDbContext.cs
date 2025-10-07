using Microsoft.EntityFrameworkCore;
using StudentApi.Models;

namespace StudentApi.Data;
public class AppDbContext : DbContext {
    public AppDbContext(DbContextOptions<AppDbContext> opt) : base(opt) { }
    public DbSet<Student> Students => Set<Student>();
}
