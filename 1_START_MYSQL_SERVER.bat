@echo off
title HarborWing Air - MySQL Server 8.4
echo ========================================================
echo Starting MySQL Server on localhost:3306...
echo Database: harborwing_air
echo User: root
echo Password: (none/blank)
echo Data Directory: %USERPROFILE%\mysql_data
echo ========================================================
echo NOTE: Keep this window open while using MySQL or Workbench!
echo.
"C:\Program Files\MySQL\MySQL Server 8.4\bin\mysqld.exe" --datadir="%USERPROFILE%\mysql_data" --console
pause
