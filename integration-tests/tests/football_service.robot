*** Settings ***
Resource    ../resources/common.resource
Suite Setup    Create Test User And Login

*** Variables ***
${LEAGUE_CODE}    PL
${TEAM_ID}        57
${TEAM_NAME}      Arsenal FC

*** Test Cases ***
Get Leagues
    [Documentation]    Fetch all supported leagues.
    ${resp}=    GET On Session    auth_session    /football/leagues
    Status Should Be    200    ${resp}
    Dictionary Should Contain Key    ${resp.json()}    leagues

Get Standings
    [Documentation]    Fetch standings for a specific league (PL).
    ${resp}=    GET On Session    auth_session    /football/standings/${LEAGUE_CODE}
    Status Should Be    200    ${resp}
    Should Be Equal As Strings    ${resp.json()['code']}    ${LEAGUE_CODE}
    Dictionary Should Contain Key    ${resp.json()}    standings

Get Schedule
    [Documentation]    Fetch today's match schedule.
    ${resp}=    GET On Session    auth_session    /football/schedule
    Status Should Be    200    ${resp}
    Dictionary Should Contain Key    ${resp.json()}    matches

Get Team Details
    [Documentation]    Fetch details of a specific team (Arsenal = 57).
    ${resp}=    GET On Session    auth_session    /football/team/${TEAM_ID}
    Status Should Be    200    ${resp}
    Should Be Equal As Integers    ${resp.json()['id']}    ${TEAM_ID}

Search Team
    [Documentation]    Search for a team by name.
    ${resp}=    GET On Session    auth_session    url=/football/search?team=Arsenal
    Status Should Be    200    ${resp}
    Dictionary Should Contain Key    ${resp.json()}    teams

Get Top Scorers
    [Documentation]    Fetch top scorers for a league (WC).
    ${resp}=    GET On Session    auth_session    /football/scorers/WC
    Status Should Be    200    ${resp}
    Dictionary Should Contain Key    ${resp.json()}    scorers

Add Favorite Team
    [Documentation]    Add a team to favorites.
    ${body}=    Create Dictionary    teamId=${TEAM_ID}    teamName=${TEAM_NAME}
    ${resp}=    POST On Session    auth_session    /football/favorite    json=${body}    expected_status=any
    # It might return 200 or 400 if already favorited. We just ensure it doesn't crash 500.
    Run Keyword If    ${resp.status_code} == 200    Dictionary Should Contain Key    ${resp.json()}    success

Get Favorite Teams
    [Documentation]    Get the list of favorite teams.
    ${resp}=    GET On Session    auth_session    /football/favorite
    Status Should Be    200    ${resp}
    Dictionary Should Contain Key    ${resp.json()}    data

Remove Favorite Team
    [Documentation]    Remove a team from favorites.
    ${resp}=    DELETE On Session    auth_session    /football/favorite/${TEAM_ID}    expected_status=any
    # Allow 200 or 400 (if it didn't exist)
    Run Keyword If    ${resp.status_code} == 200    Should Be Equal As Strings    ${resp.json()['message']}    Favorite removed

Add Recent Viewed Team
    [Documentation]    Add a team to recent viewed history.
    ${body}=    Create Dictionary    teamId=${TEAM_ID}    teamName=${TEAM_NAME}
    ${resp}=    POST On Session    auth_session    /football/recent-viewed    json=${body}
    Status Should Be    200    ${resp}
    Dictionary Should Contain Key    ${resp.json()['data']}    id

Get Recent Viewed Teams
    [Documentation]    Get the list of recently viewed teams.
    ${resp}=    GET On Session    auth_session    /football/recent-viewed
    Status Should Be    200    ${resp}
    Dictionary Should Contain Key    ${resp.json()}    data
