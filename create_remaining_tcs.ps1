$cred = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes('vinodkumar.puttagunta@wnco.com:ATATT3xFfGF0Ice80ogmMQIzrkmAi8ZZLSSBtFqySlQOYA5cbx4K_tTXkX8eN4MSK3-ewaIgcjI2F8K8KPiNK8-CootUkka4jboDjxPL3wXjHcPy722xwiK-sfml6GKLVoP66tqximAyOKi7ZIifnilBe-5eaIGV5qDJyoJ3W0_zgCkkeZwkGR8=9D163C3C'))
$base = "C:\Users\x282963\Desktop\Crew_Automation"

$files = @(
    'tc_851_02',
    'tc_853_01',
    'tc_854_01',
    'tc_855_01',
    'tc_857_01',
    'tc_859_01',
    'tc_860_01',
    'tc_860_02'
)

$results = @{}

foreach ($f in $files) {
    $path = "$base\$f.json"
    $r = curl.exe -s -X POST "https://southwest.atlassian.net/rest/api/3/issue" -H "Authorization: Basic $cred" -H "Content-Type: application/json" --data-binary "@$path"
    $key = ($r | ConvertFrom-Json).key
    $results[$f] = $key
    Write-Host "$f -> $key"
    Start-Sleep -Seconds 2
}

Write-Host ""
Write-Host "=== SUMMARY ==="
foreach ($k in $results.Keys) {
    Write-Host "$k -> $($results[$k])"
}
