setlocal enabledelayedexpansion
setlocal EnableExtensions 

SET SED=Tools\UnixUtils\sed.exe

REM Fetching packages..	

IF [%BUILD_NUMBER%] == [] (SET BUILD_NUMBER=0)

Tools\NuGet.exe install -OutputDirectory packages ILRepack
Tools\NuGet.exe install -OutputDirectory packages Microsoft.Web.RedisSessionStateProvider

FOR /F %%I IN ('dir /b packages\ILRepack.*') DO SET ILREPACKDIR=%%I
FOR /F %%I IN ('dir /b packages\Microsoft.Web.RedisSessionStateProvider.*') DO SET REDISPROVDIR=%%I
FOR /F %%I IN ('dir /b packages\StackExchange.Redis.StrongName.*') DO SET SEREDISDIR=%%I

REM Bundling EasyNetQ dependencies..

IF NOT EXIST Bundle MKDIR Bundle
IF NOT EXIST Bundle\lib MKDIR Bundle\lib
IF NOT EXIST Bundle\lib\net40 MKDIR Bundle\lib\net40
IF NOT EXIST Bundle\content MKDIR Bundle\content

xcopy packages\%REDISPROVDIR%\content Bundle\content /s /e /y

packages\%ILREPACKDIR%\tools\ILRepack.exe /internalize /out:Bundle\lib\net40\Microsoft.Web.RedisSessionStateProvider.dll ^
  packages\%REDISPROVDIR%\lib\net40\Microsoft.Web.RedisSessionStateProvider.dll ^
  packages\%SEREDISDIR%\lib\net40\StackExchange.Redis.StrongName.dll

REM Creating nuget package..

IF NOT EXIST Results MKDIR Results

FOR /F %%I IN ('echo %REDISPROVDIR% ^|%SED% -e "s/Microsoft\.Web\.RedisSessionStateProvider\.//"') DO SET VERSION=%%I
FOR /F %%I IN ('echo %VERSION% ^|%SED% -e "s/\([0-9]\+\.[0-9]\+\.[0-9]\+\).*/\1/"') DO SET VERSION=%%I.%BUILD_NUMBER%

Tools\NuGet.exe pack Bundle\Microsoft.Web.RedisSessionStateProvider.nuspec -OutputDirectory Results -BasePath Bundle -Version %VERSION%



