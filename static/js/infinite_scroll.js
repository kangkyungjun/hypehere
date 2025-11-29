/**
 * Infinite Scroll for Profile Posts Feed
 * Loads more posts as user scrolls down
 */

(function() {
    // State management
    let currentPage = 1;
    let isLoading = false;
    let hasMore = true;
    let username = '';

    // DOM elements
    const postsContainer = document.getElementById('posts-container');
    const loadingIndicator = document.getElementById('loading-indicator');
    const noMorePosts = document.getElementById('no-more-posts');

    // Initialize on DOMContentLoaded
    document.addEventListener('DOMContentLoaded', function() {
        // Get username from URL path
        const pathParts = window.location.pathname.split('/');
        const profileIndex = pathParts.indexOf('profile');
        if (profileIndex !== -1 && pathParts[profileIndex + 1]) {
            username = pathParts[profileIndex + 1];
        }

        // Check if there are more posts to load
        const postsSection = document.querySelector('.posts-feed-section');
        if (postsSection && postsSection.dataset.hasMore === 'True') {
            hasMore = true;
            setupInfiniteScroll();
        } else {
            hasMore = false;
        }
    });

    /**
     * Setup infinite scroll event listener
     */
    function setupInfiniteScroll() {
        window.addEventListener('scroll', handleScroll);
    }

    /**
     * Handle scroll event
     */
    function handleScroll() {
        if (!isNearBottom() || isLoading || !hasMore) {
            return;
        }

        loadMorePosts();
    }

    /**
     * Check if user is near bottom of page
     */
    function isNearBottom() {
        const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
        const windowHeight = window.innerHeight;
        const documentHeight = document.documentElement.scrollHeight;

        // Trigger when 200px from bottom
        return (scrollTop + windowHeight) >= (documentHeight - 200);
    }

    /**
     * Load more posts via AJAX
     */
    async function loadMorePosts() {
        if (!username) return;

        isLoading = true;
        showLoading();

        currentPage++;

        try {
            const response = await fetch(`/api/accounts/${username}/posts/?page=${currentPage}`);

            if (!response.ok) {
                throw new Error('Failed to load posts');
            }

            const data = await response.json();

            // Append posts to container
            if (data.results && data.results.length > 0) {
                appendPosts(data.results);
            }

            // Check if there are more posts
            hasMore = data.next !== null;

            if (!hasMore) {
                showNoMorePosts();
            }

        } catch (error) {
            console.error('Error loading posts:', error);
            currentPage--; // Revert page increment on error
        } finally {
            hideLoading();
            isLoading = false;
        }
    }

    /**
     * Append posts to DOM
     */
    function appendPosts(posts) {
        posts.forEach(post => {
            const postHTML = createPostHTML(post);
            postsContainer.insertAdjacentHTML('beforeend', postHTML);
        });

        // Update timestamps
        if (typeof updateAllTimestamps === 'function') {
            updateAllTimestamps();
        }
    }

    /**
     * Create HTML for a single post
     */
    function createPostHTML(post) {
        // Avatar
        let avatarHTML = '';
        if (post.author.profile_picture) {
            avatarHTML = `<img src="${post.author.profile_picture}" alt="${post.author.nickname}">`;
        } else {
            avatarHTML = `
                <svg viewBox="0 0 100 100" fill="currentColor" style="color: var(--color-secondary);">
                    <circle cx="50" cy="35" r="20"/>
                    <path d="M15 85 Q15 55 50 55 Q85 55 85 85 Z"/>
                </svg>
            `;
        }

        // Language display
        let languageHTML = '';
        if (post.native_language && post.target_language) {
            const nativeLang = post.native_language.substring(0, 2);
            const targetLang = post.target_language.substring(0, 2);
            languageHTML = `<span>${nativeLang} → ${targetLang}</span><span>•</span>`;
        }

        // Hashtags
        let hashtagsHTML = '';
        if (post.hashtags && post.hashtags.length > 0) {
            const hashtagBadges = post.hashtags.map(tag =>
                `<span class="badge badge-primary">#${tag.name}</span>`
            ).join('');
            hashtagsHTML = `
                <div class="flex gap-xs mt-sm">
                    ${hashtagBadges}
                </div>
            `;
        }

        // Translate deleted post message if needed
        let content = post.content;
        if (content === '게시물은 신고에 의해 삭제되었습니다.') {
            content = window.APP_I18N.deletedPostMessage || content;
        }

        // Format content (convert newlines to <br>)
        const formattedContent = content.replace(/\n/g, '<br>');

        return `
            <div class="post-card mb-md" style="border: 1px solid var(--color-border); border-radius: var(--radius-lg); padding: var(--space-md);">
                <div class="post-header">
                    <div class="avatar">
                        ${avatarHTML}
                    </div>
                    <div class="post-author-info">
                        <a href="/accounts/profile/${post.author.username}/" class="post-author-name">${post.author.nickname}</a>
                        <div class="post-meta">
                            ${languageHTML}
                            <span class="post-time" data-timestamp="${post.created_at}">${formatRelativeTime(post.created_at)}</span>
                        </div>
                    </div>
                </div>

                <div class="post-content">
                    <p>${formattedContent}</p>
                    ${hashtagsHTML}
                </div>

                <div class="post-actions">
                    <button class="post-action-btn">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/>
                        </svg>
                        <span>좋아요</span>
                    </button>
                    <button class="post-action-btn">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"/>
                        </svg>
                        <span>댓글</span>
                    </button>
                    <button class="post-action-btn">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <circle cx="18" cy="5" r="3"/>
                            <circle cx="6" cy="12" r="3"/>
                            <circle cx="18" cy="19" r="3"/>
                            <line x1="8.59" y1="13.51" x2="15.42" y2="17.49"/>
                            <line x1="15.41" y1="6.51" x2="8.59" y2="10.49"/>
                        </svg>
                        <span>공유</span>
                    </button>
                </div>
            </div>
        `;
    }

    /**
     * Format timestamp to relative time (fallback if utils.js not loaded)
     */
    function formatRelativeTime(timestamp) {
        if (typeof window.formatRelativeTime === 'function') {
            return window.formatRelativeTime(timestamp);
        }

        // Simple fallback
        const now = new Date();
        const past = new Date(timestamp);
        const diffSec = Math.floor((now - past) / 1000);
        const diffMin = Math.floor(diffSec / 60);
        const diffHour = Math.floor(diffMin / 60);
        const diffDay = Math.floor(diffHour / 24);

        if (diffSec < 60) return '방금 전';
        if (diffMin < 60) return `${diffMin}분 전`;
        if (diffHour < 24) return `${diffHour}시간 전`;
        return `${diffDay}일 전`;
    }

    /**
     * Show loading indicator
     */
    function showLoading() {
        if (loadingIndicator) {
            loadingIndicator.classList.remove('hidden');
        }
    }

    /**
     * Hide loading indicator
     */
    function hideLoading() {
        if (loadingIndicator) {
            loadingIndicator.classList.add('hidden');
        }
    }

    /**
     * Show no more posts message
     */
    function showNoMorePosts() {
        if (noMorePosts) {
            noMorePosts.classList.remove('hidden');
        }
    }
})();
