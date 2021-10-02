using namespace System
using namespace System.Reflection
using namespace System.Runtime.InteropServices

<#
.SYNOPSIS
    Retrieves installed product information from Windows Installer.
#>
function Get-MsiProduct {
    [CmdletBinding()]
    [OutputType()]
    param (
        # Specifies the product code.
        [Parameter(Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $ProductCode
    )

    begin {
        #region functions
        <#
        .SYNOPSIS
            Gets a property from the specified object.
        #>
        function Get-Property {
            [OutputType([Object])]
            param (
                [Object]
                $Object,

                [string]
                $Name,

                [Object]
                $Arguments
            )

            $Object.GetType().InvokeMember($Name, [BindingFlags]::GetProperty, $null, $Object, $Arguments)
        }
        #endregion
    }
    process {
        $productCodeSpecified = $PSBoundParameters.ContainsKey("ProductCode")
        $type = [type]::GetTypeFromProgID("WindowsInstaller.Installer")
        $installer = [Activator]::CreateInstance($type)

        try {
            foreach ($code in Get-Property $installer "Products" $null) {
                if ($productCodeSpecified -and $code -notin $ProductCode) {
                    continue
                }

                $productName = Get-Property $installer "ProductInfo" $code, "ProductName"
                $version = [string]::Empty
                if ($productName.Length -gt 0) {
                    $version = Get-Property $installer "ProductInfo" $code, "VersionString"
                }

                # Return value of ProductState
                # 5 - The product is installed for the current user.
                $installState = Get-Property $installer "ProductState" $code

                [PSCustomObject]@{
                    Name         = $productName
                    Version      = $version
                    InstallState = $installState
                    Installed    = $installState -eq 5
                    Language     = Get-Property $installer "ProductInfo" $code, "Language"
                    ProductCode  = $code
                }
            }
        }
        finally {
            [Marshal]::FinalReleaseComObject($installer) > $null
        }
    }
}

#region example
# Retrieves all prodcuts.
Get-MsiProduct

# Retrieves products by product code.
# Get-MsiProduct -ProductCode "{}", "{}"
#endregion
