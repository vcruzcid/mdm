# Find Duplicate Devices in Microsoft Intune
# This script connects to Microsoft Graph API and identifies potential duplicate devices
# Prerequisites: Install-Module Microsoft.Graph.Intune, Microsoft.Graph.Authentication

param(
    [Parameter(Mandatory=$false)]
    [string]$OutputFolder
)

# Install required modules if not already installed
try {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Intune)) {
        Write-Host "Installing Microsoft Graph Intune module..." -ForegroundColor Yellow
        Install-Module -Name Microsoft.Graph.Intune -Force -Scope CurrentUser -ErrorAction Stop
    }

    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        Write-Host "Installing Microsoft Graph Authentication module..." -ForegroundColor Yellow
        Install-Module -Name Microsoft.Graph.Authentication -Force -Scope CurrentUser -ErrorAction Stop
    }

    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.DeviceManagement)) {
        Write-Host "Installing Microsoft Graph DeviceManagement module..." -ForegroundColor Yellow
        Install-Module -Name Microsoft.Graph.DeviceManagement -Force -Scope CurrentUser -ErrorAction Stop
    }
} catch {
    Write-Warning "Error installing required modules: $_"
}

# Import modules
try {
    Import-Module Microsoft.Graph.Intune -ErrorAction Stop
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Import-Module Microsoft.Graph.DeviceManagement -ErrorAction Stop
} catch {
    Write-Warning "Error importing required modules: $_"
}

# Function to safely export CSV
function Export-CsvSafely {
    param(
        [Parameter(Mandatory=$true)]
        $Data,
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [string]$Description
    )
    
    try {
        $Data | Export-Csv -Path $Path -NoTypeInformation -ErrorAction Stop
        Write-Host "Exported $Description to $Path" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Error exporting $Description to $Path : $_" -ForegroundColor Red
        return $false
    }
}

# Connect to Microsoft Graph
try {
    Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
    Connect-MgGraph -Scopes "Device.Read.All", "DeviceManagementManagedDevices.Read.All"
    Write-Host "Connected successfully!" -ForegroundColor Green
} catch {
    Write-Warning "Error connecting to Microsoft Graph: $_"
}

# Function to get all devices from Intune
function Get-IntuneDevices {
    try {
        Write-Host "Retrieving all devices from Intune..." -ForegroundColor Cyan
        $devices = Get-MgDeviceManagementManagedDevice -All
        Write-Host "Successfully retrieved $($devices.Count) devices" -ForegroundColor Green
        return $devices
    } catch {
        Write-Host "Error retrieving devices: $_" -ForegroundColor Red
        return $null
    }
}

# Get all devices
$devices = Get-IntuneDevices

# Validate devices data
if ($null -eq $devices -or $devices.Count -eq 0) {
    Write-Warning "No devices found or error occurred. Exiting script."
}

# Validate that devices have expected properties
$devicesWithMissingId = @()
$devicesWithMissingName = @()
$devicesWithMissingSerial = @()

foreach ($device in $devices) {
    if (-not $device.id) {
        $devicesWithMissingId += $device
    }
    if (-not $device.deviceName) {
        $devicesWithMissingName += $device
    }
    if (-not $device.serialNumber) {
        $devicesWithMissingSerial += $device
    }
}

if ($devicesWithMissingId.Count -gt 0) {
    Write-Host "Warning: $($devicesWithMissingId.Count) device object(s) are missing the critical 'id' property. This may be due to an API issue or unexpected data format. These devices will be skipped." -ForegroundColor Yellow
    Write-Host "Here is the first object that was missing the 'id' property:"
    $devicesWithMissingId[0] | Format-List | Out-String | Write-Host
    $devices = $devices | Where-Object { $_.id }
}

if ($devicesWithMissingName.Count -gt 0 -or $devicesWithMissingSerial.Count -gt 0) {
    Write-Host "Warning: Found some devices with missing property values. This may affect duplicate detection." -ForegroundColor Yellow
    if ($devicesWithMissingName.Count -gt 0) {
        Write-Host "- $($devicesWithMissingName.Count) devices are missing a 'deviceName' value." -ForegroundColor Yellow
    }
    if ($devicesWithMissingSerial.Count -gt 0) {
        Write-Host "- $($devicesWithMissingSerial.Count) devices are missing a 'serialNumber' value." -ForegroundColor Yellow
    }
}

# Create an output folder for reports
if (-not $OutputFolder) {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $OutputFolder = Join-Path (Get-Location) "IntuneDeviceReports-$timestamp"
}

try {
    if (-not (Test-Path -Path $OutputFolder)) {
        New-Item -ItemType Directory -Path $OutputFolder -Force -ErrorAction Stop | Out-Null
    }
} catch {
    Write-Warning "Error creating output folder: $_"
}

Write-Host "Analyzing devices for potential duplicates..." -ForegroundColor Cyan

