$csvfilepath = "D:\addvmtoslb.csv"
$inputvalues = Import-Csv -Path $csvfilepath 
write-host "��ȡcsv�ļ�"
#��ѯcsv�ļ�
foreach($myinput in $inputvalues){
#��ȡLB
    $lb = Get-AzureRmLoadBalancer -Name $myinput.lbname -ResourceGroupName $myinput.lbrg
#��ȡLB��backend pool
    $lbbepmark = $false
    foreach($lbbep in  $lb.BackendAddressPools){
        if($lbbep.Name -eq $myinput.backendpoolname){$backendpool = $lbbep; $lbbepmark = $true; break}
    }
    if(!$lbbepmark){write-output "û��backend pool���ڣ�����backendpoolname�����Ƿ���ȷ"}

#��ȡVM
    $vm = Get-AzureRmVM -ResourceGroupName $myinput.vmrg -Name $myinput.vmname
    $vmnicid = $vm.NetworkProfile.NetworkInterfaces[0].Id
    $vmnic = Get-AzureRmNetworkInterface -Name $vmnicid.Split('/')[-1] -ResourceGroupName $vmnicid.Split('/')[4]
#��VM NIC���뵽load balancer
    Set-AzureRmNetworkInterfaceIpConfig -LoadBalancerBackendAddressPoolId $backendpool.Id -NetworkInterface $vmnic -Name $vmnic.IpConfigurations[0].Name -SubnetId $vmnic.IpConfigurations[0].Subnet.Id -PrivateIpAddress $vmnic.IpConfigurations[0].PrivateIpAddress
    Set-AzureRmNetworkInterface -NetworkInterface $vmnic 
}

 