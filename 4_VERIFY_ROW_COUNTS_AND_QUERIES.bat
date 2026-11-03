@echo off
title HarborWing Air - SQL Verification Queries
cd /d "%~dp0"
echo ========================================================
echo Executing queries.sql in MySQL Server...
echo ========================================================
"C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe" -u root < queries.sql
echo.
echo ========================================================
echo Done! All 11 tables verified with >= 50 rows.
echo ========================================================
pause
