$cred = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes('vinodkumar.puttagunta@wnco.com:ATATT3xFfGF0pAMAJMJBVruClKISQfvQDH2OMSmZ4NCfmyVfrDw9dyrszw2Uaq8ihg58YEuezlHIv5046KdSAkxXNGfQzlleG_zxLIxsX9bq4Uso1Ws7oKlKCjFsS2vGWRFdIp3kmqFOjgp0eZCBqepFuP9fAwCw-4_tFIWKzuo2MXJIe1Ry2Xg=886C5949'))
$headers = @{Authorization='Basic ' + $cred; 'Content-Type'='application/json'}
$baseUrl = 'https://southwest.atlassian.net/rest/raven/1.0/api/test/CSRXP-64072/step'

$steps = @(
    @{
        action = "h4. Preconditions`n`n# {{COA_CSS_TOGGLE = TRUE}}`n# {{COA_CSS_PHASE_2_TOGGLE = TRUE}}`n# {{COA_CSS_PHASE_2_AUTO_AUDIT_TOGGLE = TRUE}}`n# Reserve CM trip must exist and be eligible for Save and Replace involuntary transaction.`n# Trip release time must be *at least 2 hours prior to current system time* to qualify for processing."
        data   = ""
        result = ""
    },
    @{
        action = "Create a Reserve CM trip with valid legs in 1 DP or 2 DPs"
        data   = "Valid flight legs with report/release times for Reserve CM"
        result = "Trip is created successfully with correct DP and leg structure for Reserve CM"
    },
    @{
        action = "Assign a Crew Member in Reserve CM position"
        data   = "Reserve CM Crew Member"
        result = "Assignment is successfully created for Reserve CM"
    },
    @{
        action = "Perform Save and Replace (Involuntary) transaction on the Reserve CM trip"
        data   = "Involuntary Save and Replace event via CSS"
        result = "Save and Replace transaction is executed successfully and triggers downstream events"
    },
    @{
        action = "Verify Pairing Kafka Event"
        data   = "Pairing Topic: ent.workforce.crewPairing.v2.techp"
        result = "Pairing event is published with all trip, DP, leg, pay, credit, distance, and flight timing details reflecting the Save and Replace"
    },
    @{
        action = "Verify Assignment Kafka Event"
        data   = "Assignment Topic: ent.workforce.crewAssignment.v2"
        result = "Assignment event is published with updated assignment information and trip assignment identifiers after Save and Replace"
    },
    @{
        action = "Verify Aggregated Kafka Event"
        data   = "Aggregated Topic"
        result = "Aggregated event contains complete trip-level, DP-level, leg-level, assignment, credit, pay, and timing information for the replaced trip"
    },
    @{
        action = "Validate Kafka Payload Fields"
        data   = "Aggregated Topics: int.workforce.aggregatedCrewAssignment.v1.techp"
        result = "Required fields are populated including assignmentDetail.beginDateTimeUTC, assignmentDetail.endDateTimeUTC, pairingDetail.pay.credit, pairingDetail.dutyPeriods[], dutyPeriods.pay, reportDateTimeUTC, releaseDateTimeUTC, legs[], legs.pay.credit, distance, departure/arrival/report/release timings, and all leg-level changes"
    },
    @{
        action = "Verify COA Hydration Step Function"
        data   = "crew-qa2-techp-cmn-coa-lineholder"
        result = "Step Function executes successfully and processes all trip, DP, leg, assignment, pay, and credit information for the Save and Replace event"
    },
    @{
        action = "Verify Blaze Pull Lambda Execution"
        data   = "Blaze Pull Lambda"
        result = "Lambda executes successfully and contains complete trip-level, DP-level, leg-level, pay, credit, and timing information"
    },
    @{
        action = "Verify COA Record in DynamoDB"
        data   = "crew-qa2-techp-cmn-coatable"
        result = "COA record is created/updated successfully using COA Key or GSI COA Key reflecting the Save and Replace transaction"
    },
    @{
        action = "Validate Trip and DP Flight Date Fields"
        data   = "coaTripFirstFltDtm, coaTripLastFltDtm, coaDpFirstFltDtm, coaDpLastFltDtm"
        result = "Fields are populated from the version that contains the original flight-related timings after Save and Replace"
    },
    @{
        action = "Validate Original Version Logic"
        data   = "Versioned COA Records (V0, V1, etc.)"
        result = "If V1 contains original flight data, fields reference V1. If current version is V1 and original flight data exists in V0, fields reference V0"
    },
    @{
        action = "Verify COA Data in COA Search App"
        data   = "COA Search App"
        result = "COA Search App reflects updated trip data after Save and Replace involuntary transaction"
    },
    @{
        action = "Verify Analytical Schema"
        data   = "Analytical Schema endpoint"
        result = "Analytical Schema is updated with correct trip, DP, leg, pay, and credit data post Save and Replace"
    },
    @{
        action = "Verify CSS Database Updates"
        data   = "CSS Database"
        result = "Save and Replace transactions and results are successfully persisted in CSS Database"
    },
    @{
        action = "Verify COA Transactions"
        data   = "COA Application"
        result = "Transactions generated from Save and Replace are stored successfully in COA"
    },
    @{
        action = "Verify CSS Transaction Report"
        data   = "CSS Transaction Report"
        result = "Save and Replace related transactions are displayed correctly in the CSS Transaction Report"
    },
    @{
        action = "Verify CMOP Data"
        data   = "CMOP"
        result = "All pay credits, flight credits, and Save and Replace related credits are displayed correctly in CMOP"
    }
)

$success = 0
$fail = 0

foreach ($step in $steps) {
    $body = @{ step = @{ action = $step.action; data = $step.data; result = $step.result } } | ConvertTo-Json -Depth 5 -Compress
    try {
        $r = Invoke-RestMethod -Uri $baseUrl -Method POST -Headers $headers -Body $body
        Write-Host "OK: $($step.action.Substring(0, [Math]::Min(60, $step.action.Length)))"
        $success++
    } catch {
        $errMsg = $_.Exception.Message
        $statusCode = ''
        $respBody = ''
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
            $sr = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $respBody = $sr.ReadToEnd()
        }
        Write-Host "FAIL [$statusCode]: $($step.action.Substring(0, [Math]::Min(60, $step.action.Length))) | $errMsg | $respBody"
        $fail++
    }
}

Write-Host "---"
Write-Host "Done: $success succeeded, $fail failed"
