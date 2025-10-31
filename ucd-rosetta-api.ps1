<#
    Title: ucd-rosetta-api.ps1
    Authors: Dean Bunn
    Last Edit: 2025-10-31
#>

#Custom Object for UC Davis API Information
$global:UCDAPIInfo = [PSCustomObject]@{
                                         base_url = ""
                                         token_url = ""
                                         client_id = ""
                                         client_secret = ""
                                         oauth_token = ""
                                       }


#Load API Information from Secrets Vault
$UCDAPIInfo.base_url = Get-Secret -Name "Rosetta-Base-Url" -AsPlainText -Vault UCD-Identities;
$UCDAPIInfo.token_url = Get-Secret -Name "Rosetta-OAuth-Url" -AsPlainText -Vault UCD-Identities;
$UCDAPIInfo.client_id = Get-Secret -Name "Rosetta-Client-ID" -AsPlainText -Vault UCD-Identities;
$UCDAPIInfo.client_secret = Get-Secret -Name "Rosetta-Client-Secret" -AsPlainText -Vault UCD-Identities;

#Pull