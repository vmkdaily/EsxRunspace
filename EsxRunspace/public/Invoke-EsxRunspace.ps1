#requires -Version 3
#Requires -Modules PoshRSJob,VMware.VimAutomation.Core
Function Invoke-EsxRunspace {
  <#

      .DESCRIPTION
        Connects to one or more VMware ESX hosts using PowerShell Runspace jobs.
        Returns a default report with basic ESX info.

      .NOTES
        Script:           Invoke-EsxRunspace.ps1
        Author:           Mike Nisk
        Prior Art:        Start-RSJob syntax based on VMTN thread:
                          https://communities.vmware.com/thread/513253

        Tested Versions:  Microsoft PowerShell 5.1 (supports 4.0 and later)
                          VMware PowerCLI 6.5.2 (PowerCLI 10.x preferred)
                          PoshRSJob 1.7.3.9
                          ESXi 6.0 U2

      .PARAMETER VMHost
        String. IP Address or DNS Name of one or more ESX hosts.

      .PARAMETER Credential
        PSCredential. The login credential for ESX.

      .PARAMETER Brief
        Switch.  Returns a small set of properties (Name, Version, and State).

      .PARAMETER PassThru
        Switch. Use the PassThru switch for greater detail on returned object.
        Does not format or sort by design.

      .EXAMPLE
      $CredsESX = Get-Credential root
      Invoke-EsxRunspace -VMHost esx01.lab.local -Credential $credsESX
      Save a credential to a variable and then connect to a single ESX host,
      running the default commands in the function.

      .EXAMPLE
      $CredsESX = Get-Credential root
      $EsxList = @('esx01.lab.local', 'esx02.lab.local', 'esx03.lab.local', 'esx04.lab.local')
      Invoke-EsxRunspace -VMHost $EsxList -Credential $credsESX

      .EXAMPLE
      $credsESX = Get-Credential root
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

      .INPUTS
      none

      .OUTPUTS
      Object
  #>

  [CmdletBinding()]
  Param(

    #IP Address or DNS name of one or more VMware ESXi hosts.
    [Alias('VMHostList')]
    [string[]]$VMHost,

    #PSCredential.  Login for ESX (i.e. root).
    [Parameter(Mandatory)]
    [PSCredential]$Credential,
    
    #Switch. Returns a small set of properties.
    [switch]$Brief,
    
    #Switch. Use the PassThru switch for greater detail on returned object.
    [switch]$PassThru
  )

  Process {

    #Read in the VMHost parameter (one or more ESX hosts) to create VMHost list
    [System.Collections.Queue]$ServerList = $null
    $ServerList += $VMHost
 
    #Create a synchronized queue out of array
    [System.Collections.Queue]$ServerList = [System.Collections.Queue]::Synchronized( ([System.Collections.Queue]$ServerList) )

    #Create a synchronized array list for results
    $Report = [System.Collections.ArrayList]::Synchronized( (New-Object -TypeName System.Collections.ArrayList) )

    Start-RSJob -ScriptBlock {
      #requires -Module VMware.Vimautomation.Core
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

        #Get the ESX Object and VM counts
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
    } -ArgumentList $ServerList, $Report | Wait-RSJob | Remove-RSJob
  
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
          #Report results, Default
          return $Report | Select-Object -Property Name,State,Version,Manufacturer,Model,MemoryTotalGB,NumCpu,ProcessorType
        }
      }
    }
    Else{
      Write-Warning -Message 'No report results!'
    }
  } #End Process
} #End Process