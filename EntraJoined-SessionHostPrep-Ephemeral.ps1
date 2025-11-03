# Description: This script prepares an EntraJoined only AVD session host for FSLogix and Cloud Kerberos.


# Cloud Kerberos
$KerbRegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters"
New-ItemProperty -Path $KerbRegPath -Name "CloudKerberosTicketRetrievalEnabled" -Value 1 -PropertyType DWord -Force

# When you use Microsoft Entra ID with a roaming profile solution like FSLogix, 
# the credential keys in Credential Manager must belong to the profile thatâ€™s currently loading. 
# This will let you load your profile on many different VMs instead of being limited to just one. 
# To enable this setting, create the following registry value
$LoadCredKeyRegPath = "HKLM:\Software\Policies\Microsoft\AzureADAccount"
# Create the key if it does not exist
If (-NOT (Test-Path $LoadCredKeyRegPath)) {
  New-Item -Path $LoadCredKeyRegPath -Force | Out-Null
}  
# Now set the value
New-ItemProperty -Path $LoadCredKeyRegPath -Name "LoadCredKeyFromProfile" -Value 1 -PropertyType DWord -Force

# FSLogix Config
$ParentPath = "HKLM:\SOFTWARE\FSLogix"
$RegPath = "$ParentPath\Profiles"
$ProfilesPath = "\\sagwcavd002prof001.file.core.windows.net\fslogix1\profc\w11-2g"

# Ensure FSLogix keys exist
if (-not (Test-Path $ParentPath)) {
    New-Item -Path "HKLM:\SOFTWARE" -Name "FSLogix" -Force | Out-Null
}
if (-not (Test-Path $RegPath)) {
    New-Item -Path $ParentPath -Name "Profiles" -Force | Out-Null
}

# Set FSLogix/Profiles registry values
New-ItemProperty -Path $RegPath -Name "FlipFlopProfileDirectoryName" -Value 1 -PropertyType DWord -Force
New-ItemProperty -Path $RegPath -Name "VolumeType" -Value "VHDX" -PropertyType String -Force
New-ItemProperty -Path $RegPath -Name "VHDLocations" -Value $ProfilesPath -PropertyType String -Force
New-ItemProperty -Path $RegPath -Name "Enabled" -Value 1 -PropertyType DWord -Force
New-ItemProperty -Path $RegPath -Name "DeleteLocalProfileWhenVHDShouldApply" -Value 1 -PropertyType DWord -Force
# New-ItemProperty -Path $RegPath -Name "RedirXMLSourceFolder" -Value $RedirectionPath -PropertyType String -Force


# Reboot to enable the configuration changes

$time = [DateTime]::Now.AddMinutes(10)
$hourMinute=$time.ToString("HH:mm")

$User = "NT AUTHORITY\SYSTEM"
$Trigger = New-ScheduledTaskTrigger -Once -At $hourMinute
$Action = New-ScheduledTaskAction -Execute "c:\windows\system32\shutdown.exe" -Argument "-r -f -t 120"
Register-ScheduledTask -TaskName "Reboot once" -Trigger $Trigger -User $User -Action $Action -RunLevel Highest -Force
