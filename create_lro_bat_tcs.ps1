$cred = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes('vinodkumar.puttagunta@wnco.com:ATATT3xFfGF0Ice80ogmMQIzrkmAi8ZZLSSBtFqySlQOYA5cbx4K_tTXkX8eN4MSK3-ewaIgcjI2F8K8KPiNK8-CootUkka4jboDjxPL3wXjHcPy722xwiK-sfml6GKLVoP66tqximAyOKi7ZIifnilBe-5eaIGV5qDJyoJ3W0_zgCkkeZwkGR8=9D163C3C'))
$headers = @{ Authorization = "Basic $cred"; "Content-Type" = "application/json" }
$uri = "https://southwest.atlassian.net/rest/api/3/issue"

function MakeBody($summary, $precondition, $steps) {
    $stepRows = foreach ($s in $steps) {
        @{
            type = "tableRow"
            content = @(
                @{ type = "tableCell"; content = @(@{ type = "paragraph"; content = @(@{ type = "text"; text = $s.num }) }) },
                @{ type = "tableCell"; content = @(@{ type = "paragraph"; content = @(@{ type = "text"; text = $s.action }) }) },
                @{ type = "tableCell"; content = @(@{ type = "paragraph"; content = @(@{ type = "text"; text = $s.data }) }) },
                @{ type = "tableCell"; content = @(@{ type = "paragraph"; content = @(@{ type = "text"; text = $s.result }) }) }
            )
        }
    }
    $header = @{
        type = "tableRow"
        content = @(
            @{ type = "tableHeader"; content = @(@{ type = "paragraph"; content = @(@{ type = "text"; text = "Step"; marks = @(@{ type = "strong" }) }) }) },
            @{ type = "tableHeader"; content = @(@{ type = "paragraph"; content = @(@{ type = "text"; text = "Action"; marks = @(@{ type = "strong" }) }) }) },
            @{ type = "tableHeader"; content = @(@{ type = "paragraph"; content = @(@{ type = "text"; text = "Test Data"; marks = @(@{ type = "strong" }) }) }) },
            @{ type = "tableHeader"; content = @(@{ type = "paragraph"; content = @(@{ type = "text"; text = "Expected Result"; marks = @(@{ type = "strong" }) }) }) }
        )
    }
    return @{
        fields = @{
            project = @{ id = "10344" }
            summary = $summary
            issuetype = @{ id = "10004" }
            description = @{
                type = "doc"; version = 1
                content = @(
                    @{ type = "paragraph"; content = @(@{ type = "text"; text = "Linked Story: LRO Trigger Using Best Available Arrival Time with 120-Minute Threshold"; marks = @(@{ type = "strong" }) }) },
                    @{ type = "paragraph"; content = @(@{ type = "text"; text = $precondition }) },
                    @{ type = "rule" },
                    @{ type = "paragraph"; content = @(@{ type = "text"; text = "TEST STEPS"; marks = @(@{ type = "strong" }) }) },
                    @{ type = "table"; attrs = @{ isNumberColumnEnabled = $true; layout = "default" }; content = @($header) + $stepRows }
                )
            }
        }
    } | ConvertTo-Json -Depth 20 -Compress
}

