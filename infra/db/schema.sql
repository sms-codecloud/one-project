-- idempotent database objects
CREATE TABLE IF NOT EXISTS Students (
  Id INT NOT NULL AUTO_INCREMENT,
  FirstName VARCHAR(100) NOT NULL,
  LastName  VARCHAR(100) NOT NULL,
  Email     VARCHAR(255) NOT NULL UNIQUE,
  Age       INT NOT NULL,
  CreatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UpdatedAt TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (Id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- sample seed (optional, guard for duplicates)
INSERT INTO Students (FirstName, LastName, Email, Age)
SELECT * FROM (SELECT 'Ada','Lovelace','ada@example.com',28) AS tmp
WHERE NOT EXISTS (SELECT 1 FROM Students WHERE Email='ada@example.com') LIMIT 1;
