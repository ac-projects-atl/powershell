    Connect-MSOLService
    $users = import-csv .\users.csv -delimiter ","
    foreach ($user in $users)
    {
        $upn=$user.UPN
        $usagelocation=$user.usagelocation 
        $SKU=$user.SKU
        Set-MsolUser -UserPrincipalName $upn -UsageLocation $usagelocation
        Set-MsolUserLicense -UserPrincipalName $upn -AddLicenses $SKU
    } 
