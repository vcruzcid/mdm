# Find Duplicate Devices in Microsoft Intune
# This script connects to Microsoft Graph API and identifies potential duplicate devices
# Prerequisites: Install-Module Microsoft.Graph.Intune, Microsoft.Graph.Authentication

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
} catch {
    Write-Host "Error installing required modules: $_" -ForegroundColor Red
    exit 1
}

# Import modules
try {
    Import-Module Microsoft.Graph.Intune -ErrorAction Stop
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
} catch {
    Write-Host "Error importing required modules: $_" -ForegroundColor Red
    exit 1
}

# Connect to Microsoft Graph
try {
    Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
    Connect-MgGraph -Scopes "Device.Read.All", "DeviceManagementManagedDevices.Read.All"
    Write-Host "Connected successfully!" -ForegroundColor Green
} catch {
    Write-Host "Error connecting to Microsoft Graph: $_" -ForegroundColor Red
    exit 1
}

# Function to get all devices from Intune
function Get-IntuneDevices {
    try {
        Write-Host "Retrieving all devices from Intune..." -ForegroundColor Cyan
        $uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices"
        $allDevices = @()
        $deviceCount = 0
        
        do {
            $devices = Invoke-MgGraphRequest -Uri $uri -Method GET -ErrorAction Stop
            $uri = $devices.'@odata.nextLink'
            $allDevices += $devices.value
            $deviceCount = $allDevices.Count
            Write-Host "Retrieved $deviceCount devices so far..." -ForegroundColor Gray
            
            # Add safety check for large environments
            if ($deviceCount -gt 10000) {
                Write-Host "Warning: Large number of devices detected. Consider implementing pagination limits." -ForegroundColor Yellow
            }
        } while ($uri)
        
        Write-Host "Successfully retrieved $deviceCount devices" -ForegroundColor Green
        return $allDevices
    } catch {
        Write-Host "Error retrieving devices: $_" -ForegroundColor Red
        return $null
    }
}

# Get all devices
$devices = Get-IntuneDevices

# Validate devices data
if ($null -eq $devices -or $devices.Count -eq 0) {
    Write-Host "No devices found or error occurred. Exiting script." -ForegroundColor Red
    exit 1
}

# Validate that devices have expected properties
$sampleDevice = $devices[0]
$requiredProperties = @('deviceName', 'serialNumber', 'id')
foreach ($prop in $requiredProperties) {
    if (-not $sampleDevice.PSObject.Properties.Name.Contains($prop)) {
        Write-Host "Error: Device data missing required property '$prop'. Exiting script." -ForegroundColor Red
        exit 1
    }
}

# Create an output folder for reports
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$outputFolder = Join-Path (Get-Location) "IntuneDeviceReports-$timestamp"
try {
    New-Item -ItemType Directory -Path $outputFolder -Force -ErrorAction Stop | Out-Null
} catch {
    Write-Host "Error creating output folder: $_" -ForegroundColor Red
    exit 1
}

Write-Host "Analyzing devices for potential duplicates..." -ForegroundColor Cyan

# Find duplicates by Serial Number (ignoring empty serial numbers)
Write-Host "Checking for duplicate serial numbers..." -ForegroundColor Yellow
$serialDuplicates = $devices | 
    Where-Object { $_.serialNumber -and $_.serialNumber -ne "" } |
    Group-Object -Property serialNumber | 
    Where-Object { $_.Count -gt 1 }

if ($serialDuplicates) {
    Write-Host "Found $($serialDuplicates.Count) duplicate serial numbers!" -ForegroundColor Red
    $serialDuplicates | ForEach-Object {
        Write-Host "Serial Number: $($_.Name) - $($_.Count) devices" -ForegroundColor Red
    }
    
    # Export serial number duplicates to CSV
    $serialDuplicateDevices = $serialDuplicates | ForEach-Object { $_.Group } | Select-Object deviceName, serialNumber, model, manufacturer, operatingSystem, osVersion, userPrincipalName, lastSyncDateTime, enrolledDateTime, id
    $serialDuplicateDevices | Export-Csv -Path "$outputFolder\DuplicateSerialNumbers.csv" -NoTypeInformation
    Write-Host "Exported serial number duplicates to $outputFolder\DuplicateSerialNumbers.csv" -ForegroundColor Green
} else {
    Write-Host "No duplicate serial numbers found." -ForegroundColor Green
}

