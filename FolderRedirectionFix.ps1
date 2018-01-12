<#
 
.SYNOPSIS 
This is a Powershell Script that enables you to check and correct permission errors in redirected User Folders.
 
.DESCRIPTION 
Redirected Folders (or Folder Redirection) is a feature of the Windows Operating System. It is widely used, 
especially when Users are using multiple computers which may be the Case in Terminal Server or 
VDI (Virtual Desktop Infrastructure) Deployments. From time to time, it may happen that the Access Control 
Lists (ACLs) in get messed up. This may be caused by a wrong policy or other circumstances and is really 
painful to resolve if you have a big environment with many users.
 
With this Script, you can determine which of the users Folders are having trouble with their Permissions.
 
Please note that you must run the Script...
- on a Windows 7 or 2008 R2 machine
- against an UNC Path
- with write Permissions on your Share and Folders
 
After that, you can enable the -FixErrors Argument and run the script again. It will then fix the errors in the ACLs.
 
.EXAMPLE
.\Filter-DamagedUserFolderACL.ps1 -FolderName \\fs01\UserFolders
 
FullName                      Mode                          Result                        FoundErrors
--------                      ----                          ------                        -----------
\\fs01\UserFolders\User1      Read-Only                     Failed                        No-ReadPermissions
\\fs01\UserFolders\User2      Read-Only                     Success                       Wrong-Permissions
\\fs01\UserFolders\User3      Read-Only                     Success                       Wrong-Owner
\\fs01\UserFolders\User4      Read-Only                     Success                       {Wrong-Owner, Wrong-Pe...
 
Description
-----------
This command retrieves all of the items \\fs01\UserFolders that have an error within their ACLs. This can either 
be that the wrong User is the Owner of the Folder, or that the User doesn't have Full Control Permissions. Please 
note that, at the current state of development, the Script cannot read or fix Folders to which the User running 
the script doesn't have Access tho the Folder.
 
You probably will see that the Script found several Errors:
- No-ReadPermissions: The Script is unable to read the ACL of this folder. This usually happens when the User 
                      running the Script doesn't have any Permissions on the Folder.
- Wrong-Permissions:  The User for this Folder doesn't have Full Control Permissions on his Folder.
- Wrong-Owner:        The User for this Folder is not it's Owner.
 
.EXAMPLE
.\Filter-DamagedUserFolderACL.ps1 -FolderName \\fs01\UserFolders -LogToScreen
 
Invoked on DC01 as CORP\Administrator.
Running in Read-Only Mode.
\\fs01\UserFolders\User1 Error: Cannot check this ACL, probably because we don't have permissions!
\\fs01\UserFolders\User2 ACL Entry Mismatch!
\\fs01\UserFolders\User3 Owner Mismatch!
\\fs01\UserFolders\User4 Owner Mismatch!
\\fs01\UserFolders\User4 ACL Entry Mismatch!
\\fs01\UserFolders\User5 ACL is OK!
\\fs01\UserFolders\User6 ACL is OK!
\\fs01\UserFolders\User7 Error: Couldn't find User User6 in Active Directory!
 
Description
-----------
Adding the -LogToScreen Parameter gives you verbose Output of what is happening. However, you don't get PS Objects 
as Output. You may use -LogToFile instead.
 
.EXAMPLE
.\Filter-DamagedUserFolderACL.ps1 -FolderName \\fs01\UserFolders -LogToFile
 
Description
-----------
Adding the -LogToFile Parameter writes the verbose Output of what is happening to a file. By Default, we will 
create a Folder "Logs" inside the Folder you run the Script in. You max specify a Directory for Log Files with 
the -LogFilePath Argument.
 
.EXAMPLE
.\Filter-DamagedUserFolderACL.ps1 -FolderName \\fs01\UserFolders -FixErrors
 
FullName                      Mode                          Result                        FoundErrors
--------                      ----                          ------                        -----------
\\fs01\UserFolders\User1      Fix-Errors                    Failed                        No-ReadPermissions
\\fs01\UserFolders\User2      Fix-Errors                    Success                       Wrong-Permissions
\\fs01\UserFolders\User3      Fix-Errors                    Success                       Wrong-Owner
\\fs01\UserFolders\User4      Fix-Errors                    Success                       {Wrong-Owner, Wrong-Pe...
 
Description
-----------
This command will fix the Owner and ACL Entry of the Folder if necessary.
 
.EXAMPLE
.\Filter-DamagedUserFolderACL.ps1 -FolderName \\fs01\UserFolders -BackupACLS
 
Description
-----------
This command will backup all the ACLs for the Folders into Text Files. Note that they will be saved into the 
Directory specified by the -LogFilePath Argument.
 
.NOTES
Version
-------
You are using Version 0.1 of the Script.
 
Copyright
---------
The Script was written by: Uwe Stoppel < uwe/at/stoppel.name > <uwe.stoppel/at/cgi.com> < https://heyfryckles.wordpress.com >.
You may use, modify and redistribute it under the Terms of the GNU GPL.
Contact me if you need Support or further development.
 
Credits
-------
The Script was inspired (among others) by...
- https://sites.google.com/site/powershellandphp/powershell-1/files-and-folders/set-folders-acl-owner-and-ntfs-rights
- http://www.energizedtech.com/2010/03/powershell-how-to-add-help-to.html
- https://blogs.technet.com/b/heyscriptingguy/archive/2011/05/15/simplify-your-powershell-script-with-parameter-validation.aspx
- https://leftlobed.wordpress.com/2008/06/04/getting-the-current-script-directory-in-powershell/
- http://fixingitpro.com/2011/07/08/set-owner-with-powershell-%E2%80%9Cthe-security-identifier-is-not-allowed-to-be-the-owner-of-this-object%E2%80%9D/
- https://social.technet.microsoft.com/Forums/zh/winserverpowershell/thread/7f67b415-3ce3-4694-86d6-1a23a257d703
- http://stackoverflow.com/questions/5798096/netbios-domain-of-computer-in-powershell
- http://msdn.microsoft.com/de-de/library/system.security.accesscontrol.objectsecurity.setaccessruleprotection.aspx
- https://blogs.msdn.com/b/powershell/archive/2006/09/15/errorlevel-equivalent.aspx
- http://msdn.microsoft.com/en-us/library/windows/desktop/dd878348(v=vs.85).aspx
- https://www.vistax64.com/powershell/91098-there-equivalent-powershell-get-name-script.html
 
.LINK 
https://heyfryckles.wordpress.com
 
#>
 
param(
 
    [Parameter(Mandatory=$true,  ValueFromPipeline=$true) ] [string]$FolderName,
    [Parameter(Mandatory=$false, ValueFromPipeline=$false)] [string]$LogFilePath,
    [Parameter(Mandatory=$false, ValueFromPipeline=$false)] [switch]$FixErrors = $False,
    [Parameter(Mandatory=$false, ValueFromPipeline=$false)] [switch]$LogToScreen = $False,
    [Parameter(Mandatory=$false, ValueFromPipeline=$false)] [switch]$LogToFile = $False,
    [Parameter(Mandatory=$false, ValueFromPipeline=$false)] [switch]$BackupACLs = $False
 
    # We could need a verbose Switch so that the OK Messages can be hidden
    # We should think about better Parameter validation
 
)
 
begin {
 
}
  
process {
 
    # Returns the Folder the Script is running in
    function Get-ScriptDirectory
    {
        $Invocation = (Get-Variable MyInvocation -Scope 1).Value
        Split-Path $Invocation.MyCommand.Path
    }
 
    # Returns the SID of a Windows User
    function Get-Sid
    {
        param (
            $DSIdentity
        )
        $ErrorActionPreference = "SilentlyContinue"
        $ID = new-object System.Security.Principal.NTAccount($DSIdentity)
        return $ID.Translate([System.Security.Principal.SecurityIdentifier] ).toString()
    }
     
    function Write-Message
    {
     
        param (
            [Parameter(Mandatory=$true) ] [string]$MessageType,
            [Parameter(Mandatory=$true) ] [string]$Message,
            [Parameter(Mandatory=$false)] [bool]$LogToFile = $False,
            [Parameter(Mandatory=$false)] [bool]$LogToScreen = $True
        )
         
        if ($LogToScreen) {
         
            Switch ($MessageType) {
             
                "Success" { $strForeGroundColor = "Green" }
                "Information" { $strForeGroundColor = "White" }
                "Warning" { $strForeGroundColor = "Yellow" }
                "Error" { $strForeGroundColor = "Red" }
 
            }
            Write-Host $Message -ForeGroundColor $strForeGroundColor -BackgroundColor "Black"
             
        }
         
        if ($LogToFile) {
            Write-Output "$(Get-Date -format yyyy-MM-dd_HH-mm): $($Message)" | Out-File $LogFile -Append
        }
     
    }
 
    # If the FolderName Argument has been set...
    # (we don't necessarily need this check as we have parameter validation)
    if ($FolderName) {
     
        # We check if the specified Folder exists...
        if (Test-Path $FolderName) {
             
            # We ultimately need an UNC Path, otherwise we cannot change the Owner of the Folder
            if ([bool]([System.Uri]$FolderName).IsUnc) {
             
                #
                # We could implement another check: Do we have Permission on the Shared Folder defined?
                #
     
                if ($LogToFile -or $BackupACLs) {
     
                    # If the LogFilePath Argument wasnt given, we try to create a Folder under the Script's Directory
                    if (!($LogFilePath)) {
                        $LogFilePath = "$(Get-ScriptDirectory)\LogFiles"
                        $LogFile = "$LogFilePath\$(($MyInvocation.MyCommand).Name)_Log.txt"
                    }
                     
                    # We create the Directory for our Log Files
                    if (!(Test-Path $LogFilePath)) {
                     
                        #
                        # We could implement a routine to check for errors
                        #
                        New-Item "$($LogFilePath)" -ItemType Directory | Out-Null
                    }
                 
                }
         
                # For the LogToScreen and LogToFile Parameters, we will produce some nice Output here...
                Write-Message -MessageType "Information" -Message "Invoked on $([Environment]::MachineName) as $([Environment]::UserDomainName)\$([Environment]::UserName)." -LogToFile $LogToFile -LogToScreen $LogToScreen
         
                # We Log the current Mode of the Script for better understanding what we are doing...
                if ($FixErrors -eq $True) {
                 
                    Write-Message -MessageType "Warning" -Message "Warning! Running in Fix-Errors Mode. We will definitely apply changes to your System!" -LogToFile $LogToFile -LogToScreen $LogToScreen
                    $objPSOutputMode = @{name="Mode"; expression={"Fix-Errors"}}
 
                } else {
                 
                    Write-Message -MessageType "Information" -Message "Running in Read-Only Mode." -LogToFile $LogToFile -LogToScreen $LogToScreen
                    $objPSOutputMode = @{name="Mode"; expression={"Read-Only"}}
                     
                }
         
                Get-ChildItem $FolderName | Foreach-Object {
         
                    $strFolderItem = $_.FullName
 
                    # We get the User Name from the Folder Name
                    $strUserName = Split-Path -leaf -path ($strFolderItem)
                     
                    $strDomainName = [Environment]::UserDomainName
                     
                    # Just a dumb check if there is a corresponding user in AD: We get the User SID from Active Directory. Don't know if this will work with multiple domains.
                    if ($(Get-Sid $strUserName)) {
                     
                        # These are our two Switches:
                        # Do we have the correct Owner? (we assume yes as default)
                        $blOwnerIsCorrect = $True
                         
                        # Did we find our desired ACL Entry for the User (we assume no as default until we find what we want inside the ACL)
                        $blACLEntryFound = $False
                         
                        # Switch if we have to Crack the ACL
                        $blCanWriteToACL = $True
                         
                        # The Array for the Errors we find. It will be starting empty.
                        $arrOutputErrors = @()
                     
                        $objPSOutputName = @{name="FullName"; expression={$strFolderItem}}
                     
                        # We try to read the Folder's ACL.
                        # This may fail if we don't have the right permissions, so we temporarily ignore any errors ;o)
                        $ErrorActionPreference = "SilentlyContinue"
                        $objoldFolderACL = Get-Acl $strFolderItem
                        $ErrorActionPreference = "Continue"
                         
                        if ($objoldFolderACL) {
 
                            # If we made it this far, we can set a pointer that the ACL can be read
                            $blCanReadACL = $True
                         
                            if ($BackupACLs -eq $True) {
                             
                                Write-Output "$(Get-Date -format yyyy-MM-dd_HH-mm): Backup of ACL for User $($strUserName):" | Out-File "$($LogFilePath)\$($strUserName)_ACL.txt" -Append
                                $objoldFolderACL | Format-List | Out-File "$($LogFilePath)\$($strUserName)_ACL.txt" -Append
                             
                            }
                         
                            # We compare the actual owner with the desired one
                            if ($($objoldFolderACL.Owner.substring(($objoldFolderACL.Owner.length - $strUserName.length),$strUserName.length)) -ne $strUserName) {
                                 
                                Write-Message -MessageType "Warning" -Message "$($strFolderItem) Owner Mismatch!"  -LogToFile $LogToFile -LogToScreen $LogToScreen
                                 
                                # If there is a mismatch, we flip the switch
                                $blOwnerIsCorrect = $False
                                 
                                $arrOutputErrors += "Wrong-Owner"
 
                            }
                             
                            # We loop through all Entries in the ACL
                            $objoldFolderACL.Access | Foreach-Object {
                                         
                                # We search for our desired entry
                                if (
                                    ($_.FileSystemRights -eq "FullControl") -and
                                    ($_.AccessControlType -eq "Allow") -and
                                    ($_.IsInherited -eq $False) -and
                                    ($_.IdentityReference.Value.substring(($_.IdentityReference.Value.length - $strUserName.length), $strUserName.length) -eq $strUserName) -and
                                    ($_.InheritanceFlags -eq "ContainerInherit, ObjectInherit") -and
                                    ($_.PropagationFlags -eq "None")
                                ) {
                                    # If found, we flip the switch
                                    $blACLEntryFound = $True
                                }
 
                            }
                             
                            # If the ACL Entry was not found, we want to log this
                            if ($blACLEntryFound -ne $True) {
                                Write-Message -MessageType "Warning" -Message "$($strFolderItem) ACL Entry Mismatch!" -LogToFile $LogToFile -LogToScreen $LogToScreen
                                $arrOutputErrors += "Wrong-Permissions"
                            }
                             
                            #
                            # Here, we could need a third check that recursively loops through the Folder and searches for problems with inherited permissions
                            #
                         
                            # Here is our routine for the Fixing Stuff
                            if ($FixErrors -eq $True) {
 
                                 
                                # We start with the old ACL as the new One
                                $objnewFolderACL = $objoldFolderACL
                                 
                                if ($blOwnerIsCorrect -ne $True) {
                                    Write-Message -MessageType "Information" -Message "$($strFolderItem) Setting $($strDomainName)\$($strUserName) as Owner..." -LogToFile $LogToFile -LogToScreen $LogToScreen
                                     
                                    # We build the Security Principal for the User (we need it to set the owner)
                                    $objSecurityPrincipal = New-Object System.Security.Principal.NTAccount($strDomainName, $strUserName)
                                     
                                    # We set the Owner of the Folder to the Specified User
                                    # This Will only work with UNC Paths
                                    $objnewFolderACL.SetOwner($objSecurityPrincipal)
                                     
                                }
                                 
                                if ($blACLEntryFound -ne $True) {
                                 
                                    Write-Message -MessageType "Information" -Message "$($strFolderItem) Giving $($strDomainName)\$($strUserName) Full Control Permissions..." -LogToFile $LogToFile -LogToScreen $LogToScreen
                                     
                                    # We specify that we want not to protect the folder from the inheritance of permissions
                                    $objnewFolderACL.SetAccessRuleProtection($False, $False)
                                     
                                    # We give the User Full Control Permissions of the Folder
                                    $objACLRule = New-Object System.Security.AccessControl.FileSystemAccessRule($strUserName,"FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")
                                    $objnewFolderACL.AddAccessRule($objACLRule)
                                     
                                }
                                 
                                #
                                # Here, we would fix Inheritance problems
                                #
                                 
                                if (($blACLEntryFound -ne $True) -or ($blOwnerIsCorrect -ne $True)) {
                                 
                                    # We write the new ACL
                                    Set-Acl $strFolderItem $objnewFolderACL
                                     
                                    # We check if the Set-ACL Command was successful...
                                    if ($?) {
                                        $objPSOutputResult = @{name="Result"; expression={"Success"}}
                                        Write-Message -MessageType "Success" -Message "$($strFolderItem) Setting the new ACL Succeeded!" -LogToFile $LogToFile -LogToScreen $LogToScreen
                                    } else {
                                        $objPSOutputResult = @{name="Result"; expression={"Failed"}}
                                        Write-Message -MessageType "Error" -Message "$($strFolderItem) Setting the new ACL Failed!" -LogToFile $LogToFile -LogToScreen $LogToScreen
                                    }
                                 
                                }
                                 
                            } else {
                             
                                # As we didn't do anything, the Result will be a Sccess
                                $objPSOutputResult = @{name="Result"; expression={"Success"}}
                                 
                            }
                         
                        } else {
                             
                            # As we cannot read the ACL, we are neither Owner nor do we have any read permission
                            # We would have to "crack" the folder, that means
                            # 1. The user running the Script will have to take ownership
                            # 2. Then assign himself write permisssion
                            # 3. Then we can set our ACL as we like and remove the permission for ourself
                            # Perhaps we may implement this in the future
 
                            $blCanReadACL = $False
                            $arrOutputErrors += "No-ReadPermissions"
                            $objPSOutputResult = @{name = "Result"; expression={"Failed"}}
                            Write-Message -MessageType "Error" -Message "$($strFolderItem) Error: Cannot check this ACL, probably because we don't have permissions!" -LogToFile $LogToFile -LogToScreen $LogToScreen
                                 
                        }
 
                        if (($blACLEntryFound -ne $True) -or ($blOwnerIsCorrect -ne $True) -or ($blCanReadACL -ne $True)) {
                         
                            if ($LogToScreen -eq $False) {
     
                                $objPSOutputErrors = @{name="FoundErrors"; expression={$arrOutputErrors}}
                                "" | Select-Object $objPSOutputName, $objPSOutputMode, $objPSOutputResult, $objPSOutputErrors
 
                            }
                         
                        } else {
                         
                            Write-Message -MessageType "Success" -Message "$($strFolderItem) ACL is OK!" -LogToFile $LogToFile -LogToScreen $LogToScreen
                             
                        }
                         
                    } else {
                     
                        Write-Message -MessageType "Error" -Message "$($strFolderItem) Error: Couldn't find User $($strUserName) in Active Directory!" -LogToFile $LogToFile -LogToScreen $LogToScreen
                         
                    }
                     
                }
                 
            } else {
             
                Write-Message -MessageType "Error" -Message "$($FolderName) Error: You must specify an UNC Path!" -LogToFile $False -LogToScreen $True
                 
            }
     
        } else {
         
            Write-Message -MessageType "Error" -Message "$($FolderName) Error: The Specified Directory does not Exist!" -LogToFile $False -LogToScreen $True
         
        }
     
    }
     
}
 
end {
 
}
