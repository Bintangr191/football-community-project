*** Settings ***
Library    RequestsLibrary
Library    Collections
Library    String
Library    DatabaseLibrary

*** Variables ***
${BASE_URL}    http://localhost:3000
${TEST_USER_EMAIL}    test_integration@example.com
${TEST_USER_PASSWORD}    password123
${TEST_USER_USERNAME}    test_integration

${DB_NAME}        football_auth
${DB_USER}        football
${DB_PASSWORD}    football123
${DB_HOST}        localhost
${DB_PORT}        3306

*** Keywords ***
Create Test User And Login
    [Documentation]    Registers a test user if not exists, verifies them, then logs in to get Bearer token.
    Create Session    api_gateway    ${BASE_URL}
    
    # Try to register
    ${register_body}=    Create Dictionary    username=${TEST_USER_USERNAME}    email=${TEST_USER_EMAIL}    password=${TEST_USER_PASSWORD}
    ${resp_reg}=    POST On Session    api_gateway    /auth/register    json=${register_body}    expected_status=any
    
    # Verify user in DB directly to bypass OTP
    Connect To Database    pymysql    ${DB_NAME}    ${DB_USER}    ${DB_PASSWORD}    ${DB_HOST}    ${DB_PORT}
    Execute Sql String    UPDATE User SET isVerified=1 WHERE email='${TEST_USER_EMAIL}'
    Disconnect From Database
    
    # Login
    ${login_body}=    Create Dictionary    email=${TEST_USER_EMAIL}    password=${TEST_USER_PASSWORD}
    ${resp_login}=    POST On Session    api_gateway    /auth/login    json=${login_body}
    Status Should Be    200    ${resp_login}
    
    ${access_token}=    Set Variable    ${resp_login.json()['accessToken']}
    Set Global Variable    ${ACCESS_TOKEN}    ${access_token}
    
    # Create authenticated headers
    ${auth_headers}=    Create Dictionary    Authorization=Bearer ${ACCESS_TOKEN}    Content-Type=application/json
    Set Global Variable    ${AUTH_HEADERS}    ${auth_headers}
    
    # Create an authenticated session for all tests to use
    Create Session    auth_session    ${BASE_URL}    headers=${auth_headers}
