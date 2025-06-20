# Installation Guide - Intune Device Management Scripts

## 📋 System Requirements

### Minimum Requirements
- **Operating System**: Windows 10 (version 1903 or later) or Windows Server 2016+
- **PowerShell**: Version 5.1 or PowerShell Core 7.0+
- **Memory**: 4 GB RAM minimum, 8 GB recommended
- **Storage**: 100 MB free space for scripts and modules
- **Network**: Internet connectivity for Microsoft Graph API

### Recommended Requirements
- **Operating System**: Windows 11 or Windows Server 2019+
- **PowerShell**: PowerShell Core 7.2+
- **Memory**: 8 GB RAM or more
- **Storage**: 500 MB free space
- **Network**: High-speed internet connection

### Required Permissions
- **Local**: Administrator access on the workstation
- **Microsoft 365**: Global Administrator or Intune Administrator role
- **Network**: Ability to install PowerShell modules from PowerShell Gallery

## 🔧 Pre-Installation Checklist

Before installing the scripts, verify the following:

### ✅ System Verification
- [ ] Windows version meets minimum requirements
- [ ] PowerShell version is 5.1 or higher
- [ ] Sufficient disk space available
- [ ] Internet connectivity confirmed
- [ ] Administrative access available

### ✅ Microsoft 365 Verification
- [ ] Valid Microsoft 365 subscription with Intune
- [ ] Global Administrator or Intune Administrator role assigned
- [ ] Access to Microsoft Intune portal confirmed
- [ ] Microsoft Graph API access available

### ✅ Network Verification
- [ ] PowerShell Gallery accessible
- [ ] Microsoft Graph API endpoints reachable
- [ ] Corporate proxy configured (if applicable)
- [ ] Firewall allows PowerShell internet access

## 🚀 Installation Steps

### Step 1: Download Scripts

#### Option A: Download from Repository
1. **Navigate to the repository** in your web browser
2. **Click "Code"** and select "Download ZIP"
3. **Extract the ZIP file** to a secure location
4. **Note the folder path** for later use

#### Option B: Clone Repository (Git users)
```powershell
# Open PowerShell as Administrator
git clone <repository-url>
cd EBF
```

#### Option C: Manual File Creation
1. **Create a new folder** for the scripts
2. **Download individual script files**:
   - `Get-IntuneDuplicateDevicesReport.ps1`
   - `Set-IntuneDeviceActions.ps1`
3. **Save files** to the created folder

### Step 2: Verify Script Files

1. **Navigate to the script folder** in File Explorer
2. **Verify all files are present**:
   - `Get-IntuneDuplicateDevicesReport.ps1`
   - `Set-IntuneDeviceActions.ps1`
   - `README.md`
   - `User_Guide.md`
   - `Installation_Guide.md`

3. **Check file properties**:
   - Right-click each `.ps1` file
   - Select "Properties"
   - Ensure "Unblock" is checked (if available)

### Step 3: Configure PowerShell Execution Policy

1. **Open PowerShell as Administrator**:
   - Press `Windows + X`
   - Select "Windows PowerShell (Admin)" or "Terminal (Admin)"

2. **Check current execution policy**:
   ```powershell
   Get-ExecutionPolicy
   ```

3. **Set execution policy** (if needed):
   ```powershell
   # For current user only (recommended)
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   
   # Or for all users (requires admin)
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
   ```

4. **Verify the change**:
   ```powershell
   Get-ExecutionPolicy
   ```

### Step 4: Test PowerShell Module Installation

1. **Navigate to the script folder**:
   ```powershell
   cd "C:\Path\To\Your\Scripts"
   ```

2. **Test module installation**:
   ```powershell
   # Test Microsoft.Graph.Intune installation
   Install-Module -Name Microsoft.Graph.Intune -Force -Scope CurrentUser -ErrorAction Stop
   
   # Test Microsoft.Graph.Authentication installation
   Install-Module -Name Microsoft.Graph.Authentication -Force -Scope CurrentUser -ErrorAction Stop
   ```

3. **Verify modules are available**:
   ```powershell
   Get-Module -ListAvailable -Name Microsoft.Graph.Intune
   Get-Module -ListAvailable -Name Microsoft.Graph.Authentication
   ```

### Step 5: Test Microsoft Graph Connection

1. **Test authentication**:
   ```powershell
   # Import modules
   Import-Module Microsoft.Graph.Intune
   Import-Module Microsoft.Graph.Authentication
   
   # Test connection
   Connect-MgGraph -Scopes "Device.Read.All", "DeviceManagementManagedDevices.Read.All"
   ```

2. **Verify connection**:
   ```powershell
   # Test API access
   $devices = Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices" -Method GET
   Write-Host "Successfully connected! Found $($devices.value.Count) devices."
   ```

3. **Disconnect**:
   ```powershell
   Disconnect-MgGraph
   ```

## 🔍 Installation Verification

### Test Script Execution

1. **Test the duplicate detection script**:
   ```powershell
   # Run with WhatIf to test without making changes
   .\Get-IntuneDuplicateDevicesReport.ps1
   ```

2. **Verify output**:
   - Script should run without errors
   - Reports should be generated in a timestamped folder
   - Console should show progress and results