$tcs = @(
    @{
        summary = "TC-LRO-BAT-001: LRO Triggers When Flight Arrives More Than 2 Hours Late Based on Best Available Arrival Time Plus 120 Minutes"
        precondition = "Precondition: An original trip is created with Best Available Arrival Time captured on the last leg of the assignment. Actual Arrival exceeds Best Available Arrival Time by more than 120 minutes. Audit processing is enabled. LRO must trigger per LRO-02 (120-minute threshold rule)."
        steps = @(
            @{ num="1"; action="Create an original trip for a crew member with the last leg clearly identified"; data="Trip ID=TRIP-LRO-001, Crew Member=CM-LRO-001, Last leg=Flt 123 HOU-DAL, isOriginal=TRUE"; result="Original trip is created successfully with the last leg marked as original" },
            @{ num="2"; action="Capture Best Available Arrival Time on the original last leg at trip creation"; data="bestAvailableArrivalTime=18:00 (last leg), Scheduled Arrival=18:00"; result="Best Available Arrival Time is captured and stored on the original last leg" },
            @{ num="3"; action="Set Actual Arrival on the last leg to a value more than 120 minutes later than Best Available Arrival Time"; data="Actual Arrival=20:30 (2 hours 30 min after bestAvailableArrivalTime 18:00)"; result="Actual Arrival exceeds Best Available Arrival Time + 120 minutes threshold" },
            @{ num="4"; action="Run COA audit processing for the trip and inspect LRO evaluation"; data="Audit trigger, Processing logs"; result="Audit workflow completes. LRO evaluation uses bestAvailableArrivalTime + 120 minutes as the threshold." },
            @{ num="5"; action="Navigate to COA Search App and verify LRO is triggered on the last leg"; data="COA Search App - search by crew ID and trip, inspect LRO flag"; result="LRO is triggered. LRO flag is set on the last leg of the assignment." },
            @{ num="6"; action="Verify LRO credit of 1 TFP is reflected in Blaze response and payroll report"; data="Blaze response, Payroll report entries"; result="LRO = 1 TFP is paid on the last leg per LRO-02. Credit is reflected in both Blaze and Payroll outputs." }
        )
    },
    @{
        summary = "TC-LRO-BAT-002: LRO Does Not Trigger When Actual Arrival Delay is Within 120 Minutes of Best Available Arrival Time"
        precondition = "Precondition: An original trip is created with Best Available Arrival Time captured on the last leg. Actual Arrival is late but within 120 minutes of Best Available Arrival Time. LRO must NOT trigger per LRO-02 threshold rule."
        steps = @(
            @{ num="1"; action="Create an original trip for a crew member with the last leg clearly identified"; data="Trip ID=TRIP-LRO-002, Crew Member=CM-LRO-002, Last leg=Flt 456 DAL-MCO, isOriginal=TRUE"; result="Original trip is created successfully with the last leg marked as original" },
            @{ num="2"; action="Capture Best Available Arrival Time on the original last leg at trip creation"; data="bestAvailableArrivalTime=18:00 (last leg), Scheduled Arrival=18:00"; result="Best Available Arrival Time is captured and stored on the original last leg" },
            @{ num="3"; action="Set Actual Arrival on the last leg to a value within 120 minutes of Best Available Arrival Time"; data="Actual Arrival=19:30 (1 hour 30 min after bestAvailableArrivalTime 18:00)"; result="Actual Arrival is late but within the 120-minute threshold" },
            @{ num="4"; action="Run COA audit processing for the trip and inspect LRO evaluation"; data="Audit trigger, Processing logs"; result="Audit workflow completes. LRO evaluation uses bestAvailableArrivalTime + 120 minutes threshold." },
            @{ num="5"; action="Navigate to COA Search App and verify LRO is NOT triggered"; data="COA Search App - search by crew ID and trip, inspect LRO flag"; result="LRO is NOT triggered. LRO flag remains blank on the last leg." },
            @{ num="6"; action="Verify no LRO credit appears in Blaze response or payroll report"; data="Blaze response, Payroll report entries"; result="No LRO credit is paid. Delay within 120 minutes does not meet the LRO threshold." }
        )
    },
    @{
        summary = "TC-LRO-BAT-003: LRO Uses Scheduled Arrival as Fallback When Best Available Arrival Time is Missing"
        precondition = "Precondition: A trip is created WITHOUT Best Available Arrival Time captured (field is missing or null). Only Scheduled Arrival is available. Actual Arrival exceeds Scheduled Arrival by more than 120 minutes. System must fall back to Scheduled Arrival for the LRO threshold calculation and still trigger correctly."
        steps = @(
            @{ num="1"; action="Create an original trip for a crew member without capturing Best Available Arrival Time"; data="Trip ID=TRIP-LRO-003, Crew Member=CM-LRO-003, Last leg=Flt 789 MCO-HOU, bestAvailableArrivalTime=null or missing"; result="Original trip is created with Best Available Arrival Time absent" },
            @{ num="2"; action="Confirm Scheduled Arrival is present on the last leg for use as fallback"; data="Scheduled Arrival=18:00 (last leg)"; result="Scheduled Arrival is present and available as the fallback reference" },
            @{ num="3"; action="Set Actual Arrival on the last leg to a value more than 120 minutes after Scheduled Arrival"; data="Actual Arrival=20:30 (2 hours 30 min after Scheduled Arrival 18:00)"; result="Actual Arrival exceeds Scheduled Arrival + 120 minutes threshold" },
            @{ num="4"; action="Run COA audit processing and verify fallback logic is invoked"; data="Audit trigger, Processing logs - fallback path"; result="LRO evaluation detects missing bestAvailableArrivalTime and falls back to Scheduled Arrival + 120 minutes threshold" },
            @{ num="5"; action="Navigate to COA Search App and verify LRO is triggered correctly using the fallback"; data="COA Search App - search by crew ID and trip, inspect LRO flag and rule attribution"; result="LRO is triggered. Processing logs confirm Scheduled Arrival was used as the fallback reference." },
            @{ num="6"; action="Verify LRO credit of 1 TFP is paid and attributed to the fallback evaluation"; data="Blaze response, Payroll report, Audit transaction attribution"; result="LRO = 1 TFP is paid. The fallback behavior produces the same final LRO outcome as if Best Available Arrival Time had been present." }
        )
    },
    @{
        summary = "TC-LRO-BAT-004: Original Best Available Arrival Time Remains Unchanged After Voluntary and Involuntary Trip Modifications"
        precondition = "Precondition: An original trip is created with Best Available Arrival Time captured. Subsequent voluntary and involuntary changes are applied to the trip. The originally captured Best Available Arrival Time must remain unchanged and must be used for all LRO evaluations across versions."
        steps = @(
            @{ num="1"; action="Create an original trip and capture Best Available Arrival Time on the last leg at V0"; data="Trip ID=TRIP-LRO-004, Crew Member=CM-LRO-004, Last leg=Flt 234 DAL-AUS, bestAvailableArrivalTime=18:00, V0"; result="Original trip V0 is created with Best Available Arrival Time captured on the last leg" },
            @{ num="2"; action="Apply a Voluntary change to the trip (for example a voluntary leg swap)"; data="Voluntary change applied, New version V1 created"; result="V1 is saved. Voluntary change is applied without altering the original V0 Best Available Arrival Time." },
            @{ num="3"; action="Apply an Involuntary change to the trip (for example a reassignment of the last leg)"; data="Involuntary reassignment applied, New version V2 created"; result="V2 is saved. Involuntary change is applied without altering the original V0 Best Available Arrival Time." },
            @{ num="4"; action="Verify the originally captured Best Available Arrival Time is preserved in DynamoDB across V0 to V2"; data="DynamoDB record - compare bestAvailableArrivalTime field in V0 V1 V2"; result="bestAvailableArrivalTime remains 18:00 across all versions. The original value is not overwritten by voluntary or involuntary changes." },
            @{ num="5"; action="Run audit processing and verify LRO evaluation uses the ORIGINAL V0 Best Available Arrival Time (not any revised time)"; data="Actual Arrival=20:30, Audit trigger, LRO threshold comparison"; result="LRO evaluation uses the original V0 bestAvailableArrivalTime 18:00 + 120 minutes. Threshold comparison is against the original captured value." },
            @{ num="6"; action="Confirm LRO result is consistent regardless of how many subsequent versions exist"; data="COA Search App - final LRO value, Rule attribution across versions"; result="LRO is triggered correctly based on the original Best Available Arrival Time. Subsequent trip modifications do not shift the LRO reference time." }
        )
    }
)

$results = @{}
foreach ($tc in $tcs) {
    $body = MakeBody $tc.summary $tc.precondition $tc.steps
    try {
        $r = Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -Body $body
        $shortName = $tc.summary.Substring(0, [Math]::Min(26, $tc.summary.Length))
        $results[$shortName] = $r.key
        Write-Host "$shortName -> $($r.key)" -ForegroundColor Green
    } catch {
        Write-Host "FAILED: $($tc.summary)" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
    Start-Sleep -Seconds 2
}

Write-Host "`n=== SUMMARY ===" -ForegroundColor Yellow
$results.GetEnumerator() | ForEach-Object { Write-Host "$($_.Key) -> $($_.Value)" }
$results | ConvertTo-Json | Out-File "c:\Users\x282963\Desktop\Crew_Automation\lro_bat_tc_results.json"
Write-Host "`nResults saved to lro_bat_tc_results.json" -ForegroundColor Cyan
