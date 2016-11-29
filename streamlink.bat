@echo off
pushd %~dp0
"python\python.exe" "streamlink-script.py" %* --config "streamlinkrc"
