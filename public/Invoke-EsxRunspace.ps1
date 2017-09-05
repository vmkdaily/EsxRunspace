#requires -Version 3
Function Invoke-EsxRunspace {
  <#

      .DESCRIPTION
        Connects to one or more VMware ESX hosts using PowerShell Runspace jobs.
        Returns a default report with basic ESX info.

      .NOTES
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

      .PARAMETER VMHost
        String. IP Address or DNS Name of one or more ESX hosts.

      .PARAMETER Credential
        PSCredential. The login credential for ESX

      .PARAMETER IncludeModule
        String. The Include parameter allows adding one or more modules and/or functions
        to the Runspace for each ESX connection. By default we include 'VMware.PowerCLI.Core'.
        If you are working with VDS for example, then populate the Include with 'VMware.VimAutomation.Vds'.
        When using Include, this implies that you will edit the script to add desired datapoints to the
        returned object.

      .PARAMETER Brief
        Switch.  Returns a small set of properties (Name, Version, and State).

      .PARAMETER PassThru
        Switch. Use the PassThru switch for greater detail on returned object.
        Does not format or sort by design.

      .EXAMPLE
      Invoke-EsxRunspace -VMHost esx01.lab.local -Credential (Get-Credential)
      This example prompts for credentials and then connects to an ESX host
      running the default commands in the function.

      .EXAMPLE
      $CredsESX = Get-Credential root
      $EsxList = @('esx01.lab.local', 'esx02.lab.local', 'esx03.lab.local', 'esx04.lab.local')
      Invoke-EsxRunspace -VMHost $EsxList -Credential $credsESX
      This example creates a variable to hold an array of ESX host names.  We then run the report
      against that array which creates a Runspace job per host.

      .EXAMPLE
      $CredsESX = Get-Credential root
      Invoke-EsxRunspace -VMHost esx01.lab.local -Credential $credsESX -Include 'VMware.VimAutomation.vROps'
      This example saves a credential to variable and then connects to a single ESX host.
      This example also shows how to import an additional module to the ESX runspace.

      .EXAMPLE
      $CredsESX = Get-Credential root
      Invoke-EsxRunspace -VMHost (gc 'c:\servers.txt') -Credential $credsESX -Include 'c:\scripts\Invoke-MyCoolFunction.ps1'
      This example saves a credential to variable and then connects to a list of ESX hosts read in from a text file.
      This example also shows how to import an additional function to the ESX runspace.

      .EXAMPLE
      $credsLabESX = Get-Credential root
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
  #>

  [CmdletBinding()]
  Param(

    #IP Address or DNS name of one or more VMware ESXi hosts
    [Alias('VMHostList')]
    [string[]]$VMHost,

    #PSCredential.  Login for ESX (i.e. root).
    [PSCredential]$Credential,

    #String.  Optionally, enter one or more modules and/or functions to include in the Esx Runspace.
    [Alias('Include')]
    [string[]]$IncludeModule,
    
    #Switch.  Returns a small set of properties.
    [switch]$Brief,
    
    #Switch. Use the PassThru switch for greater detail on returned object
    [switch]$PassThru
  )

  Process {

    #Create standard modules variable
    $modules = @()
    $modules += 'VMware.PowerCLI.Core'
  
    #Include additional modules and/or functions if needed
    If($IncludeModule){
      $modules += $IncludeModule
    }
  
    #Import the modules and/or functions
    Get-Module -Name $modules -ListAvailable -ErrorAction SilentlyContinue | Import-Module -Global -ErrorAction SilentlyContinue

    #Read in the VMHost parameter (one or more ESX hosts) to create VMHost list
    [System.Collections.Queue]$ServerList = $null
    $ServerList += $VMHost
 
    #Create a synchronized queue out of array
    [System.Collections.Queue]$ServerList = [System.Collections.Queue]::Synchronized( ([System.Collections.Queue]$ServerList) )

    #Create a synchronized array list for results
    $Report = [System.Collections.ArrayList]::Synchronized( (New-Object -TypeName System.Collections.ArrayList) )

    Start-RSJob -ScriptBlock {
      [CmdletBinding()]
      param(
        $ServerList,
        $Report
      )
      
      while ($ServerList.Count -gt 0) {
      
        #take one host from list at a time
        $esx = $ServerList.Dequeue()
      
        #Connect to ESX
        try {
          $null = Connect-VIServer -Server $esx -Credential $Using:Credential -wa 0 -ea Stop
        }
        catch{
          Write-Error -Message ('{0}' -f $_.Exception.Message)
        }

        #Get the ESX Object
        $Script:EsxImpl = Get-VMHost -Server $esx
        
        #Populate report object
        $Report.Add((New-Object -TypeName PSCustomObject -Property @{
              Name                = $EsxImpl | Select-Object -ExpandProperty Name
              State               = $EsxImpl.State
              Version             = $EsxImpl.Version
              Manufacturer        = $EsxImpl.Manufacturer
              Model               = $EsxImpl.Model
              MemoryTotalGB       = [int]$EsxImpl.MemoryTotalGB
              NumCpu              = $EsxImpl.NumCpu
              ProcessorType       = $EsxImpl.ProcessorType
        }))

        #Disconnect from ESX
        try{
          $null = Disconnect-VIServer -Server $esx -Confirm:$false -Force -ErrorAction Stop
        }
        catch{
          Write-Error -Message ('{0}' -f $_.Exception.Message)
        }
      }
    } -ModulesToImport $modules -ArgumentList $ServerList, $Report | Wait-RSJob | Remove-RSJob
  
    #Report results in any order
    If($Report){
      If($PassThru){
        return $Report
      }
      Else{
        #Report results, brief
        If($Brief){
          return $Report | Select-Object -Property Name,State,Version
        }
        Else{
          #Report results, with formatting. This is the default.
          return $Report | Select-Object -Property Name,State,Version,Manufacturer,Model,MemoryTotalGB,NumCpu,ProcessorType
        }
      }
    }
    Else{
      Write-Warning -Message 'No report results!'
    }
  } #End Process
} #End Process
