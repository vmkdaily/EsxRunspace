#requires -Version 3
#requires -Modules PoshRSJob,VMware.VimAutomation.Core
Function Invoke-EsxRunspace {
  <#

      .DESCRIPTION
        Connect to one or more VMware ESXi hosts using PowerShell Runspace jobs and return some basic information.

      .NOTES
        Script:           Invoke-EsxRunspace.ps1
        Author:           Mike Nisk
        Prior Art:        Start-RSJob syntax based on VMTN thread:
                          https://communities.vmware.com/thread/513253

        Tested Versions:  Microsoft PowerShell 5.1 (supports 3.0 and later)
                          VMware PowerCLI 6.5.2 (PowerCLI 10.x preferred)
                          PoshRSJob 1.7.3.9
                          ESXi 6.0 U2

      .PARAMETER VMHost
        String. The IP Address or DNS Name of one or more VMware ESXi hosts.

      .PARAMETER Credential
        PSCredential. The login for ESXi.

      .PARAMETER Brief
        Switch. Optionally, return a small set of properties (i.e. Name, Version, and State).

      .PARAMETER PassThru
        Switch. Use the PassThru switch for greater detail on returned object.
        
      .EXAMPLE
      Invoke-EsxRunspace -VMHost esx01.lab.local -Credential (Get-Credential root)
      
      Get prompted for login information and then return a report for a single ESXi host.

      .EXAMPLE
      $CredsESX = Get-Credential root
      $EsxList = @('esx01.lab.local', 'esx02.lab.local', 'esx03.lab.local', 'esx04.lab.local')
      $report = Invoke-EsxRunspace -VMHost $EsxList -Credential $credsESX

      Save a credential to variable and then return a report for several ESXi hosts.

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

      Use Get-Content to feed the Server parameter by pointing to a text file. The text file should have one vCenter Server name per line.

      .Example
      PS C:\> Get-Module -ListAvailable -Name @('PoshRSJob','VMware.PowerCLI') | select Name,Version

      Name            Version
      ----            -------
      PoshRSJob       1.7.4.4
      VMware.PowerCLI 11.0.0.10380590

      This example tests the current client for the required modules. The script and parent module does checking for this as well. The version is not too important; latest is greatest.


      .INPUTS
      none

      .OUTPUTS
      Object
  #>

  [CmdletBinding()]
  Param(

    #String. The IP Address or DNS name of one or more VMware ESXi hosts.
    [Alias('VMHostList')]
    [string[]]$VMHost,

    #PSCredential. The login for ESXi.
    [Parameter(Mandatory)]
    [PSCredential]$Credential,
    
    #Switch. Optionally, return only a small set of properties.
    [switch]$Brief,
    
    #Switch. Use the PassThru switch for greater detail on returned object.
    [switch]$PassThru
  )

  Process {

    ## FAF array for results
    $Report = [System.Collections.ArrayList]::Synchronized((New-Object -TypeName System.Collections.ArrayList))

    Start-RSJob -ScriptBlock {
      #requires -Module VMware.Vimautomation.Core
      [CmdletBinding()]
      param(
        [string[]]$VMHost,
        [System.Collections.ArrayList]$Report
      )

      Foreach($esx in $VMHost){
      
        ## Connect to ESXi host
        try {
          $null = Connect-VIServer -Server $esx -Credential $Using:Credential -wa 0 -ea Stop
        }
        catch{
          Write-Error -Message ('{0}' -f $_.Exception.Message)
          Write-Warning -Message ('Problem connecting to {0} (skipping)!' -f $esx)
          Continue
        }

        ## Get the ESXi Object
        try{
          $EsxImpl = Get-VMHost -Server $esx -WarningAction Ignore -ErrorAction Stop
        }
        catch{
          Write-Error -Message ('{0}' -f $_.Exception.Message)
          Write-Warning -Message ('Problem enumerating ESXi host object for {0} (skipping)!' -f $esx)
          Continue
        }

        #Populate report object
        $Report.Add((New-Object -TypeName PSCustomObject -Property @{
              Name                = [string]$EsxImpl.Name
              State               = [string]$EsxImpl.State
              Version             = [string]$EsxImpl.Version
              Manufacturer        = [string]$EsxImpl.Manufacturer
              Model               = [string]$EsxImpl.Model
              MemoryTotalGB       = [int]$EsxImpl.MemoryTotalGB.ToString("#.#")
              NumCpu              = [Int32]$EsxImpl.NumCpu
              ProcessorType       = [string]($EsxImpl.ProcessorType.ToString() -replace '\s+', ' ')
        }))

        ## Session cleanup
        try{
          $null = Disconnect-VIServer -Server $esx -Confirm:$false -Force -ErrorAction Stop
        }
        catch{
          Write-Error -Message ('{0}' -f $_.Exception.Message)
        }
      }
    } -ArgumentList $VMHost, $Report | Wait-RSJob | Remove-RSJob
  
    ## Handle output
    If($null -ne $Report -and $Report.Count -ge 1){
      If($PassThru){
        return $Report
      }
      Else{
        If($Brief){
          $Report | Select-Object -Property Name,State,Version
        }
        Else{
          ## Default output. Optionally, do some Format-List here, etc.
          $Report | Select-Object -Property Name,State,Version,Manufacturer,Model,MemoryTotalGB,NumCpu,ProcessorType
        }
      }
    }
    Else{
      Write-Warning -Message 'No report results!'
    }
  } #End Process
} #End Function