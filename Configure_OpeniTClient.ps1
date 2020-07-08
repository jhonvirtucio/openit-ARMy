Param(
    [string] [Parameter(Mandatory = $true)] $SERVERURI,
    [string] [Parameter(Mandatory = $true)] $INSTALLERURL,
    [switch] $privateBoxSource
)
$OpenitProgramData = "$Env:ProgramData\Openit"
if ( !( Test-Path -Path $OpenitProgramData -PathType Container ) ) { New-Item -Path $OpenitProgramData -ItemType Directory }

if ($privateBoxSource) {
    # Install openit client directly from the privatebox
    Start-Process msiexec.exe -Wait -ArgumentList "/I $INSTALLERURL SERVERURI=$SERVERURI /l*v $OpenitProgramData\\openit_install.log /quiet"
}
else {
    # Install openit client from the azure blob storage
    $installerPath = "$OpenitProgramData\openit_client_installer.msi"
    (New-Object System.Net.WebClient).DownloadFile($INSTALLERURL, $installerPath)
    Start-Process msiexec.exe -Wait -ArgumentList "/I $installerPath SERVERURI=$SERVERURI /l*v $OpenitProgramData\openit_install.log /quiet"
    
    # Cleanup
    Remove-Item $installerPath
}