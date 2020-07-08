Param(
    [string] [Parameter(Mandatory = $true)] $SERVERURI
)
$OpenitProgramData = $Env:ProgramData + "\Openit"
if ( !( Test-Path -Path $OpenitProgramData -PathType Container ) ) { New-Item -Path $OpenitProgramData -ItemType Directory }
Start-Process msiexec.exe -Wait -ArgumentList "/I https://storageopenit.blob.core.windows.net/clientinstallers/openit_9_6_30_client_windows_x64.msi SERVERURI=$SERVERURI /l*v $OpenitProgramData\\openit_install.log /quiet"