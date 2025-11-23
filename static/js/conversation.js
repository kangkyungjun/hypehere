/**
 * Conversation Detail Page
 * Handles WebSocket connection and real-time messaging for a specific conversation
 */

class ConversationApp {
    constructor(conversationId) {
        this.conversationId = conversationId;
        this.currentWebSocket = null;
        this.reconnectAttempts = 0;
        this.maxReconnectAttempts = 5;
        this.reconnectDelay = 1000;

        // DOM elements
        this.messagesList = document.getElementById('messages-list');
        this.messageInput = document.getElementById('message-input');
        this.sendButton = document.getElementById('send-button');

        // Action modal, report modal, and block modal elements
        this.actionModal = document.getElementById('message-action-modal');
        this.reportModal = document.getElementById('message-report-modal');
        this.blockModal = document.getElementById('block-user-modal');
        this.currentReportedUserId = null;
        this.currentReportedUsername = null;
        this.selectedReportType = null;

        // Leave conversation modal elements
        this.leaveModal = document.getElementById('leave-conversation-modal');
        this.confirmLeaveBtn = document.getElementById('confirm-leave-conversation');
        this.cancelLeaveBtn = document.getElementById('cancel-leave-conversation');
        this.closeLeaveModalBtn = document.getElementById('close-leave-conversation-modal');

        this.init();
    }

    async init() {
        console.log('[Conversation] Initializing for conversation:', this.conversationId);
        await this.loadConversationDetails();
        this.setupEventListeners();
        this.setupAutoResize();
        this.setupActionModal();
        this.setupReportModal();
        this.setupBlockModal();
        this.setupLeaveModal();
        this.connectWebSocket();
        console.log('[Conversation] Initialization complete');
    }

    setupEventListeners() {
        // Send message button
        this.sendButton.addEventListener('click', () => this.sendMessage());

        // Track composition state for Korean/Japanese/Chinese input
        let isComposing = false;

        this.messageInput.addEventListener('compositionstart', () => {
            isComposing = true;
        });

        this.messageInput.addEventListener('compositionend', () => {
            isComposing = false;
        });

        // Enter key to send (Shift+Enter for new line)
        this.messageInput.addEventListener('keydown', (e) => {
            // Prevent sending during IME composition
            if (e.key === 'Enter' && !e.shiftKey && !isComposing && !e.isComposing) {
                e.preventDefault();
                this.sendMessage();
            }
        });

        // Leave conversation button
        const leaveBtn = document.querySelector('.leave-room-btn');
        if (leaveBtn) {
            leaveBtn.addEventListener('click', (e) => {
                e.preventDefault();
                this.openLeaveModal();
            });
        }
    }

    setupAutoResize() {
        // Auto-resize textarea
        this.messageInput.addEventListener('input', () => {
            this.messageInput.style.height = 'auto';
            this.messageInput.style.height = this.messageInput.scrollHeight + 'px';
        });
    }

    async loadConversationDetails() {
        try {
            const response = await fetch(`/messages/api/conversations/${this.conversationId}/`, {
                credentials: 'same-origin'
            });

            if (!response.ok) {
                throw new Error('Failed to load conversation details');
            }

            const conversation = await response.json();
            this.renderMessages(conversation.messages);
            this.scrollToBottom();
        } catch (error) {
            console.error('[Conversation] Error loading conversation details:', error);
            this.showError('대화를 불러오지 못했습니다.');
        }
    }

    renderMessages(messages) {
        if (messages.length === 0) {
            this.messagesList.innerHTML = '<div class="empty-state"><p>메시지가 없습니다</p></div>';
            return;
        }

        const currentUserId = this.getCurrentUserId();
        const messagesHTML = messages.map(msg => this.createMessageHTML(msg, currentUserId)).join('');
        this.messagesList.innerHTML = messagesHTML;
    }

    createMessageHTML(message, currentUserId) {
        const isSent = message.sender_id === currentUserId;
        const avatarSrc = message.sender_profile_picture || this.getDefaultAvatar();
        const timeStr = this.formatTime(message.created_at);

        return `
            <div class="message-item ${isSent ? 'sent' : 'received'}">
                ${!isSent ? `<img class="message-avatar" src="${avatarSrc}" alt="${this.escapeHtml(message.sender_nickname)}">` : ''}
                <div class="message-bubble">
                    <div class="message-content">${this.escapeHtml(message.content)}</div>
                </div>
                <div class="message-time">${timeStr}</div>
            </div>
        `;
    }

