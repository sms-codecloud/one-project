using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using StudentApi.Data;
// Alias to be explicit even if another Student appears later
using StudentEntity = StudentApi.Data.Student;

namespace StudentApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class StudentsController : ControllerBase
    {
        private readonly StudentDbContext _db;

        public StudentsController(StudentDbContext db) => _db = db;

        // GET: /api/students
        [HttpGet]
        public async Task<ActionResult<IEnumerable<StudentEntity>>> GetAll()
        {
            var list = await _db.Students
                                .OrderBy(s => s.Id)
                                .ToListAsync();
            return Ok(list);
        }

        // GET: /api/students/5
        [HttpGet("{id:int}")]
        public async Task<ActionResult<StudentEntity>> GetById(int id)
        {
            var item = await _db.Students.FindAsync(id);
            return item is null ? NotFound() : Ok(item);
        }

        // POST: /api/students
        [HttpPost]
        public async Task<ActionResult<StudentEntity>> Create([FromBody] StudentEntity input)
        {
            if (string.IsNullOrWhiteSpace(input.Name) || string.IsNullOrWhiteSpace(input.Email))
                return BadRequest("Name and Email are required.");

            input.Id = 0;                       // ensure insert
            input.RegisteredAt = DateTime.UtcNow;

            _db.Students.Add(input);
            await _db.SaveChangesAsync();

            return CreatedAtAction(nameof(GetById), new { id = input.Id }, input);
        }

        // PUT: /api/students/5
        [HttpPut("{id:int}")]
        public async Task<IActionResult> Update(int id, [FromBody] StudentEntity input)
        {
            var existing = await _db.Students.FindAsync(id);
            if (existing is null) return NotFound();

            if (!string.IsNullOrWhiteSpace(input.Name))  existing.Name  = input.Name;
            if (!string.IsNullOrWhiteSpace(input.Email)) existing.Email = input.Email;

            await _db.SaveChangesAsync();
            return NoContent();
        }

        // DELETE: /api/students/5
        [HttpDelete("{id:int}")]
        public async Task<IActionResult> Delete(int id)
        {
            var existing = await _db.Students.FindAsync(id);
            if (existing is null) return NotFound();

            _db.Students.Remove(existing);
            await _db.SaveChangesAsync();
            return NoContent();
        }
    }
}
