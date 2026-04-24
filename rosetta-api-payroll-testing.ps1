<#
    Title: rosetta-api-payroll-testing.ps1
    Authors: Dean Bunn and Wilson Miller
    Last Edit: 2026-03-30
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
    #Testing Payroll Association Information
    #########################################

    #Array for Reporting Association Objects
    $arrRptPayroll = @();

    #Array for Missing Assignments
    $arrMissingAssignments = @();

    #Hash Table for Rosetta IAM IDs 
    $htRosettaIAMIDs = @{};

    #Array of Department Codes
    $dptCodes = @("061000","061001","061002","061004","061015","061024","061027","061031","061500","061510","063004","063007","063016")
    

    foreach($dptCode in $dptCodes)
    {
        #############################################################
        # Rosetta Pull of All Payroll Association by Department Code
        #############################################################

        #Var for Payroll Endpoint Uri with Dept Code
        $payrollUri = $UCDAPIInfo.base_url + "ppsassociation?departmentid=" + $dptCode;

        #Make Rest Call to Pull Payroll Association Information
        $payrollData = Invoke-RestMethod -Uri $payrollUri -Method GET -Headers $headersEPCall;

        #Loop Through Returned Payroll Data
        foreach($ucdpa in $payrollData)
        {
            #Custom Object for Payroll Association
            $cstPayrollAssoc = [PSCustomObject]@{
                                                    iam_id                                  = ""
                                                    employee_id                             = ""
                                                    employee_record                         = ""
                                                    position_number                         = ""
                                                    position_title                          = ""
                                                    relationship_to_organization            = ""         
                                                    employee_classification                 = ""
                                                    employee_classification_description     = ""
                                                    status                                  = ""
                                                    hire_date                               = ""
                                                    start_date                              = ""
                                                    termination_date                        = ""
                                                    fte_percentage                          = ""
                                                    reports_to_position                     = ""
                                                    reports_to_iam_id                       = ""
                                                    reports_to_employee_id                  = ""
                                                    job_type_id                             = ""
                                                    job_type_description                    = ""
                                                    job_family_id                           = ""
                                                    job_family_description                  = ""
                                                    organization_id                         = ""
                                                    organization_title                      = ""
                                                    division_id                             = ""
                                                    division_title                          = ""
                                                    subdivision_id                          = ""
                                                    subdivision_title                       = ""
                                                    business_unit_id                        = ""
                                                    business_unit_title                     = ""
                                                    department_id                           = ""
                                                    department_title                        = ""
                                                    department_short_title                  = ""
                                                    is_health_employee                      = ""
                                                    is_campus_employee                      = ""
                                                    modified_date                           = ""
                                                    create_date                             = ""
                                                };
            
            #Load Payroll Associations
            $cstPayrollAssoc.iam_id = $ucdpa.iam_id;
            $cstPayrollAssoc.employee_id = $ucdpa.employee_id;
            $cstPayrollAssoc.employee_record = $ucdpa.employee_record;
            $cstPayrollAssoc.position_number = $ucdpa.position_number;
            $cstPayrollAssoc.position_title = $ucdpa.position_title;
            $cstPayrollAssoc.relationship_to_organization = $ucdpa.relationship_to_organization;
            $cstPayrollAssoc.employee_classification = $ucdpa.employee_classification;
            $cstPayrollAssoc.employee_classification_description = $ucdpa.employee_classification_description;
            $cstPayrollAssoc.status = $ucdpa.status;
            $cstPayrollAssoc.hire_date = $ucdpa.hire_date;
            $cstPayrollAssoc.start_date = $ucdpa.start_date;
            $cstPayrollAssoc.termination_date = $ucdpa.termination_date;
            $cstPayrollAssoc.fte_percentage = $ucdpa.fte_percentage;
            $cstPayrollAssoc.reports_to_position = $ucdpa.reports_to_position;
            $cstPayrollAssoc.reports_to_iam_id = $ucdpa.reports_to_iam_id;
            $cstPayrollAssoc.reports_to_employee_id = $ucdpa.reports_to_employee_id;
            $cstPayrollAssoc.job_type_id = $ucdpa.job_type_id;
            $cstPayrollAssoc.job_type_description = $ucdpa.job_type_description;
            $cstPayrollAssoc.job_family_id = $ucdpa.job_family_id;
            $cstPayrollAssoc.job_family_description = $ucdpa.job_family_description;
            $cstPayrollAssoc.organization_id = $ucdpa.organization_id;
            $cstPayrollAssoc.organization_title = $ucdpa.organization_title;
            $cstPayrollAssoc.division_id = $ucdpa.division_id;
            $cstPayrollAssoc.division_title = $ucdpa.division_title;
            $cstPayrollAssoc.subdivision_id = $ucdpa.subdivision_id;
            $cstPayrollAssoc.subdivision_title = $ucdpa.subdivision_title;
            $cstPayrollAssoc.business_unit_id = $ucdpa.business_unit_id;
            $cstPayrollAssoc.business_unit_title = $ucdpa.business_unit_title;
            $cstPayrollAssoc.department_id = $ucdpa.department_id;
            $cstPayrollAssoc.department_title = $ucdpa.department_title;
            $cstPayrollAssoc.department_short_title = $ucdpa.department_short_title;
            $cstPayrollAssoc.is_health_employee = $ucdpa.is_health_employee;
            $cstPayrollAssoc.is_campus_employee = $ucdpa.is_campus_employee;
            $cstPayrollAssoc.modified_date = $ucdpa.modified_date;
            $cstPayrollAssoc.create_date = $ucdpa.create_date;                               

            # Add Custom Payroll Object to Reporting Array
            $arrRptPayroll += $cstPayrollAssoc;

            #For Unique IAM IDs Counts
            [string]$tmpIDPosID = $ucdpa.iam_id + "-" + $ucdpa.position_number;

            #Check HashTable for Unique IAM + Position ID Combo
            if($htRosettaIAMIDs.ContainsKey($tmpIDPosID) -eq $false)
            {
                $htRosettaIAMIDs.Add($tmpIDPosID,"1");
            }

            #Clear Temp Var to be on Safe Side
            $tmpIDPosID = $null;

        }#End of $payrollData Foreach

        #######################################################################
        #Check Existing IAM for the Same Department Code Payroll Associations
        #######################################################################

        #Var for Uri with Payroll Department Associations Lookup
        $eiPayrollUri = $UCDAPIInfo.exst_iam_url + "associations/pps/search?key=" + $UCDAPIInfo.exst_iam_cred + "&v=1.0&apptDeptCode=" + $dptCode;

        #API Call to Existing IAM System for Associations by Department Code
        $eiResults = (Invoke-RestMethod -ContentType "application/json" -Uri $eiPayrollUri).responseData.results

        #Go Through Each Payroll Association Result
        foreach($eiResult in $eiResults)
        {
            #Var for IAMId and Position Combo
            [string]$tmprIDPosID = $eiResult.iamId + "-" + $eiResult.emplPositionNumber;

            #Safety Check HashTable for Rosetta Entries. If Not Report Out
            if($htRosettaIAMIDs.ContainsKey($tmprIDPosID) -eq $false)
            {
                #Display IAMId and Position to Script User
                write-output $tmprIDPosID;

                #Custom Object for Missing Association Information
                $cstMissingAssoc = [PSCustomObject]@{ iamId = ""
                                                      userID = ""
                                                      employeeID = ""
                                                      dFullName = ""
                                                      emplPositionNumber = ""
                                                      percentFullTime = ""
                                                      titleCode = ""
                                                      titleDisplayName = ""
                                                      deptCode = ""
                                                      deptDisplayName = ""
                                                      assocStartDate = ""
                                                      assocEndDate = ""
                                                    };
                                                        
                $cstMissingAssoc.iamId = $eiResult.iamId;
                $cstMissingAssoc.emplPositionNumber = $eiResult.emplPositionNumber;
                $cstMissingAssoc.percentFullTime = $eiResult.percentFullTime;
                $cstMissingAssoc.titleCode = "``" + $eiResult.titleCode;
                $cstMissingAssoc.titleDisplayName = $eiResult.titleDisplayName;
                $cstMissingAssoc.deptCode = "``" + $eiResult.deptCode;
                $cstMissingAssoc.deptDisplayName = $eiResult.deptDisplayName;
                $cstMissingAssoc.assocStartDate = $eiResult.assocStartDate;
                $cstMissingAssoc.assocEndDate = $eiResult.assocEndDate;

                #Var for Existing IAM Account Information Uri
                $eiAccntUri = $UCDAPIInfo.exst_iam_url + "people/prikerbacct/search?key=" + $UCDAPIInfo.exst_iam_cred + "&v=1.0&retType=people&iamId=" + $eiResult.iamId;

                #API Call to Existing IAM System for Individual Account Information
                $eiAccntResults = (Invoke-RestMethod -ContentType "application/json" -Uri $eiAccntUri).responseData.results

                foreach($eiAccntRslt in $eiAccntResults)
                {
                    $cstMissingAssoc.dFullName = $eiAccntRslt.dFullName;
                    $cstMissingAssoc.userID = $eiAccntRslt.userID;
                    $cstMissingAssoc.employeeID = $eiAccntRslt.employeeId;
                }

                # Add Custom Object to Reporting Array
                $arrMissingAssignments += $cstMissingAssoc;

                
            }

            $tmprIDPosID = $null;
        }

    }

    #$arrRptPayroll;

    #$htRosettaIAMIDs.Count.ToString();

    #$arrMissingAssignments | Out-File -FilePath ./missing.txt 

    #Missing Assignment Information to CSV
    $arrMissingAssignments | Select-Object -Property iamId,userID,employeeID,dFullName,emplPositionNumber,percentFullTime,titleCode,titleDisplayName,deptCode,deptDisplayName,assocStartDate,assocEndDate | Export-Csv -Path ("IAM_Missing_Payroll_Associations_" + (Get-Date).ToString("yyyy-MM-dd-HH-mm") + ".csv") -NoTypeInformation;

}#End of Client ID and Secret Null\Empty Checks

