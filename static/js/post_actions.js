/**
 * Post Actions - Dropdown Menu Handler
 * Handles block and report actions for posts
 */

/**
 * Get localized text for post actions
 * @param {string} key - The text key to translate
 * @returns {string} Localized text
 */
function getPostActionText(key) {
    const htmlLang = document.documentElement.lang;
    let lang = 'ko';
    if (htmlLang && htmlLang !== '') {
        const langLower = htmlLang.toLowerCase();
        if (['en', 'ja', 'es', 'ko'].includes(langLower)) {
            lang = langLower;
        }
    }

    const texts = {
        reported: {
            'ko': '신고됨',
            'en': 'Reported',
            'ja': '報告済み',
            'es': 'Reportado'
        },
        reportedBadge: {
            'ko': '신고됨',
            'en': 'Reported',
            'ja': '報告済み',
            'es': 'Reportado'
        },
        selectReportType: {
            'ko': '신고 유형을 선택해주세요.',
            'en': 'Please select a report type.',
            'ja': '報告タイプを選択してください。',
            'es': 'Por favor seleccione un tipo de reporte.'
        },
        cannotFindUser: {
            'ko': '신고할 사용자를 찾을 수 없습니다.',
            'en': 'Cannot find user to report.',
            'ja': '報告するユーザーが見つかりません。',
            'es': 'No se puede encontrar el usuario para reportar.'
        },
        networkError: {
            'ko': '네트워크 오류가 발생했습니다. 다시 시도해주세요.',
            'en': 'Network error occurred. Please try again.',
            'ja': 'ネットワークエラーが発生しました。もう一度お試しください。',
            'es': 'Ocurrió un error de red. Por favor, inténtelo de nuevo.'
        }
    };

    return texts[key] && texts[key][lang] ? texts[key][lang] : texts[key]['en'];
}

class PostActionsManager {
    constructor() {
        this.modal = document.getElementById('post-action-modal');
        this.closeBtn = document.getElementById('close-action-modal');
        this.reportModal = document.getElementById('post-report-modal');
        this.deleteModal = document.getElementById('post-delete-modal');
        this.confirmDeleteBtn = document.getElementById('confirm-delete-btn');
        this.cancelDeleteBtn = document.getElementById('cancel-delete-btn');
        this.currentPostId = null;
        this.currentAuthorUsername = null;
        this.currentNickname = null;
        this.deleteCallback = null;
        this.canEdit = false;  // Permission to edit (author or admin)
        this.canDelete = false;  // Permission to delete (author or admin)

        // Leave conversation modal elements
        this.leaveConversationModal = document.getElementById('leave-conversation-modal');
        this.confirmLeaveConversationBtn = document.getElementById('confirm-leave-conversation');
        this.cancelLeaveConversationBtn = document.getElementById('cancel-leave-conversation');
        this.closeLeaveConversationBtn = document.getElementById('close-leave-conversation-modal');
        this.currentConversationId = null;

        // Follow status tracking
        this.currentIsFollowing = false;

        // Block user modal elements (support both main page and chat room)
        this.blockUserModal = document.getElementById('block-user-modal') || document.getElementById('block-user-modal-chat');
        this.confirmBlockUserBtn = document.getElementById('confirm-block-user') || document.getElementById('confirm-block-user-chat');
        this.cancelBlockUserBtn = document.getElementById('cancel-block-user') || document.getElementById('cancel-block-user-chat');
        this.closeBlockUserBtn = document.getElementById('close-block-user-modal') || document.getElementById('close-block-user-modal-chat');
        this.blockUserName = document.getElementById('block-user-name') || document.getElementById('block-user-name-chat');
        this.currentBlockUsername = null;
        this.currentReportUserId = null;  // For user reporting in chat rooms

        // Unblock user modal elements
        this.unblockUserModal = document.getElementById('unblock-user-modal');
        this.confirmUnblockUserBtn = document.getElementById('confirm-unblock-user');
        this.cancelUnblockUserBtn = document.getElementById('cancel-unblock-user');
        this.closeUnblockUserBtn = document.getElementById('close-unblock-user-modal');
        this.unblockUserName = document.getElementById('unblock-user-name');
        this.currentUnblockUsername = null;

        // Alert modal elements (for success/error messages)
        this.alertModal = document.getElementById('alert-modal');
        this.alertMessage = document.getElementById('alert-message');
        this.alertIcon = document.getElementById('alert-icon');
        this.alertOkBtn = document.getElementById('alert-ok-btn');
        this.alertCallback = null;

        // Debug: Check if block modal elements are found
        console.log('[PostActions] Block modal elements:', {
            blockUserModal: this.blockUserModal,
            confirmBtn: this.confirmBlockUserBtn,
            cancelBtn: this.cancelBlockUserBtn,
            closeBtn: this.closeBlockUserBtn,
            nameElement: this.blockUserName
        });

        this.init();
    }

    init() {
        if (!this.modal) {
            console.warn('Post action modal not found');
            return;
        }
        this.setupEventListeners();
        this.setupReportModal();
        this.setupDeleteModal();
        this.setupLeaveConversationModal();
        this.setupBlockUserModal();
        this.setupUnblockUserModal();
        this.setupAlertModal();
    }

