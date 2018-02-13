function remove-oldvmss {
param(
    [Parameter(Mandatory=$true)] 
    [String]$loc,

    [Parameter(Mandatory=$true)] 
    [String]$rg,

    [Parameter(Mandatory=$true)] 
    [String]$vmssName
)

    $vmss1 = get-azurermvmss -ResourceGroupName $rg -vmscalesetname $vmssname
    $vmss1lbname = $vmss1.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations[0].IpConfigurations[0].LoadBalancerBackendAddressPools[0].Id.Split('/')[8]
    $vmss1lb = Get-AzureRmLoadBalancer -ResourceGroupName $rg -Name $vmss1lbname 
    $vmss1lbipid = $vmss1lb.FrontendIpConfigurations[0].PublicIpAddress.Id
    $vmss1lbipname = $vmss1lbipid.Split('/')[8]
    remove-azurermvmss -ResourceGroupName $rg -VMScaleSetName $vmssName -Force
    Remove-AzureRmLoadBalancer -ResourceGroupName $rg -Name $vmss1lbname -Force
    Remove-AzureRmPublicIpAddress -ResourceGroupName $rg -Name $vmss1lbipname -Force
}


$loc = 'chinanorth';
$rg = 'hwvmss01';
$vmssName = "hwvmss01335"

remove-oldvmss -loc $loc -rg $rg -vmssName $vmssName


