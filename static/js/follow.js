/**
 * Follow/Unfollow Functionality
 * Shared across all pages (explore, profile, home feed, etc.)
 * Requires: getCookie() from utils.js
 */

// Follow/Unfollow functionality
async function toggleFollow(username, buttonElement) {
    if (window.DEBUG) {
        console.log('[Follow] Toggle started for:', username);
        console.log('[Follow] Button element:', buttonElement);
        console.log('[Follow] Button classes:', buttonElement.classList.toString());
    }

    // Prevent multiple clicks
    if (buttonElement.disabled) {
        if (window.DEBUG) console.log('[Follow] Button is disabled, returning');
        return;
    }

    const isFollowing = buttonElement.classList.contains('btn-ghost');
    const url = isFollowing
        ? `/api/accounts/${username}/unfollow/`
        : `/api/accounts/${username}/follow/`;
    const method = isFollowing ? 'DELETE' : 'POST';

    if (window.DEBUG) {
        console.log('[Follow] isFollowing:', isFollowing);
        console.log('[Follow] URL:', url);
        console.log('[Follow] Method:', method);
        console.log('[Follow] CSRF Token:', getCookie('csrftoken'));
    }

    // Save original text and disable button
    const originalText = buttonElement.textContent;
    buttonElement.disabled = true;
    buttonElement.textContent = window.APP_I18N?.processing || '처리 중...';

    try {
        const response = await fetch(url, {
            method: method,
            headers: {
                'X-CSRFToken': getCookie('csrftoken'),
                'Content-Type': 'application/json'
            },
            credentials: 'same-origin'
        });

        if (window.DEBUG) {
            console.log('[Follow] Response status:', response.status);
            console.log('[Follow] Response ok:', response.ok);
        }

        const data = await response.json();

        if (response.ok) {
            // Update button state
            if (data.is_following && data.is_follower) {
                // Mutual follow
                buttonElement.textContent = window.APP_I18N?.mutualFollow || '맞팔로우';
                buttonElement.classList.remove('btn-primary');
                buttonElement.classList.add('btn-ghost');
            } else if (data.is_following) {
                // You follow them
                buttonElement.textContent = window.APP_I18N?.following || '팔로잉';
                buttonElement.classList.remove('btn-primary');
                buttonElement.classList.add('btn-ghost');
            } else {
                // You don't follow them
                buttonElement.textContent = window.APP_I18N?.follow || '팔로우';
                buttonElement.classList.remove('btn-ghost');
                buttonElement.classList.add('btn-primary');
            }

            // Update follower count in user cards (explore page)
            const userCard = buttonElement.closest('.user-card');
            const followerCountEl = userCard ? userCard.querySelector('.follower-count') : null;
            if (followerCountEl) {
                followerCountEl.textContent = data.follower_count;
            }

            // Update follower count on profile page
            const profileFollowerCount = document.getElementById('profile-follower-count');
            if (profileFollowerCount) {
                profileFollowerCount.textContent = data.follower_count;
            }
        } else {
            // Restore original text on error
            buttonElement.textContent = originalText;

            if (window.DEBUG) console.log('[Follow] Error response data:', data);
            if (response.status === 401) {
                console.error('[Follow] Authentication required');
                alert(window.APP_I18N?.loginRequired || '로그인이 필요합니다.');
                window.location.href = '/accounts/login/';
            } else if (response.status === 403) {
                console.error('[Follow] CSRF verification failed');
                alert(window.APP_I18N?.csrfError || 'CSRF 토큰 오류. 페이지를 새로고침해주세요.');
            } else if (response.status === 404) {
                console.error('[Follow] User not found or API endpoint not found');
                alert(window.APP_I18N?.userNotFound || '사용자를 찾을 수 없거나 API 오류가 발생했습니다.');
            } else {
                console.error('[Follow] Unknown error:', data);
                alert(data.error || window.APP_I18N?.error || '오류가 발생했습니다.');
            }
        }
    } catch (error) {
        console.error('[Follow] Network/JS error:', error);
        if (window.DEBUG) console.error('[Follow] Error stack:', error.stack);
        // Restore original text on error
        buttonElement.textContent = originalText;
        const errorMsg = window.APP_I18N?.networkError || '네트워크 오류가 발생했습니다';
        alert(errorMsg + ': ' + error.message);
    } finally {
        // Re-enable button
        buttonElement.disabled = false;
    }
}

async function messageUser(userId) {
    if (window.DEBUG) console.log('[Follow] Creating conversation with user:', userId);

    try {
        // Create or get conversation with this user
        const response = await fetch('/api/chat/conversations/', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRFToken': getCookie('csrftoken')
            },
            credentials: 'same-origin',
            body: JSON.stringify({ user_id: userId })
        });

        if (!response.ok) {
            throw new Error('Failed to create conversation');
        }

        const conversation = await response.json();

        // Navigate to conversation detail page
        window.location.href = `/messages/${conversation.id}/`;
    } catch (error) {
        console.error('[Follow] Error creating conversation:', error);
        alert(window.APP_I18N?.conversationCreateFailed || '대화를 시작할 수 없습니다.');
    }
}

// Expose functions to global window scope
window.toggleFollow = toggleFollow;
window.messageUser = messageUser;
