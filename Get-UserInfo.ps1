Function Get-UserInfo {
     
    [CmdletBinding()] 
    param ([string]$NameValue) 


	
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
			
				Get-ADUser -Identity  $SelectedUser.SamAccountName -Properties msDS-UserPasswordExpiryTimeComputed,* |Format-List Name,EmailAddress,LastLogonDate,@{n="LastLogon";e={[datetime]::FromFileTime($_.LastLogon)}},logonCount,Description,Office,OfficePhone,MobilePhone,Enabled,LockedOut,PasswordExpired,PasswordLastSet,LastBadPasswordAttempt,@{n="PasswordExpires";e={[datetime]::FromFileTime($_.'msDS-UserPasswordExpiryTimeComputed')}},When*,DistinguishedName
            
				Write-Host "User Groups:"
				Write-Host "-------------"
				Get-ADPrincipalGroupMembership -Identity $SelectedUser.SamAccountName  |Sort-Object GroupCategory,Name| Format-Table Name,GroupCategory -AutoSize
				Get-AzureADUserRegisteredDevice -ObjectId $SelectedUser.Mail | Select-Object DisplayName, DeviceOSType

				Get-MSolUser -UserPrincipalName  $SelectedUser.Mail | Format-List UserPrincipalName, DisplayName, @{n="MFA State"; e={$_.StrongAuthenticationRequirements.State}},@{n="MFA Phone Number"; e={($_.StrongAuthenticationUserDetails).PhoneNumber}},@{n="Device Name"; e={($_.StrongAuthenticationPhoneAppDetails).DeviceName}}, @{n="Methods"; e={($_.StrongAuthenticationMethods).MethodType}}, @{n="Default Method"; e={($_.StrongAuthenticationMethods).IsDefault}}
        
                #Get Personal Email
                
				$UPersEmailList=Import-Excel "C:\EmailList.xlsx" -StartRow 4 -NoHeader
				$UPersEmailList | where P1 -Like "$($SelectedUser.Surname),*" | Format-Table P1,P3
				$UPersEmailList | where P5 -Like "$($SelectedUser.Surname),*" | Format-Table P5,P7

				$CompFilter = "Description -like '*$($SelectedUser.Name)*'"
				Get-ADComputer -Filter $CompFilter -Properties *|Sort-Object -Descending lastLogonTimestamp| Select-Object Name,OperatingSystem,Description,@{Name="LastLogon"; Expression={[DateTime]::FromFileTime($_.lastLogonTimestamp)}},Created,DistinguishedName | Format-Table

                break
            }
       }    
}