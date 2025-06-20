# Intune Device Management Scripts - User Guide

## 📖 Introduction

This guide is designed for IT administrators and system managers who need to manage Microsoft Intune devices efficiently. The scripts help you identify duplicate devices and clean up non-compliant or unmanaged devices in your Intune environment.

## 🎯 What These Scripts Do

### Script 1: Get-IntuneDuplicateDevicesReport.ps1
- **Purpose**: Finds duplicate devices in your Intune environment
- **What it looks for**:
  - Devices with the same serial number
  - Devices with the same name
  - Users with multiple devices
  - Devices missing serial numbers
- **Output**: Creates CSV files with detailed reports

### Script 2: Set-IntuneDeviceActions.ps1
- **Purpose**: Retires or deletes devices from Intune
- **What it can do**:
  - Retire devices (remove from management)
  - Delete devices (permanently remove)
  - Preview actions before executing
- **Safety**: Always shows what it will do before making changes

## 🔧 Prerequisites Checklist

Before running the scripts, ensure you have:

### ✅ System Requirements
- [ ] Windows 10/11 or Windows Server 2016+
- [ ] PowerShell 5.1 or newer
- [ ] Internet connection
- [ ] Administrative access to your computer

### ✅ Permissions
- [ ] Global Administrator or Intune Administrator role in Microsoft 365
- [ ] Access to Microsoft Intune
- [ ] Ability to install PowerShell modules

### ✅ Network Access
- [ ] Can access Microsoft Graph API
- [ ] No firewall blocking PowerShell internet access
- [ ] Corporate proxy configured (if applicable)

## 🚀 Step-by-Step Instructions

### Step 1: Download and Prepare

1. **Download the scripts** to a folder on your computer
2. **Open PowerShell as Administrator**:
   - Press `Windows + X`
   - Select "Windows PowerShell (Admin)" or "Terminal (Admin)"

3. **Navigate to the script folder**:
   ```powershell
   cd "C:\Path\To\Your\Scripts"
   ```

### Step 2: Run the Duplicate Device Report

1. **Execute the report script**:
   ```powershell
   .\Get-IntuneDuplicateDevicesReport.ps1
   ```

2. **What happens**:
   - Script will install required modules (first time only)
   - You'll be prompted to sign in to Microsoft 365
   - Script will retrieve all devices from Intune
   - Progress will be shown on screen
   - Reports will be created in a timestamped folder

3. **Expected output**:
   ```
   Installing Microsoft Graph Intune module...
   Connecting to Microsoft Graph...
   Connected successfully!
   Retrieving all devices from Intune...
   Retrieved 1,234 devices so far...
   Successfully retrieved 1,234 devices
   Analyzing devices for potential duplicates...
   Checking for duplicate serial numbers...
   No duplicate serial numbers found.
   Checking for duplicate device names...
   Found 5 duplicate device names!
   ...
   All reports saved to: .\IntuneDeviceReports-20241201-143022
   ```

### Step 3: Review the Reports

1. **Navigate to the report folder** (created automatically)
2. **Open the CSV files** in Excel or similar application
3. **Review each report**:
   - `DuplicateSerialNumbers.csv` - Devices with same serial number
   - `DuplicateDeviceNames.csv` - Devices with same name
   - `DevicesWithNoSerialNumber.csv` - Devices missing serial numbers
   - `UsersWithMultipleDevices.csv` - Users with multiple devices
   - `AllDevices.csv` - Complete device list

### Step 4: Plan Your Actions

1. **Identify which devices need attention**:
   - Duplicate devices that should be removed
   - Non-compliant devices
   - Orphaned devices

2. **Decide on actions**:
   - **Retire**: Remove from Intune management (device can be re-enrolled)
   - **Delete**: Permanently remove from Intune (cannot be recovered)

3. **Create a backup plan** (recommended):
   - Export current device list
   - Document which devices will be affected

### Step 5: Preview Actions (Recommended)

1. **Run a preview** to see what would happen:
   ```powershell
   .\Set-IntuneDeviceActions.ps1 -InputFolder ".\IntuneDeviceReports-20241201-143022" -Retire -WhatIf
   ```

2. **Review the preview output**:
   - Shows which devices would be affected
   - Displays compliance and management status
   - No actual changes are made

### Step 6: Execute Actions

1. **Run the actual action**:
   ```powershell
   .\Set-IntuneDeviceActions.ps1 -InputFolder ".\IntuneDeviceReports-20241201-143022" -Retire
   ```

2. **Confirm the action** when prompted:
   ```
   Proceed with action on these 15 devices? (Y/N)
   ```

3. **Monitor the progress**:
   - Script will show each device being processed
   - Success/failure messages for each device
   - Results saved to timestamped folder

## 📊 Understanding the Reports

