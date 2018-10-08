#### Introduction
Welcome to the `EsxRunspace` module! This is an example framework for you to build upon.
We make use of the `PoshRSJob` module to create a Runspace job for each ESX connection.
This doesn't make it go faster (or maybe it does!).  Try it out.

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
Function        Invoke-EsxRunspace                                 1.0.0.1    EsxRunspace

PS C:\>
PS C:\> help Invoke-EsxRunspace -Full

NAME
    Invoke-EsxRunspace

SYNOPSIS


SYNTAX
    Invoke-EsxRunspace [[-VMHost] <String[]>] [-Credential] <PSCredential> [-Brief] [-PassThru] [<CommonParameters>]


DESCRIPTION
    Connects to one or more VMware ESX hosts using PowerShell Runspace jobs.
    Returns a default report with basic ESX info.


PARAMETERS
    -VMHost <String[]>
        String. IP Address or DNS Name of one or more ESX hosts.

        Required?                    false
        Position?                    1
        Default value
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Credential <PSCredential>
        PSCredential. The login credential for ESX.

        Required?                    true
        Position?                    2
        Default value
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Brief [<SwitchParameter>]
        Switch.  Returns a small set of properties (Name, Version, and State).

        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -PassThru [<SwitchParameter>]
        Switch. Use the PassThru switch for greater detail on returned object.
        Does not format or sort by design.

        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false

    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see
        about_CommonParameters (https:/go.microsoft.com/fwlink/?LinkID=113216).

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

    PS C:\>$CredsESX = Get-Credential root

    Invoke-EsxRunspace -VMHost esx01.lab.local -Credential $credsESX
    Save a credential to a variable and then connect to a single ESX host,
    running the default commands in the function.




    -------------------------- EXAMPLE 2 --------------------------

    PS C:\>$CredsESX = Get-Credential root

    $EsxList = @('esx01.lab.local', 'esx02.lab.local', 'esx03.lab.local', 'esx04.lab.local')
    Invoke-EsxRunspace -VMHost $EsxList -Credential $credsESX




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





RELATED LINKS




PS C:\>

```
