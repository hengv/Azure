

function create-imagefromvmss {
param(
    [Parameter(Mandatory=$true)] 
    [String]$rg,

    [Parameter(Mandatory=$true)] 
    [String]$vmssname, 

    [Parameter(Mandatory=$true)] 
    [String]$Size,

    [Parameter(Mandatory=$true)] 
    [String]$imagename,

    [Parameter(Mandatory=$true)] 
    [String]$vmusername,

    [Parameter(Mandatory=$true)] 
    [String]$vmpassword



)
    #定义变量
    $time = Get-Date
    $vnetname = $rg + 'vnet'

    $datadiskname = $imagename+"data"
    $subhash = $null
    for ($i = 0; $i -le 4; $i++){
        $j = (97..122) | Get-Random -Count 1 | % {[char]$_}
        $subhash = $subhash + $j
    }

    $tmpvmipname = $subhash + 'pip'
    $osdiskname = $subhash + 'vm-osdisk'
    $tmpvmnicname = $subhash + 'nic'
    $tmpvmname = $subhash + 'vm'

    #获取VMSS
    $vmss = Get-AzureRmVmss -ResourceGroupName $rg -VMScaleSetName $vmssname
    #获取VMSS中的instance
    $vmssvms = Get-AzureRmVmssVM -ResourceGroupName $rg -VMScaleSetName $vmssname
    #定位到第一台instance
    $vmssvm = Get-AzureRmVmssVM -ResourceGroupName $rg -VMScaleSetName $vmssname -InstanceId $vmssvms[0].InstanceId
    #抓取第一台instance的OS磁盘和Data磁盘
    $osdiskconfig = New-AzureRmDiskConfig -SourceResourceId $vmssvm.StorageProfile.OsDisk.ManagedDisk.id -SkuName StandardLRS -OsType Linux -CreateOption Copy -Location $vmssvm.Location
    #$datadiskconfig = New-AzureRmDiskConfig -SourceResourceId $vmssvm.StorageProfile.DataDisks[0].ManagedDisk.Id -SkuName StandardLRS -OsType Linux -CreateOption Copy -Location $vmssvm.Location
    #由OS磁盘复制一个新的托管磁盘
    $osdisk = New-AzureRmDisk -ResourceGroupName $rg -DiskName $osdiskname -Disk $osdiskconfig
    
    #由data磁盘复制一个新的托管磁盘
    #$datadisk = $null
    #$datadisk = Get-AzureRmDisk -ResourceGroupName $rg -DiskName $datadiskname -ErrorAction SilentlyContinue
    #if(!$datadisk){
    #$datadisk = New-AzureRmDisk -ResourceGroupName $rg -DiskName $datadiskname -Disk $datadiskconfig
    #}

    #创建临时VM的网卡
    $vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $rg -Name $vnetname
    #网卡需要的pip
    $tmpvmip = New-AzureRmPublicIpAddress -ResourceGroupName $rg -Name $tmpvmipname -Location $vmss.Location -Sku Basic -AllocationMethod Dynamic
    #创建网卡
    $tmpvmnic = New-AzureRmNetworkInterface -Name $tmpvmnicname -ResourceGroupName $rg -Location $vmss.Location -PublicIpAddressId $tmpvmip.Id -SubnetId $vnet.Subnets[0].id
    $tmpvmnic = Get-AzureRmNetworkInterface -ResourceGroupName $rg -Name $tmpvmnicname
    
    #创建虚拟机
    #定义VM大小
    $tmpvm = New-AzureRmVMConfig -VMName $tmpvmname -VMSize $Size
    #定义OS盘 
    $tmpvm = Set-AzureRmVMOSDisk -VM $tmpvm  -ManagedDiskId $osdisk.Id -CreateOption Attach -Linux -StorageAccountType StandardLRS
    #添加Data盘
    #$tmpvm = Add-AzureRmVMDataDisk -VM $tmpvm -ManagedDiskId $datadisk.Id -Lun 1 -CreateOption Attach -StorageAccountType StandardLRS
    #添加网卡
    $tmpvm = Add-AzureRmVMNetworkInterface -VM $tmpvm -Id $tmpvmnic.id -Primary
    #创建临时VM
    $tmpvm = new-azurermvm -ResourceGroupName $rg -Location $vmss.Location -VM $tmpvm
        
    #获取pip地址
    sleep(60)
    Stop-AzureRmVM -ResourceGroupName $rg -Name $tmpvmname -Force
    sleep(60)
    Start-AzureRmVM -ResourceGroupName $rg -Name $tmpvmname 
    sleep(60)
    $pip = Get-AzureRmPublicIpAddress -ResourceGroupName $rg -Name $tmpvmipname

    #ssh到VM中，进行Generalize
    $sUser = $vmusername
    $cPassword = $vmpassword
    $sPassword = $cPassword | ConvertTo-SecureString -AsPlainText -Force 
    $sHost = $pip.IpAddress
    
    $oCredential = New-Object System.Management.Automation.PSCredential($sUser, $sPassword)
    $oSessionSSH = New-SSHSession -ComputerName $sHost -Credential $oCredential -AcceptKey

    $stream = $oSessionSSH.Session.CreateShellStream("PS-SSH", 0, 0, 0, 0, 1000)

    $result = Invoke-SSHStreamExpectSecureAction -ShellStream $stream -Command "sudo su -" -ExpectString "[sudo] password for $($sUser):" -SecureAction $sPassword
    
    if ($result -eq "False"){
        $result = Invoke-SSHStreamExpectSecureAction -ShellStream $stream -Command "sudo su -" -ExpectString "[sudo] password di $($sUser):" -SecureAction $sPassword
    }

    $sReturn = $stream.Read()
    $stream.WriteLine("echo abc@12345678 | passwd root --stdin")
    $stream.WriteLine("echo yes | waagent -deprovision+user")
    sleep -s 2
    $sReturn = $stream.Read()

    Write-Output $sReturn


    #New-SshSession -ComputerName $pip.IpAddress -Username $vmusername -Password $vmpassword 
    #Invoke-SshCommand -ComputerName $pip.IpAddress -Command "echo yes | waagent -deprovision+user"

    #在Azure平台上对VM进行Generalize
    stop-azurermvm -ResourceGroupName $rg -Name $tmpvmname -Force
    Set-AzureRmVM -ResourceGroupName $rg -Name $tmpvmname -Generalized

    #把VM抓取成image
    $vm = get-azurermvm -ResourceGroupName $rg -Name $tmpvmname
    $image = New-AzureRmImageConfig -Location $vm.Location -SourceVirtualMachineId $vm.Id
    New-AzureRmImage -Image $image -ImageName $imagename -ResourceGroupName $rg

    #把相关tmp的资源删除
    remove-azurermvm -ResourceGroupName $rg -Name $tmpvmname -Force
    Remove-AzureRmNetworkInterface -ResourceGroupName $rg -Name $tmpvmnicname -Force
    Remove-AzureRmPublicIpAddress -ResourceGroupName $rg -Name $tmpvmipname -Force
    Remove-AzureRmDisk -ResourceGroupName $rg -DiskName $osdiskname -Force
    Remove-AzureRmDisk -ResourceGroupName $rg -DiskName $datadiskname -Force

}


#定义变量
$time = Get-Date
$rg = "hwvmss01"
$vmssname = "myvmss335"
$Size = 'Standard_A1'
$vmusername = "xxxx"
$vmpassword = "xxxx"
$imagename = $vmssname + "-" + $time.DayOfYear

create-imagefromvmss -rg $rg -vmssname $vmssname -Size $Size -vmusername $vmusername -vmpassword $vmpassword -imagename $imagename

