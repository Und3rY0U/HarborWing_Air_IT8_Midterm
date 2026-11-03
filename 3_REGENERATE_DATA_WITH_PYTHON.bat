@echo off
title HarborWing Air - Regenerate Synthetic Data
cd /d "%~dp0"
echo ========================================================
echo Running Python Faker Data Generator (seed=42)...
echo ========================================================
"%LOCALAPPDATA%\Programs\Python\Python312\python.exe" generate_data.py
echo.
pause
