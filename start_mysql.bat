@echo off
title HarborWing Air - MySQL Server 8.4
echo ========================================================
echo Starting MySQL Server for HarborWing Air...
echo Data Directory: %USERPROFILE%\mysql_data
echo Port: 3306
echo Root Password: (empty/none)
echo ========================================================
"C:\Program Files\MySQL\MySQL Server 8.4\bin\mysqld.exe" --datadir="%USERPROFILE%\mysql_data" --console
pause
