# FSLogix Config
$ParentPath = "HKLM:\SOFTWARE\FSLogix"
$RegPath = "$ParentPath\Profiles"

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
New-ItemProperty -Path $RegPath -Name "Enabled" -Value 1 -PropertyType DWord -Force
New-ItemProperty -Path $RegPath -Name "DeleteLocalProfileWhenVHDShouldApply" -Value 1 -PropertyType DWord -Force
New-ItemProperty -Path $RegPath -Name "IsDynamic" -Value 1 -PropertyType DWord -Force
New-ItemProperty -Path $RegPath -Name "ProfileType" -Value 3 -PropertyType DWord -Force