# Brand-new Student API (.NET 8 + MySQL)

Zero-frills Web API that performs CRUD for **Student** against MySQL 8.x using EF Core + Pomelo.

## Structure
```
api/
  StudentApi.csproj
  Program.cs
  appsettings.json
  Models/Student.cs
  Data/AppDbContext.cs
  Controllers/StudentsController.cs
  schema.sql
```
## Run locally
```powershell
# Set up database quickly
mysql -u root -p < api/schema.sql

cd api
dotnet restore
dotnet build -c Release
dotnet run
# Swagger UI: http://localhost:5000/swagger   (HTTPS also enabled by default mapping)
```
## Jenkins
- Set `PROJECT_REL = api`
- Publish with: `dotnet publish -c Release -o publish`
- Zip `publish/` as `student-api.zip` and upload to S3: `api/student-api-$BUILD_NUMBER.zip`
