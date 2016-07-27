@Echo off
setlocal enabledelayedexpansion

echo.
echo.
echo ########################################################
ECHO #############	                  	################
ECHO #############	Zabbix-Agent-Pwrd	################
ECHO #############	                  	################
echo ########################################################
echo.
echo.
echo ## Current agent setting ##

set conf_file=%~dp0\conf\zabbix_agentd.win.conf
set LOGFILE=c:\\install.log

call :getkey zabbix_server
IF DEFINED Zabbix_server (echo Zabbix Server: %Zabbix_server%)

call :getkey usecomputername
echo  %usecomputername% 
IF "%usecomputername%" equ  "yes" (ECHO Zabbix-Agent hostname: %computername%
set hostname=%computername%
)

call :getkey HostMetadata
IF DEFINED HostMetadata ( 
	if "%HostMetadata%"=="=" (ECHO ..) ELSE (
	echo HostMetadata: %HostMetadata%
	echo HostMetadata=%HostMetadata%>>%conf_file%)
)
echo.
echo.
echo.


rem log 
ECHO  Zabbix_server IP address  %zabbix_server% >>%LOGFILE%
ECHO  Zabbix agent Hostname is %hostname% >>%LOGFILE%
IF DEFINED HostMetadata ( 
	if "%HostMetadata%"=="=" (ECHO ..) ELSE (
	ECHO  Zabbix agent HostMetadata is %HostMetadata% >>%LOGFILE%) 
)
	
rem Input 

echo ## Modify agent setting ##

IF NOT DEFINED hostname (set /p hostname=input zabbix_agent hostname: )

IF NOT DEFINED zabbix_server (set /p zabbix_server=Please input zabbix server address: )
IF "%zabbix_server%"=="=" (set /p zabbix_server=Please input zabbix server address: )
echo %zabbix_server% | findstr /v "^[0-9][0-9][0-9][0-9] [3-9][0-9][0-9] 2[6][0-9] 25[6-9]"  1>nul>2>nul
IF ERRORLEVEL 1 (ECHO  Invalid ip address
exit /B 1 )





for /f "delims=" %%a in ('type "%conf_file%"') do (
  set  str=%%a
  set "str=!str:127.0.0.1=%zabbix_server%!"
  set "str=!str:Windows host=%hostname%!"
  echo !str!>>"%conf_file%"_tmp.txt
)
move "%conf_file%" "%conf_file%"_bak.txt >>%LOGFILE%
move "%conf_file%"_tmp.txt "%conf_file%" >>%LOGFILE%

 
:: 32 bit or 64 bit process detection
IF "%PROCESSOR_ARCHITECTURE%"=="x86" (
  set _processor_architecture=32bit
  goto x86
) ELSE (
  set _processor_architecture=64bit
  goto x64
)
 
:x86
xcopy "%~dp0\bin\win32" c:\zabbix /e /i /y >>%LOGFILE%
copy "%conf_file%" c:\zabbix\zabbix_agentd.conf /y >>%LOGFILE%
IF NOT ERRORLEVEL 0 (ECHO "OCCUR ERROR ,PLEASE VIEW THE INSTALL.LOG AT THIS FOLDER"
EXIT )
sc stop  "Zabbix Agent" >>%LOGFILE%
sc delete  "Zabbix Agent" >>%LOGFILE%
c:\zabbix\zabbix_agentd.exe -c c:\zabbix\zabbix_agentd.conf -i 2>>%LOGFILE% 2>>%LOGFILE% 
IF NOT ERRORLEVEL 0 (ECHO "OCCUR ERROR ,PLEASE VIEW THE INSTALL.LOG AT THIS FOLDER"
EXIT )
c:\zabbix\zabbix_agentd.exe -c c:\zabbix\zabbix_agentd.conf -s 2>>%LOGFILE% 2>>%LOGFILE% 
IF NOT ERRORLEVEL 0 (ECHO "OCCUR ERROR ,PLEASE VIEW THE INSTALL.LOG AT THIS FOLDER"
EXIT )
goto firewall
 
:x64
xcopy "%~dp0\bin\win64" c:\zabbix /e /i /y >>%LOGFILE%
IF NOT ERRORLEVEL 0 (ECHO "OCCUR ERROR ,PLEASE VIEW THE INSTALL.LOG% AT THIS FOLDER"
EXIT )
copy "%conf_file%" c:\zabbix\zabbix_agentd.conf /y >>%LOGFILE%
IF NOT ERRORLEVEL 0 (ECHO "OCCUR ERROR ,PLEASE VIEW THE INSTALL.LOG AT THIS FOLDER"
EXIT )
sc stop  "Zabbix Agent" >>%LOGFILE%
sc delete  "Zabbix Agent" >>%LOGFILE%
c:\zabbix\zabbix_agentd.exe -c c:\zabbix\zabbix_agentd.conf -i 2>>%LOGFILE%
IF NOT ERRORLEVEL 0 (ECHO "OCCUR ERROR ,PLEASE VIEW THE INSTALL.LOG AT THIS FOLDER"
EXIT )
c:\zabbix\zabbix_agentd.exe -c c:\zabbix\zabbix_agentd.conf -s 2>>%LOGFILE%
IF NOT ERRORLEVEL 0 ECHO "OCCUR ERROR ,PLEASE VIEW THE INSTALL.LOG AT THIS FOLDER"
goto firewall
 
