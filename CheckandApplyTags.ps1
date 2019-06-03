#Login to Azure
Login-AzureRmAccount

#Allow user to select subscription(s)
$SelectedSubscriptions = 
Get-AzureRmSubscription | 
Select-Object -Property Name, Id | 
Sort-Object -Property Name | 
Out-GridView -PassThru -Title 'Select subscription (hold Ctrl for multiple)' 

#List all Resources within the Subscription
$SelectedSubscriptions | % {
    $subscription = $_
    Write-Host "`n`nProcessing subcription $($subscription.Name)"
    Select-AzureRmSubscription $subscription.Id
    $Resources = Get-AzureRmResource

    #For each Resource apply the Tag of the Resource Group
    Foreach ($resource in $Resources) {
        $Rgname = $resource.Resourcegroupname

        $resourceid = $resource.resourceId
        $RGTags = (Get-AzureRmResourceGroup -Name $Rgname).Tags

        #only make changes if the resource group has some tags to apply
        if ($RGTags -ne $null) { 
            $resourcetags = $resource.Tags
            If ($resourcetags -eq $null) {
                Write-Output "---------------------------------------------"
                Write-Output "Applying the following Tags to $($resourceid)" $RGTags
                Write-Output "---------------------------------------------"
                $Settag = Set-AzureRmResource -ResourceId $resourceid -Tag $RGTags -Force
            
            }
            else {
                $RGTagFinal = @{ }
                $RGTagFinal = $resourcetags                  
                Foreach ($resourcGroupTag in $RGTags.GetEnumerator()) {                
                    If ($RGTagFinal.Keys -inotcontains $resourcGroupTag.Key) {                        
                        Write-Output "------------------------------------------------"
                        Write-Output "Add tag to resource" $resourcGroupTag
                        Write-Output "------------------------------------------------"
                        $RGTagFinal.Add($resourcGroupTag.Key, $resourcGroupTag.Value)
                    }    
                }
                Write-Output "---------------------------------------------"
                Write-Output "Applying the following Tags to $($resourceid)" $RGTagFinal
                Write-Output "---------------------------------------------"
                $Settag = Set-AzureRmResource -ResourceId $resourceid -Tag $RGTagFinal -Force
            }   
        }
    }
}
