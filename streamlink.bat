@echo off
"%~dp0\python\python.exe" "%~dp0\streamlink-script.py" --ffmpeg-ffmpeg "%~dp0\ffmpeg\ffmpeg.exe" --rtmp-rtmpdump "%~dp0\rtmpdump\rtmpdump.exe" --config "%~dp0\streamlinkrc" %*
