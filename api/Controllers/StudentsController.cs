using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using StudentApi.Data;
using StudentEntity = StudentApi.Data.Student;
using StudentDto     = StudentApi.Models.Student;

namespace StudentApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class StudentsController : ControllerBase
{
    private readonly AppDbContext _db;
    public StudentsController(AppDbContext db) => _db = db;

    [HttpGet]
    public async Task<ActionResult<IEnumerable<StudentDto>>> GetAll()
    {
        var entities = await _db.Students.AsNoTracking().ToListAsync();
        var dtos = entities.Select(e => new StudentDto
        {
            Id = e.Id,
            Name = e.Name,
            Age = e.Age,
            Email = e.Email
        });
        return Ok(dtos);
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<StudentDto>> GetById(int id)
    {
        var e = await _db.Students.AsNoTracking().FirstOrDefaultAsync(x => x.Id == id);
        if (e is null) return NotFound();
        return new StudentDto { Id = e.Id, Name = e.Name, Age = e.Age, Email = e.Email };
    }

    [HttpPost]
    public async Task<ActionResult<StudentDto>> Create(StudentDto dto)
    {
        var e = new StudentEntity { Name = dto.Name, Age = dto.Age, Email = dto.Email };
        _db.Students.Add(e);
        await _db.SaveChangesAsync();
        dto.Id = e.Id;
        return CreatedAtAction(nameof(GetById), new { id = e.Id }, dto);
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int id, StudentDto dto)
    {
        var e = await _db.Students.FirstOrDefaultAsync(x => x.Id == id);
        if (e is null) return NotFound();
        e.Name = dto.Name;
        e.Age = dto.Age;
        e.Email = dto.Email;
        await _db.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var e = await _db.Students.FirstOrDefaultAsync(x => x.Id == id);
        if (e is null) return NotFound();
        _db.Students.Remove(e);
        await _db.SaveChangesAsync();
        return NoContent();
    }
}