    connectWebSocket() {
        const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        const wsUrl = `${protocol}//${window.location.host}/ws/chat/${this.conversationId}/`;

        console.log('[Conversation] Connecting WebSocket:', wsUrl);

        try {
            this.currentWebSocket = new WebSocket(wsUrl);

            this.currentWebSocket.onopen = () => {
                console.log('[Conversation] WebSocket connected');
                this.reconnectAttempts = 0;
                // Mark messages as read
                this.markAsRead();
            };

            this.currentWebSocket.onmessage = (event) => {
                console.log('[Conversation] WebSocket message received:', event.data);
                const data = JSON.parse(event.data);
                this.handleWebSocketMessage(data);
            };

            this.currentWebSocket.onerror = (error) => {
                console.error('[Conversation] WebSocket error:', error);
            };

            this.currentWebSocket.onclose = (event) => {
                console.log('[Conversation] WebSocket closed:', event.code, event.reason);
                this.handleWebSocketClose();
            };
        } catch (error) {
            console.error('[Conversation] WebSocket connection error:', error);
            this.showError('실시간 연결에 실패했습니다.');
        }
    }

    handleWebSocketMessage(data) {
        if (data.type === 'message') {
            this.addNewMessage(data);
        }
    }

    addNewMessage(messageData) {
        const currentUserId = this.getCurrentUserId();
        const messageHTML = this.createMessageHTML({
            sender_id: messageData.sender_id,
            sender_nickname: messageData.sender_nickname,
            sender_profile_picture: null,
            content: messageData.content,
            created_at: messageData.created_at
        }, currentUserId);

        // Remove empty state if present
        const emptyState = this.messagesList.querySelector('.empty-state');
        if (emptyState) {
            emptyState.remove();
        }

        this.messagesList.insertAdjacentHTML('beforeend', messageHTML);
        this.scrollToBottom();
    }

    async sendMessage() {
        const content = this.messageInput.value.trim();
        if (!content || !this.currentWebSocket) {
            return;
        }

        // Check WebSocket connection
        if (this.currentWebSocket.readyState !== WebSocket.OPEN) {
            this.showError('연결이 끊어졌습니다. 다시 연결 중...');
            return;
        }

        try {
            // Send via WebSocket
            this.currentWebSocket.send(JSON.stringify({
                type: 'message',
                content: content
            }));

            // Clear input
            this.messageInput.value = '';
            this.messageInput.style.height = 'auto';
        } catch (error) {
            console.error('[Conversation] Error sending message:', error);
            this.showError('메시지 전송에 실패했습니다.');
        }
    }

    markAsRead() {
        if (!this.currentWebSocket || this.currentWebSocket.readyState !== WebSocket.OPEN) {
            return;
        }

        this.currentWebSocket.send(JSON.stringify({
            type: 'read'
        }));
    }

    closeWebSocket() {
        if (this.currentWebSocket) {
            console.log('[Conversation] Closing WebSocket');
            this.currentWebSocket.close();
            this.currentWebSocket = null;
        }
    }

    handleWebSocketClose() {
        // Attempt to reconnect
        if (this.reconnectAttempts < this.maxReconnectAttempts) {
            this.reconnectAttempts++;
            const delay = this.reconnectDelay * Math.pow(2, this.reconnectAttempts - 1);
            console.log(`[Conversation] Reconnecting in ${delay}ms (attempt ${this.reconnectAttempts})`);

            setTimeout(() => {
                this.connectWebSocket();
            }, delay);
        } else {
            this.showError('연결이 끊어졌습니다. 페이지를 새로고침해주세요.');
        }
    }

    scrollToBottom() {
        setTimeout(() => {
            this.messagesList.scrollTop = this.messagesList.scrollHeight;
        }, 100);
    }

    getCurrentUserId() {
        // Get current user ID from body data attribute
        return parseInt(document.body.dataset.userId);
    }

    formatTime(timestamp) {
        const date = new Date(timestamp);
        const now = new Date();
        const diffMs = now - date;
        const diffSec = Math.floor(diffMs / 1000);
        const diffMin = Math.floor(diffSec / 60);
        const diffHour = Math.floor(diffMin / 60);
        const diffDay = Math.floor(diffHour / 24);

        if (diffSec < 60) return window.APP_I18N.timeJustNow;
        if (diffMin < 60) return `${diffMin}${window.APP_I18N.timeMinutesAgo}`;
        if (diffHour < 24) return `${diffHour}${window.APP_I18N.timeHoursAgo}`;
        if (diffDay < 7) return `${diffDay}${window.APP_I18N.timeDaysAgo}`;

        // Format as date
        const currentLang = document.documentElement.lang || 'ko';
        const locale = currentLang === 'ko' ? 'ko-KR' : currentLang === 'ja' ? 'ja-JP' : 'en-US';
        return date.toLocaleDateString(locale, {
            month: 'short',
            day: 'numeric'
        });
    }

