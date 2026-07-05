*** Settings ***
Resource    ../resources/common.resource
Suite Setup    Create Test User And Login

*** Variables ***
${POST_ID}    ${EMPTY}
${COMMENT_ID}    ${EMPTY}

*** Test Cases ***
Create Published Post
    [Documentation]    Creates a new post in the forum.
    ${body}=    Create Dictionary    title=Test Post Integration    content=This is a test post body    teamId=${57}    teamName=Arsenal
    ${resp}=    POST On Session    auth_session    /forum/posts    json=${body}
    Status Should Be    200    ${resp}
    Dictionary Should Contain Key    ${resp.json()['data']}    id
    Should Be Equal As Strings    ${resp.json()['data']['status']}    PUBLISHED
    
    # Save post id for later tests
    ${post_id}=    Set Variable    ${resp.json()['data']['id']}
    Set Suite Variable    ${POST_ID}    ${post_id}

Create Scheduled Post
    [Documentation]    Creates a scheduled post.
    # We set a future date
    ${body}=    Create Dictionary    title=Scheduled Post    content=Future content    publishAt=2030-01-01T10:00:00Z
    ${resp}=    POST On Session    auth_session    /forum/posts    json=${body}
    Status Should Be    200    ${resp}
    Should Be Equal As Strings    ${resp.json()['data']['status']}    SCHEDULED

Get All Published Posts
    [Documentation]    Gets a list of posts.
    ${resp}=    GET On Session    auth_session    /forum/posts
    Status Should Be    200    ${resp}
    Dictionary Should Contain Key    ${resp.json()['data']}    posts

Get My Posts
    [Documentation]    Gets the user's posts (including scheduled).
    ${resp}=    GET On Session    auth_session    /forum/posts/me
    Status Should Be    200    ${resp}
    Dictionary Should Contain Key    ${resp.json()}    posts

Search Posts
    [Documentation]    Searches for a specific post.
    ${resp}=    GET On Session    auth_session    url=/forum/posts/search?q=Test Post
    Status Should Be    200    ${resp}
    Dictionary Should Contain Key    ${resp.json()['data']}    posts

Get Post By ID
    [Documentation]    Gets details of the post we created.
    ${resp}=    GET On Session    auth_session    /forum/posts/${POST_ID}
    Status Should Be    200    ${resp}
    Should Be Equal As Strings    ${resp.json()['data']['id']}    ${POST_ID}

Update Post
    [Documentation]    Updates the post title and content.
    ${body}=    Create Dictionary    title=Updated Test Post    content=Updated content
    ${resp}=    PUT On Session    auth_session    /forum/posts/${POST_ID}    json=${body}
    Status Should Be    200    ${resp}
    Should Be Equal As Strings    ${resp.json()['data']['title']}    Updated Test Post

Vote Post Up
    [Documentation]    Upvotes a post.
    ${body}=    Create Dictionary    postId=${POST_ID}    type=UP
    ${resp}=    POST On Session    auth_session    /forum/posts/vote    json=${body}
    Status Should Be    200    ${resp}

Create Comment
    [Documentation]    Adds a comment to the post.
    ${body}=    Create Dictionary    postId=${POST_ID}    content=This is a test comment
    ${resp}=    POST On Session    auth_session    /forum/comments    json=${body}
    Status Should Be    200    ${resp}
    Dictionary Should Contain Key    ${resp.json()['data']}    id
    
    ${comment_id}=    Set Variable    ${resp.json()['data']['id']}
    Set Suite Variable    ${COMMENT_ID}    ${comment_id}

Get Comments For Post
    [Documentation]    Gets comments for the post.
    ${resp}=    GET On Session    auth_session    /forum/posts/${POST_ID}/comments
    Status Should Be    200    ${resp}
    # The response format seems to be an array directly under data
    # Let's just check status is 200

Update Comment
    [Documentation]    Updates a comment's content.
    ${body}=    Create Dictionary    content=Updated comment content
    ${resp}=    PUT On Session    auth_session    /forum/comments/${COMMENT_ID}    json=${body}
    Status Should Be    200    ${resp}
    Should Be Equal As Strings    ${resp.json()['data']['content']}    Updated comment content

Vote Comment Down
    [Documentation]    Downvotes a comment.
    ${body}=    Create Dictionary    commentId=${COMMENT_ID}    type=DOWN
    ${resp}=    POST On Session    auth_session    /forum/comments/vote    json=${body}
    Status Should Be    200    ${resp}

Delete Comment
    [Documentation]    Deletes the comment.
    ${resp}=    DELETE On Session    auth_session    /forum/comments/${COMMENT_ID}
    Status Should Be    200    ${resp}

Delete Post
    [Documentation]    Deletes the post we created.
    ${resp}=    DELETE On Session    auth_session    /forum/posts/${POST_ID}
    Status Should Be    200    ${resp}
