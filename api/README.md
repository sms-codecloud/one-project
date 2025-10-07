# StudentApi (.NET 8 + MySQL CRUD)

This is a minimal .NET 8 Web API that performs CRUD for **Student** against MySQL 8.0.
> Note: MySQL 9.4 does not exist as of 2025-10-07. This template targets MySQL 8.x (Pomelo provider).

## Structure
```
one-project/
  global.json
  api/
    StudentApi.csproj
    Program.cs
    appsettings.json
    Properties/launchSettings.json
    Models/Student.cs
    Data/AppDbContext.cs
    Controllers/StudentsController.cs
```

## Quick start
```powershell
cd one-project\api
dotnet restore
dotnet build -c Release
# Create DB table if not using EF migrations:
#   run schema.sql on your MySQL server (or create table manually)

dotnet run
# Swagger UI: https://localhost:7131/swagger  (when running locally)
```

## Database schema (no migrations required)
Create DB and table (manual) or use `schema.sql` included:

```sql
CREATE DATABASE IF NOT EXISTS StudentDb;
CREATE USER IF NOT EXISTS 'student_user'@'%' IDENTIFIED BY 'ChangeMe!234';
GRANT ALL PRIVILEGES ON StudentDb.* TO 'student_user'@'%';
FLUSH PRIVILEGES;

USE StudentDb;
CREATE TABLE IF NOT EXISTS Students (
  Id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  Name VARCHAR(200) NOT NULL,
  Email VARCHAR(200) NOT NULL,
  Age INT NOT NULL
);
```

## Jenkins pipeline notes
- Project root under repo: `api`
- Build: `dotnet restore`, `dotnet build -c Release`
- Publish: `dotnet publish -c Release -o publish`
- Artifact zip: `student-api.zip` made from `publish/`
- S3 key: `api/student-api-$BUILD_NUMBER.zip`

