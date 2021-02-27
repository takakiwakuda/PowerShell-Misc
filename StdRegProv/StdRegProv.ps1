enum RegistryHiveUsingCim : UInt32 {
    ClassesRoot = 0x80000000L
    CurrentUser = 0x80000001L
    LocalMachine = 0x80000002L
    Users = 0x80000003L
    CurrentConfig = 0x80000005L
}

enum RegistryViewUsingCim {
    Default = 0
    Registry32 = 32
    Registry64 = 64
}

function Get-RegistryStringUsingCim {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter()]
        [RegistryHiveUsingCim]
        $Hive,

        [Parameter()]
        [string]
        $SubKeyName,

        [Parameter()]
        [string]
        $ValueName,

        [Parameter()]
        [RegistryViewUsingCim]
        $View
    )

    begin {
        #region functions
        function CreateMethodParameter {
            [OutputType([Microsoft.Management.Infrastructure.CimMethodParameter])]
            param (
                [string]
                $Name,

                [System.Object]
                $Value,

                [cimtype]
                $Type,

                [Microsoft.Management.Infrastructure.CimFlags]
                $Flags
            )

            [Microsoft.Management.Infrastructure.CimMethodParameter]::Create($Name, $Value, $Type, $Flags)
        }

        function GetRegistryString {
            [OutputType([string])]
            param (
                [CimSession]
                $CimSession,

                [UInt32]
                $Hive,

                [string]
                $SubKeyName,

                [string]
                $ValueName,

                [int]
                $View
            )

            $parameters = [Microsoft.Management.Infrastructure.CimMethodParametersCollection]::new()
            $parameters.Add((CreateMethodParameter hDefKey $Hive UInt32 In))
            $parameters.Add((CreateMethodParameter sSubKeyName $SubKeyName String In))
            $parameters.Add((CreateMethodParameter sValueName $ValueName String In))

            $options = [Microsoft.Management.Infrastructure.Options.CimOperationOptions]::new()
            if ($View -ne [RegistryViewUsingCim]::Default) {
                $options.SetCustomOption("__ProviderArchitecture", $View, $true)
                $options.SetCustomOption("__RequiredArchitecture", $true, $true)
            }

            try {
                $result = $CimSession.InvokeMethod(
                    "root\default",
                    "StdRegProv",
                    "GetStringValue",
                    $parameters,
                    $options)

                if ($result.ReturnValue.Value -eq 0) {
                    $result.OutParameters["sValue"].Value
                }
            }
            finally {
                $parameters.Dispose()
                $options.Dispose()

                if ($result) {
                    $result.Dispose()
                }
            }
        }
        #endregion
    }
    process {
        $session = [CimSession]::Create([System.Environment]::MachineName)

        try {
            GetRegistryString $session $Hive $SubKeyName $ValueName $View
        }
        finally {
            $session.Dispose()
        }
    }
}

Get-RegistryStringUsingCim -Hive LocalMachine -SubKeyName Software\Microsoft\Windows\CurrentVersion -ValueName ProgramFilesPath -View Registry32
Get-RegistryStringUsingCim -Hive LocalMachine -SubKeyName Software\Microsoft\Windows\CurrentVersion -ValueName ProgramFilesPath -View Registry64
