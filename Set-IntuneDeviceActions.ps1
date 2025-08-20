# Set-Device-Actions.ps1
# Retires or deletes non-compliant and/or not-managed devices from Intune using input CSV(s)

param(
    [Parameter(Mandatory=$false)]
    [string]$InputFolder,

    [Parameter(Mandatory=$false)]
    [string[]]$InputFiles,

    [Parameter(Mandatory=$false)]
    [string]$OutputFolder,

    [switch]$Retire,
    [switch]$Delete,
    [switch]$WhatIf
)

# Validate that at least one input method is provided
if (-not $InputFolder -and (-not $InputFiles -or $InputFiles.Count -eq 0)) {
    Write-Error "Either InputFolder or InputFiles parameter must be provided."
    exit 1
}

# Validate that at least one action is specified
if (-not $Retire -and -not $Delete) {
    Write-Error "Either -Retire or -Delete switch must be specified."
    exit 1
}

function Ensure-Modules {
    $modules = @("Microsoft.Graph.Intune", "Microsoft.Graph.Authentication")
    foreach ($mod in $modules) {
        if (-not (Get-Module -ListAvailable -Name $mod)) {
            try {
                Install-Module -Name $mod -Force -Scope CurrentUser -ErrorAction Stop
            } catch {
                Write-Error "Failed to install module $mod : $_"
                exit 1
            }
        }
        try {
            Import-Module $mod -ErrorAction Stop
        } catch {
            Write-Error "Failed to import module $mod : $_"
            exit 1
        }
    }
}

function Connect-Graph {
    try {
        Connect-MgGraph -Scopes "Device.Read.All", "DeviceManagementManagedDevices.ReadWrite.All"
    } catch {
        Write-Error "Failed to connect to Microsoft Graph. $_"
        exit 1
    }
}

function Load-InputFiles {
    if ($InputFolder) {
        if (-not (Test-Path $InputFolder)) {
            Write-Error "Input folder '$InputFolder' does not exist."
            exit 1
        }
        $defaultFiles = @("DuplicateSerialNumbers.csv", "DuplicateDeviceNames.csv")
        $InputFiles += $defaultFiles | ForEach-Object {
            $path = Join-Path $InputFolder $_
            if (Test-Path $path) { $path } else { Write-Warning "$_ not found in $InputFolder"; $null }
        }
    }
    if (-not $InputFiles) {
        Write-Error "No input CSV files provided or found."
        exit 1
    }
    return $InputFiles | Where-Object { $_ -ne $null }
}

function Validate-CsvFile {
    param([string]$FilePath)
    
    try {
        $csv = Import-Csv $FilePath -ErrorAction Stop
        
        # Check if CSV has data
        if ($csv.Count -eq 0) {
            Write-Warning "CSV file $FilePath is empty."
            return $false
        }
        
        $requiredColumns = @('deviceName', 'id')
        $csvColumns = $csv[0].PSObject.Properties.Name
        
        foreach ($col in $requiredColumns) {
            if ($col -notin $csvColumns) {
                Write-Error "CSV file $FilePath is missing required column: $col"
                return $false
            }
        }
        return $true
    } catch {
        Write-Error "Failed to validate CSV file $FilePath : $_"
        return $false
    }
}

function Get-DeviceInfo ($id) {
    try {
        $uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$id"
        $device = Invoke-MgGraphRequest -Uri $uri -Method GET -ErrorAction Stop
        return $device
    } catch {
        Write-Warning "Failed to fetch device $id : $_"
        return $null
    }
}

function Map-ComplianceState ($value) {
    switch ($value) {
        0 { return "unknown" }
        1 { return "compliant" }
        2 { return "noncompliant" }
        3 { return "conflict" }
        4 { return "error" }
        254 { return "inGracePeriod" }
        255 { return "configManager" }
        default { return "invalid" }
    }
}

function Map-ManagementState ($value) {
    switch ($value) {
        0 { return "managed" }
        1 { return "retirePending" }
        2 { return "retireFailed" }
        3 { return "wipePending" }
        4 { return "wipeFailed" }
        5 { return "unhealthy" }
        6 { return "deletePending" }
        7 { return "retireIssued" }
        8 { return "wipeIssued" }
        9 { return "wipeCanceled" }
        10 { return "retireCanceled" }
        11 { return "discovered" }
        default { return "invalid" }
    }
}

