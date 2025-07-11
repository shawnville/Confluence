# Function to update confluence page restrictions (must include current user for restrictions)
function Set-ConfluencePageRestriction {
    param (
        [string]$pageId,
        [string[]]$userName,
        [string[]]$groupName,
        [Parameter(Mandatory)]
        [ValidateSet("read", "update")]
        [string]$operation
    )

    $currentDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    # build user restrictions if any
    $userRestrictions = @()
    if ($userName) {
        foreach ($user in $userName) {
            $userRestrictions += @{
                type        = "known"
                username    = $user
            }
        }
    }

    # build group restrictions if any
    $groupRestrictions = @()
    if ($groupName) {
        foreach ($group in $groupName) {
            $groupRestrictions += @{
                type = "group"
                name = $group
            }
        }
    }

    # build base restriction object
    $restrictionsBody = @{
        content = @{
            expanded    = "true"
            id          = $pageId
        }
        operation = $operation
        lastModificationDate = $currentDateTime
        restrictions = @{}
    }

    # add user restrictions
    if ($userRestrictions.Count -gt 0) {
        $restrictionsBody.restrictions.user = $userRestrictions
    }

    # add group restrictions
    if ($groupRestrictions.Count -gt 0) {
        $restrictionsBody.restrictions.group = $groupRestrictions
    }

    # convert current restrictions object to json
    $bodyJson = $restrictionsBody | ConvertTo-Json -Depth 10
    $bodyJson = "[`n$bodyJson`n]" # because converto-json doesn't count the outer array as an array, need to add square brackets around the json

    $restrictionsURI = "$confluenceBaseUri/content/$pageId/restriction" # https://confluence.url.tld/rest/api/content/pageId/restriction
  
    if ($verboseFunctions){ Write-Host $bodyJson -ForegroundColor DarkGray }
    if ($verboseFunctions){ Write-Host $restrictionsURI -ForegroundColor DarkGray }

    if(!$testRun){ Invoke-RestMethod -Uri $restrictionsURI -Method Put -Body $bodyJson -Headers $confluenceCredHeader -ContentType 'application/json' }

}