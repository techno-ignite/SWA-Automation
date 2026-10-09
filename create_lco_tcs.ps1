$cred = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes('vinodkumar.puttagunta@wnco.com:ATATT3xFfGF0Ice80ogmMQIzrkmAi8ZZLSSBtFqySlQOYA5cbx4K_tTXkX8eN4MSK3-ewaIgcjI2F8K8KPiNK8-CootUkka4jboDjxPL3wXjHcPy722xwiK-sfml6GKLVoP66tqximAyOKi7ZIifnilBe-5eaIGV5qDJyoJ3W0_zgCkkeZwkGR8=9D163C3C'))
$base = "C:\Users\x282963\Desktop\Crew_Automation"

$files = @(
    'tc_lco_001',
    'tc_lco_002',
    'tc_lco_003',
    'tc_lco_004',
    'tc_lco_005',
    'tc_lco_006',
    'tc_lco_007',
    'tc_lco_008',
    'tc_lco_009',
    'tc_lco_010',
    'tc_lco_011',
    'tc_lco_012',
    'tc_lco_013',
    'tc_lco_014',
    'tc_lco_015',
    'tc_lco_016',
    'tc_lco_017',
    'tc_lco_018',
    'tc_lco_019',
    'tc_lco_020',
    'tc_lco_021',
    'tc_lco_022',
    'tc_lco_023',
    'tc_lco_024'
)

$results = @{}

foreach ($f in $files) {
    $path = "$base\$f.json"
    Write-Host "Creating $f ..." -ForegroundColor Cyan
    $r = curl.exe -s -X POST "https://southwest.atlassian.net/rest/api/3/issue" `
        -H "Authorization: Basic $cred" `
        -H "Content-Type: application/json" `
        --data-binary "@$path"
    $parsed = $r | ConvertFrom-Json
    $key = $parsed.key
    if ($key) {
        $results[$f] = $key
        Write-Host "$f -> $key" -ForegroundColor Green
    } else {
        $results[$f] = "ERROR: $r"
        Write-Host "$f -> FAILED: $r" -ForegroundColor Red
    }
    Start-Sleep -Seconds 2
}

Write-Host ""
Write-Host "=== SUMMARY ===" -ForegroundColor Yellow
foreach ($k in $results.Keys | Sort-Object) {
    Write-Host "$k -> $($results[$k])"
}
