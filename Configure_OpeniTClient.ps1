Param(
    [string] [Parameter(Mandatory = $true)] $SERVERURI,
    [string] [Parameter(Mandatory = $true)] $INSTALLERURL,
    [switch] $privateBoxSource
)

if ($privateBoxSource) {
    # Install openit client directly from the privatebox
    Start-Process msiexec.exe -Wait -ArgumentList "/I $INSTALLERURL SERVERURI=$SERVERURI /l*v $Env:Temp\openit_install.log /quiet"
}
else {

    $ErrorActionPreference = 'Stop'

    #region Configuration
    # The Azure Blob Storage Account and Container where all required installer files are available at.
    $StorageAccountName = 'storageopenit'
    $Container          = 'clientinstallers'

    # SasToken to access the Azure Blob Storage account. Requires at least Read + List permissions
    $SasToken = '?sv=2019-10-10&ss=b&srt=o&sp=rl&se=2022-01-07T17:48:59Z&st=2020-07-08T09:48:59Z&spr=https&sig=rc4BPLggigozF3hNAagX8s9ngAI%2FrHEUNLz7mhPVHRo%3D'

    # Installer file and arguments passed to install the application.
    $ApplicationSetupFile = 'openit_9_6_30_client_windows_x64.msi'
    $ApplicationArguments = '/S'
    #endregion Configuration

    # Install the NuGet Package Provider, preventing that trusting the PSGallery with the Set-PSRepository cmdlet would hang on user input.
    try {
        Install-PackageProvider -Name NuGet -Scope CurrentUser -Force
        Write-Output 'Installed the NuGet Package Provider'
    }
    catch {
        Write-Error "Failed to install NuGet Package Provider. Exception: $($_.Exception.Message)"
    }

    # Trust the PSGallery Repository to install required modules, preventing that installing the AzureRM.Storage Module would hang on user input.
    if((Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue).InstallationPolicy -ne 'Trusted') {
        try {
            Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
            Write-Output 'Trusted the PSGallery Repository'
        }
        catch {
            Write-Error "Failed to trust PSGallery Repository. Exception: $($_.Exception.Message)"
        }
    } else {
        Write-Output 'PSGallery repository is already trusted.'
    }

    # Install required AzureRM Storage module. Used to retrieve all installer files (Blobs) from a given Azure Blob Storage Container.
    if(-not (Get-Module -Name AzureRM.Storage -ListAvailable)) {
        try {
            Install-Module -Name AzureRM.Storage -Scope CurrentUser
            Write-Output 'Installed AzureRM.Storage Module'
        }
        catch {
            Write-Error "Failed to install required AzureRM.Storage module. Exception: $($_.Exception.Message)"
        }
    } else {
        Write-Output 'AzureRM.Storage Module is already present.'
    }

    # Create temp directory for storing the installation files in $Env:Temp
    if (!(Test-Path -Path "$Env:Temp\$Container")) { 
        Write-Output "Creating '$Env:Temp\$Container' directory"
        New-Item -ItemType Directory -Path "$Env:Temp\$Container"
    }

    # All files contained inside the given $Container will be downloaded from Azure Blob Storage (Requires SAS Token with Read + List access rights)
    try {
        Write-Output "Trying to download installer files ..."
        $AzureStorageContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -SasToken $SasToken
        $Blobs = Get-AzureStorageBlob -Container $Container -Context $AzureStorageContext
        foreach ($Blob in $Blobs) {
            # Save file to $Env:Temp\$Container
            Start-BitsTransfer -Source ($($Blob.ICloudBlob.StorageUri.PrimaryUri.AbsoluteUri) + $SasToken) -Destination "$Env:Temp\$Container\$($Blob.Name)"     
        }
        Write-Output "Downloaded all installer files"
    }
    catch {
        Write-Error "Failed to download installation files from Azure Blob Storage. Exception: $($_.Exception.Message)"
    }

    # Install application using specified arguments passed with the installer file as configured in the configuration section
    # Waits for installation to finish before continuing
    try {
        
        Start-Process msiexec.exe -Wait -ArgumentList "/I $Env:Temp\$Container\$ApplicationSetupFile SERVERURI=$SERVERURI /l*v $Env:Temp\openit_install.log /quiet"
        Write-Output 'Application installation completed.'
    }
    catch {
        Write-Error "Failed to install application. Exception: $($_.Exception.Message)"
    }

    # Clean-up installation files
    Remove-Item "$Env:Temp\$Container" -Force -Recurse
    
}