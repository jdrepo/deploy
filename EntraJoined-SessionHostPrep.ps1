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

# Reboot to enable the configuration changes

$time = [DateTime]::Now.AddMinutes(10)
$hourMinute=$time.ToString("HH:mm")

$User = "NT AUTHORITY\SYSTEM"
$Trigger = New-ScheduledTaskTrigger -Once -At $hourMinute
$Action = New-ScheduledTaskAction -Execute "c:\windows\system32\shutdown.exe" -Argument "-r -f -t 120"
Register-ScheduledTask -TaskName "Reboot once" -Trigger $Trigger -User $User -Action $Action -RunLevel Highest -Force