# Find duplicates by Device Name
Write-Host "Checking for duplicate device names..." -ForegroundColor Yellow
$nameDuplicates = $devices | 
    Group-Object -Property deviceName | 
    Where-Object { $_.Count -gt 1 }

if ($nameDuplicates) {
    Write-Host "Found $($nameDuplicates.Count) duplicate device names!" -ForegroundColor Red
    $nameDuplicates | ForEach-Object {
        Write-Host "Device Name: $($_.Name) - $($_.Count) devices" -ForegroundColor Red
    }
    
    # Export device name duplicates to CSV
    $nameDuplicateDevices = $nameDuplicates | ForEach-Object { $_.Group } | Select-Object deviceName, serialNumber, model, manufacturer, operatingSystem, osVersion, userPrincipalName, lastSyncDateTime, enrolledDateTime, id
    $nameDuplicateDevices | Export-Csv -Path "$outputFolder\DuplicateDeviceNames.csv" -NoTypeInformation
    Write-Host "Exported device name duplicates to $outputFolder\DuplicateDeviceNames.csv" -ForegroundColor Green
} else {
    Write-Host "No duplicate device names found." -ForegroundColor Green
}

# Export all devices for reference
$devices | Select-Object deviceName, serialNumber, model, manufacturer, operatingSystem, osVersion, userPrincipalName, lastSyncDateTime, enrolledDateTime, id |
    Export-Csv -Path "$outputFolder\AllDevices.csv" -NoTypeInformation
Write-Host "Exported all devices to $outputFolder\AllDevices.csv" -ForegroundColor Green

# Find devices with missing serial numbers
Write-Host "Checking for devices with missing serial numbers..." -ForegroundColor Yellow
$noSerialDevices = $devices | 
    Where-Object { -not $_.serialNumber -or $_.serialNumber -eq "" }

if ($noSerialDevices) {
    $noSerialCount = $noSerialDevices.Count
    Write-Host "Found $noSerialCount devices with missing serial numbers!" -ForegroundColor Red
    
    # Export devices with no serial number to CSV
    $noSerialDevices | Select-Object deviceName, id, model, manufacturer, operatingSystem, osVersion, userPrincipalName, lastSyncDateTime, enrolledDateTime |
        Export-Csv -Path "$outputFolder\DevicesWithNoSerialNumber.csv" -NoTypeInformation
    Write-Host "Exported devices with no serial number to $outputFolder\DevicesWithNoSerialNumber.csv" -ForegroundColor Green
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
    
    $multiUserDevices | Export-Csv -Path "$outputFolder\UsersWithMultipleDevices.csv" -NoTypeInformation
    Write-Host "Exported users with multiple devices to $outputFolder\UsersWithMultipleDevices.csv" -ForegroundColor Green
} else {
    Write-Host "No users with multiple devices found." -ForegroundColor Green
}

# Summary
Write-Host "`n===== SUMMARY =====" -ForegroundColor Cyan
Write-Host "Total devices: $($devices.Count)" -ForegroundColor White
Write-Host "Devices with duplicate serial numbers: $(if ($serialDuplicates) { $serialDuplicates.Count } else { 0 })" -ForegroundColor White
Write-Host "Devices with duplicate names: $(if ($nameDuplicates) { $nameDuplicates.Count } else { 0 })" -ForegroundColor White
Write-Host "Devices with missing serial numbers: $(if ($noSerialDevices) { $noSerialDevices.Count } else { 0 })" -ForegroundColor White
Write-Host "Users with multiple devices: $(if ($userDevices) { $userDevices.Count } else { 0 })" -ForegroundColor White
Write-Host "All reports saved to: $outputFolder" -ForegroundColor Green
Write-Host "===================" -ForegroundColor Cyan

# Disconnect from Microsoft Graph
Disconnect-MgGraph | Out-Null
Write-Host "Disconnected from Microsoft Graph" -ForegroundColor Gray

Write-Host "`nScript completed successfully!" -ForegroundColor Green