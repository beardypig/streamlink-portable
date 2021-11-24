@echo off
REM Change the code page for UTF8
chcp 65001 >NUL
set PYTHONIOENCODING=cp65001
"%~dp0\python\python.exe" "%~dp0\streamlink-script.py" --ffmpeg-ffmpeg "%~dp0\ffmpeg\ffmpeg.exe" --config "%~dp0\config" %*
