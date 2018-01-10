Set-ExecutionPolicy RemoteSigned
$cred = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $cred -Authentication Basic –AllowRedirection
Import-PSSession $Session