### DuplicateSerialNumbers.csv
| Column | Description |
|--------|-------------|
| deviceName | Name of the device |
| serialNumber | Hardware serial number |
| model | Device model |
| manufacturer | Device manufacturer |
| operatingSystem | OS (Windows, iOS, Android) |
| osVersion | Operating system version |
| userPrincipalName | Associated user email |
| lastSyncDateTime | Last sync with Intune |
| enrolledDateTime | When device was enrolled |
| id | Unique device ID |

### DuplicateDeviceNames.csv
Same structure as above, but shows devices with identical names.

### DevicesWithNoSerialNumber.csv
Devices that don't have a serial number recorded (may indicate enrollment issues).

### UsersWithMultipleDevices.csv
Shows users who have multiple devices enrolled, with a count of how many devices each user has.

## ⚠️ Safety Guidelines

### Before Running Scripts
1. **Test in a non-production environment** first
2. **Backup your current device inventory**
3. **Review the preview output carefully**
4. **Ensure you have the correct permissions**

### During Execution
1. **Don't interrupt the script** while it's running
2. **Monitor the console output** for errors
3. **Keep the PowerShell window open** until completion

### After Execution
1. **Review the results** in the output folder
2. **Check the error log** if any issues occurred
3. **Verify the changes** in the Intune portal
4. **Document what was done** for audit purposes

## 🔍 Troubleshooting Common Issues

### Authentication Problems

**Issue**: "Failed to connect to Microsoft Graph"
**Solution**:
1. Ensure you're signed in with correct account
2. Check if you have Intune Administrator permissions
3. Try running the script again

**Issue**: "Access denied" errors
**Solution**:
1. Run PowerShell as Administrator
2. Check your Microsoft 365 role assignments
3. Contact your Global Administrator

### Module Installation Issues

**Issue**: "Failed to install module"
**Solution**:
1. Check internet connection
2. Try installing manually:
   ```powershell
   Install-Module -Name Microsoft.Graph.Intune -Force -Scope CurrentUser
   Install-Module -Name Microsoft.Graph.Authentication -Force -Scope CurrentUser
   ```

### CSV File Issues

**Issue**: "CSV file is missing required column"
**Solution**:
1. Ensure CSV files have `deviceName` and `id` columns
2. Check file encoding (should be UTF-8)
3. Don't modify the generated CSV files

### Performance Issues

**Issue**: Script runs slowly or times out
**Solution**:
1. Large environments may take time to process
2. Check network connectivity
3. Consider running during off-peak hours

## 📞 Getting Help

### When to Contact Support
- Script fails to run completely
- Unexpected results or errors
- Need clarification on output
- Permission issues

### Information to Provide
1. **Error messages** (copy exact text)
2. **Script version** and PowerShell version
3. **Environment details** (number of devices, etc.)
4. **Steps taken** before the issue
5. **Screenshots** of error messages

### Self-Help Resources
- Check the troubleshooting section above
- Review error logs in output folders
- Test with `-WhatIf` parameter first
- Start with small batches of devices

## 📝 Best Practices

### Regular Maintenance
- Run duplicate detection monthly
- Review and clean up devices quarterly
- Keep scripts updated
- Document all actions taken

### Security Considerations
- Run scripts from secure workstations
- Use dedicated service accounts if possible
- Log all administrative actions
- Review permissions regularly

### Performance Optimization
- Run during maintenance windows
- Process devices in batches if needed
- Monitor system resources during execution
- Clean up old report folders periodically

## 📋 Quick Reference Commands

### Basic Operations
```powershell
# Generate duplicate device report
.\Get-IntuneDuplicateDevicesReport.ps1

# Preview retire actions
.\Set-IntuneDeviceActions.ps1 -InputFolder ".\IntuneDeviceReports-20241201-143022" -Retire -WhatIf

# Retire devices
.\Set-IntuneDeviceActions.ps1 -InputFolder ".\IntuneDeviceReports-20241201-143022" -Retire

# Delete devices (use with caution)
.\Set-IntuneDeviceActions.ps1 -InputFolder ".\IntuneDeviceReports-20241201-143022" -Delete
```

### Advanced Operations
```powershell
# Use specific CSV files
.\Set-IntuneDeviceActions.ps1 -InputFiles ".\DuplicateSerialNumbers.csv" -Retire

# Multiple input files
.\Set-IntuneDeviceActions.ps1 -InputFiles ".\file1.csv", ".\file2.csv" -Retire
```

## 🎉 Success Checklist

After running the scripts, you should have:

- [ ] Generated device reports in timestamped folders
- [ ] Reviewed duplicate device findings
- [ ] Successfully retired or deleted target devices
- [ ] Verified changes in Intune portal
- [ ] Documented actions taken
- [ ] Cleaned up old report folders (optional)

---

**Remember**: Always test in a non-production environment first and use the `-WhatIf` parameter to preview actions before executing them! 