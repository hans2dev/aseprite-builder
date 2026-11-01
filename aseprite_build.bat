@echo off
setlocal enabledelayedexpansion

:: =================================================================
:: Aseprite Builder - Windows Batch Script
:: Usage: aseprite_build.bat [version]   (e.g. aseprite_build.bat v1.3.17)
::
:: Requirements:
::   - Visual Studio 2022 (or Build Tools) with "Desktop development with C++"
::     and Windows SDK
::   - CMake 3.16+ and Ninja in PATH   (choco install cmake ninja)
::   - Optional: Inno Setup 6 (installer creation)
:: =================================================================

set "ROOT_DIR=%~dp0workspace"
set "ASEPRITE_DIR=%ROOT_DIR%\aseprite"
set "BUILD_DIR=%ROOT_DIR%\build"
set "SKIA_DIR=%ROOT_DIR%\skia"
set "DIST_DIR=%ROOT_DIR%\dist"
set "FALLBACK_VER=v1.3.17"
set "FALLBACK_SKIA=m124-08a5439a6b"
set "ASE_VER=%~1"

echo =================================================================
echo  Aseprite Builder - Windows
echo =================================================================
echo.

:: -----------------------------------------------------------------
:: [1/7] Pre-flight checks
:: -----------------------------------------------------------------
echo [1/7] Pre-flight checks...
if not exist "%ROOT_DIR%" mkdir "%ROOT_DIR%"

where cmake >nul 2>nul || (echo [!] ERROR: CMake not found in PATH & exit /b 1)
where ninja >nul 2>nul || (echo [!] ERROR: Ninja not found in PATH & exit /b 1)

