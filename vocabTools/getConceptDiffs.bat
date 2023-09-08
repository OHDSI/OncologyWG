@echo off
SET PGPASSWORD=postgres

echo "Checking differences between dev and prod concept tables..."

psql -U postgres -d vocab -h localhost -p 5432 -c ^
"SELECT * FROM dev.concept EXCEPT SELECT * FROM prod.concept;"

pause