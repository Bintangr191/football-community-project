*** Settings ***
Resource    ../resources/common.resource
Suite Setup    Create Test User And Login

*** Variables ***
${REPORT_ID}      ${EMPTY}
${COMMENT_ID}     ${EMPTY}
# Base64 image kecil valid (1x1 pixel PNG)
${VALID_IMAGE}    data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==

*** Test Cases ***
Create A New Report
    [Documentation]    Creates a new community report and saves its ID.
    ${body}=    Create Dictionary
    ...    title=Jalan Rusak Parah di Komplek
    ...    description=Jalan berlubang sangat berbahaya untuk pengendara motor dan mobil di area komplek perumahan.
    ...    latitude=${-6.200000}
    ...    longitude=${106.816666}
    ...    locationName=Komplek Perumahan Blok A
    ...    imageBase64=${VALID_IMAGE}
    ${resp}=    POST On Session    auth_session    /reports    json=${body}
    Status Should Be    201    ${resp}
    Should Be Equal As Strings    ${resp.json()['success']}    True
    Dictionary Should Contain Key    ${resp.json()['data']}    id

    ${report_id}=    Set Variable    ${resp.json()['data']['id']}
    Set Suite Variable    ${REPORT_ID}    ${report_id}

Get Report Feed (Default Hot)
    [Documentation]    Gets the report feed using default hot sort.
    ${resp}=    GET On Session    auth_session    /reports
    Status Should Be    200    ${resp}
    Should Be Equal As Strings    ${resp.json()['success']}    True
    Dictionary Should Contain Key    ${resp.json()}    data
    Dictionary Should Contain Key    ${resp.json()}    total
    Dictionary Should Contain Key    ${resp.json()}    totalPages

Get Report Feed With New Sort
    [Documentation]    Gets the report feed sorted by newest.
    ${resp}=    GET On Session    auth_session    url=/reports?sort=new&page=1&limit=10
    Status Should Be    200    ${resp}
    Should Be Equal As Strings    ${resp.json()['success']}    True

Get Report Feed With Search
    [Documentation]    Searches for a report by keyword.
    ${resp}=    GET On Session    auth_session    url=/reports?search=Jalan
    Status Should Be    200    ${resp}
    Should Be Equal As Strings    ${resp.json()['success']}    True

Get My Reports
    [Documentation]    Gets reports created by the logged-in user.
    ${resp}=    GET On Session    auth_session    /reports/me
    Status Should Be    200    ${resp}
    Should Be Equal As Strings    ${resp.json()['success']}    True
    Dictionary Should Contain Key    ${resp.json()}    data
    # Harus ada minimal 1 laporan (yang baru saja dibuat)
    ${count}=    Get Length    ${resp.json()['data']}
    Should Be True    ${count} >= 1

Get Report By ID
    [Documentation]    Gets detail of the specific report we created.
    ${resp}=    GET On Session    auth_session    /reports/${REPORT_ID}
    Status Should Be    200    ${resp}
    Should Be Equal As Strings    ${resp.json()['success']}    True
    Should Be Equal As Strings    ${resp.json()['data']['id']}    ${REPORT_ID}

Update Report
    [Documentation]    Updates the title and description of the report.
    ${body}=    Create Dictionary
    ...    title=Jalan Rusak Sangat Parah Updated
    ...    description=Deskripsi diperbarui: Kondisi jalan semakin parah dan butuh penanganan segera dari pihak terkait.
    ${resp}=    PUT On Session    auth_session    /reports/${REPORT_ID}    json=${body}
    Status Should Be    200    ${resp}
    Should Be Equal As Strings    ${resp.json()['success']}    True

Upvote Report
    [Documentation]    Upvotes the report.
    ${body}=    Create Dictionary    type=UP
    ${resp}=    POST On Session    auth_session    /reports/${REPORT_ID}/vote    json=${body}
    Status Should Be    200    ${resp}
    Should Be Equal As Strings    ${resp.json()['success']}    True
    Dictionary Should Contain Key    ${resp.json()}    upvotes
    Dictionary Should Contain Key    ${resp.json()}    score

Toggle Off Upvote Report
    [Documentation]    Upvotes the same report again to toggle off (cancel vote).
    ${body}=    Create Dictionary    type=UP
    ${resp}=    POST On Session    auth_session    /reports/${REPORT_ID}/vote    json=${body}
    Status Should Be    200    ${resp}
    Should Be Equal As Strings    ${resp.json()['success']}    True

Downvote Report
    [Documentation]    Downvotes the report.
    ${body}=    Create Dictionary    type=DOWN
    ${resp}=    POST On Session    auth_session    /reports/${REPORT_ID}/vote    json=${body}
    Status Should Be    200    ${resp}
    Should Be Equal As Strings    ${resp.json()['success']}    True

Create Comment On Report
    [Documentation]    Adds a comment to the report and saves comment ID.
    ${body}=    Create Dictionary    content=Saya juga melihat ini. Kondisinya memang sangat parah!
    ${resp}=    POST On Session    auth_session    /reports/${REPORT_ID}/comments    json=${body}
    Status Should Be    201    ${resp}
    Should Be Equal As Strings    ${resp.json()['success']}    True
    Dictionary Should Contain Key    ${resp.json()['data']}    id

    ${comment_id}=    Set Variable    ${resp.json()['data']['id']}
    Set Suite Variable    ${COMMENT_ID}    ${comment_id}

Get Comments For Report
    [Documentation]    Gets all comments for the report.
    ${resp}=    GET On Session    auth_session    /reports/${REPORT_ID}/comments
    Status Should Be    200    ${resp}
    Should Be Equal As Strings    ${resp.json()['success']}    True
    ${count}=    Get Length    ${resp.json()['data']}
    Should Be True    ${count} >= 1

Mark Report As Resolved
    [Documentation]    Marks the report as resolved with the comment ID as resolution.
    ${body}=    Create Dictionary    commentId=${COMMENT_ID}
    ${resp}=    PATCH On Session    auth_session    /reports/${REPORT_ID}/status    json=${body}
    Status Should Be    200    ${resp}
    Should Be Equal As Strings    ${resp.json()['success']}    True

Cannot Mark Already Resolved Report
    [Documentation]    Verifies that a resolved report cannot be resolved again.
    ${body}=    Create Dictionary    commentId=${COMMENT_ID}
    ${resp}=    PATCH On Session    auth_session    /reports/${REPORT_ID}/status    json=${body}    expected_status=any
    Should Be True    ${resp.status_code} == 400

Delete Comment
    [Documentation]    Deletes the comment we created.
    ${resp}=    DELETE On Session    auth_session    /reports/comments/${COMMENT_ID}
    Status Should Be    200    ${resp}
    Should Be Equal As Strings    ${resp.json()['success']}    True

Delete Report
    [Documentation]    Deletes the report we created. Must be done last.
    ${resp}=    DELETE On Session    auth_session    /reports/${REPORT_ID}
    Status Should Be    200    ${resp}
    Should Be Equal As Strings    ${resp.json()['success']}    True

Verify Report Deleted
    [Documentation]    Confirms the deleted report returns 404.
    ${resp}=    GET On Session    auth_session    /reports/${REPORT_ID}    expected_status=any
    Should Be True    ${resp.status_code} == 404
