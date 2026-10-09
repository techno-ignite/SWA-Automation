$cred = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes('vinodkumar.puttagunta@wnco.com:ATATT3xFfGF0Ice80ogmMQIzrkmAi8ZZLSSBtFqySlQOYA5cbx4K_tTXkX8eN4MSK3-ewaIgcjI2F8K8KPiNK8-CootUkka4jboDjxPL3wXjHcPy722xwiK-sfml6GKLVoP66tqximAyOKi7ZIifnilBe-5eaIGV5qDJyoJ3W0_zgCkkeZwkGR8=9D163C3C'))
$headers = @{Authorization='Basic ' + $cred; 'Content-Type'='application/json'}

# Map: story -> list of test case keys to link
$linkMap = @{
    'CREWCMBR-672' = @('CSRXP-93091','CSRXP-93092')
    'CREWCMBR-704' = @('CSRXP-93099','CSRXP-93108')
    'CREWCMBR-748' = @('CSRXP-93111','CSRXP-93112')
    'CREWCMBR-755' = @('CSRXP-93115')
    'CREWCMBR-761' = @('CSRXP-93117')
    'CREWCMBR-762' = @('CSRXP-93118','CSRXP-93122')
    'CREWCMBR-767' = @('CSRXP-93129')
    'CREWCMBR-768' = @('CSRXP-93130')
    'CREWCMBR-780' = @('CSRXP-93133')
    'CREWCMBR-785' = @('CSRXP-93135')
    'CREWCMBR-818' = @('CSRXP-93136')
    'CREWCMBR-819' = @('CSRXP-93140')
    'CREWCMBR-851' = @('CSRXP-93159','CSRXP-93172')
    'CREWCMBR-853' = @('CSRXP-93173')
    'CREWCMBR-854' = @('CSRXP-93174')
    'CREWCMBR-855' = @('CSRXP-93175')
    'CREWCMBR-857' = @('CSRXP-93176')
    'CREWCMBR-859' = @('CSRXP-93177')
    'CREWCMBR-860' = @('CSRXP-93178','CSRXP-93179')
}

$ok = 0
$fail = 0

foreach ($story in $linkMap.Keys) {
    foreach ($tc in $linkMap[$story]) {
        $body = @{
            type = @{ name = "Tests" }
            inwardIssue  = @{ key = $tc }
            outwardIssue = @{ key = $story }
        } | ConvertTo-Json -Depth 5 -Compress
        try {
            Invoke-RestMethod -Uri "https://southwest.atlassian.net/rest/api/3/issueLink" -Method POST -Headers $headers -Body $body | Out-Null
            Write-Host "OK: $tc -> $story"
            $ok++
        } catch {
            $errMsg = $_.Exception.Message
            Write-Host "FAIL: $tc -> $story | $errMsg"
            $fail++
        }
        Start-Sleep -Milliseconds 300
    }
}

Write-Host ""
Write-Host "=== LINKING DONE: $ok OK, $fail FAILED ==="
