<#
    Title: rosetta-api-student-testing.ps1
    Authors: Dean Bunn and Wilson Miller
    Last Edit: 2026-04-24
#>


#Custom Object for UC Davis API Information
$global:UCDAPIInfo = [PSCustomObject]@{
                                         base_url = ""
                                         token_url = ""
                                         client_id = ""
                                         client_secret = ""
                                         oauth_token = ""
                                         test_id = ""
                                         exst_iam_url = ""
                                         exst_iam_cred = ""
                                       }

#Load API Information from Secrets Vault
$UCDAPIInfo.base_url = Get-Secret -Name "Rosetta-Base-Url" -AsPlainText -Vault UCD-Identities;
$UCDAPIInfo.token_url = Get-Secret -Name "Rosetta-OAuth-Url" -AsPlainText -Vault UCD-Identities;
$UCDAPIInfo.client_id = Get-Secret -Name "Rosetta-Client-ID" -AsPlainText -Vault UCD-Identities;
$UCDAPIInfo.client_secret = Get-Secret -Name "Rosetta-Client-Secret" -AsPlainText -Vault UCD-Identities;
$UCDAPIInfo.test_id = Get-Secret -Name "Rosetta-Test-ID" -AsPlainText -Vault UCD-Identities;
$UCDAPIInfo.exst_iam_url = Get-Secret -Name "UCDExst-IAM-Url" -AsPlainText -Vault UCD-Identities;
$UCDAPIInfo.exst_iam_cred = Get-Secret -Name "UCDExst-IAM-Cred" -AsPlainText -Vault UCD-Identities;


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
    #Testing Student Association Information
    #########################################

    #Array for Missing Associations
    $arrMissingAssociations = @();

    #Array of Major Codes
    $mjrCodes = @("ECIV","GCIV","EBIM","GBIM","ECSI","GCSI")

    foreach($mjrCode in $mjrCodes)
    {

        #Hash Table for Rosetta IAM IDs 
        $htRosettaIAMIDs = @{};

        #############################################################
        # Rosetta Pull of All Student Association by Major Code
        #############################################################

        #Var for Payroll Endpoint Uri with Dept Code
        $studentUri = $UCDAPIInfo.base_url + "sisassociation?majorcode=" + $mjrCode;

        #Make Rest Call to Pull Payroll Association Information
        $studentData = Invoke-RestMethod -Uri $studentUri -Method GET -Headers $headersEPCall;

        foreach($ucdsa in $studentData)
        {
            #Check HashTable for Unique IAM 
            if($htRosettaIAMIDs.ContainsKey($ucdsa.iam_id) -eq $false)
            {
                $htRosettaIAMIDs.Add($ucdsa.iam_id,"1");
            }
        }

        #######################################################################
        #Check Existing IAM for the Same Major Code Student Associations
        #######################################################################

        #Var for Uri with Student Associations Lookup
        $eiStudentlUri = $UCDAPIInfo.exst_iam_url + "associations/sis/search?key=" + $UCDAPIInfo.exst_iam_cred + "&v=1.0&retType=people&majorCode=" + $mjrCode;

        #API Call to Existing IAM System for Associations by Major Code
        $eiResults = (Invoke-RestMethod -ContentType "application/json" -Uri $eiStudentlUri).responseData.results

        #Go Through Each Student Association Result
        foreach($eiResult in $eiResults)
        {
            
            #Safety Check HashTable for Rosetta Entries. If Not Report Out
            if($htRosettaIAMIDs.ContainsKey($eiResult.iamId) -eq $false)
            {
                #Display IAMId and Major Code to Script User
                write-output $eiResult.iamId;

                #Custom Object for Missing Association Information
                $cstMissingAssoc = [PSCustomObject]@{ iamId = ""
                                                      userID = ""
                                                      dFullName = ""
                                                      majorCode = ""
                                                    };

                $cstMissingAssoc.iamId = $eiResult.iamId;
                $cstMissingAssoc.userID = $eiResult.userId;
                $cstMissingAssoc.dFullName = $eiResult.dFullName;
                $cstMissingAssoc.majorCode = $mjrCode;

                # Add Custom Object to Reporting Array
                $arrMissingAssociations += $cstMissingAssoc;

            }#End of IAM ID Check on $htRosettaIAMIDs

        }#End of $eiResults Foreach
           
    }#End of $mjrCodes Foreach

    #Missing Associations Information to CSV
    $arrMissingAssociations | Select-Object -Property iamId,userID,dFullName,majorCode | Export-Csv -Path ("IAM_Missing_Student_Associations_" + (Get-Date).ToString("yyyy-MM-dd-HH-mm") + ".csv") -NoTypeInformation;

}