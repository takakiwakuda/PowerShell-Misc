#Requires -Module ActiveDirectory

function Get-ADObjectType {
    [CmdletBinding(DefaultParameterSetName = "Name")]
    [Alias("Get-ADSchemaIdGuid")]
    [OutputType()]
    param (
        [Parameter(ParameterSetName = "Name")]
        [string]
        $Name,

        [Parameter(ParameterSetName = "SchemaIdGuid")]
        [Alias("Guid")]
        [guid]
        $Type
    )

    begin {
        #region utility functions
        function BuildFilterWithGuid {
            [OutputType([string])]
            param (
                [guid]
                $Guid
            )

            # Maybe, 63 is maximum length
            $string = [System.Text.StringBuilder]::new(63)
            $string.Append("(schemaIDGUID=") > $null
            foreach ($tmp in $Guid.ToByteArray()) {
                $string.AppendFormat("\{0:x}", $tmp) > $null
            }
            $string.Append(")") > $null

            $string.ToString()
        }

        function FilterObjectTypes {
            [OutputType([Microsoft.ActiveDirectory.Management.ADObject])]
            param (
                [string]
                $Filter
            )

            $scriptblock = { [guid]::new($this.schemaIDGUID) }

            if ($Filter.Length -eq 0) {
                $ldapFilter = "(|(objectClass=attributeSchema)(objectClass=classSchema))"
            }
            else {
                $ldapFilter = "(&(|(objectClass=attributeSchema)(objectClass=classSchema)){0})" -f $Filter
            }

            $getADObjectParameters = @{
                LDAPFilter  = $ldapFilter
                Properties  = @("name", "schemaIDGUID")
                SearchBase  = (Get-ADRootDSE).SchemaNamingContext
                SearchScope = [Microsoft.ActiveDirectory.Management.ADSearchScope]::OneLevel
            }
            foreach ($object in Get-ADObject @getADObjectParameters) {
                $object.psobject.Members.Add([psscriptproperty]::new("ObjectType", $scriptblock))
                $object
            }
        }
        #endregion
    }
    process {
        switch ($PSCmdlet.ParameterSetName) {
            "Name" {
                if ($Name.Length -gt 0) {
                    $filter = "(name={0})" -f $Name
                }
            }
            "SchemaIdGuid" {
                $filter = BuildFilterWithGuid $Type
            }
        }

        FilterObjectTypes $filter
    }
}

# Get-ADObjectType
Get-ADObjectType -Name "User"
Get-ADObjectType -Guid "bf967aba-0de6-11d0-a285-00aa003049e2"