function Take-ActionOnDevices {
    param (
        $devices,
        $retire,
        $delete,
        $dryRun,
        $OutputFolder
    )

    if (-not $OutputFolder) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $OutputFolder = ".\RetireResults-$timestamp"
    }

    if (-not (Test-Path -Path $OutputFolder)) {
        New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
    }
    
    $results = @()
    $logPath = Join-Path $OutputFolder 'ActionErrors.log'

    foreach ($device in $devices) {
        $info = Get-DeviceInfo -id $device.id
        if (-not $info) { continue }

        $complianceState = Map-ComplianceState -value $info.complianceState
        $managementState = Map-ManagementState -value $info.managementState

        # Fixed logic: Skip devices that are compliant AND managed
        if ($complianceState -eq 'compliant' -and $managementState -eq 'managed') {
            continue
        }

        $result = [PSCustomObject]@{
            deviceName       = $device.deviceName
            serialNumber     = $device.serialNumber
            id               = $device.id
            complianceState  = $complianceState
            managementState  = $managementState
            Reason           = "Filtered as nonCompliant or not-managed"
            ActionTaken      = ""
            Status           = "Pending"
        }

        if (-not $dryRun) {
            if ($retire) {
                try {
                    Invoke-MgGraphRequest -Uri ("https://graph.microsoft.com/beta/deviceManagement/managedDevices/$($device.id)/retire") -Method POST -ErrorAction Stop
                    $result.ActionTaken += "Retired "
                    $result.Status = "Success"
                } catch {
                    $err = "Retire failed for device $($device.deviceName) (ID: $($device.id)): $_"
                    Write-Warning $err
                    $result.Status = "Failed to Retire"
                    Add-Content -Path $logPath -Value $err
                }
            }
            if ($delete) {
                try {
                    # Add confirmation for delete action
                    Write-Host "Deleting device: $($device.deviceName) (ID: $($device.id))" -ForegroundColor Red
                    Remove-MgDeviceManagementManagedDevice -ManagedDeviceId $device.id -Confirm:$false -ErrorAction Stop
                    $result.ActionTaken += "Deleted "
                    $result.Status = "Success"
                } catch {
                    $err = "Delete failed for device $($device.deviceName) (ID: $($device.id)): $_"
                    Write-Warning $err
                    $result.Status = "Failed to Delete"
                    Add-Content -Path $logPath -Value $err
                }
            }
        } else {
            $result.ActionTaken = "Dry-run: Would Retire/Delete"
            $result.Status = "Preview"
        }

        $results += $result
    }

    $results | Export-Csv -Path (Join-Path $OutputFolder 'Results.csv') -NoTypeInformation
    Write-Host "Results saved to $OutputFolder\Results.csv" -ForegroundColor Green
    if (Test-Path $logPath) {
        Write-Host "Some actions failed. See log: $logPath" -ForegroundColor Yellow
    }
}

# Execution
Ensure-Modules
Connect-Graph
$files = Load-InputFiles

# Validate all CSV files before processing
$validFiles = @()
foreach ($file in $files) {
    if (Validate-CsvFile -FilePath $file) {
        $validFiles += $file
    } else {
        Write-Warning "Skipping invalid CSV file: $file"
    }
}

if ($validFiles.Count -eq 0) {
    Write-Error "No valid CSV files found."
    exit 1
}

$rawDevices = @()
foreach ($file in $validFiles) {
    try {
        $rawDevices += Import-Csv $file -ErrorAction Stop
    } catch {
        Write-Warning "Failed to import CSV file '$file': $_"
    }
}
$rawDevices = $rawDevices | Sort-Object -Property deviceName -Unique

$preview = @()
foreach ($d in $rawDevices) {
    $deviceData = Get-DeviceInfo -id $d.id
    if ($deviceData -and ($deviceData.complianceState -eq 2 -or $deviceData.managementState -ne 0)) {
        $preview += [PSCustomObject]@{
            deviceName      = $deviceData.deviceName
            serialNumber    = $deviceData.serialNumber
            id              = $deviceData.id
            complianceState = Map-ComplianceState -value $deviceData.complianceState
            managementState = Map-ManagementState -value $deviceData.managementState
        }
    }
}

if (-not $preview.Count) {
    Write-Host "No matching non-compliant or unmanaged devices found." -ForegroundColor Yellow
    exit
}

Write-Host "Devices to be processed:" -ForegroundColor Cyan
$preview | Format-Table

if (-not $WhatIf) {
    $choice = Read-Host "Proceed with action on these $($preview.Count) devices? (Y/N)"
    if ($choice -ne 'Y') {
        Write-Host "Aborted by user." -ForegroundColor Red
        exit
    }
}

Take-ActionOnDevices -devices $preview -retire:$Retire -delete:$Delete -dryRun:(!$Retire -and !$Delete -or $WhatIf) -OutputFolder $OutputFolder

Disconnect-MgGraph | Out-Null
