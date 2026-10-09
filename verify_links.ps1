$cred = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes('vinodkumar.puttagunta@wnco.com:ATATT3xFfGF0Ice80ogmMQIzrkmAi8ZZLSSBtFqySlQOYA5cbx4K_tTXkX8eN4MSK3-ewaIgcjI2F8K8KPiNK8-CootUkka4jboDjxPL3wXjHcPy722xwiK-sfml6GKLVoP66tqximAyOKi7ZIifnilBe-5eaIGV5qDJyoJ3W0_zgCkkeZwkGR8=9D163C3C'))
$headers = @{Authorization='Basic ' + $cred; 'Content-Type'='application/json'}

$stories = @(
    'CREWCMBR-668','CREWCMBR-669','CREWCMBR-672','CREWCMBR-704','CREWCMBR-748',
    'CREWCMBR-755','CREWCMBR-761','CREWCMBR-762','CREWCMBR-767','CREWCMBR-768',
    'CREWCMBR-780','CREWCMBR-785','CREWCMBR-818','CREWCMBR-819','CREWCMBR-851',
    'CREWCMBR-853','CREWCMBR-854','CREWCMBR-855','CREWCMBR-857','CREWCMBR-859','CREWCMBR-860'
)

$missing = @()
foreach ($s in $stories) {
    $r = Invoke-RestMethod -Uri "https://southwest.atlassian.net/rest/api/3/issue/$s`?fields=summary,issuelinks" -Headers $headers
    # Check both inward and outward links for any CSRXP keys
    $inward  = @($r.fields.issuelinks | Where-Object { $_.inwardIssue  -and $_.inwardIssue.key  -like 'CSRXP-*' } | ForEach-Object { $_.inwardIssue.key })
    $outward = @($r.fields.issuelinks | Where-Object { $_.outwardIssue -and $_.outwardIssue.key -like 'CSRXP-*' } | ForEach-Object { $_.outwardIssue.key })
    $all = ($inward + $outward) | Sort-Object -Unique
    if ($all.Count -gt 0) {
        Write-Host "[OK $($all.Count)] $s -> $($all -join ', ')"
    } else {
        Write-Host "[MISSING] $s - $($r.fields.summary)"
        $missing += $s
    }
}

Write-Host ""
if ($missing.Count -eq 0) {
    Write-Host "ALL $($stories.Count) stories have linked test cases."
} else {
    Write-Host "MISSING LINKS on $($missing.Count) stories: $($missing -join ', ')"
}
