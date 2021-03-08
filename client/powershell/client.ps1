function Display-Popup{
    param(
        [string]$header,
        [string]$message,
    )
    [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
    [System.Windows.Forms.MessageBox]::Show($message,$header)
}

function Display-Notification{
    param(
        [string]$header,
        [string]$message
    )
    [Reflection.Assembly]::loadwithpatrialname('System.Windows.Forms')
    [Reflection.Assembly]::loadwithpatrialname('System.Drawing')
    $notify = new-object system.windows.forms.notifyicon
    $notify.icon = [System.Drawing.SystemIcons]::Information
    $notify.visible = $true
    $notify.showbaloontip(10,$header, $message, [system.windows.forms.tooltopicon]::None)
}

function Validate-Credential {
    param(
        [System.Management.Automation.PSCredential] $credential
    )
    begin{
        Add-Type -AssemblyName System.DirectoryServices.AccountManagement
        $DS = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::"Domain")
    }
    process{
        return $DS.ValidateCredentials($credential.GetNetWorkCredential().UserName, $credential.GetNetWorkCredential().password)
    }
}

function Get-Criteria{
    try
    {
    #Get a list of regex strings to check criteria of passwd
    return Invoke-WebRequest -Uri |
    ConvertFrom-Json
    }
    catch
    {
    $StatusCode = $_.Exception.Response.StatusCode.value__
    }
  }

function Get-PwndStatus{
    param(
        [System.Management.Automation.PSCredential] $credential
    )
    # Create Input Data 
    $md5StringBuilder = New-Object System.Text.StringBuilder 
    $sha1 = [System.Security.Cryptography.HashAlgorithm]::Create("sha1")
    $string   = [system.Text.Encoding]::UTF8.GetBytes($credential.GetNetWorkCredential().password) 
    $sha1 = New-Object System.Security.Cryptography.SHA1CryptoServiceProvider
    $ResultHash = $sha1.ComputeHash($string) | 
    % { [void] $md5StringBuilder.Append($_.ToString("x2")) }

    $hash = $md5StringBuilder.ToString()
    $qs = $hash.SubString(0,5)
    $uri = 'https://api.pwnedpasswords.com/range/' + $qs

    $resp = Invoke-WebRequest $uri | Select-Object -Expand Content
    $suffix = $hash.SubString(5) 
    return $resp -match $suffix
}

function Post-Results{
    

}

function Test-Credential {
    param(
        [System.Management.Automation.PSCredential] $credential
    )
    $passwd = $credential.GetNetWorkCredential().password
    
    $criteria = Get-Criteria 
    $results = @()
    foreach ($crit in $criteria) { 
    $results += @{
        "id" = $crit.id;
 		"result" = $item.title -match $crit.pattern;
    }
    }

    #Get first two chars of passwd to get dictionary slice for comparison
    $pwnedStatus = Get-PwndStatus $credential.GetNetWorkCredential().password

    return @{
        "criteria_results" = $results;
        "pwned_status" = $pwnedStatus
    }
}

function Initiate-Test {
    $maxtries = 3
    $attempts = 0
    $valid = $false
    $creds = Get-Credential
    while($attempts -le $maxtries){
        $attempts++
        if(Validate-Credential($creds)){
            $valid = $true
            break
        }
        Display-Popup "Warning" "Please Enter your Credentials again"
    }
    if($valid){
        $results = Test-Credential $creds
        Post-Results $results
    }
    else{
        Display-Popup "ERROR" "Too many attempts to enter password, a sys admin will be contacting you."
    }
}
