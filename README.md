#### Introduction
Welcome to the `EsxRunspace` module! This is an example framework for you to build upon.
We make use of the `PoshRSJob` module to create a Runspace job for each ESX connection.
This doesn't make it go faster (or maybe it does!).  Try it out.

#### Help
```

NAME
    Invoke-EsxRunspace

SYNOPSIS


SYNTAX
    Invoke-EsxRunspace [[-VMHost] <String[]>] [[-Credential] <PSCredential>] [[-IncludeModule] <String[]>]
    [-Brief] [-PassThru] [<CommonParameters>]


DESCRIPTION
    Connects to one or more VMware ESX hosts using PowerShell Runspace jobs.
    Returns a default report with basic ESX info.

NOTES


        Script:           Invoke-EsxRunspace.ps1
        Author:           Mike Nisk
        Requires:         The PoshRSJob module by Bo Prox.
                          https://github.com/proxb/PoshRSJob

                          If you do not have the above module:
                          Install-Module -Name PoshRSJob

                          To load the module (if needed):
                          Get-Module -ListAvailable -Name PoshRSJob | Import-Module

        Prior Art:        The syntax used herein for Start-RSJob is based on VMTN thread:
                          https://communities.vmware.com/thread/513253

        Tested Versions:  Older versions should work fine, but this was tested on:
                          Microsoft PowerShell 5.1
                          VMware PowerCLI 6.5.2
                          PoshRSJob 1.7.3.9
                          ESXi 6.0 U2
                          
PARAMETERS
    -VMHost <String[]>
        String. IP Address or DNS Name of one or more ESX hosts.

    -Credential <PSCredential>
        PSCredential. The login credential for ESX
        
    -IncludeModule <String[]>
        String. The Include parameter allows adding one or more modules and/or functions
        to the Runspace for each ESX connection. By default we include 'VMware.PowerCLI.Core'.
        If you are working with VDS for example, then populate the Include with 'VMware.VimAutomation.Vds'.
        When using Include, this implies that you will edit the script to add desired datapoints to the
        returned object.

    -Brief [<SwitchParameter>]
        Switch.  Returns a small set of properties (Name, Version, and State).

    -PassThru [<SwitchParameter>]
        Switch. Use the PassThru switch for greater detail on returned object.
        Does not format or sort by design.

```
#### Examples
```-------------------------- EXAMPLE 1 --------------------------

PS C:\>Invoke-EsxRunspace -VMHost esx01.lab.local -Credential (Get-Credential)

This example prompts for credentials and then connects to an ESX host
running the default commands in the function.


-------------------------- EXAMPLE 2 --------------------------

PS C:\>$CredsESX = Get-Credential root

$EsxList = @('esx01.lab.local', 'esx02.lab.local', 'esx03.lab.local', 'esx04.lab.local')
Invoke-EsxRunspace -VMHost $EsxList -Credential $credsESX
This example creates a variable to hold an array of ESX host names.  We then run the report
against that array which creates a Runspace job per host.


-------------------------- EXAMPLE 3 --------------------------

PS C:\>$CredsESX = Get-Credential root

Invoke-EsxRunspace -VMHost esx01.lab.local -Credential $credsESX -Include 'VMware.VimAutomation.vROps'
This example saves a credential to variable and then connects to a single ESX host.
This example also shows how to import an additional module to the ESX runspace.


-------------------------- EXAMPLE 4 --------------------------

PS C:\>$CredsESX = Get-Credential root

Invoke-EsxRunspace -VMHost (gc 'c:\servers.txt') -Credential $credsESX -Include 'c:\scripts\Invoke-MyCoolFunction.ps1'
This example saves a credential to variable and then connects to a list of ESX hosts read in from a text file.
This example also shows how to import an additional function to the ESX runspace.


-------------------------- EXAMPLE 5 --------------------------

PS C:\>$credsLabESX = Get-Credential root

$EsxList = @('esx01.lab.local','esx02.lab.local','esx03.lab.local','esx04.lab.local')
$report = Invoke-EsxRunspace -VMHost $EsxList -Credential $credsLabESX
$report | select -First 1

Name          : esx01.lab.local
State         : Connected
Version       : 6.0.0
Manufacturer  : Apple Inc.
Model         : MacPro6,1
MemoryTotalGB : 64
NumCpu        : 4
ProcessorType : Intel(R) Xeon(R) CPU E5-1620 v2 @ 3.70GHz

This example shows how to save the output to a variable.  We can then look at just one object,
or all.  We can also pipe $report to Out-GridView or Export-Csv of course.

```
