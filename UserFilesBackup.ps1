#Find and copy user Folders on specified PCs

Function UserBackup {

$PCList = Get-Content C:\Computers.txt | Get-ADComputer -Properties Name,Description
$BackupFolder = "F:\BranchName\"

$PCList | ForEach-Object {

    #Check if PC online
    if(Test-Connection -CN $_.dnshostname -Count 1 -BufferSize 16 -Quiet) {

        $PCName = $_.Name
        $PCDescription = $_.Description
        $UsersDir = "\\" + $PCName + "\C$\Users\"

        Write-Host "-=== $PCName $PCDescription ===-" -ForegroundColor Yellow

        #Check if network share is available
        if(Test-Path $UsersDir -ErrorAction Ignore){

            $RemoveList=[System.Collections.ArrayList]@(
            "john*","vlad*","temp*",
            "edvord*","brad*","linda*","bob*",
            "public","user*","greg*","*admin*")
            $SamNameList=[System.Collections.ArrayList]((Get-ChildItem $UsersDir).Name).ToLower()
            $RemoveList.ForEach({
                $RemoveItem = $_
                ($SamNameList | Where-Object {$_ -like $RemoveItem}).ForEach({ $SamNameList.Remove($_) })
            })

            $SamNameList.ForEach({

                $PCBackupFolder = $BackupFolder + $PCName + "_" + $PCDescription.Replace(" ","")
                $UserBackupFolder = $PCBackupFolder + "\" + $_
                $UserPathDir = $UsersDir + $_
                $UserBackupFolderDesk=$UserBackupFolder + "\Desktop"
                $UserBackupFolderDoc = $UserBackupFolder + "\Documents"
                $RobocopyArg = "/S /ZB /NP /NFL /NJH /XA:SH /TEE /TBD /XJD /R:5 /W:5 /MT:16 /XF '*.pst' '*.lnk' '*.exe'" 

                $UserBookmarks = $UserPathDir + "\AppData\Local\Google\Chrome\User Data\Default\Bookmarks"
                $UserDocPath = $UserPathDir + "\Documents"
                $UserDeskPath = $UserPathDir + "\Desktop"
                $UserFavPath = $UserPathDir + "\Favorites"

                $UserBookmarksEnable = $false
                $UserDocEnable = $false
                $UserDeskEnable = $false
                $UserFavEnable = $false
                $UserPSTEnable = $false
                
                Write-Host "Checking Directories in $_..." -ForegroundColor Yellow
                #check if UserBookmarks dir exist
                    if(Test-Path $UserBookmarks -ErrorAction Ignore){
                         Write-Host "Bookmarks Copy Enabled" -ForegroundColor Green
                         $UserBookmarksEnable = $true
                    }

                   If ( Get-ChildItem -Path $UserDocPath  -Recurse -ErrorAction SilentlyContinue -Depth 1 -Include *.pdf, *.doc, *.xls, *.jpg, *docx, *.xlsx| Select-Object Name,FullName){
                        Write-Host "Documents Copy Enabled" -ForegroundColor Green
                        $UserDocEnable = $true
                   }

                   If ( Get-ChildItem -Path $UserDeskPath  -Recurse -ErrorAction SilentlyContinue -Depth 1 -Include *.pdf, *.doc, *.xls, *.jpg, *docx, *.xlsx| Select-Object Name,FullName){
                        Write-Host "Desktop Copy Enabled" -ForegroundColor Green
                        $UserDeskEnable = $true
                   }

                   If ( (Get-ChildItem -Path $UserFavPath  -Recurse -ErrorAction SilentlyContinue -Depth 0 -Filter *.url | Select-Object Name,FullName | Measure-Object).count -gt 4){
                        Write-Host "Favorites Copy Enabled" -ForegroundColor Green
                        $UserFavEnable = $true
                   }

                   Write-Host "Looking for PST Files..." -ForegroundColor Green
                   $UserPSTFiles = Get-ChildItem -Path $UserPathDir -Filter *.pst -Recurse -ErrorAction SilentlyContinue | Select-Object Name,FullName
                   
                   If ( $UserPSTFiles ){
                    Write-Host "PST Copy Enabled" -ForegroundColor Green
                    $UserPSTEnable = $true
                   }

                   if ( $UserBookmarksEnable -or $UserDocEnable -or $UserDeskEnable -or $UserFavEnable -or $UserPSTEnable  ){
                    
                    CreateBackupFolder -PCBackupFolder $PCBackupFolder -UserBackupFolder $UserBackupFolder

                        if ($UserBookmarksEnable) {
                            Write-Host "Copying Bookmarks to $UserBackupFolder ..."
                            Copy-Item $UserBookmarks -Destination $UserBackupFolder
                        }

                        if ($UserDocEnable) {
                            Write-Host "Copying Documents to $UserBackupFolder ..."
                            robocopy $UserDocPath $UserBackupFolderDoc /S /ZB /NP /NFL /NJH /XA:SH /TEE /TBD /XJD /R:5 /W:5 /MT:16 /XF '*.pst' '*.lnk' '*.exe'
                            # Copy-Item $UserDocPath -Destination $UserBackupFolder -Recurse -Exclude *.pst, *.lnk, *.exe
                        }

                        if ($UserDeskEnable) {
                            Write-Host "Copying Desktop to $UserBackupFolder ..."
                            robocopy $UserDeskPath $UserBackupFolderDesk /S /ZB /NP /NFL /NJH /XA:SH /TEE /TBD /XJD /R:5 /W:5 /MT:16 /XF '*.pst' '*.lnk' '*.exe'
                            # Copy-Item $UserDeskPath -Destination $UserBackupFolder -Recurse -Exclude *.pst, *.lnk, *.exe
                        }
                        if ($UserFavEnable) {
                            Write-Host "Copying Favorites to $UserBackupFolder ..."
                            Copy-Item $UserFavPath -Destination $UserBackupFolder -Recurse -Exclude *.pst, *.lnk, *.exe
                        }

                        if ($UserPSTEnable) {
                            
                            ForEach($UserPSTFile in $UserPSTFiles) {
                                Write-Host "Copying PST Files $($UserPSTFile.FullName) ..."
                                Copy-Item $UserPSTFile.FullName -Destination $UserBackupFolder
                            }
                        }   

                   }
                
            })    
        }
    }
  }
}


Function CreateBackupFolder($PCBackupFolder,$UserBackupFolder) {


    
    if(!(Test-Path $PCBackupFolder -ErrorAction Ignore)){
                           
        Write-Host "Make a New PC Backup Folder" $PCBackupFolder
        $null = New-Item -Path $PCBackupFolder -ItemType Directory

    }

    if(!(Test-Path $UserBackupFolder -ErrorAction Ignore)){

        Write-Host "Make a New User Backup Folder" $UserBackupFolder
        $null = New-Item -Path $UserBackupFolder -ItemType Directory
    }


}

