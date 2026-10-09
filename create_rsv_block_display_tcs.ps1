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
                    @{ type = "paragraph"; content = @(@{ type = "text"; text = "Linked Story: Reserve Block Display Based on Overlap with Reserve Trip"; marks = @(@{ type = "strong" }) }) },
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
        summary = "TC-RSVBLK-001: Reserve Block is Displayed When It is Associated With or Overlaps the Reserve Trip"
        precondition = "Precondition: A crew member has a Reserve Trip. A Reserve Block exists that either shares association with the Reserve Trip or overlaps with the Reserve Trip time window. The Reserve Block MUST be displayed on the Reserve Trip view."
        steps = @(
            @{ num="1"; action="Set up a crew member with a Reserve Trip in the system"; data="Crew Member=CM-RSVBLK-001, Reserve Trip ID=RSV-TRIP-001, Trip start=Day 1 06:00, Trip end=Day 3 18:00"; result="Reserve Trip is set up successfully for the crew member" },
            @{ num="2"; action="Create a Reserve Block that overlaps with the Reserve Trip time window"; data="Reserve Block ID=RSV-BLK-001, Block start=Day 2 00:00, Block end=Day 2 23:59 (overlaps middle of trip)"; result="Reserve Block overlapping the Reserve Trip is created successfully" },
            @{ num="3"; action="Navigate to COA Search App and retrieve the Reserve Trip view for the crew member"; data="COA Search App - search by crew ID and Reserve Trip ID"; result="Reserve Trip view loads successfully for the crew member" },
            @{ num="4"; action="Verify the overlapping Reserve Block is associated and displayed on the Reserve Trip view"; data="Reserve Block section of the Reserve Trip view"; result="Reserve Block RSV-BLK-001 is displayed on the Reserve Trip view with correct block start and end timestamps" },
            @{ num="5"; action="Repeat with a Reserve Block fully contained within the Reserve Trip and one that partially overlaps"; data="Case A: Block fully inside trip (Day 2 10:00 to Day 2 14:00). Case B: Block partially overlaps start (Day 0 20:00 to Day 1 10:00). Case C: Block partially overlaps end (Day 3 10:00 to Day 4 10:00)"; result="All three overlap variations display the Reserve Block correctly on the Reserve Trip view" },
            @{ num="6"; action="Verify the displayed Reserve Block details match the DynamoDB and backend data"; data="DynamoDB record for Reserve Block, Reserve Trip association field"; result="Reserve Block details on the UI match the backend record. The association logic between Reserve Block and Reserve Trip is correctly reflected in the display." }
        )
    },
    @{
        summary = "TC-RSVBLK-002: Reserve Block is NOT Displayed When It Occurs Before the Reserve Trip and Does Not Overlap"
        precondition = "Precondition: A crew member has a Reserve Trip. A Reserve Block exists that ends entirely BEFORE the Reserve Trip start time with no overlap. The Reserve Block MUST NOT be displayed on the Reserve Trip view."
        steps = @(
            @{ num="1"; action="Set up a crew member with a Reserve Trip in the system"; data="Crew Member=CM-RSVBLK-002, Reserve Trip ID=RSV-TRIP-002, Trip start=Day 5 06:00, Trip end=Day 7 18:00"; result="Reserve Trip is set up successfully for the crew member" },
            @{ num="2"; action="Create a Reserve Block that ends completely before the Reserve Trip starts"; data="Reserve Block ID=RSV-BLK-002, Block start=Day 1 00:00, Block end=Day 3 23:59 (ends well before trip start Day 5)"; result="Reserve Block before the Reserve Trip (no overlap) is created successfully" },
            @{ num="3"; action="Confirm there is no time overlap between the Reserve Block and the Reserve Trip"; data="Block end=Day 3 23:59, Trip start=Day 5 06:00, Gap >24 hours, No overlap"; result="Reserve Block and Reserve Trip have no time intersection" },
            @{ num="4"; action="Navigate to COA Search App and retrieve the Reserve Trip view for the crew member"; data="COA Search App - search by crew ID and Reserve Trip ID"; result="Reserve Trip view loads successfully for the crew member" },
            @{ num="5"; action="Verify the Reserve Block that occurred before the Reserve Trip is NOT displayed on the Reserve Trip view"; data="Reserve Block section of the Reserve Trip view"; result="Reserve Block RSV-BLK-002 is NOT displayed on the Reserve Trip view. The block is correctly excluded because it does not overlap." },
            @{ num="6"; action="Verify that the exclusion is specifically due to the non-overlap condition and not a data error"; data="Processing logs, Overlap check attribution"; result="Logs confirm the overlap check returned false. The Reserve Block exists in the system but is correctly filtered out from the Reserve Trip display per the non-overlap rule." }
        )
    },
    @{
        summary = "TC-RSVBLK-003: Reserve Block is NOT Displayed When It Occurs After the Reserve Trip and Does Not Overlap"
        precondition = "Precondition: A crew member has a Reserve Trip. A Reserve Block exists that starts entirely AFTER the Reserve Trip end time with no overlap. The Reserve Block MUST NOT be displayed on the Reserve Trip view."
        steps = @(
            @{ num="1"; action="Set up a crew member with a Reserve Trip in the system"; data="Crew Member=CM-RSVBLK-003, Reserve Trip ID=RSV-TRIP-003, Trip start=Day 1 06:00, Trip end=Day 3 18:00"; result="Reserve Trip is set up successfully for the crew member" },
            @{ num="2"; action="Create a Reserve Block that starts completely after the Reserve Trip ends"; data="Reserve Block ID=RSV-BLK-003, Block start=Day 5 00:00, Block end=Day 7 23:59 (starts well after trip end Day 3)"; result="Reserve Block after the Reserve Trip (no overlap) is created successfully" },
            @{ num="3"; action="Confirm there is no time overlap between the Reserve Trip and the Reserve Block"; data="Trip end=Day 3 18:00, Block start=Day 5 00:00, Gap >24 hours, No overlap"; result="Reserve Trip and Reserve Block have no time intersection" },
            @{ num="4"; action="Navigate to COA Search App and retrieve the Reserve Trip view for the crew member"; data="COA Search App - search by crew ID and Reserve Trip ID"; result="Reserve Trip view loads successfully for the crew member" },
            @{ num="5"; action="Verify the Reserve Block that occurs after the Reserve Trip is NOT displayed on the Reserve Trip view"; data="Reserve Block section of the Reserve Trip view"; result="Reserve Block RSV-BLK-003 is NOT displayed on the Reserve Trip view. The block is correctly excluded because it does not overlap." },
            @{ num="6"; action="Verify that the Reserve Block still exists independently in the system and can be viewed outside the trip context"; data="Reserve Block search by block ID, independent block view"; result="Reserve Block RSV-BLK-003 is present in the system and visible in its own context. It is only excluded from the specific Reserve Trip display because of the non-overlap condition." }
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
$results | ConvertTo-Json | Out-File "c:\Users\x282963\Desktop\Crew_Automation\rsv_block_display_tc_results.json"
Write-Host "`nResults saved to rsv_block_display_tc_results.json" -ForegroundColor Cyan
