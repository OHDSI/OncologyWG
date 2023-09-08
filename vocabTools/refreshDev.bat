@echo off
SET PGPASSWORD=postgres
psql -U postgres -d vocab -h localhost -p 5432 -f ./sql/refreshDev.sql
echo dev schema has been refreshed. Press any key to exit
pause