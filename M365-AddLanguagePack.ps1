param(
    [Parameter(Mandatory=$true,
               ValueFromPipelineByPropertyName=$true,
               Position=0)]
    [string] $targetLanguage    # e.g. "de-DE"
)

$tmpDir = "c:\temp\" 



#create folder if it doesn't exist
if (!(Test-Path $tmpDir)) { mkdir $tmpDir -Force }
        
#write a log file with the same name of the script
Start-Transcript "$tmpDir\step_InstallLanguagePack.log" -Append
"================"
"Starting Language Pack ($targetLanguage) installation $(Get-Date)"

$ErrorActionPreference = "Continue"

#region Start ODT download
$ProgressPreference = 'SilentlyContinue'
$myjobs = @() 

$LPdownloads1 = @{
    'ODT'          = "https://download.microsoft.com/download/6c1eeb25-cf8b-41d9-8d0d-cc1dbc032140/officedeploymenttool_19231-20072.exe"    
}

Write-Output "Starting download jobs #1 $(Get-Date)"
foreach ($download in $LPdownloads1.GetEnumerator()) {
    $downloadPath = $tmpDir + "\$(Split-Path $($download.Value) -Leaf)"
    if (!(Test-Path $downloadPath )) {
        #download if not there
        $myjobs += Start-Job -ArgumentList $($download.Value), $downloadPath -Name "download" -ScriptBlock {
            param([string] $downloadURI,
                [string]$downloadPath
            )
            #Invoke-WebRequest -Uri $download -OutFile $downloadPath # is 10 slower than the webclient
            $wc = New-Object net.webclient
            $wc.Downloadfile( $downloadURI, $downloadPath)
        } 
    }
}

do {
    Start-Sleep 15
    $running = @($myjobs | Where-Object { ($_.State -eq 'Running') })
    $myjobs | Group-Object State | Select-Object count, name
    Write-Output "-----------------"
}
while ($running.count -gt 0)

Write-Output "Finished downloads #1 $(Get-Date)"

#region Office Language Pack installation
#https://www.microsoft.com/en-us/download/details.aspx?id=49117
#downloaded Office Deployment Tool -> created a config file (https://config.office.com/) to add $targetLanguage as language -> execute OCT tool to download & install LP
Write-Output "Installing Office Language Pack $(Get-Date)"

$ODTConfig = @"
<Configuration ID="6ed8046a-e8ac-46ce-8d33-824b0bfc1e54">
  <Add OfficeClientEdition="64" Channel="Current">
    <Product ID="O365ProPlusRetail">
      <Language ID="$targetLanguage" />
      <ExcludeApp ID="Groove" />
      <ExcludeApp ID="Lync" />
      <ExcludeApp ID="OneDrive" />
    </Product>
    <Product ID="LanguagePack">
      <Language ID="$targetLanguage" />
    </Product>
    <Product ID="ProofingTools">
      <Language ID="$targetLanguage" />
    </Product>
  </Add>
  <Property Name="SharedComputerLicensing" Value="1" />
  <Property Name="SCLCacheOverride" Value="0" />
  <Property Name="AUTOACTIVATE" Value="0" />
  <Property Name="FORCEAPPSHUTDOWN" Value="FALSE" />
  <Property Name="DeviceBasedLicensing" Value="0" />
  <Updates Enabled="TRUE" />
  <Display Level="None" AcceptEULA="TRUE" />
</Configuration>
"@

$ODTConfig

Out-File -FilePath "$tmpDir\ODTConfig.xml" -InputObject $ODTConfig

Start-Process -filepath "$tmpDir\officedeploymenttool*.exe" -ArgumentList "/extract:$tmpDir\ODT /quiet" -wait
start-sleep 3

try {
    Write-Output "Executing Office Deployment Tool...this will take a while... $(Get-Date)"
    Start-Process -FilePath "$tmpDir\ODT\setup.exe" -Wait -ErrorAction Stop -ArgumentList "/configure $tmpDir\ODTConfig.xml" -NoNewWindow
}
catch {
    $ErrorMessage = $_.Exception.message
    Write-Output "Error installing Office Language Pack $ErrorMessage"
}
Write-Output "End Office Language Pack $(Get-Date)"
#endregion

Stop-Transcript
