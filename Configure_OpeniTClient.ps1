$OpenitProgramData = $Env:ProgramData + '\\Openit'
if ( !( Test-Path -Path $OpenitProgramData -PathType Container ) ) { New-Item -Path $OpenitProgramData -ItemType Directory }
Start-Process msiexec.exe -Wait -ArgumentList "/I https://privatebox.openit.com/67880d02f530b30df656b7f2226ed204/openit_client_windows_x64.msi /l*v $OpenitProgramData\\openit_install.log /quiet"