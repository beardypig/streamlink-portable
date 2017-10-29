goto="Streamlink.Init" /* input + quality dialogs and hidecmd launcher
:: save as Streamlink.bat in Streamlink folder, can be called using [Win+R] Run-menu after first launch, enter:
:: streamlink                          = with no parameters will show stream name input-dialog 
:: streamlink esl_dota2                = with just the url or twitch stream name will show quality choice-dialog  
:: streamlink twitch.tv/esl_dota2 720p = with both url or twitch stream name and quality will launch video player directly 
:"Streamlink.Batch"
rem set "TWITCH_OAUTH_TOKEN=--twitch-oauth-token YourTwitchOauthToken" 
set "CONFIG=--config streamlinkrc %TWITCH_OAUTH_TOKEN%" 
set "RTMPDUMP=--rtmp-rtmpdump rtmpdump\rtmpdump.exe"
set "FFMPEG=--ffmpeg-ffmpeg ffmpeg\ffmpeg.exe"
set "STREAMLINK=python\python.exe streamlink-script.py %FFMPEG% %RTMPDUMP% %CONFIG%"
::
for /f "tokens=1,2,3* delims= " %%T in ("%*") do set "URL=%%~U" & set "STREAM=%%~V"
if not defined URL echo  Input empty, insert url & call :input "STREAMLINK: Insert url" "OK" URL
if not defined URL ( echo  [X] No stream url & timeout /t 4 & exit/b ) else echo  "%URL%" - selecting quality, please wait..
if "%URL:/=%"=="%URL%" echo  Input not complete url, assume "twitch.tv/%URL%" & set "URL=http://twitch.tv/%URL%" 
if /i "%URL:+chat=%"=="%URL%" ( set "OPEN_CHAT=" ) else set "URL=%URL:+chat=%" & set "OPEN_CHAT=1"
if defined OPEN_CHAT start %URL%/chat
set "STREAMLINK_LIST=%STREAMLINK% "%URL%" ^| find.exe /i "Available" 2^>nul" & set "LIST=" 
if not defined STREAM for /f "usebackq tokens=2* delims=:" %%A in (`%STREAMLINK_LIST%`) do set "LIST=%%A" 
if defined LIST call set "LIST=%%LIST:(=,%%" &call set "LIST=%%LIST:)=%%" &call set "LIST=%%LIST: =%%" 
if defined LIST echo  Available streams: %LIST% & call :choice "%URL%" "%LIST%" STREAM
if defined LIST if not defined STREAM set "STREAMLINK=echo  [X] No choice selected & rem"
%STREAMLINK% "%URL%" "%STREAM%,720p,480p,best"
if "%TSTPATH%"=="%path%" ( reg add HKEY_CURRENT_USER\Environment /v PATH /t REG_SZ /f /d "%path%;%~dp0;" >nul 2>nul &setx OS %OS% )
taskkill /t /f /im mshta.exe >nul 2>nul & exit/b 
::----------------------------------------------------------------------------------------------------------------------------------
:"Streamlink.Utils"
:input %1:title %2:button %3:output_variable                                      ||:example: call :input "Enter stream" "OK" result
setlocal & call :_header "%~1" input 
set "input=%input%<div><input class='button edit' name='in' type='text'><button id='ok' class='button ok'>%~2</button></div></body>" 
for /f "usebackq tokens=* delims=" %%# in (`mshta "%input%"`) do set "input_var=%%#"
endlocal & call set "%~3=%input_var%" & exit /b                                                    
:choice %1:title %2:options %3:output_variable                                  ||:example: call :choice Choose "op1,op2,op3" result
setlocal & call :_header "%~1" choice 
set "choice=%choice% <div id='buttons' class='content'/><input type='hidden' name='options' value='%~2'></body>" 
for /f "usebackq tokens=* delims=" %%# in (`mshta "%choice%"`) do set "choice_var=%%#"
endlocal & call set "%~3=%choice_var%" & exit /b                                                    
:_header %1:title %2:type["input" or "choice"]                                    ||:i used internally by input and choice functions
setlocal & set "h=about:<title>%~1</title><head><hta:application innerborder='no' sysmenu='yes' scroll='no'><style>body {" 
set "h=%h% background-color:#17141F;} .button {background-color:#7D5BBE;border:0.1em solid #392E5C;color:white;padding:0.1em 0.1em;"
set "h=%h% text-align:center;text-decoration:none;display:inline-block;font-size:1em;cursor:pointer;width:99%%;display:block;}"
if "%~2"=="input" set "h=%h% .ok {margin:0 0.1em;padding:0 0;width:18%%;display:inline-block}" 
set "h=%h% .edit {background-color:#392E5C;width:80%%;display:inline-block}</style></head>"
set "h=%h% <body onload='%~2()'><script language='javascript' src='file://%~f0'></script>"
endlocal & set "%~2=%h%" & exit /b                                                    
::----------------------------------------------------------------------------------------------------------------------------------
:"Streamlink.Init" Hybrid initialization with self-restart and HideCmd - script uses mshta windows instead
@echo off & setlocal & chcp 65001 >NUL & set "PYTHONIOENCODING=cp65001" & pushd "%~dp0" & call set "TSTPATH=%%path:%~dp0=%%"
@if not "%1"=="init" ( wscript //nologo /E:JScript "%~f0" HideCmd "init %*" & exit/b ) else goto="Streamlink.Batch"    
::----------------------------------------------------------------------------------------------------------------------------------
:"Streamlink.JScript" */
function input(){
  window.onerror = function(){ close(); }; var input = document.getElementById('in'), ok = document.getElementById('ok');
  window.moveTo(parseInt(window.parent.screen.availWidth/3),parseInt(window.parent.screen.availHeight/6));window.resizeTo(512,128);
  ok.onclick = function() { close(new ActiveXObject('Scripting.FileSystemObject').GetStandardStream(1).Write(input.value)); };  
}
function choice(){
  window.onerror = function(){ close(); }; var opt=document.getElementById('options').value.split(','), wh=(opt.length+1)*64;  
  window.moveTo(parseInt(window.parent.screen.availWidth/3),parseInt(window.parent.screen.availHeight/6));window.resizeTo(512,512);
	var buttons = document.getElementById('buttons'); for (o in opt) {
    var i = document.createElement('button'); i.setAttribute('className', 'button'); i.className='button';
    i.onclick = function() { close(new ActiveXObject('Scripting.FileSystemObject').GetStandardStream(1).Write(this.value)); };
    i.appendChild(document.createTextNode(opt[o])); buttons.appendChild(i); buttons.appendChild(document.createElement('br'));
  }
}
function HideCmd(self, arguments) { WScript.CreateObject('WScript.Shell').Run(self+' '+arguments, 0, 'False') }
if (typeof window!='object' && WSH.Arguments.length>=1 && WSH.Arguments(0)=='HideCmd') HideCmd(WSH.ScriptFullName,WSH.Arguments(1));
// end of hybrid batch script
