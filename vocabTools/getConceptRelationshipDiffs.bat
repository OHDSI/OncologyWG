@echo off
SET PGPASSWORD=postgres

echo "Checking differences between dev and prod concept_relationship tables..."

psql -U postgres -d vocab -h localhost -p 5432 -c ^
"SELECT * FROM dev.concept_relationship EXCEPT SELECT * FROM prod.concept_relationship;"

pause