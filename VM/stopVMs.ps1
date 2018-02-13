$vmnames = @('shhqmds19','shhqmds01','shhqtf2np23','shhqmds02','shhqmds25','shhqmds03','shhqmds07','shhqgqs14','shhqgqs18','shhqnewsds12','shhqtf1np02','shhqnewsds01','shhqnewsds26','shhqgqs09','shhqzookeeper02','shhqmds09','shhqmds13','shhqmds15','shhqmds23','shhqgqs08','shhqmds18','shhqmds08','shhqmds12','shhqgqs11','shhqicms44')

$vms = Get-AzureRmVM


foreach($vmname in $vmnames){
    

    foreach($vm in $vms){
        if($vm.Name -eq $vmname){
            Write-Host "RG" = $vm.ResourceGroupName
            Write-Host "VM" = $vm.name
                        Stop-AzureRmVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -Force
            }
    }
}

