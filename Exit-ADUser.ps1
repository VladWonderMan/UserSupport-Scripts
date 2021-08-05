Function Exit-ADUser
{
    [CmdletBinding()]
     
    param
    (
     
    [Parameter (Mandatory=$true,Position=0)]
    [string]$SamAccName,
    [switch]$SharedMailbox
    )
    Write-Host "Processing $SamAccName ..." -ForegroundColor Green

    Disable-ADAccount -Identity $SamAccName
    Write-Host "Account Disabled" -ForegroundColor Green

    Get-AdPrincipalGroupMembership -Identity $SamAccName| Where-Object -Property Name -Ne -Value 'Domain Users' | Remove-AdGroupMember -Members $SamAccName -Confirm:$false
    Write-Host "Groups Deleted" -ForegroundColor Green

    Get-ADUser -Identity $SamAccName|Move-ADObject -TargetPath "OU=Disabled Accounts,DC=local,DC=com"
    Write-Host "Moved To Disabled Acounts" -ForegroundColor Green

    Set-ADUser $SamAccName -replace @{msExchHideFromAddressLists="TRUE"}
    Write-Host "Hided from the AddressBook" -ForegroundColor Green

    if ($SharedMailbox.IsPresent)
    {
        Set-Mailbox -Identity $SamAccName -Type Shared
        Write-Host "Turned to SharedMailbox" -ForegroundColor Green
        Write-Host "What user would you like to have a Full Access?" -ForegroundColor Yellow 
 
#FindUser
    $SelectedUser=$null
    while ($True) {
        
        If (!$NameValue) {
            $NameValue = Read-Host "Type User Name"
        }
    
        $UsrFilter = "name -like '*$NameValue*'"

        $Users = Get-ADUser -Filter $UsrFilter -Properties *|Sort-Object name| Select-Object Name,SamAccountName,Mail,Office,OfficePhone,Created,DistinguishedName,GivenName,Surname
        $Users | Add-Member -MemberType NoteProperty -Name Index -Value 0 -Force | Select-Object Name,SamAccountName,Mail,Office,OfficePhone,Created,DistinguishedName

        If (!$Users) {
            Write-Host "No Users Found" -ForegroundColor Red
            $NameValue = $null
            continue
        }
        
        $i=0
        ForEach ($User in $Users) {
            $User.Index = $i
            $i++
        }

        $Users | Format-Table Index,Name,SamAccountName,Mail,Office,OfficePhone,Created,DistinguishedName
        $UserIndex = Read-Host "User Index(Search Again(Y))"
    
        If ($UserIndex -eq "Y") {
            $NameValue = $null
            continue
        }
        $UserIndexInt = [int]$UserIndex
        If ($UserIndexInt -lt $i){
        
            $Users | Select-Object -index $UserIndex | Format-Table Index,Name,SamAccountName,Mail,Office,OfficePhone,Created,DistinguishedName
            $SelectedUser = $Users | Select-Object -index $UserIndex
            break
        }
   }    

        $FAAcname=$SelectedUser.SamAccountName
        $null=Add-MailboxPermission -identity $SamAccName -User $FAAcname -AccessRights FullAccess
        Write-Host "Full Access Provided to $FAAcname" -ForegroundColor Green
        Get-MailboxPermission -identity $SamAccName


    } 

}