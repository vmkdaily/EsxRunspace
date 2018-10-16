#### Introduction
Welcome to the `EsxRunspace` module! This is an example framework for you to build upon.
We make use of the `PoshRSJob` module to create a Runspace job for each VMware ESXi connection.
This module has excellent memory management and uses one of the fastest array types in PowerShell.
Also see the related module, VcRunspace to gather reports for vCenter Servers instead of ESXi hosts.

#### Help
```

PS C:\> Import-Module c:\temp\EsxRunspace -Verbose
VERBOSE: Loading module from path 'c:\temp\EsxRunspace\EsxRunspace.psd1'.
VERBOSE: Loading module from path 'c:\temp\EsxRunspace\EsxRunspace.psm1'.
VERBOSE: Importing function 'Invoke-EsxRunspace'.
PS C:\>
PS C:\> gcm -Module EsxRunspace

CommandType     Name                                               Version    Source
-----------     ----                                               -------    ------
Function        Invoke-EsxRunspace                                 1.0.0.2    EsxRunspace

PS C:\>
PS C:\> help Invoke-EsxRunspace -Full

NAME
    Invoke-EsxRunspace

SYNOPSIS


SYNTAX
    Invoke-EsxRunspace [[-VMHost] <String[]>] [-Credential] <PSCredential> [-Brief] [-PassThru] [<CommonParameters>]


DESCRIPTION
    Connect to one or more VMware ESXi hosts using PowerShell Runspace jobs and return some basic information.


PARAMETERS
    -VMHost <String[]>
        String. The IP Address or DNS Name of one or more VMware ESXi hosts.

        Required?                    false
        Position?                    1
        Default value
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Credential <PSCredential>
        PSCredential. The login for ESXi.

        Required?                    true
        Position?                    2
        Default value
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Brief [<SwitchParameter>]
        Switch. Optionally, return a small set of properties (i.e. Name, Version, and State).

        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -PassThru [<SwitchParameter>]
        Switch. Use the PassThru switch for greater detail on returned object.

        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false

    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see
        about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

INPUTS
    none


OUTPUTS
    Object


NOTES


        Script:           Invoke-EsxRunspace.ps1
        Author:           Mike Nisk
        Prior Art:        Start-RSJob syntax based on VMTN thread:
                          https://communities.vmware.com/thread/513253

        Tested Versions:  Microsoft PowerShell 5.1 (supports 3.0 and later)
                          VMware PowerCLI 6.5.2 (PowerCLI 10.x preferred)
                          PoshRSJob 1.7.3.9
                          ESXi 6.0 U2

    -------------------------- EXAMPLE 1 --------------------------

    PS C:\>Invoke-EsxRunspace -VMHost esx01.lab.local -Credential (Get-Credential root)

    Get prompted for login information and then return a report for a single ESXi host.




    -------------------------- EXAMPLE 2 --------------------------

    PS C:\>$CredsESX = Get-Credential root

    $EsxList = @('esx01.lab.local', 'esx02.lab.local', 'esx03.lab.local', 'esx04.lab.local')
    $report = Invoke-EsxRunspace -VMHost $EsxList -Credential $credsESX

    Save a credential to variable and then return a report for several ESXi hosts.




    -------------------------- EXAMPLE 3 --------------------------

    PS C:\>$credsESX = Get-Credential root

    $report = Invoke-EsxRunspace -VMHost (gc $home/esx-list.txt) -Credential $credsESX
    $report | select -First 1

    Name          : esx01.lab.local
    State         : Connected
    Version       : 6.0.0
    Manufacturer  : Apple Inc.
    Model         : MacPro6,1
    MemoryTotalGB : 64
    NumCpu        : 4
    ProcessorType : Intel(R) Xeon(R) CPU E5-1620 v2 @ 3.70GHz

    Use Get-Content to feed the Server parameter by pointing to a text file. The text file should have one vCenter Server name per line.




    -------------------------- EXAMPLE 4 --------------------------

    PS C:\>Get-Module -ListAvailable -Name @('PoshRSJob','VMware.PowerCLI') | select Name,Version

    Name            Version
    ----            -------
    PoshRSJob       1.7.4.4
    VMware.PowerCLI 11.0.0.10380590

    This example tests the current client for the required modules. The script and parent module does checking for this as well. The version is not too important; latest is greatest.





RELATED LINKS




PS C:\>

```
