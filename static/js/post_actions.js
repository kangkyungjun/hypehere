/**
 * Post Actions - Dropdown Menu Handler
 * Handles block and report actions for posts
 */

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
        this.deleteCallback = null;

        // Leave conversation modal elements
        this.leaveConversationModal = document.getElementById('leave-conversation-modal');
        this.confirmLeaveConversationBtn = document.getElementById('confirm-leave-conversation');
        this.cancelLeaveConversationBtn = document.getElementById('cancel-leave-conversation');
        this.closeLeaveConversationBtn = document.getElementById('close-leave-conversation-modal');
        this.currentConversationId = null;

        // Block user modal elements (support both main page and chat room)
        this.blockUserModal = document.getElementById('block-user-modal') || document.getElementById('block-user-modal-chat');
        this.confirmBlockUserBtn = document.getElementById('confirm-block-user') || document.getElementById('confirm-block-user-chat');
        this.cancelBlockUserBtn = document.getElementById('cancel-block-user') || document.getElementById('cancel-block-user-chat');
        this.closeBlockUserBtn = document.getElementById('close-block-user-modal') || document.getElementById('close-block-user-modal-chat');
        this.blockUserName = document.getElementById('block-user-name') || document.getElementById('block-user-name-chat');
        this.currentBlockUsername = null;
        this.currentReportUserId = null;  // For user reporting in chat rooms

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
    }

    setupEventListeners() {
        // Dropdown toggle buttons (event delegation)
        document.addEventListener('click', (e) => {
            const toggleBtn = e.target.closest('.dropdown-toggle');
            if (toggleBtn) {
                e.preventDefault();
                e.stopPropagation();

                // Profile page actions (user actions)
                if (toggleBtn.classList.contains('profile-actions-toggle')) {
                    this.handleProfileDropdownClick(toggleBtn);
                // Chat page actions (user actions)
                } else if (toggleBtn.classList.contains('chat-actions-toggle')) {
                    this.handleChatDropdownClick(toggleBtn);
                } else {
                    // Post actions
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

        console.log('Opening modal for post:', this.currentPostId, 'by', this.currentAuthorUsername);
        this.openModal();
    }

    handleProfileDropdownClick(button) {
        // Get user data from button attributes
        this.currentAuthorUsername = button.dataset.username;
        this.currentUserId = button.dataset.userId;
        this.currentPostId = null;  // No post ID for profile actions

        console.log('Opening modal for user:', this.currentAuthorUsername, 'ID:', this.currentUserId);
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
            const response = await fetch(`/messages/api/conversations/${this.currentConversationId}/leave/`, {
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

    updateModalContent() {
        /**
         * Dynamically update modal content based on ownership
         * Own posts: Edit, Delete
         * Other's posts: Block, Report
         */
        const actionBody = this.modal.querySelector('.post-action-body');
        if (!actionBody) {
            console.warn('Modal action body not found');
            return;
        }

        if (this.isOwnPost()) {
            // Own post: Edit/Delete
            actionBody.innerHTML = `
                <button class="action-item action-edit" data-action="edit" type="button">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
                        <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
                    </svg>
                    <span>${window.POST_ACTIONS_I18N?.edit || 'Edit'}</span>
                </button>
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
        } else {
            // Other's post: Block/Report
            actionBody.innerHTML = `
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
    }

    openModal() {
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

    handleBlock() {
        console.log('[PostActions] Block action triggered');
        console.log('[PostActions] Post ID:', this.currentPostId);
        console.log('[PostActions] Author username:', this.currentAuthorUsername);

        if (!this.currentAuthorUsername) {
            console.error('[PostActions] No author username available');
            alert('사용자 정보를 찾을 수 없습니다.');
            return;
        }

        // Save username before closing modal (closeModal clears currentAuthorUsername)
        const username = this.currentAuthorUsername;

        // Close action modal
        this.closeModal();

        // Open block confirmation modal
        console.log('[PostActions] Calling openBlockUserModal with username:', username);
        this.openBlockUserModal(username);
    }

    openBlockUserModal(username) {
        console.log('[PostActions] openBlockUserModal called with username:', username);
        console.log('[PostActions] blockUserModal element:', this.blockUserModal);

        this.currentBlockUsername = username;

        // Set modal content
        const lang = document.documentElement.lang || 'ko';
        if (this.blockUserName) {
            if (lang === 'en') {
                this.blockUserName.textContent = `Block ${username}?`;
            } else {
                this.blockUserName.textContent = `${username}님을 차단하시겠습니까?`;
            }
            console.log('[PostActions] Set block user name text');
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
                const lang = document.documentElement.lang || 'ko';
                if (lang === 'en') {
                    alert(`${this.currentBlockUsername} has been blocked`);
                } else {
                    alert(`${this.currentBlockUsername}님을 차단했습니다`);
                }

                this.closeBlockUserModal();

                // Reload page to hide blocked user's content
                window.location.reload();
            } else {
                const error = await response.json().catch(() => ({ error: 'Unknown error' }));
                const lang = document.documentElement.lang || 'ko';
                if (lang === 'en') {
                    alert(`Block failed: ${error.error || 'Server error occurred'}`);
                } else {
                    alert(`차단 실패: ${error.error || '서버 오류가 발생했습니다'}`);
                }
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

    setupBlockUserModal() {
        console.log('[PostActions] setupBlockUserModal called');
        if (!this.blockUserModal) {
            console.warn('[PostActions] Block user modal not found');
            return;
        }
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
        if (!this.reportModal) {
            console.warn('Report modal not found');
            return;
        }

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
        if (!this.deleteModal) {
            console.warn('Delete modal not found');
            return;
        }

        // Confirm delete button
        if (this.confirmDeleteBtn) {
            this.confirmDeleteBtn.addEventListener('click', () => {
                this.closeDeleteModal();
                if (this.deleteCallback) {
                    this.deleteCallback();
                    this.deleteCallback = null;
                }
            });
        }

        // Cancel delete button
        if (this.cancelDeleteBtn) {
            this.cancelDeleteBtn.addEventListener('click', () => {
                this.closeDeleteModal();
            });
        }

        // Click outside to close
        this.deleteModal.addEventListener('click', (e) => {
            if (e.target === this.deleteModal) {
                this.closeDeleteModal();
            }
        });

        // Escape key to close
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && !this.deleteModal.classList.contains('hidden')) {
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
        this.deleteCallback = null;
    }

    setupLeaveConversationModal() {
        if (!this.leaveConversationModal) {
            console.warn('Leave conversation modal not found');
            return;
        }

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
            const lang = document.documentElement.lang || 'ko';
            alert(lang === 'en' ? 'Please select a report type.' : '신고 유형을 선택해주세요.');
            return;
        }

        if (!this.currentReportUserId) {
            console.error('No user ID available for report');
            const lang = document.documentElement.lang || 'ko';
            alert(lang === 'en' ? 'Cannot find user to report.' : '신고할 사용자를 찾을 수 없습니다.');
            return;
        }

        try {
            const response = await fetch('/api/chat/report/', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRFToken': this.getCsrfToken()
                },
                credentials: 'same-origin',
                body: JSON.stringify({
                    reported_user: this.currentReportUserId,
                    report_type: reportType,
                    description: description
                })
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
            const lang = document.documentElement.lang || 'ko';
            alert(lang === 'en' ? 'Network error occurred. Please try again.' : '네트워크 오류가 발생했습니다. 다시 시도해주세요.');
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
                alert(window.POST_ACTIONS_I18N?.postDeleted || 'Post deleted successfully.');

                // Remove post card from DOM
                const postCard = document.querySelector(`[data-post-id="${this.currentPostId}"]`);
                console.log('Post card found:', !!postCard);
                if (postCard) {
                    postCard.remove();
                    console.log('Post card removed from DOM');
                }

                this.closeModal();

                // Reload page to refresh the list
                console.log('Reloading page...');
                window.location.reload();
            } else {
                const error = await response.json().catch(() => ({ detail: '알 수 없는 오류' }));
                console.error('Delete failed with error:', error);
                alert(`삭제 실패: ${error.detail || '서버 오류가 발생했습니다'}`);
            }
            } catch (error) {
                console.error('Delete error:', error);
                alert(window.POST_ACTIONS_I18N?.networkError || 'Network error occurred. Please try again.');
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
}

// Initialize on DOMContentLoaded
document.addEventListener('DOMContentLoaded', () => {
    window.postActionsManager = new PostActionsManager();
});
