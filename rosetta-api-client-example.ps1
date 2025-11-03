<#
    Title: rosetta-api-client-example.ps1
    Authors: Dean Bunn and Wilson Miller
    Last Edit: 2025-11-03
#>

#Custom Object for UC Davis API Information
$global:UCDAPIInfo = [PSCustomObject]@{
                                         base_url = ""
                                         token_url = ""
                                         client_id = ""
                                         client_secret = ""
                                         oauth_token = ""
                                         test_id = ""
                                       }


#Load API Information from Secrets Vault
$UCDAPIInfo.base_url = Get-Secret -Name "Rosetta-Base-Url" -AsPlainText -Vault UCD-Identities;
$UCDAPIInfo.token_url = Get-Secret -Name "Rosetta-OAuth-Url" -AsPlainText -Vault UCD-Identities;
$UCDAPIInfo.client_id = Get-Secret -Name "Rosetta-Client-ID" -AsPlainText -Vault UCD-Identities;
$UCDAPIInfo.client_secret = Get-Secret -Name "Rosetta-Client-Secret" -AsPlainText -Vault UCD-Identities;
$UCDAPIInfo.test_id = Get-Secret -Name "Rosetta-Test-ID" -AsPlainText -Vault UCD-Identities;

#Check for Required Client ID and Secret Before Making API Calls
if([string]::IsNullOrEmpty($UCDAPIInfo.client_id) -eq $false -and [string]::IsNullOrEmpty($UCDAPIInfo.client_secret) -eq $false)
{

    #Configure OAuth Header
    $headersOAuthCall = @{"client_id"=$UCDAPIInfo.client_id;
                          "client_secret"=$UCDAPIInfo.client_secret;
                          "grant_type"="CLIENT_CREDENTIALS";
                         }

    #Make Rest Call to Token EndPoint to Get Access Token
    $rtnTokenInfo = Invoke-RestMethod -Uri $UCDAPIInfo.token_url -Method POST -Headers $headersOAuthCall;

    #Check for Return Access Token 
    if([string]::IsNullOrEmpty($rtnTokenInfo.access_token) -eq $false)
    {
        $UCDAPIInfo.oauth_token = $rtnTokenInfo.access_token;
    }
    else 
    {
        #Terminate Script Due to Token wasn't Returned
        exit;
    }#End of Null\Empty Check on Access Token

    #Var for Account EndPoint Uri with User IAM ID
    $accountsUri = $UCDAPIInfo.base_url + "accounts?iamid=" + $UCDAPIInfo.test_id;

    #Var for Regular EndPoint Headers Calls
    $headersEPCall = @{"Authorization"="Bearer " + $UCDAPIInfo.oauth_token;};

    #Make Rest Call to Pull Accounts Information
    $arrAccountInfo = Invoke-RestMethod -Uri $accountsUri -Method GET -Headers $headersEPCall;

    #Check for Returned Accounts
    if($arrAccountInfo.Count -gt 0)
    {
        #Loop Through Accounts Listed for Member
        foreach($accountInfo in $arrAccountInfo)
        {
            #Check for the UCPath Positions
            if($accountInfo.AccountName -eq "UCPath Position Entitlement")
            {

                foreach($ucpathPEAttribute in $accountInfo.attributes)
                {
                    $ucpathPEAttribute
                }
            }
        }

    }#End of Empty Check on $arrAccountInfo

}#End of Null\Empty Checks on Client ID and Secret

