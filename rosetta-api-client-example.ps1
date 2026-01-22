<#
    Title: rosetta-api-client-example.ps1
    Authors: Dean Bunn and Wilson Miller
    Last Edit: 2026-01-21
#>

#Custom Object for UC Davis API Information
$global:UCDAPIInfo = [PSCustomObject]@{
                                         base_url = ""
                                         token_url = ""
                                         client_id = ""
                                         client_secret = ""
                                         oauth_token = ""
                                         test_id = "1000024325"
                                       }


#Load API Information from Secrets Vault
$UCDAPIInfo.base_url = Get-Secret -Name "Rosetta-Base-Url" -AsPlainText -Vault UCD-Identities;
$UCDAPIInfo.token_url = Get-Secret -Name "Rosetta-OAuth-Url" -AsPlainText -Vault UCD-Identities;
$UCDAPIInfo.client_id = Get-Secret -Name "Rosetta-Client-ID" -AsPlainText -Vault UCD-Identities;
$UCDAPIInfo.client_secret = Get-Secret -Name "Rosetta-Client-Secret" -AsPlainText -Vault UCD-Identities;
#$UCDAPIInfo.test_id = Get-Secret -Name "Rosetta-Test-ID" -AsPlainText -Vault UCD-Identities;

#Check for Required Client ID and Secret Before Making API Calls
if([string]::IsNullOrEmpty($UCDAPIInfo.client_id) -eq $false -and [string]::IsNullOrEmpty($UCDAPIInfo.client_secret) -eq $false)
{

    ##########################################
    #Retreiving OAuth Token
    ##########################################

    #Configure OAuth Header
    $headersOAuthCall = @{"client_id"=$UCDAPIInfo.client_id;
                          "client_secret"=$UCDAPIInfo.client_secret;
                          "grant_type"="CLIENT_CREDENTIALS";
                          "scope"="read:public"
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

    #Var for Regular EndPoint Headers Calls
    $headersEPCall = @{"Authorization"="Bearer " + $UCDAPIInfo.oauth_token;};

    #########################################
    #Viewing People EndPoint Information
    #########################################

    #Array for Reporting People Objects
    $arrRptPeople = @();

    #Var for People Endpoint Uri with User IAM ID
    $peopleUri = $UCDAPIInfo.base_url + "people?iamid=" + $UCDAPIInfo.test_id;

    #Make Rest Call to Pull People Information
    $peopleInfoJson = Invoke-RestMethod -Uri $peopleUri -Method GET -Headers $headersEPCall | ConvertTo-Json -Depth 5

    #Write-Output ($peopleInfo | ConvertTo-Json -Depth 5).ToString();
    #(Invoke-WebRequest -Uri $peopleUri -Method GET -Headers $headersEPCall).Content | ConvertTo-Json -Depth 5

    #Convert Returned From Properly Formated Json to Object Array
    $peopleData = $peopleInfoJson | ConvertFrom-Json -Depth 7;

    #Loop Through Returned People
    foreach($peopleDatum in $peopleData)
    {
        
        $peopleDatum

        <#
        #Custom Object for 
        $cstUCDPerson = [PSCustomObject]@{
                                            iam_id = ""
                                            displayname = ""
                                            birth_date = ""
                                            manager_iam_id = ""
                                            provisioning_status_primary = ""
                                            name_lived_first_name = ""
                                            name_lived_middle_name = ""
                                            name_lived_last_name = ""
                                            name_legal_first_name = ""
                                            name_legal_middle_name = ""
                                            name_legal_last_name = ""
                                            id_iam_id = ""
                                            id_login_id = ""
                                            id_student_id = ""
                                            id_mothra_id = ""
                                            id_employee_id = ""
                                            id_mail_id = ""
                                            email_primary = ""
                                            email_work = ""
                                            email_personal = ""
                                            phone_primary = ""
                                            phone_personal = ""
                                            modified_date = ""
                                            affiliation = @()
                                            employment_status = @()
                                            student_association = @()
                                            payroll_association = @()
                                        }

        #Set IAM ID
        if([string]::IsNullOrEmpty($peopleDatum.iam_id) -eq $false)
        {
            $cstUCDPerson.iam_id = $peopleDatum.iam_id;
        }

        #Set Display Name
        if([string]::IsNullOrEmpty($peopleDatum.displayname) -eq $false)
        {
            $cstUCDPerson.displayname = $peopleDatum.displayname;
        }

        #Set Birth Date
        if([string]::IsNullOrEmpty($peopleDatum.birth_date) -eq $false)
        {
            $cstUCDPerson.birth_date = $peopleDatum.birth_date;
        }

        #Set Manager IAM ID
        if([string]::IsNullOrEmpty($peopleDatum.manager_iam_id) -eq $false)
        {
            $cstUCDPerson.manager_iam_id = $peopleDatum.manager_iam_id;
        }

        #Set Provisioning Status Primary
        if([string]::IsNullOrEmpty($peopleDatum.provisioning_status.primary) -eq $false)
        {
            $cstUCDPerson.provisioning_status_primary = $peopleDatum.provisioning_status.primary;
        }

        #Set Name Lived First Name
        if([string]::IsNullOrEmpty($peopleDatum.name.lived_first_name) -eq $false)
        {
            $cstUCDPerson.name_lived_first_name = $peopleDatum.name.lived_first_name;
        }
    
        #Set Name Lived Middle Name
        if([string]::IsNullOrEmpty($peopleDatum.name.lived_middle_name) -eq $false)
        {
            $cstUCDPerson.name_lived_middle_name = $peopleDatum.name.lived_middle_name;
        }


        # Add Custom People Object to Reporting Array
        $arrRptPeople += $cstUCDPerson;
        #>
    }

    #Display Reporting Array
    #$arrRptPeople;

}#End of Null\Empty Checks on Client ID and Secret

