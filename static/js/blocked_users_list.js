/**
 * 차단 목록 관리 클래스
 */
class BlockedUsersListManager {
    constructor() {
        this.users = [];
        this.isLoading = false;

        // DOM 요소
        this.loadingState = document.getElementById('loading-state');
        this.emptyState = document.getElementById('empty-state');
        this.usersSection = document.getElementById('users-section');
        this.usersContainer = document.getElementById('users-container');

        this.init();
    }

    /**
     * 초기화
     */
    async init() {
        await this.loadUsers();
    }

    /**
     * 차단한 사용자 목록 불러오기
     */
    async loadUsers() {
        if (this.isLoading) return;

        this.isLoading = true;
        this.showLoading();

        try {
            const response = await fetch('/api/accounts/blocked-users/', {
                credentials: 'same-origin'
            });

            if (!response.ok) {
                throw new Error('Failed to load blocked users');
            }

            const data = await response.json();
            this.users = data.results || data || [];

            this.hideLoading();

            if (this.users.length === 0) {
                this.showEmptyState();
            } else {
                this.renderUsers();
            }
        } catch (error) {
            console.error('Error loading blocked users:', error);
            this.hideLoading();
            this.showEmptyState();
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * 사용자 목록 렌더링
     */
    renderUsers() {
        this.usersContainer.innerHTML = '';

        this.users.forEach(user => {
            const userCard = this.createUserCard(user);
            this.usersContainer.appendChild(userCard);
        });

        this.usersSection.classList.remove('hidden');
        this.emptyState.classList.add('hidden');
    }

    /**
     * 사용자 카드 생성
     */
    createUserCard(user) {
        const card = document.createElement('div');
        card.className = 'user-card';
        card.dataset.username = user.username;

        card.innerHTML = `
            <div class="user-clickable-area">
                <img class="user-avatar"
                     src="${user.profile_picture || '/static/images/default-avatar.png'}"
                     alt="${this.escapeHtml(user.nickname)}"
                     onerror="this.src='/static/images/default-avatar.png'">
                <div class="user-info">
                    <div class="user-nickname">${this.escapeHtml(user.nickname)}</div>
                    <div class="user-username">@${this.escapeHtml(user.username)}</div>
                    ${user.bio ? `<div class="user-bio">${this.escapeHtml(user.bio)}</div>` : ''}
                </div>
            </div>
            <div class="user-actions">
                <button class="btn btn-secondary btn-unblock" data-username="${user.username}">
                    ${window.APP_I18N?.unblock || '차단 해제'}
                </button>
            </div>
        `;

        // 차단 해제 버튼 이벤트
        const unblockBtn = card.querySelector('.btn-unblock');
        unblockBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            this.handleUnblock(user.username);
        });

        // 프로필 클릭 이벤트 (클릭 가능 영역만)
        const clickableArea = card.querySelector('.user-clickable-area');
        clickableArea.addEventListener('click', () => {
            window.location.href = `/accounts/profile/${user.username}/`;
        });

        return card;
    }

    /**
     * 차단 해제 처리
     */
    async handleUnblock(username) {
        const card = this.usersContainer.querySelector(`[data-username="${username}"]`);
        const unblockBtn = card.querySelector('.btn-unblock');

        if (unblockBtn.disabled) return;

        const originalText = unblockBtn.textContent;
        unblockBtn.disabled = true;
        unblockBtn.textContent = window.APP_I18N?.processing || '처리 중...';

        try {
            const response = await fetch(`/api/accounts/${username}/unblock/`, {
                method: 'DELETE',
                headers: {
                    'X-CSRFToken': this.getCookie('csrftoken')
                },
                credentials: 'same-origin'
            });

            if (!response.ok) {
                throw new Error('Failed to unblock user');
            }

            // 목록에서 제거
            this.users = this.users.filter(u => u.username !== username);
            card.remove();

            // 목록이 비어있으면 empty state 표시
            if (this.users.length === 0) {
                this.showEmptyState();
            }

        } catch (error) {
            console.error('Error unblocking user:', error);
            alert(window.APP_I18N?.unblockFailed || '차단 해제에 실패했습니다.');
            unblockBtn.disabled = false;
            unblockBtn.textContent = originalText;
        }
    }

    /**
     * 로딩 상태 표시
     */
    showLoading() {
        this.loadingState.classList.remove('hidden');
        this.emptyState.classList.add('hidden');
        this.usersSection.classList.add('hidden');
    }

    /**
     * 로딩 상태 숨김
     */
    hideLoading() {
        this.loadingState.classList.add('hidden');
    }

    /**
     * 빈 상태 표시
     */
    showEmptyState() {
        this.emptyState.classList.remove('hidden');
        this.usersSection.classList.add('hidden');
    }

    /**
     * HTML 이스케이프
     */
    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    /**
     * CSRF 토큰 가져오기
     */
    getCookie(name) {
        const match = document.cookie.match(new RegExp('(^| )' + name + '=([^;]+)'));
        return match ? match[2] : null;
    }
}
