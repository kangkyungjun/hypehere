/**
 * Explore Page - Search Functionality
 * Handles post search with debouncing and result rendering
 */

class ExploreManager {
    constructor() {
        this.searchInput = document.getElementById('search-input');
        this.clearBtn = document.getElementById('clear-search');
        this.resultsContainer = document.getElementById('results-container');
        this.emptyStateInitial = document.getElementById('empty-state-initial');
        this.emptyStateNoResults = document.getElementById('empty-state-no-results');
        this.loadingState = document.getElementById('loading-state');

        // New elements for user section
        this.usersSection = document.getElementById('users-section');
        this.usersContainer = document.getElementById('users-container');
        this.postsSection = document.getElementById('posts-section');

        this.debounceTimer = null;
        this.currentQuery = '';
        this.isAuthenticated = false;  // Track authentication state

        this.init();
    }

    init() {
        this.checkAuthentication();  // Check if user is logged in
        this.setupEventListeners();

        // Check for search query in URL parameters
        const urlParams = new URLSearchParams(window.location.search);
        const query = urlParams.get('q');

        if (query) {
            // Auto-fill search input and execute search
            this.searchInput.value = query;
            this.clearBtn.classList.remove('hidden');
            this.handleSearch(query);
        } else {
            this.searchInput.focus();
        }
    }

    async checkAuthentication() {
        try {
            const response = await fetch('/api/accounts/profile/', {
                credentials: 'same-origin'
            });
            this.isAuthenticated = response.ok;
        } catch (error) {
            console.error('Auth check error:', error);
            this.isAuthenticated = false;
        }
    }

    setupEventListeners() {
        // Search input with debounce
        this.searchInput.addEventListener('input', (e) => {
            const query = e.target.value.trim();

            // Show/hide clear button
            if (query) {
                this.clearBtn.classList.remove('hidden');
            } else {
                this.clearBtn.classList.add('hidden');
            }

            // Debounce search
            clearTimeout(this.debounceTimer);
            this.debounceTimer = setTimeout(() => {
                this.handleSearch(query);
            }, 300);
        });

        // Clear button
        this.clearBtn.addEventListener('click', () => {
            this.searchInput.value = '';
            this.clearBtn.classList.add('hidden');
            this.showInitialState();
            this.searchInput.focus();
        });

        // Enter key
        this.searchInput.addEventListener('keydown', (e) => {
            if (e.key === 'Enter') {
                const query = this.searchInput.value.trim();
                this.handleSearch(query);
            }
        });
    }

    async handleSearch(query) {
        this.currentQuery = query;

        // Empty query - show initial state
        if (!query) {
            this.showInitialState();
            return;
        }

        // Show loading
        this.showLoading();

        try {
            // Use the new combined search API
            const response = await fetch(`/api/accounts/search/combined/?q=${encodeURIComponent(query)}`);

            if (!response.ok) {
                throw new Error('Search failed');
            }

            const data = await response.json();

            // Check if query changed during request
            if (this.currentQuery !== query) {
                return;
            }

            // Handle combined results
            const hasUsers = data.users && data.users.length > 0;
            const hasPosts = data.posts && data.posts.length > 0;

            if (hasUsers || hasPosts) {
                this.renderCombinedResults(data.users || [], data.posts || []);
            } else {
                this.showNoResults();
            }

        } catch (error) {
            console.error('Search error:', error);
            this.showNoResults();
        }
    }

    showInitialState() {
        this.hideAllStates();
        this.emptyStateInitial.classList.remove('hidden');
    }

    showLoading() {
        this.hideAllStates();
        this.loadingState.classList.remove('hidden');
    }

    showNoResults() {
        this.hideAllStates();
        this.emptyStateNoResults.classList.remove('hidden');
    }

    hideAllStates() {
        this.emptyStateInitial.classList.add('hidden');
        this.emptyStateNoResults.classList.add('hidden');
        this.loadingState.classList.add('hidden');
        this.resultsContainer.classList.add('hidden');
        this.usersSection.classList.add('hidden');
        this.postsSection.classList.add('hidden');
    }

    renderCombinedResults(users, posts) {
        this.hideAllStates();

        // Render users section if there are users
        if (users.length > 0) {
            this.usersSection.classList.remove('hidden');
            const usersHTML = users.map(user => this.createUserHTML(user)).join('');
            this.usersContainer.innerHTML = usersHTML;

            // Load follow statuses for all users if authenticated
            if (this.isAuthenticated) {
                this.loadFollowStatuses(users);
            }
        }

        // Render posts section if there are posts
        if (posts.length > 0) {
            this.postsSection.classList.remove('hidden');
            this.renderResults(posts);
        }
    }

    async loadFollowStatuses(users) {
        // Load follow status for each user
        for (const user of users) {
            try {
                const response = await fetch(`/api/accounts/${user.username}/follow-status/`, {
                    credentials: 'same-origin'
                });

                if (response.ok) {
                    const data = await response.json();
                    // Update button state for this user
                    const button = document.querySelector(`.user-card[data-username="${user.username}"] .follow-btn`);
                    if (button && data.is_following) {
                        button.textContent = window.APP_I18N.following;
                        button.classList.remove('btn-primary');
                        button.classList.add('btn-ghost');
                    }
                }
            } catch (error) {
                console.error(`Failed to load follow status for ${user.username}:`, error);
            }
        }
    }

