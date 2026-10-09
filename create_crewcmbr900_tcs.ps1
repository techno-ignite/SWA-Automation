$cred = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes('vinodkumar.puttagunta@wnco.com:ATATT3xFfGF0Ice80ogmMQIzrkmAi8ZZLSSBtFqySlQOYA5cbx4K_tTXkX8eN4MSK3-ewaIgcjI2F8K8KPiNK8-CootUkka4jboDjxPL3wXjHcPy722xwiK-sfml6GKLVoP66tqximAyOKi7ZIifnilBe-5eaIGV5qDJyoJ3W0_zgCkkeZwkGR8=9D163C3C'))
$headers = @{ Authorization = "Basic $cred"; "Content-Type" = "application/json" }
$uri = "https://southwest.atlassian.net/rest/api/3/issue"

function MakeBody($summary, $oneLiner) {
    return @{
        fields = @{
            project     = @{ id = "10344" }
            summary     = $summary
            issuetype   = @{ id = "10004" }
            description = @{
                type    = "doc"; version = 1
                content = @(
                    @{ type = "paragraph"; content = @(@{ type = "text"; text = "Linked Story: CREWCMBR-900"; marks = @(@{ type = "strong" }) }) },
                    @{ type = "paragraph"; content = @(@{ type = "text"; text = $oneLiner }) }
                )
            }
        }
    } | ConvertTo-Json -Depth 20 -Compress
}

$tcs = @(
    @{ summary = "TC-900-01: OTA Auto-Combine - Pairing Total Equals Sum of Individual Pairing Credits (Not Sum of DPs)"; oneLiner = "Verify OTA auto-combined trip's Pairing Total after Auto Audit equals sum of individual pairing credits, not sum of duty periods." },
    @{ summary = "TC-900-02: OTA Auto-Combine - DP Guarantee Applied Before Combined Trip Total"; oneLiner = "Verify OTA auto-combined trip flown short on one DP still guarantees (G) that DP's original credit before computing the combined trip total." },
    @{ summary = "TC-900-03: Full TTGA Auto-Combine - Pairing Total Equals Sum of Individual Pairing Credits (Not Sum of DPs)"; oneLiner = "Verify Full TTGA auto-combined trip's Pairing Total after Auto Audit equals sum of individual pairing credits, not sum of duty periods." },
    @{ summary = "TC-900-04: Full TTGA Auto-Combine - Combined Trip Not Paid Less Than Sum of Original Pairing Totals"; oneLiner = "Verify Full TTGA auto-combined trip flown as scheduled does not pay less than the sum of the two pre-combine original pairing totals." },
    @{ summary = "TC-900-05: Full TTGA Auto-Combine - Class C/J Double Time Regardless of Pairing Label"; oneLiner = "Verify Full TTGA auto-combined trip with Class = C or Class = J pays double time regardless of pairing label." },
    @{ summary = "TC-900-06: Partial TTGA Auto-Combine - Pairing Total Equals Sum of Individual Pairing Credits (Not Sum of DPs)"; oneLiner = "Verify Partial TTGA auto-combined trip's Pairing Total after Auto Audit equals sum of individual pairing credits, not sum of duty periods." },
    @{ summary = "TC-900-07: Partial TTGA Auto-Combine - Only Traded DP Credit Recalculated"; oneLiner = "Verify Partial TTGA auto-combined trip only recalculates the traded DP's credit while retained DPs' credit stays unchanged." },
    @{ summary = "TC-900-08: Partial TTGA Auto-Combine - Combined Trip Not Paid Less Than Sum of Original DP Credits"; oneLiner = "Verify Partial TTGA auto-combined trip does not pay less than the sum of the original DP credits it was built from." },
    @{ summary = "TC-900-09: Mixed OTA + Full TTGA Auto-Combine - Highest Source Guarantee Honored"; oneLiner = "Verify a trip Auto Combined from a mix of OTA and Full TTGA sources pays no less than the highest guaranteed total among contributing source trips." },
    @{ summary = "TC-900-10: Auto-Combined Trip (OTA/TTGA/Partial TTGA) Flagged for Manual Audit, Not Auto Audit"; oneLiner = "Verify an Auto Combined trip (OTA, TTGA, or Partial TTGA) is flagged for manual audit review instead of Auto Audit per AU-19, rather than running Phase 2 Auto Audit." }
)

$results = @{}

$tmpDir = Join-Path $env:TEMP "crewcmbr900_tcs"
New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null

$i = 0
foreach ($tc in $tcs) {
    $i++
    $body = MakeBody -summary $tc.summary -oneLiner $tc.oneLiner
    $tmpFile = Join-Path $tmpDir "tc_$i.json"
    [System.IO.File]::WriteAllText($tmpFile, $body, [System.Text.Encoding]::UTF8)
    $r = curl.exe -s -X POST $uri -H "Authorization: Basic $cred" -H "Content-Type: application/json" --data-binary "@$tmpFile"
    $parsed = $null
    try { $parsed = $r | ConvertFrom-Json } catch {}
    $key = $parsed.key
    if ($key) {
        $results[$tc.summary] = $key
        Write-Host "$($tc.summary) -> $key" -ForegroundColor Green
    } else {
        $results[$tc.summary] = "ERROR: $r"
        Write-Host "$($tc.summary) -> FAILED: $r" -ForegroundColor Red
    }
    Start-Sleep -Seconds 1
}

Write-Host ""
Write-Host "=== SUMMARY ===" -ForegroundColor Yellow
foreach ($k in $results.Keys) {
    Write-Host "$k -> $($results[$k])"
}

$results | ConvertTo-Json | Out-File -FilePath "crewcmbr900_tc_results.json" -Encoding utf8
