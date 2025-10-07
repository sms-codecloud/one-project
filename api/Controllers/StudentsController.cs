using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using StudentApi.Data;
using StudentApi.Models;

namespace StudentApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class StudentsController : ControllerBase
{
    private readonly AppDbContext _db;
    public StudentsController(AppDbContext db) => _db = db;

    // GET: api/students
    [HttpGet]
    public async Task<ActionResult<IEnumerable<Student>>> GetAll() =>
        await _db.Students.AsNoTracking().ToListAsync();

    // GET: api/students/5
    [HttpGet("{id:int}")]
    public async Task<ActionResult<Student>> GetOne(int id)
    {
        var s = await _db.Students.AsNoTracking().FirstOrDefaultAsync(x => x.Id == id);
        if (s is null) return NotFound();
        return s;
    }

    // POST: api/students
    [HttpPost]
    public async Task<ActionResult<Student>> Create(Student s)
    {
        _db.Students.Add(s);
        await _db.SaveChangesAsync();
        return CreatedAtAction(nameof(GetOne), new { id = s.Id }, s);
    }

    // PUT: api/students/5
    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int id, Student s)
    {
        if (id != s.Id) return BadRequest();
        _db.Entry(s).State = EntityState.Modified;
        try
        {
            await _db.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            if (!await _db.Students.AnyAsync(x => x.Id == id)) return NotFound();
            throw;
        }
        return NoContent();
    }

    // DELETE: api/students/5
    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var s = await _db.Students.FindAsync(id);
        if (s is null) return NotFound();
        _db.Students.Remove(s);
        await _db.SaveChangesAsync();
        return NoContent();
    }
}
