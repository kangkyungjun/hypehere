/**
 * Messages List Page
 * Handles conversation list display and navigation
 */

class MessagesApp {
    constructor() {
        this.conversations = [];

        // DOM elements
        this.conversationsList = document.getElementById('conversations-list');

        this.init();
    }

    async init() {
        if (window.DEBUG) console.log('[Messages] Initializing...');
        await this.loadConversations();
        this.connectNotificationSocket();
        if (window.DEBUG) console.log('[Messages] Initialization complete');
    }

    async loadConversations() {
        try {
            const response = await fetch('/messages/api/conversations/', {
                credentials: 'same-origin'
            });

            if (window.DEBUG) console.log('[DEBUG] API Response status:', response.status);

            if (!response.ok) {
                console.error('[Messages] Failed to load conversations:', response.status);
                return;
            }

            const data = await response.json();
            if (window.DEBUG) console.log('[DEBUG] API response data:', data);

            // Handle paginated response (DRF returns {results: [...]})
            this.conversations = data.results || data;
            if (window.DEBUG) console.log('[DEBUG] Conversations array:', this.conversations);

            // 각 대화의 unread_count 출력
            if (window.DEBUG) {
                console.log('[DEBUG] 📊 Conversation Details:');
                this.conversations.forEach((conv, index) => {
                    console.log(`[DEBUG]   [${index}] Conversation ID: ${conv.id}`);
                    console.log(`[DEBUG]   [${index}] Other user: ${conv.other_user?.nickname || 'Unknown'}`);
                    console.log(`[DEBUG]   [${index}] Unread count: ${conv.unread_count}`);
                    console.log(`[DEBUG]   [${index}] Last message: ${conv.last_message?.content || 'None'}`);
                });
            }

            this.renderConversationsList();
        } catch (error) {
            console.error('[Messages] Error loading conversations:', error);
        }
    }

    renderConversationsList() {
        if (this.conversations.length === 0) {
            this.conversationsList.innerHTML = `
                <div class="empty-state">
                    <svg width="100" height="100" viewBox="0 0 100 100" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M85 25H15C10 25 5 30 5 35V65C5 70 10 75 15 75H25L35 85V75H85C90 75 95 70 95 65V35C95 30 90 25 85 25Z"/>
                        <circle cx="30" cy="45" r="3"/>
                        <circle cx="50" cy="45" r="3"/>
                        <circle cx="70" cy="45" r="3"/>
                    </svg>
                    <p>메시지가 없습니다</p>
                </div>
            `;
            return;
        }

        const conversationsHTML = this.conversations.map(conv => this.createConversationHTML(conv)).join('');
        this.conversationsList.innerHTML = conversationsHTML;

        // 렌더링 후 badge 확인
        if (window.DEBUG) {
            console.log('[DEBUG] 🔍 Checking rendered badges:');
            const badges = document.querySelectorAll('.unread-badge');
            console.log(`[DEBUG]   Found ${badges.length} badge(s) in DOM`);
            badges.forEach((badge, index) => {
                console.log(`[DEBUG]   Badge ${index}: text="${badge.textContent}", display="${window.getComputedStyle(badge).display}"`);
            });
        }

        // Add click listeners - navigate to conversation detail page
        this.conversationsList.querySelectorAll('.conversation-item').forEach(item => {
            item.addEventListener('click', () => {
                const conversationId = parseInt(item.dataset.conversationId);
                window.location.href = `/messages/${conversationId}/`;
            });
        });
    }

