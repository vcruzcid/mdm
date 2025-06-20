# Intune Device Management Scripts

This repository contains PowerShell scripts for managing Microsoft Intune devices, specifically for identifying duplicate devices and performing cleanup operations on non-compliant or unmanaged devices.

## 📋 Overview

The scripts provide automated solutions for common Intune device management tasks:

1. **Get-IntuneDuplicateDevicesReport.ps1** - Identifies and reports duplicate devices in Intune
2. **Set-IntuneDeviceActions.ps1** - Retires or deletes non-compliant and unmanaged devices

## 🎯 Use Cases

- **Device Cleanup**: Remove duplicate or orphaned devices from Intune
- **Compliance Management**: Identify and manage non-compliant devices
- **Audit and Reporting**: Generate comprehensive device reports
- **Bulk Operations**: Perform actions on multiple devices efficiently

## 📋 Prerequisites

### System Requirements
- Windows PowerShell 5.1 or PowerShell Core 7.0+
- Windows 10/11 or Windows Server 2016+
- Internet connectivity for Microsoft Graph API access

### Permissions Required
- **Global Administrator** or **Intune Administrator** role
- Microsoft Graph API permissions:
  - `Device.Read.All`
  - `DeviceManagementManagedDevices.Read.All`
  - `DeviceManagementManagedDevices.ReadWrite.All` (for Set-IntuneDeviceActions.ps1)

### PowerShell Modules
The scripts automatically install and import these modules:
- `Microsoft.Graph.Intune`
- `Microsoft.Graph.Authentication`

## 🚀 Quick Start

### 1. Clone or Download
```powershell
# Clone the repository
git clone <repository-url>
cd EBF

# Or download and extract the scripts to a folder
```

### 2. Run the Duplicate Device Report
```powershell
# Generate a comprehensive duplicate device report
.\Get-IntuneDuplicateDevicesReport.ps1
```

### 3. Review and Act on Results
```powershell
# Use the generated CSV files with the device actions script
.\Set-IntuneDeviceActions.ps1 -InputFolder ".\IntuneDeviceReports-20241201-143022" -Retire -WhatIf
```

## 📁 Script Details

### Get-IntuneDuplicateDevicesReport.ps1

**Purpose**: Identifies potential duplicate devices in Microsoft Intune by analyzing:
- Serial numbers
- Device names
- User associations
- Missing serial numbers

**Output Files**:
- `DuplicateSerialNumbers.csv` - Devices with duplicate serial numbers
- `DuplicateDeviceNames.csv` - Devices with duplicate names
- `DevicesWithNoSerialNumber.csv` - Devices missing serial numbers
- `UsersWithMultipleDevices.csv` - Users with multiple devices
- `AllDevices.csv` - Complete device inventory

**Features**:
- Automatic pagination for large environments
- Memory safety limits (50,000 devices max)
- Comprehensive error handling
- Timestamped output folders

### Set-IntuneDeviceActions.ps1

**Purpose**: Performs bulk actions on non-compliant or unmanaged devices

**Actions Available**:
- **Retire**: Removes device from Intune management
- **Delete**: Permanently removes device from Intune

**Safety Features**:
- Dry-run mode for testing
- User confirmation prompts
- Detailed logging and error reporting
- CSV validation

## 🔧 Usage Examples

### Basic Duplicate Detection
```powershell
# Run duplicate detection
.\Get-IntuneDuplicateDevicesReport.ps1
```

### Retire Non-Compliant Devices
```powershell
# Preview what would be retired
.\Set-IntuneDeviceActions.ps1 -InputFolder ".\IntuneDeviceReports-20241201-143022" -Retire -WhatIf

# Actually retire the devices
.\Set-IntuneDeviceActions.ps1 -InputFolder ".\IntuneDeviceReports-20241201-143022" -Retire
```

### Delete Specific Devices
```powershell
# Delete devices from specific CSV files
.\Set-IntuneDeviceActions.ps1 -InputFiles ".\DuplicateSerialNumbers.csv", ".\DuplicateDeviceNames.csv" -Delete
```

### Custom Input Files
```powershell
# Use custom CSV files with device IDs
.\Set-IntuneDeviceActions.ps1 -InputFiles ".\custom-devices.csv" -Retire
```

## 📊 Output Structure

### Report Folders
```
IntuneDeviceReports-YYYYMMDD-HHMMSS/
├── DuplicateSerialNumbers.csv
├── DuplicateDeviceNames.csv
├── DevicesWithNoSerialNumber.csv
├── UsersWithMultipleDevices.csv
└── AllDevices.csv
```

### Action Results
```
RetireResults-YYYYMMDD-HHMMSS/
├── Results.csv
└── ActionErrors.log
```

## ⚠️ Important Notes

### Safety Considerations
- **Always use `-WhatIf` first** to preview actions
- **Backup your data** before running destructive operations
- **Test in a non-production environment** first
- **Review device lists** before confirming actions

### Limitations
- Maximum 50,000 devices per report (configurable)
- Requires appropriate Microsoft Graph permissions
- Network connectivity required for API calls
- Some devices may be protected from deletion

### Error Handling
- Scripts provide detailed error messages
- Failed operations are logged to error files
- Scripts exit gracefully on critical errors
- CSV validation prevents processing invalid files

## 🔍 Troubleshooting

### Common Issues

**Authentication Errors**
```powershell
# Ensure you have the correct permissions
# Try reconnecting to Microsoft Graph
Connect-MgGraph -Scopes "Device.Read.All", "DeviceManagementManagedDevices.ReadWrite.All"
```

**Module Installation Issues**
```powershell
# Install modules manually if needed
Install-Module -Name Microsoft.Graph.Intune -Force -Scope CurrentUser
Install-Module -Name Microsoft.Graph.Authentication -Force -Scope CurrentUser
```

**CSV File Issues**
```powershell
# Ensure CSV files have required columns: deviceName, id
# Check file encoding (should be UTF-8)
```

### Log Files
- Check `ActionErrors.log` for detailed error information
- Review console output for warnings and errors
- Validate CSV file formats and content

## 📝 Script Parameters

### Get-IntuneDuplicateDevicesReport.ps1
No parameters required - runs with default settings.

### Set-IntuneDeviceActions.ps1
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `InputFolder` | String | No* | Folder containing CSV files |
| `InputFiles` | String[] | No* | Specific CSV files to process |
| `Retire` | Switch | No* | Retire devices from Intune |
| `Delete` | Switch | No* | Delete devices from Intune |
| `WhatIf` | Switch | No | Preview actions without executing |

*Either `InputFolder` or `InputFiles` must be provided, and either `Retire` or `Delete` must be specified.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For issues and questions:
1. Check the troubleshooting section
2. Review error logs
3. Ensure prerequisites are met
4. Create an issue with detailed information

## 📚 Additional Resources

- [Microsoft Graph API Documentation](https://docs.microsoft.com/en-us/graph/)
- [Intune PowerShell Documentation](https://docs.microsoft.com/en-us/mem/intune/fundamentals/powershell-intune-samples)
- [Microsoft Graph PowerShell SDK](https://github.com/microsoftgraph/msgraph-sdk-powershell) 