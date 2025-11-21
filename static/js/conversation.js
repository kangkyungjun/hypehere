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

        this.init();
    }

    async init() {
        console.log('[Conversation] Initializing for conversation:', this.conversationId);
        await this.loadConversationDetails();
        this.setupEventListeners();
        this.setupAutoResize();
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
        const isSent = message.sender === currentUserId;
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
            sender: messageData.sender_id,
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

        if (diffSec < 60) return '방금 전';
        if (diffMin < 60) return `${diffMin}분 전`;
        if (diffHour < 24) return `${diffHour}시간 전`;
        if (diffDay < 7) return `${diffDay}일 전`;

        // Format as date
        return date.toLocaleDateString('ko-KR', {
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
