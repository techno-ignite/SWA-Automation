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
                    @{ type = "paragraph"; content = @(@{ type = "text"; text = "Linked Story: Reserve/Standby 3-Hour Threshold Logic for Last DP LCO Determination"; marks = @(@{ type = "strong" }) }) },
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
        summary = "TC-RSV3HR-001: Reserve or Standby - Last DP Departs Before Last Day of Reserve Block and Arrival Less Than 3 Hours Late - LCO = P"
        precondition = "Precondition: Crew member has a Reserve (R) or Standby (S) assignment. Last DP leg departure date is BEFORE the last day of the reserve block (reserve days remain after departure). Arrival is late but LESS than 3 hours past original scheduled arrival. New reserve-specific 3-hour threshold logic must apply."
        steps = @(
            @{ num="1"; action="Set up a crew member with a Reserve or Standby assignment and multi-day reserve block"; data="assignmentLabel=R or S, Reserve block=5 days, Crew Member=RSV001"; result="Reserve/Standby assignment is set up successfully across the reserve block" },
            @{ num="2"; action="Configure a Reserve/Standby trip where the last DP leg departure date is before the last day of the reserve block"; data="Reserve block last day=Day 5, Last DP departure date=Day 3 (reserve days remain)"; result="Last DP is scheduled before the final day of the reserve block" },
            @{ num="3"; action="Apply a late arrival of less than 3 hours to the last DP leg"; data="Original last DP arrival=18:00, Actual arrival=20:30 (2 hours 30 min late)"; result="Last DP leg arrives less than 3 hours late" },
            @{ num="4"; action="Trigger COA audit processing and verify new reserve logic is applied for this configuration"; data="Audit trigger for Reserve/Standby assignment"; result="New reserve 3-hour threshold logic is invoked. The system identifies this as a Reserve/Standby last-DP-not-last-RAP scenario." },
            @{ num="5"; action="Navigate to COA Search App and verify LCO value for the last DP leg"; data="COA Search App - search by crew ID and trip, inspect last DP leg LCO code"; result="LCO = P. Reserve/Standby late arrival under 3 hours with remaining reserve days produces LCO-P (50%)." },
            @{ num="6"; action="Verify LCO value matches Blaze response and payroll report"; data="Blaze response, Payroll report entries"; result="LCO-P is reflected in Blaze response and Payroll report. Override credit is 50% of straight leg TFP." }
        )
    },
    @{
        summary = "TC-RSV3HR-002: Reserve or Standby - Last DP Departs Before Last Day of Reserve Block and Arrival More Than 3 Hours Late - LCO = D"
        precondition = "Precondition: Crew member has a Reserve (R) or Standby (S) assignment. Last DP leg departure date is BEFORE the last day of the reserve block (reserve days remain after departure). Arrival is MORE than 3 hours past original scheduled arrival. New reserve-specific 3-hour threshold logic must apply."
        steps = @(
            @{ num="1"; action="Set up a crew member with a Reserve or Standby assignment and multi-day reserve block"; data="assignmentLabel=R or S, Reserve block=5 days, Crew Member=RSV002"; result="Reserve/Standby assignment is set up successfully across the reserve block" },
            @{ num="2"; action="Configure a Reserve/Standby trip where the last DP leg departure date is before the last day of the reserve block"; data="Reserve block last day=Day 5, Last DP departure date=Day 3 (reserve days remain)"; result="Last DP is scheduled before the final day of the reserve block" },
            @{ num="3"; action="Apply a late arrival of more than 3 hours to the last DP leg"; data="Original last DP arrival=18:00, Actual arrival=21:30 (3 hours 30 min late)"; result="Last DP leg arrives more than 3 hours late" },
            @{ num="4"; action="Trigger COA audit processing and verify new reserve logic is applied"; data="Audit trigger for Reserve/Standby assignment"; result="New reserve 3-hour threshold logic is invoked. The 3-hour boundary is detected as exceeded." },
            @{ num="5"; action="Navigate to COA Search App and verify LCO value for the last DP leg"; data="COA Search App - search by crew ID and trip, inspect last DP leg LCO code"; result="LCO = D. Reserve/Standby late arrival over 3 hours with remaining reserve days produces LCO-D (100%)." },
            @{ num="6"; action="Verify LCO value matches Blaze response and payroll report"; data="Blaze response, Payroll report entries"; result="LCO-D is reflected in Blaze response and Payroll report. Override credit is 100% of straight leg TFP." }
        )
    },
    @{
        summary = "TC-RSV3HR-003: Reserve (R) and Standby (S) Assignments Evaluated Separately - 3-Hour Threshold Logic Applied Consistently for Both Labels"
        precondition = "Precondition: Two crew members with identical trip configurations - one has assignmentLabel=R (Reserve) and the other assignmentLabel=S (Standby). Both have reserve days remaining after departure date. Both have the same late arrival conditions. The new 3-hour threshold logic must apply consistently to both labels."
        steps = @(
            @{ num="1"; action="Set up Crew Member A with Reserve (R) assignment and reserve days remaining after departure"; data="assignmentLabel=R, Crew Member=RSV003A, Reserve block last day=Day 5, Last DP departure=Day 3"; result="Reserve (R) assignment is set up with reserve days remaining" },
            @{ num="2"; action="Set up Crew Member B with Standby (S) assignment and identical configuration"; data="assignmentLabel=S, Crew Member=RSV003B, Reserve block last day=Day 5, Last DP departure=Day 3"; result="Standby (S) assignment is set up with identical reserve days remaining" },
            @{ num="3"; action="Apply identical late arrival of less than 3 hours to both crew members' last DP legs"; data="Both crew members: Original arrival=18:00, Actual arrival=20:00 (2 hours late)"; result="Identical late arrival conditions are applied to both R and S assignments" },
            @{ num="4"; action="Trigger COA audit processing for both crew members"; data="Audit trigger for both R and S assignments"; result="New reserve 3-hour threshold logic is invoked for both R and S labels. Processing path is identical for both labels." },
            @{ num="5"; action="Navigate to COA Search App and compare LCO values for both crew members"; data="COA Search App - search both crew members, compare last DP leg LCO code"; result="Both Crew Member A (R) and Crew Member B (S) have LCO = P. The 3-hour threshold logic is applied consistently regardless of R vs S label." },
            @{ num="6"; action="Repeat the comparison with late arrival of more than 3 hours and verify both produce LCO = D"; data="Both crew members: Actual arrival shifted to 21:30 (3 hours 30 min late)"; result="Both crew members produce LCO = D. The 3-hour threshold logic treats R and S assignment labels identically." }
        )
    },
    @{
        summary = "TC-RSV3HR-004: Reserve or Standby - Last DP Leg - Reserve-Specific Calculation Overrides Existing laterArrival() Result"
        precondition = "Precondition: Crew member has a Reserve (R) or Standby (S) assignment. The target leg is on the LAST DP of the trip. The existing laterArrival() function would have returned one LCO value, but the new reserve-specific 3-hour threshold calculation must take precedence and override that result."
        steps = @(
            @{ num="1"; action="Set up a Reserve or Standby assignment where the target leg is on the last DP"; data="assignmentLabel=R or S, Crew Member=RSV004, Leg position=Last DP, Reserve days remaining"; result="Reserve/Standby last DP configuration is set up" },
            @{ num="2"; action="Configure conditions that would trigger the existing laterArrival() function to return a specific LCO result"; data="Trip conditions matching legacy laterArrival() behavior path"; result="Existing laterArrival() path is identifiable in the processing logs for comparison" },
            @{ num="3"; action="Apply a late arrival that crosses the 3-hour threshold"; data="Original last DP arrival=18:00, Actual arrival=21:30 (3 hours 30 min late)"; result="3-hour threshold is exceeded for this Reserve/Standby last DP leg" },
            @{ num="4"; action="Trigger COA audit processing and inspect which calculation path is used"; data="Audit trigger, Step Function execution path, Processing logs"; result="Reserve-specific 3-hour threshold calculation takes precedence over laterArrival() for this last DP leg" },
            @{ num="5"; action="Verify the final LCO reflects the 3-hour threshold rule result and not the legacy laterArrival() output"; data="COA Search App - final LCO value, Processing logs comparing laterArrival() vs reserve-specific result"; result="Final LCO reflects the 3-hour threshold rule (LCO = D for over 3 hours). Legacy laterArrival() output is overridden by the reserve-specific calculation." },
            @{ num="6"; action="Verify the override is applied specifically because the leg is on the last DP and crew is Reserve/Standby"; data="Rule attribution in processing logs"; result="The precedence is correctly attributed to the Reserve/Standby last DP condition. Other combinations do not trigger this precedence." }
        )
    },
    @{
        summary = "TC-RSV3HR-005: Reserve or Standby - Leg Departure Date Equals Last Day of Reserve Block - Existing Behavior Unchanged, Any Lateness Produces LCO = D"
        precondition = "Precondition: Crew member has a Reserve (R) or Standby (S) assignment. The leg departure date EQUALS the last day of the reserve block (no reserve days remaining after departure). Existing behavior must remain unchanged - any lateness results in LCO = D regardless of 3-hour threshold."
        steps = @(
            @{ num="1"; action="Set up a Reserve or Standby assignment where the leg departure date equals the last day of the reserve block"; data="assignmentLabel=R or S, Crew Member=RSV005, Reserve block last day=Day 5, Leg departure date=Day 5"; result="Reserve/Standby assignment is set up where the leg lands on the final day of the reserve block" },
            @{ num="2"; action="Confirm no reserve days remain after the leg departure date"; data="Reserve days remaining after departure=0"; result="Leg departure equals the final day of the reserve block" },
            @{ num="3"; action="Apply a late arrival of less than 3 hours to the leg"; data="Original arrival=18:00, Actual arrival=20:00 (2 hours late)"; result="Late arrival under 3 hours is applied to the leg" },
            @{ num="4"; action="Trigger COA audit processing and verify LCO result"; data="Audit trigger, COA Search App - LCO value"; result="LCO = D. Existing behavior applies because the leg is on the last day of the reserve block. The 3-hour threshold does not relax the rule in this scenario." },
            @{ num="5"; action="Repeat with a late arrival of more than 3 hours and verify LCO result remains D"; data="Actual arrival shifted to 21:30 (3 hours 30 min late)"; result="LCO = D. Existing behavior produces LCO-D regardless of exact lateness duration when leg equals last day of reserve block." },
            @{ num="6"; action="Verify this scenario is distinct from the 3-hour threshold path in processing logs"; data="Processing logs, Rule attribution"; result="Logs indicate the existing 'last day of reserve block' path is used, not the new 3-hour threshold path. Behavior is preserved from pre-enhancement." }
        )
    },
    @{
        summary = "TC-RSV3HR-NEG-001: Non-Reserve/Standby Assignment with Similar Late Arrival - New Reserve Logic Not Triggered, Existing laterArrival() Behavior Unchanged"
        precondition = "Precondition: Crew member has a NON-Reserve/Standby assignment (assignmentLabel is NOT R and NOT S - e.g. Lineholder). Late arrival conditions are similar to the Reserve/Standby test cases. The new reserve 3-hour threshold logic must NOT be triggered, and existing laterArrival() behavior must remain unchanged."
        steps = @(
            @{ num="1"; action="Set up a crew member with a non-Reserve/Standby assignment (Lineholder)"; data="assignmentLabel=L or any non-R/non-S value, Crew Member=RSVNEG001, Trip type=Lineholder"; result="Non-Reserve/Standby assignment is set up successfully for the Lineholder" },
            @{ num="2"; action="Configure trip and leg conditions similar to Reserve/Standby test cases"; data="Last DP leg, Late arrival conditions mirroring TC-RSV3HR-001 or TC-RSV3HR-002"; result="Late arrival conditions are applied to the Lineholder leg" },
            @{ num="3"; action="Apply a late arrival of less than 3 hours and trigger COA audit"; data="Original arrival=18:00, Actual arrival=20:30 (2 hours 30 min late)"; result="Audit processing proceeds for the Lineholder trip" },
            @{ num="4"; action="Verify the new reserve 3-hour threshold logic is NOT triggered"; data="Processing logs, Step Function execution path"; result="Reserve-specific branch is not executed. The processing uses the existing laterArrival() path only." },
            @{ num="5"; action="Verify the final LCO reflects existing laterArrival() behavior and NOT the reserve-specific threshold"; data="COA Search App - LCO value, Rule attribution"; result="LCO value is determined by existing laterArrival() rules. No change in behavior for Lineholder/non-R/non-S assignments." },
            @{ num="6"; action="Repeat with late arrival of more than 3 hours and confirm no reserve rule is applied"; data="Actual arrival shifted to 21:30 (3 hours 30 min late)"; result="LCO is still determined by existing laterArrival() logic. The 3-hour threshold path is not entered for non-Reserve/Standby assignments." }
        )
    },
    @{
        summary = "TC-RSV3HR-NEG-002: Reserve or Standby Trip Not in Last DP Scope - New Reserve Logic Not Applied, Existing LCO Processing Continues Unchanged"
        precondition = "Precondition: Crew member has a Reserve (R) or Standby (S) assignment, but the target leg is NOT in the last DP of the trip (e.g. first DP or middle DP). The new reserve 3-hour threshold logic must NOT be applied, and existing LCO processing must continue unchanged for that leg."
        steps = @(
            @{ num="1"; action="Set up a crew member with a Reserve or Standby assignment and a multi-DP trip"; data="assignmentLabel=R or S, Crew Member=RSVNEG002, Trip has 3 DPs"; result="Reserve/Standby assignment with multi-DP trip is set up successfully" },
            @{ num="2"; action="Configure the target leg to be on a DP that is NOT the last DP"; data="Target leg position=DP1 (first) or DP2 (middle), Last DP=DP3"; result="Target leg is confirmed on a non-last DP" },
            @{ num="3"; action="Apply a late arrival of more than 3 hours to the non-last DP leg"; data="Target leg actual arrival > scheduled arrival by 3+ hours"; result="Late arrival exceeding 3 hours is applied to the non-last DP leg" },
            @{ num="4"; action="Trigger COA audit processing and verify the 3-hour reserve logic is NOT applied"; data="Audit trigger, Processing logs, Step Function execution"; result="Reserve 3-hour threshold path is not entered because the leg is not on the last DP. Scope condition is correctly enforced." },
            @{ num="5"; action="Verify existing LCO processing is used for this non-last-DP leg"; data="COA Search App - LCO value, Rule attribution"; result="LCO is determined by existing LCO rules per Section 11 trip-boundary formula. No reserve-specific override is applied." },
            @{ num="6"; action="Verify the leg on the LAST DP of the same trip still gets the correct reserve logic applied if applicable"; data="Compare non-last DP leg LCO vs last DP leg LCO in the same trip"; result="Last DP leg (if present and late) correctly uses reserve 3-hour threshold logic. Non-last DP leg uses existing LCO rules. Both coexist correctly in the same trip." }
        )
    }
)

$results = @{}
foreach ($tc in $tcs) {
    $body = MakeBody $tc.summary $tc.precondition $tc.steps
    try {
        $r = Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -Body $body
        $shortName = $tc.summary.Substring(0, [Math]::Min(28, $tc.summary.Length))
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
$results | ConvertTo-Json | Out-File "c:\Users\x282963\Desktop\Crew_Automation\reserve_3hr_tc_results.json"
Write-Host "`nResults saved to reserve_3hr_tc_results.json" -ForegroundColor Cyan
