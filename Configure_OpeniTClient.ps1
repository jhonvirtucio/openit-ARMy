Param(
    [string] [Parameter(Mandatory = $true)] $SERVERURI,
    [string] [Parameter(Mandatory = $true)] $INSTALLERURL
)
$OpenitProgramData = $Env:ProgramData + "\Openit"
if ( !( Test-Path -Path $OpenitProgramData -PathType Container ) ) { New-Item -Path $OpenitProgramData -ItemType Directory }
Start-Process msiexec.exe -Wait -ArgumentList "/I $INSTALLERURL SERVERURI=$SERVERURI /l*v $OpenitProgramData\\openit_install.log /quiet"