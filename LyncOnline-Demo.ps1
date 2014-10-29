
# Lync Online Demo Script Tom Arbuthnot Teched 2014

# Variables To Set
$VerbosePreference = 'Continue'
$TenantName = 'tomarbuthnot' 
$credential = Get-Credential

Write-Verbose 'Start an Azure AD Session'
connect-msolservice -credential $credential

Write-Verbose 'Start Lync Online Session'
Import-PSSession (New-CsOnlineSession -Credential $credential)

Write-Verbose 'Start Exchange Online Session (required for Lync Usage Reports)'
Import-PSSession (New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $credential -Authentication Basic -AllowRedirection)

Write-Verbose 'Start a SharePoint Online Session'
Connect-SPOService -Url "https://$TenantName-admin.sharepoint.com" -credential $credential

# Sessions
Get-PSSession | Format-Table -AutoSize

# Get Licence Usage
Get-MsolAccountSku | Format-Table -AutoSize

# Create a New User and emable for All Office 365 Services:

New-MsolUser -UserPrincipalName Tom.TechedEurope@tomarbuthnot.com -DisplayName 'Tom TechedEurope' -FirstName 'Tom' -LastName 'TechedEurope' -UsageLocation GB -LicenseAssignment $((Get-MsolAccountSku).AccountSkuId)
# User will be fored to update password on first sign in

Get-CsOnlineUser -WarningAction silentlycontinue | Select-Object DisplayName,SipAddress,ClientPolicy,ConferencingPolicy



# Global Policy Change: Not allow Meetings to be recorded globally:
Set-CsMeetingConfiguration -AllowConferenceRecording $True -Verbose


# Per User Policy Change


Get-CsClientPolicy | Select-Object identity

Get-CsExternalAccessPolicy | Select-Object Identity

Get-CsConferencingPolicy | Select-Object Identity

# BposS = Small, BposL = Large, BosX = Extra Large

# I have a small, so which are applicable to me, hard to read names so lets space them out

$TidyNames = @()

Get-CsConferencingPolicy | Where-Object {$_.Identity -like 'Tag:BposS*'} | Select-Object Identity | 
ForEach-Object {
            $EasyName = ($_.Identity).Replace('Tag:BposS','') 
            $EasyName2 = ($EasyName -creplace '((?<=[a-z])[A-Z]|[A-Z](?=[a-z]))',' $&')
            
            # Remove Leading Space
            If ( ($EasyName2.StartsWith(' ')) )
              {
              $EasyName2 = $EasyName2.Substring(1) 
              }

            $output = New-Object -TypeName PSobject 
            $output | add-member NoteProperty 'ConferencingPolicy' -value $_.Identity
            $output | add-member NoteProperty 'Description' -value $EasyName2
            $TidyNames += $output }

$TidyNames | Sort-Object Description | Format-table -AutoSize

# FT = File Transfer

# Set one of my users to not be allowed Video

Grant-CsConferencingPolicy -Identity sip:user.one@tomarbuthnot.com -PolicyName Tag:BposSAllModalityNoVideo -Verbose



# Remove Sessions (alternatively they will timeout, but there is a 10 concurrent tennant limit)

Get-PSSession | Remove-PSSession -verbose