3. **Test the device actions script** (with WhatIf):
   ```powershell
   # Create a test CSV file
   @"
   deviceName,id
   TestDevice,test-id-123
   "@ | Out-File -FilePath "test-devices.csv" -Encoding UTF8
   
   # Test the script
   .\Set-IntuneDeviceActions.ps1 -InputFiles "test-devices.csv" -Retire -WhatIf
   ```

### Verify File Structure

After successful installation, your folder should contain:

```
EBF/
├── Get-IntuneDuplicateDevicesReport.ps1
├── Set-IntuneDeviceActions.ps1
├── README.md
├── User_Guide.md
├── Installation_Guide.md
└── IntuneDeviceReports-YYYYMMDD-HHMMSS/  (created after first run)
    ├── DuplicateSerialNumbers.csv
    ├── DuplicateDeviceNames.csv
    ├── DevicesWithNoSerialNumber.csv
    ├── UsersWithMultipleDevices.csv
    └── AllDevices.csv
```

## ⚠️ Common Installation Issues

### Execution Policy Issues

**Issue**: "Execution policy prevents running scripts"
**Solution**:
```powershell
# Check current policy
Get-ExecutionPolicy

# Set appropriate policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Verify change
Get-ExecutionPolicy
```

### Module Installation Failures

**Issue**: "Failed to install PowerShell modules"
**Solutions**:
1. **Check internet connection**:
   ```powershell
   Test-NetConnection -ComputerName powershellgallery.com -Port 443
   ```

2. **Update PowerShellGet**:
   ```powershell
   Install-Module -Name PowerShellGet -Force -AllowClobber
   ```

3. **Use alternative installation**:
   ```powershell
   Install-Module -Name Microsoft.Graph.Intune -Force -Scope CurrentUser -AllowClobber
   ```

### Authentication Issues

**Issue**: "Failed to connect to Microsoft Graph"
**Solutions**:
1. **Check permissions**:
   - Verify Global Administrator or Intune Administrator role
   - Ensure account has access to Intune

2. **Clear cached credentials**:
   ```powershell
   Disconnect-MgGraph
   Clear-AzureRmContext
   ```

3. **Use different authentication method**:
   ```powershell
   Connect-MgGraph -Scopes "Device.Read.All" -UseDeviceAuthentication
   ```

### Network/Firewall Issues

**Issue**: "Network connectivity problems"
**Solutions**:
1. **Check corporate proxy**:
   ```powershell
   # Set proxy if needed
   $proxy = "http://proxy.company.com:8080"
   $webClient = New-Object System.Net.WebClient
   $webClient.Proxy = New-Object System.Net.WebProxy($proxy)
   ```

2. **Verify firewall settings**:
   - Allow PowerShell through Windows Firewall
   - Check corporate firewall for Microsoft Graph endpoints

3. **Test connectivity**:
   ```powershell
   Test-NetConnection -ComputerName graph.microsoft.com -Port 443
   ```

## 🔧 Post-Installation Configuration

### Create Shortcuts (Optional)

1. **Create desktop shortcuts**:
   - Right-click on desktop
   - Select "New" → "Shortcut"
   - Browse to script location
   - Add PowerShell execution: `powershell.exe -ExecutionPolicy Bypass -File "C:\Path\To\Script.ps1"`

2. **Create Start Menu entries**:
   - Copy shortcuts to `%APPDATA%\Microsoft\Windows\Start Menu\Programs`

### Configure Logging (Optional)

1. **Create log directory**:
   ```powershell
   New-Item -ItemType Directory -Path "C:\Logs\IntuneScripts" -Force
   ```

2. **Modify scripts** to include logging (advanced users only)

### Set Up Scheduled Tasks (Optional)

1. **Create scheduled task** for regular duplicate detection:
   ```powershell
   # Example: Run weekly on Sundays at 2 AM
   $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"C:\Path\To\Get-IntuneDuplicateDevicesReport.ps1`""
   $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 2am
   Register-ScheduledTask -TaskName "Intune Duplicate Detection" -Action $action -Trigger $trigger
   ```

## 📋 Installation Checklist

### Pre-Installation
- [ ] System requirements verified
- [ ] Microsoft 365 permissions confirmed
- [ ] Network connectivity tested
- [ ] Administrative access available

### Installation Steps
- [ ] Scripts downloaded and extracted
- [ ] PowerShell execution policy configured
- [ ] Required modules installed
- [ ] Microsoft Graph connection tested

### Verification
- [ ] Scripts execute without errors
- [ ] Reports generate successfully
- [ ] File structure verified
- [ ] Test run completed

### Post-Installation
- [ ] Shortcuts created (optional)
- [ ] Logging configured (optional)
- [ ] Scheduled tasks set up (optional)
- [ ] Documentation reviewed

## 🆘 Troubleshooting Support

### Self-Help Resources
1. **Check this installation guide** for common issues
2. **Review the User Guide** for usage instructions
3. **Check PowerShell version**: `$PSVersionTable.PSVersion`
4. **Verify module installation**: `Get-Module -ListAvailable -Name Microsoft.Graph*`

### When to Seek Help
- Installation fails after following all steps
- Scripts run but produce unexpected results
- Authentication issues persist
- Network connectivity problems

### Information to Provide
- PowerShell version and execution policy
- Error messages (exact text)
- System specifications
- Network environment details
- Steps already attempted

---

**Installation Complete!** 🎉

Once you've completed all verification steps, you're ready to use the Intune Device Management Scripts. Refer to the User Guide for detailed usage instructions. 