    createUserHTML(user) {
        // Default avatar if no profile picture
        const avatarSrc = user.profile_picture || 'data:image/svg+xml,' + encodeURIComponent(`
            <svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
                <circle cx="50" cy="35" r="20" fill="#4F46E5"/>
                <path d="M15 85 Q15 55 50 55 Q85 55 85 85 Z" fill="#4F46E5"/>
            </svg>
        `);

        // Truncate bio to 10 characters if longer
        const bioText = user.bio ? (user.bio.length > 10 ? user.bio.substring(0, 10) + '...' : user.bio) : '';

        return `
            <div class="user-card" data-user-id="${user.id}" data-username="${user.username}">
                <div class="user-clickable-area" onclick="window.location.href='/accounts/profile/${user.username}/'">
                    <img class="user-avatar" src="${avatarSrc}" alt="${user.nickname}">
                    <div class="user-info">
                        <div class="user-nickname">${this.escapeHtml(user.nickname || user.display_name)}</div>
                        ${bioText ? `<div class="user-bio">${this.escapeHtml(bioText)}</div>` : ''}
                        <div class="user-stats">
                            <span class="stat-item">
                                <span class="stat-value">${user.posts_count || 0}</span>
                                <span class="stat-label">${window.APP_I18N.posts}</span>
                            </span>
                            <span class="stat-item">
                                <span class="stat-value follower-count">${user.follower_count || 0}</span>
                                <span class="stat-label">${window.APP_I18N.followers}</span>
                            </span>
                            <span class="stat-item">
                                <span class="stat-value">${user.following_count || 0}</span>
                                <span class="stat-label">${window.APP_I18N.following}</span>
                            </span>
                        </div>
                    </div>
                </div>
                <div class="user-actions">
                    ${this.isAuthenticated ? `
                        <button class="btn btn-sm btn-primary follow-btn"
                                data-user-id="${user.id}"
                                data-username="${user.username}"
                                onclick="event.stopPropagation(); toggleFollow('${user.username}', this)">
                            ${window.APP_I18N.follow}
                        </button>
                        <button class="btn btn-sm btn-ghost" onclick="event.stopPropagation(); messageUser(${user.id})">
                            ${window.APP_I18N.message}
                        </button>
                    ` : `
                        <button class="btn btn-sm btn-ghost"
                                onclick="event.stopPropagation(); window.location.href='/accounts/login/'">
                            ${window.APP_I18N.login}
                        </button>
                    `}
                </div>
            </div>
        `;
    }

    renderResults(posts) {
        // Don't hide all states here since this can be called from renderCombinedResults
        this.resultsContainer.style.display = 'grid';

        const postsHTML = posts.map((post, index) => this.createPostHTML(post, index)).join('');
        this.resultsContainer.innerHTML = postsHTML;

        // Update modal viewer's posts array for navigation
        if (window.postModalViewer) {
            console.log('[Explore] PostModalViewer에 posts 설정:', posts);
            window.postModalViewer.posts = posts;

            // 총 포스트 수 업데이트
            const totalCountEl = document.getElementById('total-posts-count');
            if (totalCountEl) {
                totalCountEl.textContent = posts.length;
                console.log('[Explore] total-posts-count 업데이트:', posts.length);
            }
        } else {
            console.error('[Explore] PostModalViewer가 초기화되지 않음!');
        }
    }

    createPostHTML(post, index) {
        // Handle deleted posts
        let content = post.content;
        if (post.is_deleted_by_admin) {
            // Translate deleted post message if needed
            if (content === '게시물은 관리자에 의해 삭제되었습니다.') {
                content = window.APP_I18N.deletedByAdminMessage || content;
            }
        } else if (content === '게시물은 신고에 의해 삭제되었습니다.') {
            // Legacy: translate old deletion message
            content = window.APP_I18N.deletedPostMessage || content;
        }

        // Format content (limit for grid preview)
        let contentPreview = content || '';
        if (contentPreview.length > 100) {
            contentPreview = contentPreview.substring(0, 100) + '...';
        }
        const formattedContent = this.escapeHtml(contentPreview);

        return `
            <div class="search-result-card" data-post-id="${post.id}" onclick="console.log('클릭됨: postId=${post.id}, index=${index}'); openPostModal(${post.id}, ${index})">
                <!-- Post Content Preview -->
                <div class="post-preview">
                    <p class="post-preview-text">${formattedContent}</p>
                </div>

                <!-- Hover Overlay with Stats -->
                <div class="post-overlay">
                    <span class="stat">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="white" stroke="white" stroke-width="2">
                            <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/>
                        </svg>
                        ${post.like_count || 0}
                    </span>
                    <span class="stat">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="white" stroke="white" stroke-width="2">
                            <path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"/>
                        </svg>
                        ${post.comment_count || 0}
                    </span>
                </div>
            </div>
        `;
    }

    formatRelativeTime(timestamp) {
        const now = new Date();
        const past = new Date(timestamp);
        const diffSec = Math.floor((now - past) / 1000);
        const diffMin = Math.floor(diffSec / 60);
        const diffHour = Math.floor(diffMin / 60);
        const diffDay = Math.floor(diffHour / 24);

        if (diffSec < 60) return '방금 전';
        if (diffMin < 60) return `${diffMin}분 전`;
        if (diffHour < 24) return `${diffHour}시간 전`;
        if (diffDay < 7) return `${diffDay}일 전`;
        return past.toLocaleDateString('ko-KR');
    }

    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
}

// Follow/Unfollow functionality moved to follow.js
// Functions available globally: toggleFollow(), messageUser()

// Initialize on DOMContentLoaded
document.addEventListener('DOMContentLoaded', () => {
    new ExploreManager();
});
