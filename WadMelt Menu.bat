@echo off
rem WadFusion builder menu: check your source WADs before building, build the IPK3, patch an existing one.
rem Run it from the folder that holds wadmelt.exe (or wadmelt.py). Command line shortcuts:
rem     "WadMelt Menu.bat" check     only list what was found
rem     "WadMelt Menu.bat" build     check, then build (asks before it starts)
setlocal EnableDelayedExpansion
cd /d "%~dp0"
title WadMelt builder

set "FOLDERS=wadmelt_folders.txt"
set "WF="
if exist "wadmelt.exe" set WF="%~dp0wadmelt.exe"
if not defined WF if exist "wadmelt.py" (
    where python >nul 2>nul
    if errorlevel 1 (
        echo Python was not found. Install Python 3 from python.org, or use the wadmelt.exe release.
        pause
        exit /b 1
    )
    set "WF=python wadmelt.py"
)
if not defined WF (
    echo Put this file next to wadmelt.exe or wadmelt.py.
    pause
    exit /b 1
)
if not exist "source_wads" mkdir "source_wads"

if /i "%~1"=="check" ( call :check & exit /b !errorlevel! )
if /i "%~1"=="build" ( call :build & exit /b !errorlevel! )

:menu
cls
echo ==========================================================
echo   WadMelt builder
echo ==========================================================
echo.
echo   Source WAD folders searched:
echo     source_wads\  ^(next to this file^)
if exist "%FOLDERS%" (
    for /f "usebackq delims=" %%F in ("%FOLDERS%") do (
        if exist "%%F\" ( echo     %%F ) else ( echo     %%F   ^(not found^) )
    )
)
echo.
echo   1  Check my WADs ^(shows what is found and what is missing^)
echo   2  Build doom_fusion.ipk3
echo   3  Add another folder that holds source WADs
echo   4  Search a folder tree for source WADs
echo   5  Forget the added folders
echo   6  Patch an existing doom_fusion.ipk3 with newer WadMelt files
echo   7  Open source_wads folder
echo   8  Open the last log
echo   9  Download and build the Xtras packs ^(about 440 MB from GitHub^)
echo   Q  Quit
echo.
choice /c 123456789Q /n /m "  Choose: "
set "PICK=%errorlevel%"
if "%PICK%"=="1" ( call :check & pause & goto menu )
if "%PICK%"=="2" ( call :build & pause & goto menu )
if "%PICK%"=="3" ( call :addfolder & goto menu )
if "%PICK%"=="4" ( call :scan & goto menu )
if "%PICK%"=="5" ( call :forget & goto menu )
if "%PICK%"=="6" ( call :patch & pause & goto menu )
if "%PICK%"=="7" ( start "" explorer "%~dp0source_wads" & goto menu )
if "%PICK%"=="8" ( if exist wadmelt.log ( start "" notepad wadmelt.log ) else ( echo No log yet. & pause ) & goto menu )
if "%PICK%"=="9" ( call :xtras & goto menu )
exit /b 0

:folderargs
set "WARGS="
if exist "%FOLDERS%" (
    for /f "usebackq delims=" %%F in ("%FOLDERS%") do (
        if exist "%%F\" set WARGS=!WARGS! -w "%%F"
    )
)
exit /b 0

:check
call :folderargs
echo.
%WF% --check%WARGS%
exit /b %errorlevel%

:build
call :check
if errorlevel 1 (
    echo.
    echo Nothing to build yet. Fix the PROBLEM line above first.
    exit /b 1
)
echo.
echo If the list above looks right, the build starts after you confirm.
echo.
%WF%%WARGS%
exit /b %errorlevel%

:patch
call :folderargs
echo.
%WF% -p%WARGS%
exit /b %errorlevel%

:addfolder
echo.
set "NEWF="
set /p "NEWF=  Folder path (you can drag the folder onto this window): "
if not defined NEWF exit /b 0
set "NEWF=!NEWF:"=!"
if "!NEWF:~-1!"=="\" set "NEWF=!NEWF:~0,-1!"
if not exist "!NEWF!\" (
    echo   That folder does not exist.
    pause
    exit /b 1
)
if exist "%FOLDERS%" (
    findstr /x /i /c:"!NEWF!" "%FOLDERS%" >nul 2>nul
    if not errorlevel 1 (
        echo   Already in the list.
        pause
        exit /b 0
    )
)
>>"%FOLDERS%" echo !NEWF!
echo   Added. Choose 1 to see what it contributes.
pause
exit /b 0

:scan
echo.
set "SCANF="
set /p "SCANF=  Folder to search, for example D:\Games (drag a folder here): "
if not defined SCANF exit /b 0
set "SCANF=!SCANF:"=!"
if "!SCANF:~-1!"=="\" set "SCANF=!SCANF:~0,-1!"
echo.
%WF% --scan "!SCANF!"
echo.
echo   Use option 3 to add the folder you want. Where a WAD appears in two versions, add only the folder
echo   with the version you want, or copy that one file into source_wads\.
pause
exit /b 0

:forget
if exist "%FOLDERS%" del "%FOLDERS%"
echo.
echo   The added folders were forgotten. source_wads\ is still searched.
pause
exit /b 0

:xtras
echo.
if not exist "%~dp0xtras\get_xtras.ps1" (
    echo   The xtras folder is missing next to this file.
    pause
    exit /b 1
)
where pwsh >nul 2>nul
if errorlevel 1 (
    echo   The Xtras setup needs PowerShell 7. Install it with this command, then run this menu again:
    echo       winget install Microsoft.PowerShell
    pause
    exit /b 1
)
echo   This downloads the WadFusion Xtras packs by Someguyman from their GitHub pages ^(about 440 MB^)
echo   and builds the merged pack and the Unofficial pack next to this file. Nothing of theirs is changed.
choice /c YN /n /m "  Continue? [Y/N] "
if errorlevel 2 exit /b 0
pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0xtras\get_xtras.ps1" -OutDir "%~dp0."
pause
exit /b 0
