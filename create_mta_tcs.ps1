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
                    @{ type = "paragraph"; content = @(@{ type = "text"; text = "Linked Story: Market Time Adjustment"; marks = @(@{ type = "strong" }) }) },
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
        summary = "TC-MTA-001: Market Time Adjustment - Original Leg Delayed by 15 Minutes Remains Original and No LCO Generated"
        precondition = "Precondition: Crew member has an original leg on flight 123 HOU-DAL in V0 with plannedDepTime=08:00. Change type is Market Time Adjustment. Delay = exactly 15 minutes. isOriginal = TRUE."
        steps = @(
            @{ num="1"; action="Set up a crew member with an original leg on flight 123 HOU-DAL in V0 with plannedDepTime 08:00"; data="Flight 123 HOU-DAL, isOriginal=TRUE, plannedDepTime=08:00, V0"; result="Original leg is set up successfully in V0" },
            @{ num="2"; action="Apply a market time adjustment delay of exactly 15 minutes to the original leg"; data="Delay=15 min, newDepTime=08:15, changeType=Market Time Adjustment"; result="Market time adjustment of 15 minutes is applied to the leg" },
            @{ num="3"; action="Navigate to COA Search App and retrieve the COA record for the crew member"; data="COA Search App - search by crew ID and trip"; result="COA record is retrieved successfully" },
            @{ num="4"; action="Verify the leg retains isOriginal = TRUE after exactly 15-minute delay"; data="isOriginal flag in COA record for the leg"; result="isOriginal = TRUE. A delay of 15 minutes or less does not change original status." },
            @{ num="5"; action="Verify no LCO is generated for this leg"; data="LCO field in COA record"; result="LCO: Not Generated. lcoCode is blank for this leg." }
        )
    },
    @{
        summary = "TC-MTA-002: Market Time Adjustment - Original Leg Delayed More Than 15 Minutes Becomes Non-Original and Evaluated for LCO"
        precondition = "Precondition: Crew member has an original leg on flight 123 HOU-DAL in V0 with plannedDepTime=08:00. Change type is Market Time Adjustment. Delay > 15 minutes. isOriginal = TRUE initially."
        steps = @(
            @{ num="1"; action="Set up a crew member with an original leg on flight 123 HOU-DAL in V0 with plannedDepTime 08:00"; data="Flight 123 HOU-DAL, isOriginal=TRUE, plannedDepTime=08:00, V0"; result="Original leg is set up successfully in V0" },
            @{ num="2"; action="Apply a market time adjustment delay of more than 15 minutes to the original leg"; data="Delay=16 min, newDepTime=08:16, changeType=Market Time Adjustment"; result="Market time adjustment of more than 15 minutes is applied to the leg" },
            @{ num="3"; action="Navigate to COA Search App and retrieve the COA record for the crew member"; data="COA Search App - search by crew ID and trip"; result="COA record is retrieved successfully" },
            @{ num="4"; action="Verify the leg is treated as Non-Original after delay of more than 15 minutes"; data="isOriginal flag in COA record for the leg"; result="isOriginal = FALSE. A delay of more than 15 minutes changes original status to Non-Original." },
            @{ num="5"; action="Verify the leg is evaluated for LCO eligibility"; data="LCO field in COA record"; result="LCO: Eligible for evaluation. Leg is Non-Original and must be assessed for LCO." }
        )
    },
    @{
        summary = "TC-MTA-003: Market Time Adjustment - First Trip Original Leg Delayed More Than 15 Minutes with Earlier Trip Start Generates LCO-D"
        precondition = "Precondition: Crew member has an original first leg on flight 123 HOU-DAL in V0. Change type is Market Time Adjustment. Delay/move > 15 minutes resulting in earlier trip start. isOriginal = TRUE initially."
        steps = @(
            @{ num="1"; action="Set up a crew member with an original first leg of the trip on flight 123 HOU-DAL in V0"; data="Flight 123 HOU-DAL, isOriginal=TRUE, leg position=First leg of trip, plannedDepTime=08:00, V0"; result="Original first trip leg is set up successfully in V0" },
            @{ num="2"; action="Apply a market time adjustment that moves the first leg by more than 15 minutes resulting in an earlier trip start time"; data="Delay/move > 15 min, new trip start is earlier than original planned trip start, changeType=Market Time Adjustment"; result="Market time adjustment applied resulting in earlier trip start time" },
            @{ num="3"; action="Navigate to COA Search App and retrieve the COA record for the crew member"; data="COA Search App - search by crew ID and trip"; result="COA record is retrieved successfully" },
            @{ num="4"; action="Verify the first leg is treated as Non-Original after more than 15-minute adjustment"; data="isOriginal flag in COA record for the first leg"; result="isOriginal = FALSE. Adjustment of more than 15 minutes changes original status to Non-Original." },
            @{ num="5"; action="Verify trip start boundary is impacted and LCO-D is generated for this first leg"; data="LCO field in COA record for the first leg"; result="LCO-D is generated. Earlier trip start on a first original leg with more than 15-minute adjustment triggers LCO-D." }
        )
    },
    @{
        summary = "TC-MTA-004: Market Time Adjustment - Last Trip Original Leg Delayed More Than 15 Minutes with Later Trip End Generates LCO-P"
        precondition = "Precondition: Crew member has an original last leg on flight 456 DAL-MCO in V0. Change type is Market Time Adjustment. Delay > 15 minutes resulting in later trip end. isOriginal = TRUE initially."
        steps = @(
            @{ num="1"; action="Set up a crew member with an original last leg of the trip on flight 456 DAL-MCO in V0"; data="Flight 456 DAL-MCO, isOriginal=TRUE, leg position=Last leg of trip, plannedArrTime=18:00, V0"; result="Original last trip leg is set up successfully in V0" },
            @{ num="2"; action="Apply a market time adjustment delay of more than 15 minutes to the last leg resulting in a later trip end time"; data="Delay > 15 min, newArrTime=18:20, new trip end is later than original planned trip end, changeType=Market Time Adjustment"; result="Market time adjustment applied resulting in later trip end time" },
            @{ num="3"; action="Navigate to COA Search App and retrieve the COA record for the crew member"; data="COA Search App - search by crew ID and trip"; result="COA record is retrieved successfully" },
            @{ num="4"; action="Verify the last leg is treated as Non-Original after delay of more than 15 minutes"; data="isOriginal flag in COA record for the last leg"; result="isOriginal = FALSE. Delay of more than 15 minutes changes original status to Non-Original." },
            @{ num="5"; action="Verify trip end boundary is impacted and LCO-P is generated for this last leg"; data="LCO field in COA record for the last leg"; result="LCO-P is generated. Later trip end on a last original leg with more than 15-minute delay triggers LCO-P." }
        )
    },
    @{
        summary = "TC-MTA-005: Market Time Adjustment - Middle Original Leg Delayed More Than 15 Minutes - Non-Original but No LCO When Trip Boundaries Not Impacted"
        precondition = "Precondition: Crew member has a multi-leg trip where the middle leg is original on flight 234 HOU-AUS in V0. Delay > 15 minutes on middle leg only. Trip start and trip end boundaries are NOT impacted. isOriginal = TRUE initially."
        steps = @(
            @{ num="1"; action="Set up a crew member with a multi-leg trip where the middle leg is original on flight 234 HOU-AUS in V0"; data="Trip: Leg1=123 DAL-HOU (first), Leg2=234 HOU-AUS (middle, isOriginal=TRUE), Leg3=345 AUS-MCO (last). V0."; result="Multi-leg trip with original middle leg is set up successfully in V0" },
            @{ num="2"; action="Apply a market time adjustment delay of more than 15 minutes to the middle leg only - trip start and end are not impacted"; data="Delay > 15 min on Leg2 only, trip start (Leg1) unchanged, trip end (Leg3) unchanged, changeType=Market Time Adjustment"; result="Market time adjustment applied to middle leg only without changing trip boundaries" },
            @{ num="3"; action="Navigate to COA Search App and retrieve the COA record for the crew member"; data="COA Search App - search by crew ID and trip"; result="COA record is retrieved successfully" },
            @{ num="4"; action="Verify the middle leg is treated as Non-Original after more than 15-minute delay"; data="isOriginal flag in COA record for the middle leg"; result="isOriginal = FALSE. Delay of more than 15 minutes changes original status to Non-Original for the middle leg." },
            @{ num="5"; action="Verify no LCO is generated because trip start and trip end boundaries are not impacted by this middle leg delay"; data="LCO field in COA record for the middle leg"; result="LCO: Not Generated. Middle leg delay with no trip boundary impact does not trigger LCO even though leg is Non-Original." },
            @{ num="6"; action="Verify the first and last legs retain their original isOriginal status unchanged"; data="isOriginal flag for Leg1 and Leg3 in COA record"; result="Leg1 isOriginal = TRUE and Leg3 isOriginal = TRUE. Only the delayed middle leg changes to Non-Original." }
        )
    }
)

$results = @{}
foreach ($tc in $tcs) {
    $body = MakeBody $tc.summary $tc.precondition $tc.steps
    $r = Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -Body $body
    $results[$tc.summary.Substring(0,15)] = $r.key
    Write-Host "$($tc.summary.Substring(0,20)) -> $($r.key)" -ForegroundColor Green
    Start-Sleep -Seconds 2
}

Write-Host "`n=== SUMMARY ===" -ForegroundColor Yellow
$results.GetEnumerator() | ForEach-Object { Write-Host "$($_.Key) -> $($_.Value)" }