    setupEventListeners() {
        // Dropdown toggle buttons (event delegation)
        document.addEventListener('click', (e) => {
            const toggleBtn = e.target.closest('.dropdown-toggle');
            if (toggleBtn) {
                e.preventDefault();
                e.stopPropagation();  // Prevent parent card click handlers

                // Profile page actions (user actions)
                if (toggleBtn.classList.contains('profile-actions-toggle')) {
                    this.handleProfileDropdownClick(toggleBtn);
                // Chat page actions (user actions)
                } else if (toggleBtn.classList.contains('chat-actions-toggle')) {
                    this.handleChatDropdownClick(toggleBtn);
                } else {
                    // Post actions (including grid cards)
                    this.handleDropdownClick(toggleBtn);
                }
            }
        });

        // Modal close button
        if (this.closeBtn) {
            this.closeBtn.addEventListener('click', () => this.closeModal());
        }

        // Click outside to close
        if (this.modal) {
            this.modal.addEventListener('click', (e) => {
                if (e.target === this.modal) {
                    this.closeModal();
                }
            });
        }

        // Action buttons (event delegation)
        document.addEventListener('click', (e) => {
            const actionBtn = e.target.closest('.action-item');
            if (actionBtn && !this.modal.classList.contains('hidden')) {
                e.preventDefault();
                const action = actionBtn.dataset.action;
                this.handleAction(action);
            }
        });

        // Escape key to close
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && !this.modal.classList.contains('hidden')) {
                this.closeModal();
            }
        });

        // Leave room button (event delegation)
        document.addEventListener('click', (e) => {
            const leaveBtn = e.target.closest('.leave-room-btn');
            if (leaveBtn) {
                e.preventDefault();
                this.handleLeaveRoom(leaveBtn);
            }
        });
    }

    handleDropdownClick(button) {
        // Get post data
        const postCard = button.closest('.post-card');
        if (!postCard) {
            console.warn('Post card not found');
            return;
        }

        this.currentPostId = postCard.dataset.postId;
        this.currentAuthorUsername = postCard.dataset.authorUsername;  // Direct attribute

        // Check for permission data attributes (set by backend template or API)
        // These should be 'true' or 'false' strings from data attributes
        if (postCard.dataset.canEdit !== undefined) {
            this.canEdit = postCard.dataset.canEdit === 'true';
        } else {
            // Fallback: use ownership check
            this.canEdit = this.isOwnPost();
        }

        if (postCard.dataset.canDelete !== undefined) {
            this.canDelete = postCard.dataset.canDelete === 'true';
        } else {
            // Fallback: use ownership check
            this.canDelete = this.isOwnPost();
        }

        console.log('Opening modal for post:', this.currentPostId, 'by', this.currentAuthorUsername,
                    'canEdit:', this.canEdit, 'canDelete:', this.canDelete);
        this.openModal();
    }

    handleProfileDropdownClick(button) {
        // Get user data from button attributes
        this.currentAuthorUsername = button.dataset.username;
        this.currentNickname = button.dataset.nickname;  // Get nickname for display
        this.currentUserId = button.dataset.userId;
        this.currentIsBlocking = button.dataset.isBlocking === 'true';  // Check blocking status
        this.currentPostId = null;  // No post ID for profile actions

        console.log('Opening modal for user:', this.currentNickname, 'Username:', this.currentAuthorUsername, 'ID:', this.currentUserId, 'Blocking:', this.currentIsBlocking);
        this.openModal();
    }

    handleChatDropdownClick(button) {
        // Get user data from button attributes (chat page)
        this.currentAuthorUsername = button.dataset.username;
        this.currentUserId = button.dataset.userId;
        this.currentPostId = null;  // No post ID for chat actions

        console.log('Opening modal for chat user:', this.currentAuthorUsername, 'ID:', this.currentUserId);
        this.openModal();
    }

    handleLeaveRoom(button) {
        const conversationId = button.dataset.conversationId;

        if (!conversationId) {
            console.warn('No conversation ID found');
            return;
        }

        console.log('Leave room action triggered for conversation:', conversationId);

        // Open modal instead of using confirm()
        this.openLeaveConversationModal(conversationId);
    }

    openLeaveConversationModal(conversationId) {
        this.currentConversationId = conversationId;

        // Show modal
        if (this.leaveConversationModal) {
            this.leaveConversationModal.classList.remove('hidden');
        }
    }

    closeLeaveConversationModal() {
        if (this.leaveConversationModal) {
            this.leaveConversationModal.classList.add('hidden');
        }
        this.currentConversationId = null;
    }

    async confirmLeaveConversation() {
        if (!this.currentConversationId) return;

        try {
            const response = await fetch(`/api/chat/conversations/${this.currentConversationId}/leave/`, {
                method: 'POST',
                headers: {
                    'X-CSRFToken': this.getCsrfToken(),
                    'Content-Type': 'application/json',
                },
                credentials: 'same-origin'
            });

            if (response.ok) {
                const data = await response.json();
                this.closeLeaveConversationModal();
                // Navigate back to messages list
                window.location.href = '/messages/';
            } else {
                const error = await response.json().catch(() => ({ error: '알 수 없는 오류' }));
                alert(`나가기 실패: ${error.error || '서버 오류가 발생했습니다'}`);
            }
        } catch (error) {
            console.error('Leave room error:', error);
            alert('대화방 나가기 중 오류가 발생했습니다.\n\n네트워크 연결을 확인해주세요.');
        }
    }

    isOwnPost() {
        /**
         * Check if the current post/profile belongs to the logged-in user
         * @returns {boolean} True if own post, false otherwise
         */
        return this.currentAuthorUsername === window.CURRENT_USER;
    }

    async fetchFollowStatus(username) {
        /**
         * Fetch follow status for a user
         * @param {string} username - Username to check follow status
         * @returns {boolean} True if following, false otherwise
         */
        try {
            const response = await fetch(`/api/accounts/${username}/follow-status/`, {
                credentials: 'same-origin'
            });
            if (response.ok) {
                const data = await response.json();
                return data.is_following;
            }
        } catch (error) {
            console.error('[PostActions] Follow status fetch error:', error);
        }
        return false;
    }

    getFollowButtonText(isFollowing) {
        /**
         * Get follow button text based on current language
         * @param {boolean} isFollowing - Whether currently following the user
         * @returns {string} Localized button text
         */
        const lang = document.documentElement.lang || 'ko';
        const translations = {
            'ko': {
                follow: '팔로우',
                unfollow: '언팔로우'
            },
            'en': {
                follow: 'Follow',
                unfollow: 'Unfollow'
            },
            'ja': {
                follow: 'フォロー',
                unfollow: 'フォロー解除'
            },
            'es': {
                follow: 'Seguir',
                unfollow: 'Dejar de seguir'
            }
        };

        const langTranslations = translations[lang] || translations['en'];
        return isFollowing ? langTranslations.unfollow : langTranslations.follow;
    }

    updateModalContent() {
        /**
         * Dynamically update modal content based on permissions
         * - Own post: Edit, Delete (author only)
         * - Admin's other post: Edit, Delete, Block, Report (admin viewing others)
         * - Other's post: Block, Report (regular user)
         */
        const actionBody = this.modal.querySelector('.post-action-body');
        if (!actionBody) {
            console.warn('Modal action body not found');
            return;
        }

        const isOwn = this.isOwnPost();
        const isAdmin = (this.canEdit || this.canDelete) && !isOwn;

        let buttons = '';

        // Case 1: Own post - Show Edit/Delete only
        if (isOwn) {
            if (this.canEdit) {
                buttons += `
                    <button class="action-item action-edit" data-action="edit" type="button">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
                            <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
                        </svg>
                        <span>${window.POST_ACTIONS_I18N?.edit || 'Edit'}</span>
                    </button>
                `;
            }

            if (this.canDelete) {
                buttons += `
                    <button class="action-item action-delete" data-action="delete" type="button">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <polyline points="3 6 5 6 21 6"/>
                            <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/>
                            <line x1="10" y1="11" x2="10" y2="17"/>
                            <line x1="14" y1="11" x2="14" y2="17"/>
                        </svg>
                        <span>${window.POST_ACTIONS_I18N?.delete || 'Delete'}</span>
                    </button>
                `;
            }
        }
        // Case 2: Admin viewing other's post - Show Edit/Delete/Follow/Block/Report
        else if (isAdmin) {
            if (this.canEdit) {
                buttons += `
                    <button class="action-item action-edit" data-action="edit" type="button">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
                            <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
                        </svg>
                        <span>${window.POST_ACTIONS_I18N?.edit || 'Edit'}</span>
                    </button>
                `;
            }

            if (this.canDelete) {
                buttons += `
                    <button class="action-item action-delete" data-action="delete" type="button">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <polyline points="3 6 5 6 21 6"/>
                            <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/>
                            <line x1="10" y1="11" x2="10" y2="17"/>
                            <line x1="14" y1="11" x2="14" y2="17"/>
                        </svg>
                        <span>${window.POST_ACTIONS_I18N?.delete || 'Delete'}</span>
                    </button>
                `;
            }

            // Follow button at the top (before Block/Report)
            buttons += `
                <button class="action-item action-follow" data-action="follow" type="button">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
                        <circle cx="8.5" cy="7" r="4"/>
                        <line x1="20" y1="8" x2="20" y2="14"/>
                        <line x1="23" y1="11" x2="17" y2="11"/>
                    </svg>
                    <span>${this.getFollowButtonText(this.currentIsFollowing)}</span>
                </button>
            `;

            buttons += `
                <button class="action-item action-block" data-action="block" type="button">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <circle cx="12" cy="12" r="10"/>
                        <line x1="4.93" y1="4.93" x2="19.07" y2="19.07"/>
                    </svg>
                    <span>${window.POST_ACTIONS_I18N?.block || 'Block'}</span>
                </button>
                <button class="action-item action-report" data-action="report" type="button">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/>
                        <line x1="12" y1="9" x2="12" y2="13"/>
                        <line x1="12" y1="17" x2="12.01" y2="17"/>
                    </svg>
                    <span>${window.POST_ACTIONS_I18N?.report || 'Report'}</span>
                </button>
            `;
        }
        // Case 3: Regular user viewing other's post - Show Follow/Block/Report
        else {
            // Follow button at the top (before Block/Report)
            buttons += `
                <button class="action-item action-follow" data-action="follow" type="button">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
                        <circle cx="8.5" cy="7" r="4"/>
                        <line x1="20" y1="8" x2="20" y2="14"/>
                        <line x1="23" y1="11" x2="17" y2="11"/>
                    </svg>
                    <span>${this.getFollowButtonText(this.currentIsFollowing)}</span>
                </button>
                <button class="action-item action-block" data-action="block" type="button">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <circle cx="12" cy="12" r="10"/>
                        <line x1="4.93" y1="4.93" x2="19.07" y2="19.07"/>
                    </svg>
                    <span>${window.POST_ACTIONS_I18N?.block || 'Block'}</span>
                </button>
                <button class="action-item action-report" data-action="report" type="button">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/>
                        <line x1="12" y1="9" x2="12" y2="13"/>
                        <line x1="12" y1="17" x2="12.01" y2="17"/>
                    </svg>
                    <span>${window.POST_ACTIONS_I18N?.report || 'Report'}</span>
                </button>
            `;
        }

        actionBody.innerHTML = buttons;
    }

    async openModal() {
        // Fetch follow status for other's posts
        if (!this.isOwnPost() && this.currentAuthorUsername) {
            this.currentIsFollowing = await this.fetchFollowStatus(this.currentAuthorUsername);
        }

        if (this.modal) {
            this.updateModalContent();  // Update content before showing
            this.modal.classList.remove('hidden');
            document.body.style.overflow = 'hidden';
            document.body.classList.add('modal-open');
        }
    }

    closeModal() {
        if (this.modal) {
            this.modal.classList.add('hidden');
            document.body.style.overflow = '';
            document.body.classList.remove('modal-open');
            this.currentPostId = null;
            this.currentAuthorUsername = null;
            this.canEdit = false;
            this.canDelete = false;
        }
    }

    handleAction(action) {
        // For profile actions (block/report), currentPostId might be null
        // For post actions (edit/delete), currentPostId is required
        if (!this.currentPostId && (action === 'edit' || action === 'delete')) {
            console.warn('No post selected');
            return;
        }

        switch (action) {
            case 'edit':
                this.handleEdit();
                break;
            case 'delete':
                this.handleDelete();
                break;
            case 'follow':
                this.handleFollow();
                break;
            case 'block':
                this.handleBlock();
                break;
            case 'report':
                this.handleReport();
                break;
            default:
                console.warn('Unknown action:', action);
        }
    }

    async handleFollow() {
        console.log('[PostActions] Follow action triggered');
        console.log('[PostActions] Author username:', this.currentAuthorUsername);
        console.log('[PostActions] Current is following:', this.currentIsFollowing);

        if (!this.currentAuthorUsername) {
            console.error('[PostActions] No author username available');
            alert('사용자 정보를 찾을 수 없습니다.');
            return;
        }

        // Save username and follow status before closing modal
        const username = this.currentAuthorUsername;
        const isFollowing = this.currentIsFollowing;

        // Close action modal
        this.closeModal();

        // Create temporary button element for toggleFollow function
        const tempBtn = document.createElement('button');
        tempBtn.textContent = isFollowing ?
            (window.APP_I18N?.following || 'Following') :
            (window.APP_I18N?.follow || 'Follow');
        tempBtn.className = isFollowing ? 'btn-ghost' : 'btn-primary';

        // Call existing toggleFollow function from follow.js
        if (window.toggleFollow) {
            await window.toggleFollow(username, tempBtn);

            // Update local state based on result
            this.currentIsFollowing = tempBtn.classList.contains('btn-ghost');

            console.log('[PostActions] Follow status updated:', this.currentIsFollowing);
        } else {
            console.error('[PostActions] toggleFollow function not found');
            alert('팔로우 기능을 사용할 수 없습니다.');
        }
    }

    handleBlock() {
        console.log('[PostActions] Block action triggered');
        console.log('[PostActions] Post ID:', this.currentPostId);
        console.log('[PostActions] Author username:', this.currentAuthorUsername);
        console.log('[PostActions] Is blocking:', this.currentIsBlocking);

        if (!this.currentAuthorUsername) {
            console.error('[PostActions] No author username available');
            alert('사용자 정보를 찾을 수 없습니다.');
            return;
        }

        // Save username and blocking status before closing modal (closeModal clears these)
        const username = this.currentAuthorUsername;
        const isBlocking = this.currentIsBlocking;

        // Close action modal
        this.closeModal();

        // Route to appropriate modal based on blocking status
        if (isBlocking) {
            // User is already blocked -> Show unblock confirmation modal
            console.log('[PostActions] Calling openUnblockUserModal with username:', username);
            this.openUnblockUserModal(username);
        } else {
            // User is not blocked -> Show block confirmation modal
            console.log('[PostActions] Calling openBlockUserModal with username:', username);
            this.openBlockUserModal(username);
        }
    }

    openBlockUserModal(username) {
        console.log('[PostActions] openBlockUserModal called with username:', username);
        console.log('[PostActions] blockUserModal element:', this.blockUserModal);

        this.currentBlockUsername = username;

        // Use nickname for display, fallback to username if nickname not available
        const displayName = this.currentNickname || username;

        // Set modal content with multi-language support
        const lang = document.documentElement.lang || 'ko';
        if (this.blockUserName) {
            const blockTexts = {
                'ko': `${displayName}님을 차단하시겠습니까?`,
                'en': `Block ${displayName}?`,
                'ja': `${displayName}さんをブロックしますか？`,
                'es': `¿Bloquear a ${displayName}?`
            };
            this.blockUserName.textContent = blockTexts[lang] || blockTexts['ko'];
            console.log('[PostActions] Set block user name text with displayName:', displayName);
        } else {
            console.warn('[PostActions] blockUserName element not found');
        }

        // Show modal
        if (this.blockUserModal) {
            console.log('[PostActions] Showing block user modal');
            this.blockUserModal.classList.remove('hidden');
            this.blockUserModal.classList.add('show');
            console.log('[PostActions] Modal classes:', this.blockUserModal.classList);
        } else {
            console.error('[PostActions] blockUserModal is null, cannot show modal');
        }
    }

    closeBlockUserModal() {
        if (this.blockUserModal) {
            this.blockUserModal.classList.remove('show');
            this.blockUserModal.classList.add('hidden');
        }
        this.currentBlockUsername = null;
    }

    async confirmBlockUser() {
        if (!this.currentBlockUsername) return;

        try {
            const response = await fetch(`/api/accounts/${this.currentBlockUsername}/block/`, {
                method: 'POST',
                headers: {
                    'X-CSRFToken': this.getCsrfToken(),
                    'Content-Type': 'application/json',
                },
                credentials: 'same-origin'
            });

            if (response.ok) {
                // Use nickname for display, fallback to username if not available
                const displayName = this.currentNickname || this.currentBlockUsername;
                const lang = document.documentElement.lang || 'ko';
                const message = lang === 'en'
                    ? `${displayName} has been blocked`
                    : `${displayName}님을 차단했습니다`;
                window.showAlert(message, 'success');

                this.closeBlockUserModal();

                // Remove blocked user's content from DOM immediately
                this.removeBlockedUserContent(this.currentBlockUsername);

                console.log('[PostActions] Blocked user content removed from UI');
            } else {
                const error = await response.json().catch(() => ({ error: 'Unknown error' }));
                const lang = document.documentElement.lang || 'ko';
                const message = lang === 'en'
                    ? `Block failed: ${error.error || 'Server error occurred'}`
                    : `차단 실패: ${error.error || '서버 오류가 발생했습니다'}`;
                window.showAlert(message, 'error');
            }
        } catch (error) {
            console.error('Block user error:', error);
            const lang = document.documentElement.lang || 'ko';
            if (lang === 'en') {
                alert('An error occurred while blocking the user.\n\nPlease check your network connection.');
            } else {
                alert('사용자 차단 중 오류가 발생했습니다.\n\n네트워크 연결을 확인해주세요.');
            }
        }
    }

    removeBlockedUserContent(username) {
        console.log('[PostActions] Removing content from blocked user:', username);

        // Remove posts from feed
        const postCards = document.querySelectorAll('[data-author-username]');
        let removedCount = 0;

        postCards.forEach(card => {
            const authorUsername = card.getAttribute('data-author-username');
            if (authorUsername === username) {
                console.log('[PostActions] Removing post card:', card);
                card.style.transition = 'opacity 0.3s ease-out';
                card.style.opacity = '0';
                setTimeout(() => {
                    card.remove();
                }, 300);
                removedCount++;
            }
        });

        // Remove comments from blocked user
        const comments = document.querySelectorAll('.comment-item[data-author-username]');
        comments.forEach(comment => {
            const authorUsername = comment.getAttribute('data-author-username');
            if (authorUsername === username) {
                console.log('[PostActions] Removing comment:', comment);
                comment.style.transition = 'opacity 0.3s ease-out';
                comment.style.opacity = '0';
                setTimeout(() => {
                    comment.remove();
                }, 300);
                removedCount++;
            }
        });

        // Remove user cards (explore page)
        const userCards = document.querySelectorAll('.user-card[data-username]');
        userCards.forEach(card => {
            const cardUsername = card.getAttribute('data-username');
            if (cardUsername === username) {
                console.log('[PostActions] Removing user card:', card);
                card.style.transition = 'opacity 0.3s ease-out';
                card.style.opacity = '0';
                setTimeout(() => {
                    card.remove();
                }, 300);
                removedCount++;
            }
        });

        console.log(`[PostActions] Removed ${removedCount} items from blocked user`);
    }

    markPostAsReported(postId) {
        console.log('[PostActions] Marking post as reported:', postId);

        // Find the post card
        const postCard = document.querySelector(`[data-post-id="${postId}"]`);
        if (!postCard) {
            console.warn('[PostActions] Post card not found for ID:', postId);
            return;
        }

        // Find the report button within the post actions dropdown
        const reportBtn = postCard.querySelector('.action-item[data-action="report"]');
        if (reportBtn) {
            // Disable the button
            reportBtn.style.opacity = '0.5';
            reportBtn.style.pointerEvents = 'none';

            // Change text to indicate it's already reported
            const textContent = reportBtn.textContent.trim();
            if (!textContent.includes('✓') && !textContent.includes('신고됨') && !textContent.includes('Reported')) {
                reportBtn.textContent = '✓ ' + getPostActionText('reported');
            }

            console.log('[PostActions] Report button disabled for post:', postId);
        }

        // Optionally add a visual indicator to the post card
        const existingBadge = postCard.querySelector('.reported-badge');
        if (!existingBadge) {
            const badge = document.createElement('div');
            badge.className = 'reported-badge';
            badge.style.cssText = 'position: absolute; top: 10px; right: 10px; background: rgba(255, 59, 48, 0.1); color: #ff3b30; padding: 4px 8px; border-radius: 4px; font-size: 12px; font-weight: 500;';
            badge.textContent = getPostActionText('reportedBadge');

            // Make sure post card has relative positioning
            if (postCard.style.position !== 'relative' && postCard.style.position !== 'absolute') {
                postCard.style.position = 'relative';
            }

            postCard.appendChild(badge);
            console.log('[PostActions] Added reported badge to post:', postId);
        }
    }

    setupBlockUserModal() {
        console.log('[PostActions] setupBlockUserModal called');
        // 이미 설정된 경우 스킵
        if (this._blockModalSetup) {
            return;
        }
        if (!this.blockUserModal) {
            console.warn('[PostActions] Block user modal not found');
            return;
        }
        this._blockModalSetup = true;
        console.log('[PostActions] Block user modal found, setting up event listeners');

        // Confirm block button
        if (this.confirmBlockUserBtn) {
            this.confirmBlockUserBtn.addEventListener('click', () => {
                this.confirmBlockUser();
            });
        }

        // Cancel block button
        if (this.cancelBlockUserBtn) {
            this.cancelBlockUserBtn.addEventListener('click', () => {
                this.closeBlockUserModal();
            });
        }

        // Close button (X)
        if (this.closeBlockUserBtn) {
            this.closeBlockUserBtn.addEventListener('click', () => {
                this.closeBlockUserModal();
            });
        }

        // Click outside to close
        this.blockUserModal.addEventListener('click', (e) => {
            if (e.target === this.blockUserModal) {
                this.closeBlockUserModal();
            }
        });

        // Escape key to close
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && !this.blockUserModal.classList.contains('hidden')) {
                this.closeBlockUserModal();
            }
        });
    }

    setupUnblockUserModal() {
        console.log('[PostActions] setupUnblockUserModal called');
        // 이미 설정된 경우 스킵
        if (this._unblockModalSetup) {
            return;
        }
        if (!this.unblockUserModal) {
            console.warn('[PostActions] Unblock user modal not found');
            return;
        }
        this._unblockModalSetup = true;
        console.log('[PostActions] Unblock user modal found, setting up event listeners');

        // Confirm unblock button
        if (this.confirmUnblockUserBtn) {
            this.confirmUnblockUserBtn.addEventListener('click', () => {
                this.confirmUnblockUser();
            });
        }

        // Cancel unblock button
        if (this.cancelUnblockUserBtn) {
            this.cancelUnblockUserBtn.addEventListener('click', () => {
                this.closeUnblockUserModal();
            });
        }

        // Close button (X)
        if (this.closeUnblockUserBtn) {
            this.closeUnblockUserBtn.addEventListener('click', () => {
                this.closeUnblockUserModal();
            });
        }

        // Click outside to close
        this.unblockUserModal.addEventListener('click', (e) => {
            if (e.target === this.unblockUserModal) {
                this.closeUnblockUserModal();
            }
        });

        // Escape key to close
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && !this.unblockUserModal.classList.contains('hidden')) {
                this.closeUnblockUserModal();
            }
        });
    }

    openUnblockUserModal(username) {
        console.log('[PostActions] openUnblockUserModal called with username:', username);
        console.log('[PostActions] unblockUserModal element:', this.unblockUserModal);

        this.currentUnblockUsername = username;

        // Use nickname for display, fallback to username if nickname not available
        const displayName = this.currentNickname || username;

        // Set modal content with multi-language support
        const lang = document.documentElement.lang || 'ko';
        if (this.unblockUserName) {
            const unblockTexts = {
                'ko': `${displayName}님을 차단 해제하시겠습니까?`,
                'en': `Unblock ${displayName}?`,
                'ja': `${displayName}さんのブロックを解除しますか？`,
                'es': `¿Desbloquear a ${displayName}?`
            };
            this.unblockUserName.textContent = unblockTexts[lang] || unblockTexts['ko'];
            console.log('[PostActions] Set unblock user name text with displayName:', displayName);
        } else {
            console.warn('[PostActions] unblockUserName element not found');
        }

        // Show modal
        if (this.unblockUserModal) {
            console.log('[PostActions] Showing unblock user modal');
            this.unblockUserModal.classList.remove('hidden');
            this.unblockUserModal.classList.add('show');
            console.log('[PostActions] Modal classes:', this.unblockUserModal.classList);
        } else {
            console.error('[PostActions] unblockUserModal is null, cannot show modal');
        }
    }

    closeUnblockUserModal() {
        if (this.unblockUserModal) {
            this.unblockUserModal.classList.remove('show');
            this.unblockUserModal.classList.add('hidden');
        }
        this.currentUnblockUsername = null;
    }

    async confirmUnblockUser() {
        if (!this.currentUnblockUsername) return;

        try {
            const response = await fetch(`/api/accounts/${this.currentUnblockUsername}/unblock/`, {
                method: 'DELETE',
                headers: {
                    'X-CSRFToken': this.getCsrfToken(),
                    'Content-Type': 'application/json',
                },
                credentials: 'same-origin'
            });

            if (response.ok) {
                // Use nickname for display, fallback to username if not available
                const displayName = this.currentNickname || this.currentUnblockUsername;
                const lang = document.documentElement.lang || 'ko';
                const message = lang === 'en'
                    ? `${displayName} has been unblocked`
                    : `${displayName}님을 차단 해제했습니다`;
                window.showAlert(message, 'success');

                this.closeUnblockUserModal();

                // Reload the page to update UI (blocking status changed)
                setTimeout(() => {
                    window.location.reload();
                }, 500);
            } else {
                const error = await response.json().catch(() => ({ error: 'Unknown error' }));
                const lang = document.documentElement.lang || 'ko';
                const message = lang === 'en'
                    ? `Unblock failed: ${error.error || 'Server error occurred'}`
                    : `차단 해제 실패: ${error.error || '서버 오류가 발생했습니다'}`;
                window.showAlert(message, 'error');
            }
        } catch (error) {
            console.error('Unblock user error:', error);
            const lang = document.documentElement.lang || 'ko';
            if (lang === 'en') {
                alert('An error occurred while unblocking the user.\n\nPlease check your network connection.');
            } else {
                alert('사용자 차단 해제 중 오류가 발생했습니다.\n\n네트워크 연결을 확인해주세요.');
            }
        }
    }

    handleReport() {
        console.log('Report action triggered');
        console.log('Post ID:', this.currentPostId);

        if (!this.currentPostId) {
            console.error('No post ID available for report');
            alert(window.POST_ACTIONS_I18N?.cannotFindPost || 'Cannot find post to report.');
            return;
        }

        // Close action modal (but keep currentPostId for report modal)
        if (this.modal) {
            this.modal.classList.add('hidden');
            document.body.classList.remove('modal-open');
        }

        // Open report modal (currentPostId is still preserved)
        this.showReportModal();
    }

    setupReportModal() {
        // 이미 설정된 경우 스킵
        if (this._reportModalSetup) {
            return;
        }
        if (!this.reportModal) {
            console.warn('Report modal not found');
            return;
        }
        this._reportModalSetup = true;

        // Close button
        const closeBtn = document.getElementById('close-report-modal');
        if (closeBtn) {
            closeBtn.addEventListener('click', () => this.hideReportModal());
        }

        // Cancel button
        const cancelBtn = document.getElementById('cancel-post-report-btn');
        if (cancelBtn) {
            cancelBtn.addEventListener('click', () => this.hideReportModal());
        }

        // Report type buttons (visual selection)
        const reportTypeBtns = document.querySelectorAll('.report-type-btn');
        const reportTypeInput = document.getElementById('post-report-type');

        reportTypeBtns.forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.preventDefault();
                // Remove selected from all buttons
                reportTypeBtns.forEach(b => b.classList.remove('selected'));
                // Add selected to clicked button
                btn.classList.add('selected');
                // Update hidden input value
                const reportType = btn.getAttribute('data-type');
                if (reportTypeInput) {
                    reportTypeInput.value = reportType;
                }
            });
        });

        // Form submit
        const reportForm = document.getElementById('post-report-form');
        if (reportForm) {
            reportForm.addEventListener('submit', (e) => {
                e.preventDefault();
                this.submitReport();
            });
        }

        // Submit button (explicit handler)
        const submitBtn = document.getElementById('submit-post-report-btn');
        if (submitBtn) {
            submitBtn.addEventListener('click', (e) => {
                e.preventDefault();
                this.submitReport();
            });
        }

        // Click overlay to close
        this.reportModal.addEventListener('click', (e) => {
            if (e.target === this.reportModal) {
                this.hideReportModal();
            }
        });

        // Escape key to close
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && !this.reportModal.classList.contains('hidden')) {
                this.hideReportModal();
            }
        });
    }

    setupDeleteModal() {
        // 이미 설정된 경우 스킵
        if (this._deleteModalSetup) {
            return;
        }
        if (!this.deleteModal) {
            console.warn('Delete modal not found');
            return;
        }
        this._deleteModalSetup = true;

        // Confirm delete button
        if (this.confirmDeleteBtn) {
            this.confirmDeleteBtn.addEventListener('click', () => {
                // Execute callback BEFORE closing (which sets callback to null)
                if (this.deleteCallback) {
                    const callback = this.deleteCallback;
                    this.deleteCallback = null;
                    this.closeDeleteModal();
                    callback();
                } else {
                    this.closeDeleteModal();
                }
            });
        }

        // Cancel delete button
        if (this.cancelDeleteBtn) {
            this.cancelDeleteBtn.addEventListener('click', () => {
                this.deleteCallback = null;
                this.closeDeleteModal();
            });
        }

        // Click outside to close
        this.deleteModal.addEventListener('click', (e) => {
            if (e.target === this.deleteModal) {
                this.deleteCallback = null;
                this.closeDeleteModal();
            }
        });

        // Escape key to close
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && !this.deleteModal.classList.contains('hidden')) {
                this.deleteCallback = null;
                this.closeDeleteModal();
            }
        });
    }

    openDeleteModal(callback) {
        if (!this.deleteModal) return;

        this.deleteCallback = callback;
        this.deleteModal.classList.remove('hidden');
        document.body.classList.add('delete-modal-open');
    }

    closeDeleteModal() {
        if (!this.deleteModal) return;

        this.deleteModal.classList.add('hidden');
        document.body.classList.remove('delete-modal-open');
        // Don't set deleteCallback to null here - it's managed in the confirm handler
    }

    setupLeaveConversationModal() {
        // 이미 설정된 경우 스킵
        if (this._leaveModalSetup) {
            return;
        }
        if (!this.leaveConversationModal) {
            console.warn('Leave conversation modal not found');
            return;
        }
        this._leaveModalSetup = true;

        // Confirm leave button
        if (this.confirmLeaveConversationBtn) {
            this.confirmLeaveConversationBtn.addEventListener('click', () => {
                this.confirmLeaveConversation();
            });
        }

        // Cancel leave button
        if (this.cancelLeaveConversationBtn) {
            this.cancelLeaveConversationBtn.addEventListener('click', () => {
                this.closeLeaveConversationModal();
            });
        }

        // Close button (X)
        if (this.closeLeaveConversationBtn) {
            this.closeLeaveConversationBtn.addEventListener('click', () => {
                this.closeLeaveConversationModal();
            });
        }

        // Click outside to close
        this.leaveConversationModal.addEventListener('click', (e) => {
            if (e.target === this.leaveConversationModal) {
                this.closeLeaveConversationModal();
            }
        });

        // Escape key to close
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && !this.leaveConversationModal.classList.contains('hidden')) {
                this.closeLeaveConversationModal();
            }
        });
    }

    showReportModal() {
        if (this.reportModal) {
            this.reportModal.classList.remove('hidden');
            document.body.style.overflow = 'hidden';
        }
    }

    hideReportModal() {
        if (this.reportModal) {
            this.reportModal.classList.add('hidden');
            document.body.style.overflow = '';
            // Reset form
            const reportForm = document.getElementById('post-report-form');
            if (reportForm) {
                reportForm.reset();
            }
            // Reset visual selection
            const reportTypeBtns = document.querySelectorAll('.report-type-btn');
            reportTypeBtns.forEach(btn => btn.classList.remove('selected'));
            // Reset hidden input
            const reportTypeInput = document.getElementById('post-report-type');
            if (reportTypeInput) {
                reportTypeInput.value = '';
            }
            // Clear currentPostId and currentReportUserId after report modal is closed
            this.currentPostId = null;
            this.currentReportUserId = null;
            this.currentAuthorUsername = null;
        }
    }

    openReportModal() {
        this.showReportModal();
    }

    async submitUserReport() {
        const reportType = document.getElementById('post-report-type').value;
        const description = document.getElementById('post-report-description').value;

        if (!reportType) {
            alert(getPostActionText('selectReportType'));
            return;
        }

        if (!this.currentReportUserId) {
            console.error('No user ID available for report');
            alert(getPostActionText('cannotFindUser'));
            return;
        }

        try {
            // Use FormData for file + data transmission
            const formData = new FormData();
            formData.append('reported_user', this.currentReportUserId);
            formData.append('report_type', reportType);
            formData.append('description', description || '');

            const response = await fetch('/api/chat/report/', {
                method: 'POST',
                headers: {
                    'X-CSRFToken': this.getCsrfToken()
                    // Content-Type removed - browser sets multipart/form-data automatically
                },
                credentials: 'same-origin',
                body: formData
            });

            if (response.ok) {
                this.hideReportModal();
            } else {
                const errorData = await response.json().catch(() => ({ error: '알 수 없는 오류' }));
                console.error('User report error:', errorData);
                alert(errorData.error || '신고 처리 중 오류가 발생했습니다.');
            }
        } catch (error) {
            console.error('User report submission error:', error);
            alert(getPostActionText('networkError'));
        }
    }

    async submitReport() {
        // Auto-detect: if reporting a user (chat room), use submitUserReport
        if (this.currentReportUserId) {
            return await this.submitUserReport();
        }

        // Otherwise, proceed with post reporting
        const reportType = document.getElementById('post-report-type').value;
        const description = document.getElementById('post-report-description').value;

        if (!reportType) {
            alert(window.POST_ACTIONS_I18N?.selectReportType || 'Please select a report type.');
            return;
        }

        if (!this.currentPostId) {
            console.error('No post ID available for report');
            alert(window.POST_ACTIONS_I18N?.cannotFindPost || 'Cannot find post to report.');
            return;
        }

        try {
            const response = await fetch(`/api/posts/${this.currentPostId}/report/`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRFToken': this.getCsrfToken()
                },
                credentials: 'same-origin',
                body: JSON.stringify({
                    report_type: reportType,
                    description: description
                })
            });

            if (response.ok) {
                alert(window.POST_ACTIONS_I18N?.reportSubmitted || 'Report submitted successfully. We will review it.');
                this.hideReportModal();

                // Mark post as reported in UI
                this.markPostAsReported(this.currentPostId);

                console.log('[PostActions] Post marked as reported:', this.currentPostId);
            } else {
                const error = await response.json().catch(() => ({ detail: '알 수 없는 오류' }));
                console.error('Report error:', error);
                alert(`신고 접수 실패: ${error.detail || error.report_type?.[0] || '서버 오류가 발생했습니다'}`);
            }
        } catch (error) {
            console.error('Report submission error:', error);
            alert(window.POST_ACTIONS_I18N?.networkError || 'Network error occurred. Please try again.');
        }
    }

    handleEdit() {
        console.log('Edit action triggered for post:', this.currentPostId);

        // Store postId before closing modal (closeModal clears currentPostId)
        const postId = this.currentPostId;

        // Close action modal
        this.closeModal();

        // Open edit modal using the stored postId
        if (typeof window.openEditModal === 'function') {
            window.openEditModal(postId);
        } else {
            console.error('openEditModal function not found. Make sure post_modal.js is loaded.');
            alert('Edit functionality is not available.');
        }
    }

    async handleDelete() {
        console.log('=== DELETE DEBUG START ===');
        console.log('Delete action triggered for post:', this.currentPostId);
        console.log('POST_ACTIONS_I18N available:', !!window.POST_ACTIONS_I18N);
        console.log('CSRF token:', this.getCsrfToken());

        // Open delete confirmation modal instead of browser confirm()
        this.openDeleteModal(async () => {
            console.log('Delete confirmed, making API call...');

            try {
            const url = `/api/posts/${this.currentPostId}/`;
            console.log('DELETE URL:', url);

            const response = await fetch(url, {
                method: 'DELETE',
                headers: {
                    'X-CSRFToken': this.getCsrfToken(),
                },
                credentials: 'same-origin'
            });

            console.log('Response status:', response.status);
            console.log('Response ok:', response.ok);

            if (response.ok) {
                console.log('Delete successful!');
                this.closeModal();

                // Show success modal and reload page after user clicks OK
                this.showSuccessModal(
                    window.POST_ACTIONS_I18N?.postDeleted || '게시물이 삭제되었습니다.',
                    () => window.location.reload()
                );
            } else {
                const error = await response.json().catch(() => ({
                    detail: window.POST_ACTIONS_I18N?.unknownError || '알 수 없는 오류'
                }));
                console.error('[PostActions] Delete failed with error:', error);
                const errorMsg = window.POST_ACTIONS_I18N?.deleteFailed || '삭제 실패';
                const serverError = window.POST_ACTIONS_I18N?.serverError || '서버 오류가 발생했습니다';
                this.showErrorModal(`${errorMsg}: ${error.detail || serverError}`);
            }
            } catch (error) {
                console.error('Delete error:', error);
                this.showErrorModal(window.POST_ACTIONS_I18N?.networkError || '네트워크 오류가 발생했습니다. 다시 시도해주세요.');
            }

            console.log('=== DELETE DEBUG END ===');
        });
    }

    getCsrfToken() {
        /**
         * Get CSRF token from cookie or hidden input
         * @returns {string} CSRF token
         */
        // Try to get from cookie first
        const cookieMatch = document.cookie.match(/csrftoken=([^;]+)/);
        if (cookieMatch) {
            return cookieMatch[1];
        }

        // Fallback: try to get from hidden input
        const tokenInput = document.querySelector('[name=csrfmiddlewaretoken]');
        if (tokenInput) {
            return tokenInput.value;
        }

        console.warn('CSRF token not found');
        return '';
    }

    // ==========================================
    // Alert Modal Functions
    // ==========================================

    setupAlertModal() {
        if (!this.alertModal || !this.alertOkBtn) {
            console.warn('Alert modal elements not found');
            return;
        }

        // OK button click handler
        this.alertOkBtn.addEventListener('click', () => {
            this.closeAlertModal();
            if (this.alertCallback) {
                const callback = this.alertCallback;
                this.alertCallback = null;
                callback();
            }
        });

        // Click outside to close
        this.alertModal.addEventListener('click', (e) => {
            if (e.target === this.alertModal) {
                this.closeAlertModal();
                if (this.alertCallback) {
                    const callback = this.alertCallback;
                    this.alertCallback = null;
                    callback();
                }
            }
        });

        // Escape key to close
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && this.alertModal && !this.alertModal.classList.contains('hidden')) {
                this.closeAlertModal();
                if (this.alertCallback) {
                    const callback = this.alertCallback;
                    this.alertCallback = null;
                    callback();
                }
            }
        });
    }

    showSuccessModal(message, callback = null) {
        if (!this.alertModal) return;

        // Set success icon (checkmark)
        this.alertIcon.innerHTML = `
            <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="#10b981" stroke-width="2">
                <circle cx="12" cy="12" r="10"/>
                <path d="M9 12l2 2 4-4"/>
            </svg>
        `;

        this.alertMessage.textContent = message;
        this.alertCallback = callback;

        this.alertModal.classList.remove('hidden');
        document.body.classList.add('modal-open');
    }

    showErrorModal(message, callback = null) {
        if (!this.alertModal) return;

        // Set error icon (X)
        this.alertIcon.innerHTML = `
            <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="#ef4444" stroke-width="2">
                <circle cx="12" cy="12" r="10"/>
                <path d="M15 9l-6 6M9 9l6 6"/>
            </svg>
        `;

        this.alertMessage.textContent = message;
        this.alertCallback = callback;

        this.alertModal.classList.remove('hidden');
        document.body.classList.add('modal-open');
    }

    closeAlertModal() {
        if (!this.alertModal) return;

        this.alertModal.classList.add('hidden');
        document.body.classList.remove('modal-open');
    }
}

// Initialize on DOMContentLoaded
document.addEventListener('DOMContentLoaded', () => {
    window.postActionsManager = new PostActionsManager();
});
