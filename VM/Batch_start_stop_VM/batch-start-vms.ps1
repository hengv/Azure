$jobs = @()
$userinfopath = "D:\user.csv"
$csvfilepath = "D:\batchstartvm.csv"
$inputvalues = Import-Csv -Path $csvfilepath 
$userinfo = Import-Csv -Path $userinfopath
For ( $x=0; $x -lt $inputvalues.Count;$x++)
    {

    $rg = $inputvalues[$x].vmrg
    $vmname = $inputvalues[$x].vmname
    $params = @($rg, $vmname, $userinfo)
    $job = Start-Job -ScriptBlock { 
        param($rg, $vmname,$userinfo)
        $azureAccountName = $userinfo.username
        $azurePassword = ConvertTo-SecureString $userinfo.password -AsPlainText -Force
        $psCred = New-Object System.Management.Automation.PSCredential($azureAccountName, $azurePassword)
        Login-AzureRmAccount -Environment 'AzureChinaCloud' -Credential $psCred 
        Write-Output $rg
        Write-Output $vmname
        Start-AzureRmVM -Name $vmname -ResourceGroupName $rg
     } -ArgumentList $params
     $jobs = $jobs + $job
 }


If($jobs -ne @())
  {
  write-host "Waiting for jobs to complete..." -foregroundcolor yellow -backgroundcolor red
  wait-job -job $jobs
  get-job | receive-job
  }
Else
  {
  write-host "all VMs have been started" -foregroundcolor yellow -backgroundcolor red
  get-azureRMVm
  }