# Find duplicates by Device Name and Serial Number (ignoring empty serial numbers)
Write-Host "Checking for duplicate Device Name and Serial Number..." -ForegroundColor Yellow
$combinedDuplicates = $devices | 
    Where-Object { $_.serialNumber -and $_.serialNumber -ne "" -and $_.deviceName -and $_.deviceName -ne "" } |
    Group-Object -Property deviceName, serialNumber | 
    Where-Object { $_.Count -gt 1 }

if ($combinedDuplicates) {
    Write-Host "Found $($combinedDuplicates.Count) duplicate device name and serial number combinations!" -ForegroundColor Red
    $combinedDuplicates | ForEach-Object {
        $firstItem = $_.Group[0]
        Write-Host "Device Name: $($firstItem.deviceName), Serial Number: $($firstItem.serialNumber) - $($_.Count) devices" -ForegroundColor Red
    }
    
    # Export combined duplicates to CSV
    $combinedDuplicateDevices = $combinedDuplicates | ForEach-Object { $_.Group } | Select-Object deviceName, serialNumber, model, manufacturer, operatingSystem, osVersion, userPrincipalName, lastSyncDateTime, enrolledDateTime, id
    Export-CsvSafely -Data $combinedDuplicateDevices -Path "$OutputFolder\DuplicateDeviceNameAndSerial.csv" -Description "device name and serial number duplicates"
} else {
    Write-Host "No duplicate device name and serial number combinations found." -ForegroundColor Green
}

# Export all devices for reference
Export-CsvSafely -Data ($devices | Select-Object deviceName, serialNumber, model, manufacturer, operatingSystem, osVersion, userPrincipalName, lastSyncDateTime, enrolledDateTime, id) -Path "$OutputFolder\AllDevices.csv" -Description "all devices"

# Find devices with missing serial numbers
Write-Host "Checking for devices with missing serial numbers..." -ForegroundColor Yellow
$noSerialDevices = $devices | 
    Where-Object { -not $_.serialNumber -or $_.serialNumber -eq "" }

if ($noSerialDevices) {
    $noSerialCount = $noSerialDevices.Count
    Write-Host "Found $noSerialCount devices with missing serial numbers!" -ForegroundColor Red
    
    # Export devices with no serial number to CSV
    Export-CsvSafely -Data ($noSerialDevices | Select-Object deviceName, id, model, manufacturer, operatingSystem, osVersion, userPrincipalName, lastSyncDateTime, enrolledDateTime) -Path "$OutputFolder\DevicesWithNoSerialNumber.csv" -Description "devices with no serial number"
} else {
    Write-Host "No devices with missing serial numbers found." -ForegroundColor Green
}

# Find duplicate users with multiple devices (might indicate duplicates)
Write-Host "Checking for users with multiple devices..." -ForegroundColor Yellow
$userDevices = $devices | 
    Where-Object { $_.userPrincipalName -and $_.userPrincipalName -ne "" } |
    Group-Object -Property userPrincipalName |
    Where-Object { $_.Count -gt 1 } |
    Sort-Object Count -Descending

if ($userDevices) {
    Write-Host "Found $($userDevices.Count) users with multiple devices." -ForegroundColor Yellow
    $userDevices | Select-Object -First 10 | ForEach-Object {
        Write-Host "User: $($_.Name) - $($_.Count) devices" -ForegroundColor Yellow
    }
    
    if ($userDevices.Count -gt 10) {
        Write-Host "(Showing only top 10 users with most devices)" -ForegroundColor Gray
    }
    
    # Export user devices to CSV
    $multiUserDevices = $userDevices | ForEach-Object { 
        $userName = $_.Name
        $_.Group | Add-Member -MemberType NoteProperty -Name "DeviceCount" -Value $_.Count -PassThru
    } | Select-Object deviceName, serialNumber, model, manufacturer, operatingSystem, osVersion, userPrincipalName, DeviceCount, lastSyncDateTime, enrolledDateTime, id
    
    Export-CsvSafely -Data $multiUserDevices -Path "$OutputFolder\UsersWithMultipleDevices.csv" -Description "users with multiple devices"
} else {
    Write-Host "No users with multiple devices found." -ForegroundColor Green
}

# Summary
Write-Host "`n===== SUMMARY =====" -ForegroundColor Cyan
Write-Host "Total devices: $($devices.Count)" -ForegroundColor White
Write-Host "Devices with duplicate name and serial number: $(if ($combinedDuplicates) { $combinedDuplicates.Count } else { 0 })" -ForegroundColor White
Write-Host "Devices with missing serial numbers: $(if ($noSerialDevices) { $noSerialDevices.Count } else { 0 })" -ForegroundColor White
Write-Host "Users with multiple devices: $(if ($userDevices) { $userDevices.Count } else { 0 })" -ForegroundColor White
Write-Host "All reports saved to: $OutputFolder" -ForegroundColor Green
Write-Host "===================" -ForegroundColor Cyan

# Disconnect from Microsoft Graph
Disconnect-MgGraph | Out-Null
Write-Host "Disconnected from Microsoft Graph" -ForegroundColor Gray

Write-Host "`nScript completed successfully!" -ForegroundColor Green
