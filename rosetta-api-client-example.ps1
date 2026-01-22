<#
    Title: rosetta-api-client-example.ps1
    Authors: Dean Bunn and Wilson Miller
    Last Edit: 2026-01-22
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
    #$arrRptPeople = @();

    #Var for People Endpoint Uri with User IAM ID
    $peopleUri = $UCDAPIInfo.base_url + "people?iamid=" + $UCDAPIInfo.test_id;

    #Make Rest Call to Pull People Information
    $peopleData = Invoke-RestMethod -Uri $peopleUri -Method GET -Headers $headersEPCall;


    #Loop Through Returned People
    foreach($peopleDatum in $peopleData)
    {
        
        #Custom Object for 
        $cstUCDPerson = [PSCustomObject]@{
                                            iam_id                      = ""
                                            displayname                 = ""
                                            birth_date                  = ""
                                            manager_iam_id              = ""
                                            provisioning_status_primary = ""
                                            name_lived_first_name       = ""
                                            name_lived_middle_name      = ""
                                            name_lived_last_name        = ""
                                            name_legal_first_name       = ""
                                            name_legal_middle_name      = ""
                                            name_legal_last_name        = ""
                                            id_iam_id                   = ""
                                            id_login_id                 = ""
                                            id_student_id               = ""
                                            id_mothra_id                = ""
                                            id_employee_id              = ""
                                            id_mail_id                  = ""
                                            id_pidm                     = ""
                                            email_primary               = ""
                                            email_work                  = ""
                                            email_personal              = ""
                                            phone_primary               = ""
                                            phone_personal              = ""
                                            modified_date               = ""
                                            affiliation                 = @()
                                            employment_status           = @()
                                            student_association         = @()
                                            payroll_association         = @()
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

        #Check Provisioning Statuses 
        if($null -ne $peopleDatum.provisioning_status -and $peopleDatum.provisioning_status.Length -gt 0)
        {
            #Go Through Each Provided Status
            foreach($provstat in $peopleDatum.provisioning_status)
            {

                #Check Primary Status
                if($provstat.PSObject.Properties.Name -contains 'primary')
                {
                    $cstUCDPerson.provisioning_status_primary = $provstat.PSObject.Properties['primary'].Value;
                }

            }#End of Provisioning Status Foreach

        }#End of Provisioning Status Count Checks

        #Check "Name" Values
        if($null -ne $peopleDatum.name -and $peopleDatum.name.Length -gt 0)
        {

            #Go Through Each Provided UCD Name
            foreach($um in $peopleDatum.name)
            {

                #Check Lived First Name
                if($um.PSObject.Properties.Name -contains 'lived_first_name')
                {
                    $cstUCDPerson.name_lived_first_name = $um.PSObject.Properties['lived_first_name'].Value;
                }

                #Check Lived Middle Name
                if($um.PSObject.Properties.Name -contains 'lived_middle_name')
                {
                    $cstUCDPerson.name_lived_middle_name = $um.PSObject.Properties['lived_middle_name'].Value;
                }

                #Check Lived Last Name
                if($um.PSObject.Properties.Name -contains 'lived_last_name')
                {
                    $cstUCDPerson.name_lived_last_name = $um.PSObject.Properties['lived_last_name'].Value;
                }

                #Check Legal First Name
                if($um.PSObject.Properties.Name -contains 'legal_first_name')
                {
                    $cstUCDPerson.name_legal_first_name = $um.PSObject.Properties['legal_first_name'].Value;
                }

                #Check Legal Middle Name
                if($um.PSObject.Properties.Name -contains 'legal_middle_name')
                {
                    $cstUCDPerson.name_legal_middle_name = $um.PSObject.Properties['legal_middle_name'].Value;
                }

                #Check Legal First Name
                if($um.PSObject.Properties.Name -contains 'legal_last_name')
                {
                    $cstUCDPerson.name_legal_last_name = $um.PSObject.Properties['legal_last_name'].Value;
                }

            }#End of Provided Names Foreach

        }#End of Provided Name Count Check

        #Check "ID" Values
        if($null -ne $peopleDatum.id -and $peopleDatum.id.Length -gt 0)
        {
            #Go Through Each Provided ID
            foreach($ucdid in $peopleDatum.id)
            {
                #Check IAM ID
                if($ucdid.PSObject.Properties.Name -contains 'iam_id')
                {
                    $cstUCDPerson.id_iam_id = $ucdid.PSObject.Properties['iam_id'].Value;
                }

                #Check Login ID
                if($ucdid.PSObject.Properties.Name -contains 'login_id')
                {
                    $cstUCDPerson.id_login_id = $ucdid.PSObject.Properties['login_id'].Value;
                }

                #Check student ID
                if($ucdid.PSObject.Properties.Name -contains 'student_id')
                {
                    $cstUCDPerson.id_student_id = $ucdid.PSObject.Properties['student_id'].Value;
                }

                #Check Mothra ID
                if($ucdid.PSObject.Properties.Name -contains 'mothra_id')
                {
                    $cstUCDPerson.id_mothra_id = $ucdid.PSObject.Properties['mothra_id'].Value;
                }

                #Check Employee ID
                if($ucdid.PSObject.Properties.Name -contains 'employee_id')
                {
                    $cstUCDPerson.id_employee_id = $ucdid.PSObject.Properties['employee_id'].Value;
                }

                #Check Mail ID
                if($ucdid.PSObject.Properties.Name -contains 'mail_id')
                {
                    $cstUCDPerson.id_mail_id = $ucdid.PSObject.Properties['mail_id'].Value;
                }

                #Check PIDM ID
                if($ucdid.PSObject.Properties.Name -contains 'pidm_id')
                {
                    $cstUCDPerson.id_pidm = $ucdid.PSObject.Properties['pidm_id'].Value;
                }

            }#End of IDs Foreach

        }#End of "ID" Null Count Check

        #Check Emails
        if($null -ne $peopleDatum.email -and $peopleDatum.email.Length -gt 0)
        {
            #Go Through Each Provided Email
            foreach($ucdeml in $peopleDatum.email)
            {

                #Check Primary Email
                if($ucdeml.PSObject.Properties.Name -contains 'primary')
                {
                    $cstUCDPerson.email_primary = $ucdeml.PSObject.Properties['primary'].Value;
                }

                #Check Work Email
                if($ucdeml.PSObject.Properties.Name -contains 'work')
                {
                    $cstUCDPerson.email_work = $ucdeml.PSObject.Properties['work'].Value;
                }

                #Check Primary Email
                if($ucdeml.PSObject.Properties.Name -contains 'personal')
                {
                    $cstUCDPerson.email_personal = $ucdeml.PSObject.Properties['personal'].Value;
                }

            }#End of Email Foreach

        }#End of Email Count Checks

        #Check Phones
        if($null -ne $peopleDatum.phone -and $peopleDatum.phone.Length -gt 0)
        {
            #Go Through Each Provided Phone
            foreach($phne in $peopleDatum.phone)
            {
                #Check Primary Phone
                if($phne.PSObject.Properties.Name -contains 'primary')
                {
                    $cstUCDPerson.phone_primary = $phne.PSObject.Properties['primary'].Value;
                }

                #Check Personal Phone
                if($phne.PSObject.Properties.Name -contains 'personal')
                {
                    $cstUCDPerson.phone_personal = $phne.PSObject.Properties['personal'].Value;
                }

            }#End of Phone Foreach

        }#End of Phone Count Checks

        #Check Affiliations
        if($null -ne $peopleDatum.affiliation -and $peopleDatum.affiliation.Length -gt 0)
        {
            foreach($ucdafl in $peopleDatum.affiliation)
            {
                $cstUCDPerson.affiliation += $ucdafl;
            }

        }#End of Affiliations

        #Check Employment Status
        if($null -ne $peopleDatum.employment_status -and $peopleDatum.employment_status.Length -gt 0)
        {
            foreach($ucdems in $peopleDatum.employment_status)
            {
                $cstUCDPerson.employment_status += $ucdems;
            }

        }#End of Employment Statuses

        #Check Payroll Associations
        if($null -ne $peopleDatum.payroll_association -and $peopleDatum.payroll_association.Length -gt 0)
        {
            #Go Through Each Payroll Association
            foreach($ucdpa in $peopleDatum.payroll_association)
            {

                #Custom Object for Payroll Association (Mainly So You Can See the Returned Properties)
                $cstPayrollAssoc = [PSCustomObject]@{
                                                        employee_record                         = ""
                                                        employee_id                             = ""
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
                                                    };

                #Load Payroll Associations
                $cstPayrollAssoc.employee_record = $ucdpa.employee_record;
                $cstPayrollAssoc.employee_id = $ucdpa.employee_id;
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

                # Add Payroll Association to Payroll Associations
                $cstUCDPerson.payroll_association += $cstPayrollAssoc;
                
            }#End of Payroll Associations Foreach

        }#End of Payroll Association Null Counts
        
        #Check Student Associations
        if($null -ne $peopleDatum.student_association -and $peopleDatum.student_association.Length -gt 0)
        {

            foreach($arrUCDSA in $peopleDatum.student_association)
            {
                #Custom Object for Student Association
                $cstStudentAssoc = [PSCustomObject]@{
                                                        college         = ""
                                                        major           = ""
                                                        academic_level  = ""
                                                        class_level     = ""
                                                    };

                foreach($ucdsa in $arrUCDSA)
                {
                    #Check College
                    if($ucdsa.PSObject.Properties.Name -contains 'college')
                    {
                        $cstStudentAssoc.college = $ucdsa.PSObject.Properties['college'].Value;
                    }

                    #Check Major
                    if($ucdsa.PSObject.Properties.Name -contains 'major')
                    {
                        $cstStudentAssoc.major = $ucdsa.PSObject.Properties['major'].Value;
                    }

                    #Check Academic Level
                    if($ucdsa.PSObject.Properties.Name -contains 'academic_level')
                    {
                        $cstStudentAssoc.academic_level = $ucdsa.PSObject.Properties['academic_level'].Value;
                    }

                    #Check Class Level
                    if($ucdsa.PSObject.Properties.Name -contains 'class_level')
                    {
                        $cstStudentAssoc.class_level = $ucdsa.PSObject.Properties['class_level'].Value;
                    }

                }#End of $arrUCDSA

                $cstUCDPerson.student_association += $cstStudentAssoc;

            }#End of Student Association Foreach

        }#End of Student Association Null Count Checks
        
        # Add Custom People Object to Reporting Array
        $arrRptPeople += $cstUCDPerson;
    }

    #Display Report Array
    $arrRptPeople

}#End of Null\Empty Checks on Client ID and Secret

