*** Settings ***
Resource    ../resources/common.resource
Suite Setup    Create Session    api_gateway    ${BASE_URL}

*** Variables ***
${NEW_USER_EMAIL}    new_user@example.com
${NEW_USER_PASSWORD}    password123
${NEW_USER_USERNAME}    new_user_123

*** Test Cases ***
Register A New User
    [Documentation]    Test registration of a new user and bypass OTP verification via DB.
    ${body}=    Create Dictionary    username=${NEW_USER_USERNAME}    email=${NEW_USER_EMAIL}    password=${NEW_USER_PASSWORD}
    ${resp}=    POST On Session    api_gateway    /auth/register    json=${body}    expected_status=any
    Run Keyword If    ${resp.status_code} == 201    Dictionary Should Contain Key    ${resp.json()}    success
    
    # Verify user in DB directly to bypass OTP
    Connect To Database    pymysql    ${DB_NAME}    ${DB_USER}    ${DB_PASSWORD}    ${DB_HOST}    ${DB_PORT}
    Execute Sql String    UPDATE User SET isVerified=1 WHERE email='${NEW_USER_EMAIL}'
    Disconnect From Database
    
Login And Get Tokens
    [Documentation]    Test user login and token generation.
    ${body}=    Create Dictionary    email=${NEW_USER_EMAIL}    password=${NEW_USER_PASSWORD}
    ${resp}=    POST On Session    api_gateway    /auth/login    json=${body}
    Status Should Be    200    ${resp}
    Dictionary Should Contain Key    ${resp.json()}    accessToken
    Dictionary Should Contain Key    ${resp.json()}    refreshToken
    
    Set Suite Variable    ${LOCAL_REFRESH_TOKEN}    ${resp.json()['refreshToken']}
    Set Suite Variable    ${LOCAL_ACCESS_TOKEN}    ${resp.json()['accessToken']}

Refresh Token
    [Documentation]    Test refreshing the access token.
    ${body}=    Create Dictionary    refreshToken=${LOCAL_REFRESH_TOKEN}
    ${resp}=    POST On Session    api_gateway    /auth/refresh    json=${body}
    Status Should Be    200    ${resp}
    Dictionary Should Contain Key    ${resp.json()}    accessToken
    
    # Save new tokens for logout
    Set Suite Variable    ${LOCAL_REFRESH_TOKEN}    ${resp.json()['refreshToken']}
    Set Suite Variable    ${LOCAL_ACCESS_TOKEN}    ${resp.json()['accessToken']}

Get Profile
    [Documentation]    Test getting user profile.
    ${headers}=    Create Dictionary    Authorization=Bearer ${LOCAL_ACCESS_TOKEN}
    ${resp}=    GET On Session    api_gateway    /auth/profile    headers=${headers}
    Status Should Be    200    ${resp}
    Dictionary Should Contain Key    ${resp.json()['data']}    email
    Should Be Equal    ${resp.json()['data']['email']}    ${NEW_USER_EMAIL}

Update Profile
    [Documentation]    Test updating user profile.
    ${headers}=    Create Dictionary    Authorization=Bearer ${LOCAL_ACCESS_TOKEN}
    ${body}=    Create Dictionary    fullName=Updated Name    bio=This is a test bio
    ${resp}=    PATCH On Session    api_gateway    /auth/profile    json=${body}    headers=${headers}
    Status Should Be    200    ${resp}
    Should Be Equal    ${resp.json()['data']['fullName']}    Updated Name

Logout
    [Documentation]    Test user logout using the refresh token.
    ${body}=    Create Dictionary    refreshToken=${LOCAL_REFRESH_TOKEN}
    ${resp}=    POST On Session    api_gateway    /auth/logout    json=${body}
    Status Should Be    200    ${resp}
    Should Be Equal As Strings    ${resp.json()['success']}    True
