# Script for importing O365 information into AD and removing problematic AD values
# This is meant to prepare an environment for AD Connect
#
#Assumptions:
# Input file is exported from O365, but with samaccountname data added to "sam" column
# Validate the spreadsheet before importing (It'll be easier to add data before the import)
#      Fix any export issues (if users have a comma in the address, the rest of the columns will be on a new line. This needs to be fixed manually.)
#      Country will be assumed to be US unless otherwise specified (and other country codes will be ignored)
#      Phone numbers will be converted to United States E.164 format (+14045551234) if possible. 
#

$inputfile = read-host "Enter the path of the CSV file"

$setattr = $true    #Set user attributes in AD?
$clearlync = $true  #Clear Lync entries in AD?
$setmail = $true   #Set mail and proxy address values?

$users=Import-Csv $inputfile 
 foreach ($user in $users) {
    $displayname = $user.displayname
    Out-Host -InputObject "Editing User $displayname"		
    
    #Verify the user has a samaccountname value (otherwise we can't do anything)
    if ($user.sam -ne ""){
        #Document current state of user properties
        Get-ADUser -identity $user.sam -Properties city,c,co,countrycode,department,fax,mobilephone,office,officephone,postalcode,state,streetaddress,title,emailaddress,proxyaddresses,msRTCSIP-DeploymentLocator,msRTCSIP-FederationEnabled,msRTCSIP-InternetAccessEnabled,msRTCSIP-OptionFlags,msRTCSIP-PrimaryHomeServer,msRTCSIP-PrimaryUserAddress,msRTCSIP-UserEnabled,msRTCSIP-UserPolicies | Select samaccountname,displayname,city,c,co,countrycode,department,fax,mobilephone,office,officephone,postalcode,state,streetaddress,title,emailaddress,@{L='ProxyAddress_0'; E={$_.proxyaddresses[0]}},@{L='ProxyAddress_1';E={$_.ProxyAddresses[1]}},@{L='ProxyAddress_2';E={$_.ProxyAddresses[2]}},@{L='ProxyAddress_3';E={$_.ProxyAddresses[3]}},@{L='ProxyAddress_4';E={$_.ProxyAddresses[4]}},@{L='ProxyAddress_5';E={$_.ProxyAddresses[5]}},@{L='ProxyAddress_6';E={$_.ProxyAddresses[6]}},@{L='ProxyAddress_7';E={$_.ProxyAddresses[7]}},@{L='ProxyAddress_8';E={$_.ProxyAddresses[8]}},@{L='ProxyAddress_9';E={$_.ProxyAddresses[9]}},msRTCSIP-DeploymentLocator,msRTCSIP-FederationEnabled,msRTCSIP-InternetAccessEnabled,msRTCSIP-OptionFlags,msRTCSIP-PrimaryHomeServer,msRTCSIP-PrimaryUserAddress,msRTCSIP-UserEnabled,msRTCSIP-UserPolicies | Export-CSV -LiteralPath "c:\sysadmin\Users-before.csv" -Append -NoTypeInformation
		
        if ($setattr){
            if ($user.city -ne "") {set-aduser -identity $user.sam -City $user.city}
	        if ($user.country -eq "US" -or $user.country -eq "") {set-aduser -identity $user.sam -Replace @{c="US";co="United States";countrycode=840}}
	        if ($user.department -ne "") {set-aduser -identity $user.sam -Department $user.department}
	        if ($user.fax -ne "") {set-aduser -identity $user.sam -Fax Format-E164($user.Fax)}
	        if ($user.mobilephone -ne "") {set-aduser -identity $user.sam -MobilePhone Format-E164($user.MobilePhone)}
	        if ($user.office -ne "") {set-aduser -identity $user.sam -Office $user.Office}
	        if ($user.phonenumber -ne "") {set-aduser -identity $user.sam -OfficePhone Format-E164($user.phonenumber)}
	        if ($user.postalcode -ne "") {set-aduser -identity $user.sam -PostalCode $user.postalcode}
	        if ($user.state -ne "") {set-aduser -identity $user.sam -State $user.state}
	        if ($user.streetaddress -ne "") {set-aduser -identity $user.sam -StreetAddress $user.streetaddress}
	        if ($user.title -ne "") {set-aduser -identity $user.sam -Title $user.title}
        }

        if ($clearlync){
            set-aduser -identity $user.sam -Clear msRTCSIP-DeploymentLocator
            set-aduser -identity $user.sam -Clear msRTCSIP-FederationEnabled
            set-aduser -identity $user.sam -Clear msRTCSIP-InternetAccessEnabled
            set-aduser -identity $user.sam -Clear msRTCSIP-OptionFlags
            set-aduser -identity $user.sam -Clear msRTCSIP-PrimaryHomeServer
            set-aduser -identity $user.sam -Clear msRTCSIP-PrimaryUserAddress
            set-aduser -identity $user.sam -Clear msRTCSIP-UserEnabled
            set-aduser -identity $user.sam -Clear msRTCSIP-UserPolicies
        }

        if ($setmail){
            if ($user.userprincipalname -ne "") {
                set-aduser -identity $user.sam -EmailAddress $user.userprincipalname
                $sip = "sip:"+$user.userprincipalname
                set-aduser -Identity $user.sam -Replace @{Proxyaddresses=$sip}
                $palist = $user.proxyaddresses -split "\+",200
                if ($palist[0] -ne "") {foreach ($pa in $palist) {set-aduser -identity $user.sam -Add @{Proxyaddresses=$pa}}}
            }
        }

	    #Verify properties have been set successfully	
        Get-ADUser -identity $user.sam -Properties city,c,co,countrycode,department,fax,mobilephone,office,officephone,postalcode,state,streetaddress,title,emailaddress,proxyaddresses,msRTCSIP-DeploymentLocator,msRTCSIP-FederationEnabled,msRTCSIP-InternetAccessEnabled,msRTCSIP-OptionFlags,msRTCSIP-PrimaryHomeServer,msRTCSIP-PrimaryUserAddress,msRTCSIP-UserEnabled,msRTCSIP-UserPolicies | Select samaccountname,displayname,city,c,co,countrycode,department,fax,mobilephone,office,officephone,postalcode,state,streetaddress,title,msRTCSIP-DeploymentLocator,emailaddress,@{L='ProxyAddress_0'; E={$_.proxyaddresses[0]}},@{L='ProxyAddress_1';E={$_.ProxyAddresses[1]}},@{L='ProxyAddress_2';E={$_.ProxyAddresses[2]}},@{L='ProxyAddress_3';E={$_.ProxyAddresses[3]}},@{L='ProxyAddress_4';E={$_.ProxyAddresses[4]}},@{L='ProxyAddress_5';E={$_.ProxyAddresses[5]}},@{L='ProxyAddress_6';E={$_.ProxyAddresses[6]}},@{L='ProxyAddress_7';E={$_.ProxyAddresses[7]}},@{L='ProxyAddress_8';E={$_.ProxyAddresses[8]}},@{L='ProxyAddress_9';E={$_.ProxyAddresses[9]}},msRTCSIP-FederationEnabled,msRTCSIP-InternetAccessEnabled,msRTCSIP-OptionFlags,msRTCSIP-PrimaryHomeServer,msRTCSIP-PrimaryUserAddress,msRTCSIP-UserEnabled,msRTCSIP-UserPolicies | Export-CSV -LiteralPath "c:\sysadmin\Users-after.csv" -Append -NoTypeInformation
        
        #Spread out the editing so you can pause if errors occur
        wait-event -timeout 2

    } else {Out-Host -InputObject "Skipped user $displayname, they have no valid SAM"}
}

function Format-E164 ([string]$Number){
    #check to see if it's already in E164 format
    if (($number.substring(0,2) -eq '+1') -and ($number.Length -eq 12)) {return $number}
    
    #strip all characters and check to see if it's the right length
    $onlynumber = $number -replace "\D"
    if ($onlynumber.length -eq 10) {
        $onlynumber= '+1' + $onlynumber
        return $onlynumber
    }

    #check to see if it's got a 1 added to the front already (like a 1800 number)
    if (($onlynumber.length -eq 11) -and ($onlynumber.substring(0,1) -eq '1')){
        $onlynumber= '+' + $onlynumber
        return $onlynumber
    }
    
    #If no match is found, the input will be returned unaltered and we'll need to fix it in post
    return $number
}
