# New-WebApp Script

A script to create a website on Azure. The design is to walk you through the basic options (Resource Group, App Service Plan, Location, etc.) to help streamline the creation of an Azure website. The hope is for this to grow to support more advanced functionality, and serve as a basic bootstrapping tool.

## Prerequisites

- [PowerShell](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-windows-powershell?view=powershell-6)
- [Azure PowerShell module](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-1.7.0)

## Usage

```console
Connect-AzAccount # Authenticate to Azure
New-WebApp.ps1
```

## Features to come

- Enable git deployment
- Enable GitHub integration

## License

MIT License. No warranty, no guarantees