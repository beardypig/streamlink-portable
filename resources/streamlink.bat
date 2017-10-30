goto="Streamlink.Init" /* 
::     url input + stream choice dialogs and hidecmd launcher
:: Save as Streamlink.bat in Streamlink folder, can be called using [Win+R] Run-menu after first launch
:: streamlink                            = with no parameters shows url input-dialog 
:: streamlink dreamleague                = with just the url or twitch channel name shows stream choice-dialog  
:: streamlink twitch.tv/dreamleague 720p = with both url and stream choice launches video player directly 
:: Detects options like --help or --twitch-oauth-authenticate in url input-dialog and shows cmd window   
:"Streamlink.Batch"
rem set "TWITCH_OAUTH_TOKEN=--twitch-oauth-token YourTwitchOauthToken" 
set "CONFIG=--config streamlinkrc %TWITCH_OAUTH_TOKEN%" 
set "DEFAULT=--default-stream "720p,480p,best""
set "RTMPDUMP=--rtmp-rtmpdump rtmpdump\rtmpdump.exe"
set "PYTHONIOENCODING=cp65001" & chcp 65001 >NUL
set "STREAMLINK=python\python.exe streamlink-script.py %FFMPEG% %RTMPDUMP% %CONFIG%"
set "URL=%~1"
set "STREAM=%~2"
if not defined URL echo  Input empty, insert url & call :input "STREAMLINK: Insert url" "OK" URL
if not defined URL echo  [X] Input empty & timeout /t 4 & exit/b
if /i "%URL:~0,2%"=="--" echo  Input contains options & call :showcmd cmd /k %STREAMLINK% %DEFAULT% %URL% & exit/b
if "%URL: --=%"=="%URL%" ( echo  %URL% loading, wait.. ) else call :showcmd cmd /k %STREAMLINK% %DEFAULT% %URL% & exit/b 
if /i "%URL:~-5%"=="+chat" ( set "URL=%URL:~0,-5%" & set "OPEN_CHAT=1" ) else set "OPEN_CHAT="
if "%URL:/=%"=="%URL%" echo  Input non-url, assume "twitch.tv/%URL%" & set "URL=http://twitch.tv/%URL%" 
if defined OPEN_CHAT start %URL%/chat
set "--QUERYONLY--=--player QUERYONLY ^| find.exe /i "Available streams" 2^>nul" & set "LIST="
if not defined STREAM for /f "usebackq tokens=2* delims=:" %%Q in (`%STREAMLINK% %URL% %--QUERYONLY--%`) do set "LIST=%%Q" 
if defined LIST call set "LIST=%%LIST:(=,%%" &call set "LIST=%%LIST:)=%%" &call set "LIST=%%LIST: =%%" 
if defined LIST echo  Available streams: %LIST% & call :choice "%URL%" "%LIST%" STREAM
if defined LIST if not defined STREAM set "STREAMLINK=echo  [X] No choice selected & rem"
%STREAMLINK% --default-stream "%STREAM%,720p,480p,best" %URL%
call set "TSTPATH=%%path:%~dp0=%%" & rem add Streamlink directory to current user environment without duplicating entries
if "%TSTPATH%"=="%path%" ( reg add HKEY_CURRENT_USER\Environment /v PATH /t REG_SZ /f /d "%path%;%~dp0;" >nul 2>nul &setx OS %OS% )
exit/b
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
:hidecmd %*:arguments
setlocal & set "--arguments--=%*" & wscript //nologo /E:JScript "%~f0" RunCMD --arguments-- 0 & endlocal & exit/b
:showcmd %*:arguments
setlocal & set "--arguments--=%*" & wscript //nologo /E:JScript "%~f0" RunCMD --arguments-- 1 & endlocal & exit/b
::----------------------------------------------------------------------------------------------------------------------------------
:"Streamlink.Init" Hybrid initialization with HideCmd and arguments pass-trough after self-restart 
@echo off & setlocal & pushd "%~dp0" & if "%1"=="--self--restart--" call :"Streamlink.Batch" %--init--% & endlocal & exit/b  
set "--init--=%*" & call :hidecmd "%~f0" --self--restart-- & endlocal & exit/b  
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
function RunCMD(arguments, show) { WScript.CreateObject('WScript.Shell').Run('%'+ arguments +'%', show, 'False'); }
if (typeof window != 'object' && WScript.Arguments(0)=='RunCMD') RunCMD(WScript.Arguments(1), WScript.Arguments(2));
// end of hybrid batch script