:firewall
:: Get windows Version numbers
For /f "tokens=2 delims=[]" %%G in ('ver') Do (set _version=%%G) 
For /f "tokens=2,3,4 delims=. " %%G in ('echo %_version%') Do (set _major=%%G& set _minor=%%H& set _build=%%I) 
Echo Major version: %_major%  Minor Version: %_minor%.%_build% >>%LOGFILE%
 
:: OS detection
IF "%_major%"=="5" (
  IF "%_minor%"=="0" Echo OS details: Windows 2000 [%_processor_architecture%] >>%LOGFILE%
  IF "%_minor%"=="1" Echo OS details: Windows XP [%_processor_architecture%] >>%LOGFILE%
  IF "%_minor%"=="2" IF "%_processor_architecture%"=="32bit" Echo OS details: Windows 2003 [%_processor_architecture%] >>%LOGFILE%
  IF "%_minor%"=="2" IF "%_processor_architecture%"=="64bit" Echo OS details: Windows 2003 or XP 64 bit [%_processor_architecture%] >>%LOGFILE%
  netsh firewall delete portopening protocol=tcp port=10050 >>%LOGFILE%
  netsh firewall add portopening protocol=tcp port=10050 name=zabbix_10050 mode=enable scope=custom addresses=%zabbix_server% >>%LOGFILE%
) ELSE IF "%_major%"=="6" (
  IF "%_minor%"=="0" Echo OS details: Windows Vista or Windows 2008 [%_processor_architecture%] >>%LOGFILE%
  IF "%_minor%"=="1" Echo OS details: Windows 7 or Windows 2008 R2 [%_processor_architecture%] >>%LOGFILE%
  IF "%_minor%"=="2" Echo OS details: Windows 8 or Windows Server 2012 [%_processor_architecture%] >>%LOGFILE%
  IF "%_minor%"=="3" Echo OS details: Windows 8.1 or Windows Server 2012 R2 [%_processor_architecture%] >>%LOGFILE%
  IF "%_minor%"=="4" Echo OS details: Windows 10  [%_processor_architecture%] >>%LOGFILE%
  netsh advfirewall firewall delete rule name="zabbix_10050" >>%LOGFILE%
  netsh advfirewall firewall add rule name="zabbix_10050" protocol=TCP dir=in localport=10050 action=allow remoteip=%zabbix_server% >>%LOGFILE%
  IF NOT ERRORLEVEL 0 (ECHO "OCCUR ERROR ,PLEASE VIEW THE INSTALL.LOG AT THIS FOLDER"
EXIT )
)
ECHO INSTALL SUCCESS.
 
pause
GOTO:EOF


:getkey

:: Read variables from command line
SET INIFile=install.ini
SET INISection=option
SET INIKey=%1
SET INIValue=


:: Reset temporary variables
SET SectOK=0
SET SectFound=0
SET KeyFound=0

:: Search the INI file line by line
FOR /F "tokens=* delims=" %%A IN ('TYPE %INIFile%') DO CALL :ParseINI "%%A"

:: Display the result
ECHO.
IF NOT %SectFound%==1 (
    ECHO INI section not found
    EXIT /B 1
) ELSE (
    IF NOT %KeyFound%==1 (
        ECHO INI key not found
        EXIT /B 2
    ) ELSE (
        IF NOT DEFINED INIValue (
            ECHO Value not defined
            EXIT /B 3
			)
        )
    )
)

SET %INIKey%=%INIValue%
GOTO:EOF

:ParseINI
IF "%SectFound%"=="1" IF "%KeyFound%"=="1" GOTO:EOF
SET Line="%~1"

ECHO.%Line%| FIND /I "[%INISection%]" >NUL
IF NOT ERRORLEVEL 1 (
    SET SectOK=1
    SET SectFound=1
    GOTO:EOF
)
:: Check if this line is a different section header
IF "%Line:~1,1%"=="[" SET SectOK=0
IF %SectOK%==0 GOTO:EOF

:: Parse any "key=value" line
FOR /F "tokens=1* delims==" %%a IN ('ECHO.%Line%') DO (
    SET Key=%%a^"
    SET Value=^"%%b
)

SET Value=%Value:"=%
:: Remove quotes
SET Key=%Key:"=%
:: Remove tabs
SET Value=%Value:   =%
SET Key=%Key:   =%
:: Remove leading spaces
FOR /F "tokens=* delims= " %%A IN ("%Key%")   DO SET Key=%%A
FOR /F "tokens=* delims= " %%A IN ("%Value%") DO SET Value=%%A
:: Remove trailing spaces
FOR /L %%A in (1,1,32) do if "!Key:~-1!"==" " set Key=!Key:~0,-1!
FOR /L %%A in (1,1,32) do if "!Value:~-1!"==" " set Value=!Value:~0,-1!

:: Now check if the key matches the required key
IF /I "%Key%"=="%INIKey%" (
    SET INIValue=%Value%
    SET KeyFound=1
)

:: End of ParseINI subroutine
GOTO:EOF
exit /b 0