    getDefaultAvatar() {
        return 'data:image/svg+xml,' + encodeURIComponent(`
            <svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
                <circle cx="50" cy="35" r="20" fill="#4F46E5"/>
                <path d="M15 85 Q15 55 50 55 Q85 55 85 85 Z" fill="#4F46E5"/>
            </svg>
        `);
    }

    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    showError(message) {
        alert(message);
    }

    // ===== Action Modal Methods =====

    setupActionModal() {
        if (!this.actionModal) return;

        // Three-dot button opens action modal
        const chatActionsBtn = document.getElementById('chat-actions-btn');
        if (chatActionsBtn) {
            chatActionsBtn.addEventListener('click', () => {
                const userId = parseInt(chatActionsBtn.dataset.userId);
                const username = chatActionsBtn.dataset.username;
                this.openActionModal(userId, username);
            });
        }

        // Close button
        document.getElementById('close-message-action-modal')?.addEventListener('click', () => {
            this.closeActionModal();
        });

        // Action buttons (Block, Report)
        this.actionModal.addEventListener('click', (e) => {
            const actionBtn = e.target.closest('[data-action]');
            if (actionBtn) {
                const action = actionBtn.dataset.action;
                this.handleActionSelect(action);
            }
        });

        // Close on overlay click
        this.actionModal.addEventListener('click', (e) => {
            if (e.target === this.actionModal) {
                this.closeActionModal();
            }
        });

        // Close on ESC key
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && !this.actionModal.classList.contains('hidden')) {
                this.closeActionModal();
            }
        });
    }

    openActionModal(userId, username) {
        // Prevent self-actions
        const currentUserId = parseInt(document.body.dataset.userId);
        if (userId === currentUserId) {
            const lang = document.documentElement.lang || 'ko';
            const message = lang === 'en'
                ? 'You cannot perform actions on yourself'
                : '자기 자신에게는 작업을 수행할 수 없습니다';
            if (window.showAlert) {
                window.showAlert(message, 'error');
            } else {
                alert(message);
            }
            return;
        }

        this.currentReportedUserId = userId;
        this.currentReportedUsername = username;

        // Show modal
        this.actionModal.classList.remove('hidden');
        document.body.style.overflow = 'hidden';
    }

    closeActionModal() {
        this.actionModal.classList.add('hidden');
        document.body.style.overflow = '';
    }

    handleActionSelect(action) {
        this.closeActionModal();

        if (action === 'report') {
            this.openReportModal();
        } else if (action === 'block') {
            this.handleBlockUser();
        }
    }

    // ===== Report Modal Methods =====

    setupReportModal() {
        if (!this.reportModal) return;

        // Report type buttons
        document.querySelectorAll('#message-report-modal .report-type-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                const type = btn.dataset.type;
                this.handleReportTypeSelect(type);
            });
        });

        // Close buttons
        document.getElementById('close-message-report-modal')?.addEventListener('click', () => {
            this.closeReportModal();
        });

        document.getElementById('cancel-message-report-btn')?.addEventListener('click', () => {
            this.closeReportModal();
        });

        // Form submit
        document.getElementById('message-report-form')?.addEventListener('submit', (e) => {
            e.preventDefault();
            this.submitReport();
        });

        // Close on overlay click
        this.reportModal.addEventListener('click', (e) => {
            if (e.target === this.reportModal) {
                this.closeReportModal();
            }
        });

        // Close on ESC key
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && !this.reportModal.classList.contains('hidden')) {
                this.closeReportModal();
            }
        });
    }

    openReportModal() {
        // Reset form
        document.getElementById('message-report-form')?.reset();
        document.getElementById('message-report-type').value = '';
        this.selectedReportType = null;
        document.querySelectorAll('#message-report-modal .report-type-btn').forEach(btn => {
            btn.classList.remove('selected');
        });

        // Show modal
        this.reportModal.classList.remove('hidden');
        document.body.style.overflow = 'hidden';
    }

    closeReportModal() {
        this.reportModal.classList.add('hidden');
        document.body.style.overflow = '';
        this.currentReportedUserId = null;
        this.currentReportedUsername = null;
        this.selectedReportType = null;
    }

    handleReportTypeSelect(type) {
        this.selectedReportType = type;

        // Update visual state
        document.querySelectorAll('#message-report-modal .report-type-btn').forEach(btn => {
            if (btn.dataset.type === type) {
                btn.classList.add('selected');
            } else {
                btn.classList.remove('selected');
            }
        });

        // Set hidden input value
        document.getElementById('message-report-type').value = type;
    }

    async submitReport() {
        const reportType = document.getElementById('message-report-type').value;
        const description = document.getElementById('message-report-description').value;

        if (!reportType) {
            const lang = document.documentElement.lang || 'ko';
            const message = lang === 'en'
                ? 'Please select a report type'
                : '신고 유형을 선택해주세요';
            if (window.showAlert) {
                window.showAlert(message, 'error');
            } else {
                alert(message);
            }
            return;
        }

        if (!this.currentReportedUserId) {
            console.error('No user ID set for reporting');
            return;
        }

        try {
            const response = await fetch('/api/chat/report/', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRFToken': this.getCsrfToken()
                },
                body: JSON.stringify({
                    reported_user: this.currentReportedUserId,
                    report_type: reportType,
                    description: description || '',
                    conversation: this.conversationId
                })
            });

            if (response.ok) {
                const lang = document.documentElement.lang || 'ko';
                const message = lang === 'en'
                    ? 'Report submitted successfully'
                    : '신고가 접수되었습니다';
                if (window.showAlert) {
                    window.showAlert(message, 'success');
                } else {
                    alert(message);
                }
                this.closeReportModal();
            } else {
                const error = await response.json().catch(() => ({ error: 'Unknown error' }));
                const lang = document.documentElement.lang || 'ko';
                const message = lang === 'en'
                    ? `Report failed: ${error.error || 'Server error occurred'}`
                    : `신고 실패: ${error.error || '서버 오류가 발생했습니다'}`;
                if (window.showAlert) {
                    window.showAlert(message, 'error');
                } else {
                    alert(message);
                }
            }
        } catch (error) {
            console.error('Report submission error:', error);
            const lang = document.documentElement.lang || 'ko';
            const message = lang === 'en'
                ? 'Network error occurred. Please try again.'
                : '네트워크 오류가 발생했습니다. 다시 시도해주세요.';
            if (window.showAlert) {
                window.showAlert(message, 'error');
            } else {
                alert(message);
            }
        }
    }

    getCsrfToken() {
        // Try to get from cookie first
        const cookieValue = document.cookie
            .split('; ')
            .find(row => row.startsWith('csrftoken='))
            ?.split('=')[1];

        if (cookieValue) {
            return cookieValue;
        }

        // Fallback to hidden input
        return document.querySelector('[name=csrfmiddlewaretoken]')?.value || '';
    }

    // ===== Block User Methods =====

    setupBlockModal() {
        if (!this.blockModal) return;

        // Close button
        document.getElementById('close-block-user-modal')?.addEventListener('click', () => {
            this.closeBlockModal();
        });

        // Cancel button
        document.getElementById('cancel-block-user')?.addEventListener('click', () => {
            this.closeBlockModal();
        });

        // Confirm button
        document.getElementById('confirm-block-user')?.addEventListener('click', () => {
            this.confirmBlockUser();
        });

        // Close on overlay click
        this.blockModal.addEventListener('click', (e) => {
            if (e.target === this.blockModal) {
                this.closeBlockModal();
            }
        });

        // Close on ESC key
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && !this.blockModal.classList.contains('hidden')) {
                this.closeBlockModal();
            }
        });
    }

    handleBlockUser() {
        if (!this.currentReportedUserId) {
            console.error('No user ID set for blocking');
            return;
        }
        this.openBlockModal();
    }

    openBlockModal() {
        // Set username in modal
        const blockUserName = document.getElementById('block-user-name');
        const lang = document.documentElement.lang || 'ko';
        if (blockUserName) {
            blockUserName.textContent = lang === 'en'
                ? `Block ${this.currentReportedUsername}?`
                : `${this.currentReportedUsername}님을 차단하시겠습니까?`;
        }

        // Show modal
        this.blockModal.classList.remove('hidden');
        document.body.style.overflow = 'hidden';
    }

    closeBlockModal() {
        this.blockModal.classList.add('hidden');
        document.body.style.overflow = '';
    }

    async confirmBlockUser() {
        this.closeBlockModal();

        if (!this.currentReportedUsername) {
            console.error('No username set for blocking');
            return;
        }

        try {
            const response = await fetch(`/api/accounts/${this.currentReportedUsername}/block/`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRFToken': this.getCsrfToken()
                }
            });

            const lang = document.documentElement.lang || 'ko';
            if (response.ok) {
                const message = lang === 'en'
                    ? `${this.currentReportedUsername} has been blocked`
                    : `${this.currentReportedUsername}님을 차단했습니다`;
                if (window.showAlert) {
                    window.showAlert(message, 'success');
                } else {
                    alert(message);
                }
                window.location.href = '/messages/';
            } else {
                const error = await response.json().catch(() => ({ error: 'Unknown error' }));
                const message = lang === 'en'
                    ? `Block failed: ${error.error || 'Server error occurred'}`
                    : `차단 실패: ${error.error || '서버 오류가 발생했습니다'}`;
                if (window.showAlert) {
                    window.showAlert(message, 'error');
                } else {
                    alert(message);
                }
            }
        } catch (error) {
            console.error('Block user error:', error);
            const lang = document.documentElement.lang || 'ko';
            const message = lang === 'en'
                ? 'Network error occurred. Please try again.'
                : '네트워크 오류가 발생했습니다. 다시 시도해주세요.';
            if (window.showAlert) {
                window.showAlert(message, 'error');
            } else {
                alert(message);
            }
        }
    }

    // ==================== Leave Conversation Modal Methods ====================

    setupLeaveModal() {
        if (!this.leaveModal) return;

        // Close button
        if (this.closeLeaveModalBtn) {
            this.closeLeaveModalBtn.addEventListener('click', () => {
                this.closeLeaveModal();
            });
        }

        // Cancel button
        if (this.cancelLeaveBtn) {
            this.cancelLeaveBtn.addEventListener('click', () => {
                this.closeLeaveModal();
            });
        }

        // Confirm button
        if (this.confirmLeaveBtn) {
            this.confirmLeaveBtn.addEventListener('click', () => {
                this.confirmLeave();
            });
        }

        // Close on overlay click
        this.leaveModal.addEventListener('click', (e) => {
            if (e.target === this.leaveModal) {
                this.closeLeaveModal();
            }
        });

        // Close on ESC key
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && !this.leaveModal.classList.contains('hidden')) {
                this.closeLeaveModal();
            }
        });
    }

    openLeaveModal() {
        if (!this.leaveModal) return;

        this.leaveModal.classList.remove('hidden');
        document.body.style.overflow = 'hidden';
    }

    closeLeaveModal() {
        if (!this.leaveModal) return;

        this.leaveModal.classList.add('hidden');
        document.body.style.overflow = '';
    }

    async confirmLeave() {
        this.closeLeaveModal();

        try {
            const response = await fetch(`/messages/api/conversations/${this.conversationId}/leave/`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRFToken': this.getCsrfToken()
                },
                credentials: 'same-origin'
            });

            const lang = document.documentElement.lang || 'ko';
            if (response.ok) {
                const message = lang === 'en'
                    ? 'You have left the conversation'
                    : '대화방을 나갔습니다';
                if (window.showAlert) {
                    window.showAlert(message, 'success');
                }
                // Redirect to conversations list
                window.location.href = '/messages/';
            } else {
                const error = await response.json().catch(() => ({ error: 'Unknown error' }));
                const message = lang === 'en'
                    ? `Failed to leave: ${error.error || 'Server error occurred'}`
                    : `나가기 실패: ${error.error || '서버 오류가 발생했습니다'}`;
                if (window.showAlert) {
                    window.showAlert(message, 'error');
                } else {
                    alert(message);
                }
            }
        } catch (error) {
            console.error('Leave conversation error:', error);
            const lang = document.documentElement.lang || 'ko';
            const message = lang === 'en'
                ? 'Network error occurred. Please try again.'
                : '네트워크 오류가 발생했습니다. 다시 시도해주세요.';
            if (window.showAlert) {
                window.showAlert(message, 'error');
            } else {
                alert(message);
            }
        }
    }
}

// Initialize when DOM is ready
let conversationApp;
document.addEventListener('DOMContentLoaded', () => {
    // Get conversation ID from window variable set in template
    const conversationId = window.CONVERSATION_ID;
    if (conversationId) {
        conversationApp = new ConversationApp(conversationId);
    }
});

// Cleanup on page unload
window.addEventListener('beforeunload', () => {
    if (conversationApp) {
        conversationApp.closeWebSocket();
    }
});
