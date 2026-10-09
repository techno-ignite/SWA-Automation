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
                    @{ type = "paragraph"; content = @(@{ type = "text"; text = "Linked Story: Reserve Trip v0 Save Based on CM Notification and Check-In Status"; marks = @(@{ type = "strong" }) }) },
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
        summary = "TC-RESERVE-001: Reserve Trip - CM Notified but Not Checked In - v0 is Saved and Original Attributes Available for Audit Processing"
        precondition = "Precondition: A Reserve trip is assigned to a crew member. CM has been Notified but has NOT Checked In. Reserve audit processing is enabled. V0 processing is triggered."
        steps = @(
            @{ num="1"; action="Set up a Reserve trip for a crew member in the system"; data="Trip type=Reserve, Crew Member=CM001, Trip assigned"; result="Reserve trip is set up successfully for the crew member" },
            @{ num="2"; action="Mark the crew member as Notified for the Reserve trip without Check-In"; data="notificationStatus=Notified, checkInStatus=NotCheckedIn"; result="CM status is set to Notified with no Check-In recorded" },
            @{ num="3"; action="Trigger V0 processing for the Reserve trip and verify V0 record creation"; data="Reserve trip, Trigger=V0 Save event"; result="V0 is saved successfully for the Reserve trip" },
            @{ num="4"; action="Navigate to COA Search App and retrieve the Reserve trip V0 record"; data="COA Search App - search by crew ID and Reserve trip"; result="V0 record is retrieved successfully and shows isLatestOriginal=TRUE" },
            @{ num="5"; action="Verify original attributes are stored in DynamoDB for audit processing"; data="DynamoDB table coaTable - lookup by tripAssignmentId"; result="Original attributes (coaTripFirstFltDtm, coaTripLastFltDtm, DP boundaries, leg attributes) are present and complete" },
            @{ num="6"; action="Verify Phase 2 audit processing has access to the stored original attributes"; data="Audit staging table, Blaze request payload"; result="Audit processing successfully reads original attributes from V0. Reserve trip is included in audit workflow." }
        )
    },
    @{
        summary = "TC-RESERVE-002: Reserve Trip - CM Checked In but Not Notified - v0 is Saved and Original Attributes Tracked Correctly"
        precondition = "Precondition: A Reserve trip is assigned to a crew member. CM has Checked In but has NOT been Notified. Reserve audit processing is enabled. V0 processing is triggered."
        steps = @(
            @{ num="1"; action="Set up a Reserve trip for a crew member in the system"; data="Trip type=Reserve, Crew Member=CM002, Trip assigned"; result="Reserve trip is set up successfully for the crew member" },
            @{ num="2"; action="Mark the crew member as Checked In for the Reserve trip without Notification"; data="notificationStatus=NotNotified, checkInStatus=CheckedIn"; result="CM status is set to Checked In with no Notification recorded" },
            @{ num="3"; action="Trigger V0 processing for the Reserve trip and verify V0 record creation"; data="Reserve trip, Trigger=V0 Save event"; result="V0 is saved successfully for the Reserve trip" },
            @{ num="4"; action="Navigate to COA Search App and retrieve the Reserve trip V0 record"; data="COA Search App - search by crew ID and Reserve trip"; result="V0 record is retrieved successfully and shows isLatestOriginal=TRUE" },
            @{ num="5"; action="Verify original attributes are tracked correctly in DynamoDB"; data="DynamoDB table coaTable - lookup by tripAssignmentId"; result="Original attributes are tracked with correct values. All leg isOriginal flags, DP boundaries, and trip boundaries match assigned Reserve trip." },
            @{ num="6"; action="Verify the stored original attributes remain stable across subsequent processing"; data="Re-fetch V0 record after processing cycle"; result="Original attributes are preserved and unchanged. Audit processing uses the correctly tracked original attributes." }
        )
    },
    @{
        summary = "TC-RESERVE-003: Reserve Trip - CM Both Notified and Checked In - v0 is Saved Successfully and Reserve Audit Processing Continues"
        precondition = "Precondition: A Reserve trip is assigned to a crew member. CM has been both Notified AND Checked In. Reserve audit processing is enabled. V0 processing is triggered."
        steps = @(
            @{ num="1"; action="Set up a Reserve trip for a crew member in the system"; data="Trip type=Reserve, Crew Member=CM003, Trip assigned"; result="Reserve trip is set up successfully for the crew member" },
            @{ num="2"; action="Mark the crew member as both Notified and Checked In for the Reserve trip"; data="notificationStatus=Notified, checkInStatus=CheckedIn"; result="CM status is set to both Notified and Checked In" },
            @{ num="3"; action="Trigger V0 processing for the Reserve trip and verify V0 record creation"; data="Reserve trip, Trigger=V0 Save event"; result="V0 is saved successfully for the Reserve trip" },
            @{ num="4"; action="Navigate to COA Search App and retrieve the Reserve trip V0 record"; data="COA Search App - search by crew ID and Reserve trip"; result="V0 record is retrieved successfully and shows isLatestOriginal=TRUE" },
            @{ num="5"; action="Verify Reserve audit processing is initiated and continues through the normal workflow"; data="Step Function execution for Reserve audit, Audit status transitions"; result="Audit workflow proceeds from NotStarted to Started to Completed. No cancellation or failure due to Reserve-specific conditions." },
            @{ num="6"; action="Verify all original attributes are stored and audit transactions are generated"; data="DynamoDB V0 record, Audit transaction records"; result="Original attributes are complete. Audit transactions reflect the Reserve trip evaluation per LCO/LRO/RRO precedence rules." }
        )
    },
    @{
        summary = "TC-RESERVE-004: Non-Reserve Trip - Any Notification and Check-In Status - Existing Behavior Remains Unchanged"
        precondition = "Precondition: A non-Reserve (Lineholder) trip is assigned to a crew member. CM notification and check-in statuses are set in various combinations. Reserve-specific enhancement must NOT affect this flow."
        steps = @(
            @{ num="1"; action="Set up a Lineholder (non-Reserve) trip for a crew member in the system"; data="Trip type=Lineholder (Regular), Crew Member=CM004, Trip assigned"; result="Non-Reserve trip is set up successfully for the crew member" },
            @{ num="2"; action="Set the crew member notification and check-in statuses to any combination"; data="notificationStatus=Notified or NotNotified, checkInStatus=CheckedIn or NotCheckedIn (any combination)"; result="CM statuses are applied as configured for the Lineholder trip" },
            @{ num="3"; action="Trigger V0 processing for the non-Reserve trip"; data="Lineholder trip, Trigger=V0 Save event"; result="V0 is saved successfully following existing Lineholder behavior" },
            @{ num="4"; action="Navigate to COA Search App and verify the V0 record follows the existing Lineholder flow"; data="COA Search App - search by crew ID and Lineholder trip"; result="V0 record exists and is identical to pre-enhancement behavior. No new validation gates are applied to the Lineholder flow." },
            @{ num="5"; action="Verify Reserve-specific notification/check-in gating logic is NOT triggered"; data="Processing logs, Step Function path"; result="Reserve-specific branch is not executed. Lineholder path proceeds without evaluating Notified/CheckedIn conditions." },
            @{ num="6"; action="Verify audit processing for the Lineholder trip is unchanged by the Reserve enhancement"; data="Audit workflow, Audit transactions"; result="Lineholder audit workflow completes normally. No regression introduced by the Reserve enhancement." }
        )
    },
    @{
        summary = "TC-RESERVE-005 (Negative): Reserve Trip - CM Neither Notified Nor Checked In - v0 is NOT Saved and Trip Disregarded for Original Attribute Tracking"
        precondition = "Precondition: A Reserve trip is assigned to a crew member. CM has NEITHER been Notified NOR Checked In. Reserve audit processing is enabled. V0 save condition must fail per contract: LCO-04 Reserve Acknowledgement Rule."
        steps = @(
            @{ num="1"; action="Set up a Reserve trip for a crew member in the system"; data="Trip type=Reserve, Crew Member=CM005, Trip assigned"; result="Reserve trip is set up successfully for the crew member" },
            @{ num="2"; action="Ensure the crew member is neither Notified nor Checked In for the Reserve trip"; data="notificationStatus=NotNotified, checkInStatus=NotCheckedIn"; result="CM has no acknowledgement recorded for the Reserve trip" },
            @{ num="3"; action="Attempt to trigger V0 processing for the Reserve trip"; data="Reserve trip, Trigger=V0 Save event"; result="V0 save is skipped because the CM has not acknowledged the Reserve trip (per LCO-04)" },
            @{ num="4"; action="Navigate to COA Search App and search for the Reserve trip V0 record"; data="COA Search App - search by crew ID and Reserve trip"; result="No V0 record is returned. The Reserve trip is not stored for original attribute tracking." },
            @{ num="5"; action="Verify DynamoDB does not contain a V0 entry for this Reserve trip"; data="DynamoDB table coaTable - lookup by tripAssignmentId"; result="No V0 record exists in DynamoDB. Original attributes are not persisted for this Reserve trip." },
            @{ num="6"; action="Verify the Reserve trip is disregarded from original attribute tracking in subsequent audit cycles"; data="Audit staging, Reserve audit workflow"; result="Reserve trip does not appear in the audit staging table. The trip is correctly disregarded for original tracking until CM is Notified or Checked In." }
        )
    },
    @{
        summary = "TC-RESERVE-006 (Negative): Reserve Trip - Invalid or Missing Notification and Check-In Status - System Handles Gracefully Without Impacting Audit Processing"
        precondition = "Precondition: A Reserve trip is assigned to a crew member. The notification and/or check-in status fields are invalid or missing (null, empty string, or unexpected value). System must handle gracefully without crashing or impacting other audit processing."
        steps = @(
            @{ num="1"; action="Set up a Reserve trip for a crew member in the system"; data="Trip type=Reserve, Crew Member=CM006, Trip assigned"; result="Reserve trip is set up successfully for the crew member" },
            @{ num="2"; action="Simulate invalid or missing notification and check-in status values on the CM record"; data="notificationStatus=null OR empty OR invalid value (e.g. 'XYZ'), checkInStatus=null OR empty OR invalid value"; result="Reserve trip has invalid or missing notification and check-in statuses" },
            @{ num="3"; action="Trigger V0 processing for the Reserve trip and observe system behavior"; data="Reserve trip, Trigger=V0 Save event"; result="System does not save V0 for this Reserve trip because the status cannot be validated. No exception is thrown that aborts the pipeline." },
            @{ num="4"; action="Navigate to COA Search App and search for the Reserve trip V0 record"; data="COA Search App - search by crew ID and Reserve trip"; result="No V0 record is returned for this Reserve trip. The missing/invalid status prevents V0 save." },
            @{ num="5"; action="Verify the condition is logged for operational visibility without crashing the service"; data="Service logs, Error metrics"; result="A warning or error log is recorded identifying the invalid/missing status. The service continues to run and process other trips." },
            @{ num="6"; action="Verify audit processing for other valid trips continues without impact"; data="Other crew members' audit workflows (valid Reserve and Lineholder trips)"; result="Audit processing for other trips is unaffected. The invalid Reserve trip is isolated and does not block or corrupt the overall audit pipeline." }
        )
    }
)

$results = @{}
foreach ($tc in $tcs) {
    $body = MakeBody $tc.summary $tc.precondition $tc.steps
    try {
        $r = Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -Body $body
        $shortName = $tc.summary.Substring(0, [Math]::Min(25, $tc.summary.Length))
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
$results | ConvertTo-Json | Out-File "c:\Users\x282963\Desktop\Crew_Automation\reserve_tc_results.json"
Write-Host "`nResults saved to reserve_tc_results.json" -ForegroundColor Cyan
