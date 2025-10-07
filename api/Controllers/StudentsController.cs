using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using StudentApi.Data;
using StudentApi.Models;

namespace StudentApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class StudentsController : ControllerBase {
    private readonly AppDbContext _db;
    public StudentsController(AppDbContext db) => _db = db;

    [HttpGet] public async Task<ActionResult<IEnumerable<Student>>> Get() => await _db.Students.AsNoTracking().ToListAsync();

    [HttpGet("{id:int}")] public async Task<ActionResult<Student>> GetOne(int id) {
        var s = await _db.Students.FindAsync(id);
        return s is null ? NotFound() : Ok(s);
    }

    [HttpPost] public async Task<ActionResult<Student>> Create(Student s) {
        _db.Students.Add(s);
        await _db.SaveChangesAsync();
        return CreatedAtAction(nameof(GetOne), new { id = s.Id }, s);
    }

    [HttpPut("{id:int}")] public async Task<IActionResult> Update(int id, Student s) {
        if (id != s.Id) return BadRequest();
        _db.Entry(s).State = EntityState.Modified;
        await _db.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("{id:int}")] public async Task<IActionResult> Delete(int id) {
        var s = await _db.Students.FindAsync(id);
        if (s is null) return NotFound();
        _db.Students.Remove(s);
        await _db.SaveChangesAsync();
        return NoContent();
    }
}