:: Load MSVC x64 environment if cl.exe is not available yet
where cl >nul 2>nul
if errorlevel 1 (
    set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
    if not exist "!VSWHERE!" (
        echo [!] ERROR: Visual Studio not found. Install VS 2022 with C++ workload.
        exit /b 1
    )
    set "VS_DIR="
    for /f "usebackq tokens=*" %%i in (`"!VSWHERE!" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "VS_DIR=%%i"
    if not defined VS_DIR (
        echo [!] ERROR: MSVC x64 toolset not found.
        exit /b 1
    )
    echo [+] Visual Studio: !VS_DIR!
    call "!VS_DIR!\Common7\Tools\VsDevCmd.bat" -arch=x64 -host_arch=x64 >nul
    where cl >nul 2>nul || (echo [!] ERROR: Failed to initialize MSVC environment & exit /b 1)
)
echo [+] MSVC environment ready
echo.

:: -----------------------------------------------------------------
:: [2/7] Resolve version
:: -----------------------------------------------------------------
echo [2/7] Resolving Aseprite version...
if not defined ASE_VER (
    for /f "usebackq delims=" %%v in (`powershell -NoProfile -Command "try { (Invoke-RestMethod -UseBasicParsing https://api.github.com/repos/aseprite/aseprite/releases/latest).tag_name } catch { '' }"`) do set "ASE_VER=%%v"
)
if not defined ASE_VER (
    echo [!] Could not query GitHub API. Using fallback %FALLBACK_VER%
    set "ASE_VER=%FALLBACK_VER%"
)
echo [+] Version: %ASE_VER%
echo.

:: -----------------------------------------------------------------
:: [3/7] Download Aseprite source
:: -----------------------------------------------------------------
echo [3/7] Downloading Aseprite source...
if exist "%ASEPRITE_DIR%" rd /s /q "%ASEPRITE_DIR%"
if exist "%BUILD_DIR%" rd /s /q "%BUILD_DIR%"
mkdir "%ASEPRITE_DIR%"

set "SRC_URL=https://github.com/aseprite/aseprite/releases/download/%ASE_VER%/Aseprite-%ASE_VER%-Source.zip"
set "SRC_ZIP=%ROOT_DIR%\aseprite_src.zip"
powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -UseBasicParsing -Uri '%SRC_URL%' -OutFile '%SRC_ZIP%'"
if errorlevel 1 (
    echo [!] Source.zip not available - falling back to git clone
    where git >nul 2>nul || (echo [!] ERROR: git not found & exit /b 1)
    rd /s /q "%ASEPRITE_DIR%"
    git clone --recursive --depth 1 --branch %ASE_VER% https://github.com/aseprite/aseprite.git "%ASEPRITE_DIR%" || (echo [!] ERROR: git clone failed & exit /b 1)
) else (
    powershell -NoProfile -Command "Expand-Archive -Force '%SRC_ZIP%' '%ASEPRITE_DIR%'" || (echo [!] ERROR: Failed to extract source & exit /b 1)
    del /f /q "%SRC_ZIP%"
)
if not exist "%ASEPRITE_DIR%\laf\CMakeLists.txt" (
    echo [!] ERROR: laf submodule missing in source
    exit /b 1
)
echo [+] Source ready
echo.

:: -----------------------------------------------------------------
:: [4/7] Download Skia (version required by this Aseprite release)
:: -----------------------------------------------------------------
echo [4/7] Downloading Skia...
set "SKIA_TAG=%FALLBACK_SKIA%"
if exist "%ASEPRITE_DIR%\laf\misc\skia-tag.txt" (
    set /p SKIA_TAG=<"%ASEPRITE_DIR%\laf\misc\skia-tag.txt"
)
echo [+] Skia tag: %SKIA_TAG%

set "SKIA_ZIP=%ROOT_DIR%\Skia-Windows-Release-x64-%SKIA_TAG%.zip"
if not exist "%SKIA_ZIP%" (
    powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -UseBasicParsing -Uri 'https://github.com/aseprite/skia/releases/download/%SKIA_TAG%/Skia-Windows-Release-x64.zip' -OutFile '%SKIA_ZIP%'"
    if errorlevel 1 (
        del /f /q "%SKIA_ZIP%" 2>nul
        echo [!] ERROR: Failed to download Skia
        exit /b 1
    )
)
if exist "%SKIA_DIR%" rd /s /q "%SKIA_DIR%"
powershell -NoProfile -Command "Expand-Archive -Force '%SKIA_ZIP%' '%SKIA_DIR%'" || (echo [!] ERROR: Failed to extract Skia & exit /b 1)
if not exist "%SKIA_DIR%\out\Release-x64\skia.lib" (
    echo [!] ERROR: skia.lib not found
    exit /b 1
)
echo [+] Skia ready
echo.

:: -----------------------------------------------------------------
:: [5/7] Configure
:: -----------------------------------------------------------------
echo [5/7] Configuring with CMake...
cmake -S "%ASEPRITE_DIR%" -B "%BUILD_DIR%" -G Ninja ^
    -DCMAKE_BUILD_TYPE=RelWithDebInfo ^
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 ^
    -DLAF_BACKEND=skia ^
    -DSKIA_DIR="%SKIA_DIR%" ^
    -DSKIA_LIBRARY_DIR="%SKIA_DIR%\out\Release-x64" ^
    -DSKIA_LIBRARY="%SKIA_DIR%\out\Release-x64\skia.lib" ^
    -DENABLE_UPDATER=OFF ^
    -DENABLE_TESTS=OFF
if errorlevel 1 (echo [!] ERROR: CMake configuration failed & exit /b 1)
echo.

:: -----------------------------------------------------------------
:: [6/7] Build
:: -----------------------------------------------------------------
echo [6/7] Building (this takes a while)...
cmake --build "%BUILD_DIR%" -- -j %NUMBER_OF_PROCESSORS%
if errorlevel 1 (echo [!] ERROR: Build failed & exit /b 1)
if not exist "%BUILD_DIR%\bin\aseprite.exe" (echo [!] ERROR: aseprite.exe not produced & exit /b 1)
echo [+] Build succeeded
echo.

:: -----------------------------------------------------------------
:: [7/7] Package (portable ZIP + optional installer)
:: -----------------------------------------------------------------
echo [7/7] Packaging...
set "PKG_DIR=%ROOT_DIR%\package"
if exist "%PKG_DIR%" rd /s /q "%PKG_DIR%"
if not exist "%DIST_DIR%" mkdir "%DIST_DIR%"
mkdir "%PKG_DIR%"

robocopy "%BUILD_DIR%\bin" "%PKG_DIR%" /E /NFL /NDL /NJH /NJS /XF *.pdb *.ilk *.exp *.lib gen.exe >nul
if errorlevel 8 (echo [!] ERROR: Failed to copy build output & exit /b 1)
echo # This file is here so Aseprite behaves as a portable program> "%PKG_DIR%\aseprite.ini"

set "ZIP_OUT=%DIST_DIR%\Aseprite-%ASE_VER%-Windows-x64.zip"
if exist "%ZIP_OUT%" del /f /q "%ZIP_OUT%"
powershell -NoProfile -Command "Compress-Archive -Path '%PKG_DIR%\*' -DestinationPath '%ZIP_OUT%'" || (echo [!] ERROR: Failed to create ZIP & exit /b 1)
echo [+] Portable: %ZIP_OUT%

set "ISCC=%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe"
if exist "%ISCC%" (
    set "ISS_FILE=%ROOT_DIR%\aseprite_installer.iss"
    del /f /q "%PKG_DIR%\aseprite.ini"
    > "!ISS_FILE!" (
        echo [Setup]
        echo AppName=Aseprite
        echo AppVersion=%ASE_VER%
        echo DefaultDirName={autopf}\Aseprite
        echo DefaultGroupName=Aseprite
        echo UninstallDisplayIcon={app}\aseprite.exe
        echo OutputBaseFilename=Aseprite-%ASE_VER%-Windows-x64-Setup
        echo OutputDir=%DIST_DIR%
        echo ArchitecturesAllowed=x64compatible
        echo ArchitecturesInstallIn64BitMode=x64compatible
        echo Compression=lzma2
        echo SolidCompression=yes
        echo [Files]
        echo Source: "%PKG_DIR%\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
        echo [Icons]
        echo Name: "{group}\Aseprite"; Filename: "{app}\aseprite.exe"
    )
    "%ISCC%" /Q "!ISS_FILE!" && echo [+] Installer created in %DIST_DIR%
) else (
    echo [i] Inno Setup not found - skipping installer
)

echo.
echo =================================================================
echo  Done! Output: %DIST_DIR%
echo =================================================================
endlocal
exit /b 0