    createConversationHTML(conversation) {
        const otherUser = conversation.other_user;

        // Null check for other_user
        if (!otherUser) {
            console.error('[DEBUG] Conversation missing other_user:', conversation);
            return '';
        }

        const lastMessage = conversation.last_message;
        const unreadCount = conversation.unread_count;

        // Badge 생성 로그
        if (window.DEBUG) {
            console.log(`[DEBUG] 🎨 Creating conversation HTML for ID: ${conversation.id}`);
            console.log(`[DEBUG]   Unread count: ${unreadCount}`);
            console.log(`[DEBUG]   Will create badge: ${unreadCount > 0}`);
        }

        // Default avatar
        const avatarSrc = otherUser.profile_picture || this.getDefaultAvatar();

        // Format time
        const timeStr = lastMessage ? this.formatTime(lastMessage.created_at) : '';

        // Last message preview
        const lastMessagePreview = lastMessage ? this.escapeHtml(lastMessage.content) : '대화를 시작하세요';

        // Unread badge - inline style ensures visibility on initial render
        const unreadBadge = unreadCount > 0 ? `<span class="unread-badge" style="display: inline-flex;">${unreadCount}</span>` : '';

        return `
            <div class="conversation-item" data-conversation-id="${conversation.id}">
                <img class="conversation-avatar" src="${avatarSrc}" alt="${this.escapeHtml(otherUser.nickname)}">
                <div class="conversation-info">
                    <div class="conversation-header">
                        <span class="conversation-nickname">${this.escapeHtml(otherUser.nickname)}</span>
                        <span class="conversation-time">${timeStr}</span>
                    </div>
                    <div class="conversation-last-message">
                        <span>${lastMessagePreview}</span>
                        ${unreadBadge}
                    </div>
                </div>
            </div>
        `;
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

    // WebSocket notification handling
    connectNotificationSocket() {
        const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        const wsUrl = `${protocol}//${window.location.host}/ws/notifications/`;

        if (window.DEBUG) console.log('[Messages] 🔌 Connecting to notification WebSocket:', wsUrl);
        this.notificationSocket = new WebSocket(wsUrl);

        this.notificationSocket.onopen = () => {
            if (window.DEBUG) {
                console.log('[Messages] ✅ Notification WebSocket connected');
                console.log('[Messages]   ReadyState:', this.notificationSocket.readyState);
            }
        };

        this.notificationSocket.onmessage = (event) => {
            const data = JSON.parse(event.data);
            if (window.DEBUG) console.log('[Messages] 📬 Received notification:', data);

            if (data.type === 'new_message') {
                this.handleNewMessageNotification(data);
            }
        };

        this.notificationSocket.onerror = (error) => {
            console.error('[Messages] ❌ Notification WebSocket error:', error);
        };

        this.notificationSocket.onclose = (event) => {
            if (window.DEBUG) {
                console.log('[Messages] ❌ Notification WebSocket closed');
                console.log('[Messages]   Code:', event.code, 'Reason:', event.reason);
                console.log('[Messages]   Was clean:', event.wasClean);
                console.log('[Messages] 🔄 Reconnecting in 5s...');
            }
            setTimeout(() => this.connectNotificationSocket(), 5000);
        };
    }

    handleNewMessageNotification(data) {
        const conversationId = data.conversation_id;
        const unreadCount = data.unread_count;

        if (window.DEBUG) {
            console.log('[Messages] 📬 Handling new message notification');
            console.log('[Messages]   Conversation ID:', conversationId);
            console.log('[Messages]   Unread count:', unreadCount);
            console.log('[Messages]   Sender:', data.sender);
        }

        // 해당 대화의 카드 찾기
        const conversationCard = document.querySelector(`[data-conversation-id="${conversationId}"]`);
        if (window.DEBUG) console.log('[Messages]   Found card:', !!conversationCard);

        if (conversationCard) {
            // 뱃지 업데이트
            this.updateConversationBadge(conversationCard, unreadCount);

            // 마지막 메시지 업데이트
            this.updateLastMessage(conversationCard, data.last_message);

            // 대화를 리스트 맨 위로 이동
            this.moveConversationToTop(conversationCard);

            // 시각적 효과 (하이라이트)
            this.highlightConversation(conversationCard);
        } else {
            // 대화가 리스트에 없으면 전체 리스트 새로고침
            if (window.DEBUG) console.log('[Messages]   Card not found, reloading list...');
            this.loadConversations();
        }
    }

    updateConversationBadge(conversationCard, unreadCount) {
        if (window.DEBUG) {
            console.log('[Messages] 🔔 Updating badge');
            console.log('[Messages]   Unread count:', unreadCount);
        }

        const lastMessageDiv = conversationCard.querySelector('.conversation-last-message');
        if (window.DEBUG) console.log('[Messages]   Found lastMessageDiv:', !!lastMessageDiv);

        if (!lastMessageDiv) {
            console.error('[Messages]   ❌ lastMessageDiv not found!');
            return;
        }

        let badge = lastMessageDiv.querySelector('.unread-badge');
        if (window.DEBUG) console.log('[Messages]   Existing badge:', !!badge);

        if (unreadCount > 0) {
            if (!badge) {
                if (window.DEBUG) console.log('[Messages]   Creating new badge');
                // 뱃지 생성
                badge = document.createElement('span');
                badge.className = 'unread-badge';
                lastMessageDiv.appendChild(badge);
            }
            badge.textContent = unreadCount;
            badge.style.display = 'inline-flex'; // 강제 표시

            if (window.DEBUG) {
                console.log('[Messages]   ✅ Badge updated:', badge.textContent);
                console.log('[Messages]   Badge display:', window.getComputedStyle(badge).display);
                console.log('[Messages]   Badge visibility:', window.getComputedStyle(badge).visibility);
                console.log('[Messages]   Badge background:', window.getComputedStyle(badge).backgroundColor);
            }
        } else {
            // 뱃지 제거
            if (badge) {
                if (window.DEBUG) console.log('[Messages]   Removing badge (count = 0)');
                badge.remove();
            }
        }
    }

    updateLastMessage(conversationCard, lastMessage) {
        const lastMessageDiv = conversationCard.querySelector('.conversation-last-message span');
        if (lastMessageDiv && lastMessage) {
            lastMessageDiv.textContent = this.escapeHtml(lastMessage.content);
        }

        // 시간 업데이트
        const timeSpan = conversationCard.querySelector('.conversation-time');
        if (timeSpan && lastMessage) {
            timeSpan.textContent = this.formatTime(lastMessage.created_at);
        }
    }

    moveConversationToTop(conversationCard) {
        const list = conversationCard.parentElement;
        list.insertBefore(conversationCard, list.firstChild);
    }

    highlightConversation(conversationCard) {
        conversationCard.classList.add('new-message-highlight');
        setTimeout(() => {
            conversationCard.classList.remove('new-message-highlight');
        }, 2000);
    }
}

// Initialize when DOM is ready
let messagesApp;
document.addEventListener('DOMContentLoaded', () => {
    messagesApp = new MessagesApp();
});
