/**
 * Followers/Following List Manager
 * Handles loading and displaying followers/following lists with follow actions
 */

class FollowersListManager {
    constructor(username, pageType) {
        this.username = username;
        this.pageType = pageType; // 'followers' or 'following'
        this.loadingState = document.getElementById('loading-state');
        this.emptyState = document.getElementById('empty-state');
        this.usersSection = document.getElementById('users-section');
        this.usersContainer = document.getElementById('users-container');
        this.isAuthenticated = document.body.hasAttribute('data-user-id');

        this.init();
    }

    async init() {
        await this.loadUsers();
    }

    /**
     * Load followers or following based on page type
     */
    async loadUsers() {
        try {
            this.showLoading();

            const endpoint = `/api/accounts/${this.username}/${this.pageType}/`;
            const response = await fetch(endpoint);

            if (!response.ok) {
                throw new Error(`Failed to load ${this.pageType}`);
            }

            const data = await response.json();
            const users = data.results || data;

            if (users.length === 0) {
                this.showEmptyState();
            } else {
                await this.renderUsers(users);
            }

        } catch (error) {
            console.error(`Error loading ${this.pageType}:`, error);
            this.showError();
        }
    }

    /**
     * Render user cards
     */
    async renderUsers(users) {
        this.hideAllStates();
        this.usersSection.classList.remove('hidden');

        // Render user cards
        const usersHTML = users.map(user => this.createUserHTML(user)).join('');
        this.usersContainer.innerHTML = usersHTML;

        // Load follow statuses if user is authenticated
        if (this.isAuthenticated) {
            await this.loadFollowStatuses(users);
        }
    }

    /**
     * Create HTML for a single user card (similar to explore.js)
     */
    createUserHTML(user) {
        const avatarSrc = user.profile_picture || 'data:image/svg+xml,' + encodeURIComponent(`
            <svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
                <circle cx="50" cy="35" r="20" fill="#4F46E5"/>
                <path d="M15 85 Q15 55 50 55 Q85 55 85 85 Z" fill="#4F46E5"/>
            </svg>
        `);

        const bioText = user.bio ? (user.bio.length > 100 ? user.bio.substring(0, 100) + '...' : user.bio) : '';

        const currentUserId = document.body.getAttribute('data-user-id');
        const isOwnProfile = currentUserId && parseInt(currentUserId) === user.id;

        return `
            <div class="user-card" data-user-id="${user.id}" data-username="${user.username}">
                <div class="user-clickable-area" onclick="window.location.href='/accounts/profile/${user.username}/'">
                    <img class="user-avatar" src="${avatarSrc}" alt="${user.nickname}">
                    <div class="user-info">
                        <div class="user-nickname">${this.escapeHtml(user.nickname || user.display_name || user.username)}</div>
                        ${bioText ? `<div class="user-bio">${this.escapeHtml(bioText)}</div>` : ''}
                        <div class="user-stats">
                            <span class="stat-item">
                                <span class="stat-value">${user.posts_count || 0}</span>
                                <span class="stat-label">게시물</span>
                            </span>
                            <span class="stat-item">
                                <span class="stat-value follower-count">${user.follower_count || 0}</span>
                                <span class="stat-label">팔로워</span>
                            </span>
                            <span class="stat-item">
                                <span class="stat-value">${user.following_count || 0}</span>
                                <span class="stat-label">팔로잉</span>
                            </span>
                        </div>
                    </div>
                </div>
                <div class="user-actions">
                    ${this.isAuthenticated && !isOwnProfile ? `
                        <button class="btn btn-sm btn-primary follow-btn"
                                data-user-id="${user.id}"
                                data-username="${user.username}"
                                onclick="event.stopPropagation(); toggleFollow('${user.username}', this)">
                            팔로우
                        </button>
                        <button class="btn btn-sm btn-ghost" onclick="event.stopPropagation(); messageUser(${user.id})">
                            메시지
                        </button>
                    ` : isOwnProfile ? `
                        <button class="btn btn-sm btn-ghost" disabled>
                            나
                        </button>
                    ` : `
                        <button class="btn btn-sm btn-ghost"
                                onclick="event.stopPropagation(); window.location.href='/accounts/login/'">
                            로그인
                        </button>
                    `}
                </div>
            </div>
        `;
    }

    /**
     * Load follow statuses for all displayed users
     */
    async loadFollowStatuses(users) {
        try {
            const currentUserId = document.body.getAttribute('data-user-id');

            for (const user of users) {
                // Skip own profile
                if (currentUserId && parseInt(currentUserId) === user.id) {
                    continue;
                }

                const response = await fetch(`/api/accounts/${user.username}/follow-status/`);
                if (response.ok) {
                    const data = await response.json();
                    this.updateFollowButton(user.username, data.is_following, data.is_follower);
                }
            }
        } catch (error) {
            console.error('Error loading follow statuses:', error);
        }
    }

    /**
     * Update follow button state
     */
    updateFollowButton(username, isFollowing, isFollower = false) {
        const button = this.usersContainer.querySelector(`button[data-username="${username}"]`);
        if (button) {
            if (isFollowing && isFollower) {
                // Mutual follow
                button.textContent = '맞팔로우';
                button.classList.remove('btn-primary');
                button.classList.add('btn-ghost');
            } else if (isFollowing) {
                // You follow them
                button.textContent = '팔로잉';
                button.classList.remove('btn-primary');
                button.classList.add('btn-ghost');
            } else {
                // You don't follow them
                button.textContent = '팔로우';
                button.classList.remove('btn-ghost');
                button.classList.add('btn-primary');
            }
        }
    }

    /**
     * State management
     */
    showLoading() {
        this.hideAllStates();
        this.loadingState.classList.remove('hidden');
    }

    showEmptyState() {
        this.hideAllStates();
        this.emptyState.classList.remove('hidden');
    }

    showError() {
        this.hideAllStates();
        this.emptyState.querySelector('h3').textContent = '오류 발생';
        this.emptyState.querySelector('p').textContent = '데이터를 불러오는 중 오류가 발생했습니다';
        this.emptyState.classList.remove('hidden');
    }

    hideAllStates() {
        this.loadingState.classList.add('hidden');
        this.emptyState.classList.add('hidden');
        this.usersSection.classList.add('hidden');
    }

    /**
     * Escape HTML to prevent XSS
     */
    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
}
