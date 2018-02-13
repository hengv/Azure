$csvfilepath = "D:\addvmtoslb.csv"
$inputvalues = Import-Csv -Path $csvfilepath 
write-host "读取csv文件"
#轮询csv文件
foreach($myinput in $inputvalues){
#获取LB
    $lb = Get-AzureRmLoadBalancer -Name $myinput.lbname -ResourceGroupName $myinput.lbrg
#获取LB的backend pool
    $lbbepmark = $false
    foreach($lbbep in  $lb.BackendAddressPools){
        if($lbbep.Name -eq $myinput.backendpoolname){$backendpool = $lbbep; $lbbepmark = $true; break}
    }
    if(!$lbbepmark){write-output "没有backend pool存在，请检查backendpoolname参数是否正确"}

#获取VM
    $vm = Get-AzureRmVM -ResourceGroupName $myinput.vmrg -Name $myinput.vmname
    $vmnicid = $vm.NetworkProfile.NetworkInterfaces[0].Id
    $vmnic = Get-AzureRmNetworkInterface -Name $vmnicid.Split('/')[-1] -ResourceGroupName $vmnicid.Split('/')[4]
#把VM NIC加入到load balancer
    Set-AzureRmNetworkInterfaceIpConfig -LoadBalancerBackendAddressPoolId $backendpool.Id -NetworkInterface $vmnic -Name $vmnic.IpConfigurations[0].Name -SubnetId $vmnic.IpConfigurations[0].Subnet.Id -PrivateIpAddress $vmnic.IpConfigurations[0].PrivateIpAddress
    Set-AzureRmNetworkInterface -NetworkInterface $vmnic 
}

 