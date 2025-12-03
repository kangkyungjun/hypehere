/**
 * Header Badge Manager
 * Handles real-time unread message and notification count display in header
 * Works across all pages for authenticated users
 */

class HeaderBadgeManager {
    constructor() {
        this.messagesBadge = document.getElementById('header-messages-badge');
        this.notificationsBadge = document.getElementById('header-notifications-badge');
        this.notificationSocket = null;

        if (!this.messagesBadge && !this.notificationsBadge) {
            console.warn('[HeaderBadge] No badge elements found in DOM');
            return;
        }

        this.init();
    }

    async init() {
        if (window.DEBUG) console.log('[HeaderBadge] Initializing header badge manager...');

        // Load initial badge counts from API
        await this.updateMessageBadge();
        await this.updateNotificationBadge();

        // Connect to notification WebSocket for real-time updates
        this.connectNotificationSocket();

        if (window.DEBUG) console.log('[HeaderBadge] Initialization complete');
    }

    async updateMessageBadge(retryCount = 0) {
        try {
            const response = await fetch('/api/chat/unread-count/', {
                credentials: 'same-origin'
            });

            if (!response.ok) {
                console.error('[HeaderBadge] Failed to load unread message count:', response.status);

                // Retry logic for server errors (5xx) or rate limiting (429)
                if (retryCount < 3 && (response.status >= 500 || response.status === 429)) {
                    const delay = 1000 * (retryCount + 1); // 1s, 2s, 3s
                    if (window.DEBUG) console.log(`[HeaderBadge] Retrying in ${delay}ms... (${retryCount + 1}/3)`);
                    setTimeout(() => this.updateMessageBadge(retryCount + 1), delay);
                }
                return;
            }

            const data = await response.json();
            if (window.DEBUG) console.log('[HeaderBadge] Loaded unread message count:', data.total_unread_count);

            this.updateBadge(this.messagesBadge, data.total_unread_count);

        } catch (error) {
            console.error('[HeaderBadge] Error loading unread message count:', error);

            // Retry on network errors
            if (retryCount < 3) {
                const delay = 1000 * (retryCount + 1); // 1s, 2s, 3s
                if (window.DEBUG) console.log(`[HeaderBadge] Retrying after error in ${delay}ms... (${retryCount + 1}/3)`);
                setTimeout(() => this.updateMessageBadge(retryCount + 1), delay);
            }
        }
    }

    async updateNotificationBadge(retryCount = 0) {
        try {
            const response = await fetch('/notifications/api/unread_count/', {
                credentials: 'same-origin'
            });

            if (!response.ok) {
                console.error('[HeaderBadge] Failed to load unread notification count:', response.status);

                // Retry logic for server errors (5xx) or rate limiting (429)
                if (retryCount < 3 && (response.status >= 500 || response.status === 429)) {
                    const delay = 1000 * (retryCount + 1); // 1s, 2s, 3s
                    if (window.DEBUG) console.log(`[HeaderBadge] Retrying in ${delay}ms... (${retryCount + 1}/3)`);
                    setTimeout(() => this.updateNotificationBadge(retryCount + 1), delay);
                }
                return;
            }

            const data = await response.json();
            if (window.DEBUG) console.log('[HeaderBadge] Loaded unread notification count:', data.unread_count);

            this.updateBadge(this.notificationsBadge, data.unread_count);

        } catch (error) {
            console.error('[HeaderBadge] Error loading unread notification count:', error);

            // Retry on network errors
            if (retryCount < 3) {
                const delay = 1000 * (retryCount + 1); // 1s, 2s, 3s
                if (window.DEBUG) console.log(`[HeaderBadge] Retrying after error in ${delay}ms... (${retryCount + 1}/3)`);
                setTimeout(() => this.updateNotificationBadge(retryCount + 1), delay);
            }
        }
    }

    updateBadge(badge, count) {
        if (!badge) return;

        if (window.DEBUG) console.log('[HeaderBadge] Updating badge count:', count);

        if (count > 0) {
            // Display badge with count (show "99+" for counts > 99)
            badge.textContent = count > 99 ? '99+' : count;
            badge.classList.remove('hidden');
            if (window.DEBUG) console.log('[HeaderBadge] Badge visible with count:', badge.textContent);
        } else {
            // Hide badge when no unread items
            badge.classList.add('hidden');
            if (window.DEBUG) console.log('[HeaderBadge] Badge hidden (no unread items)');
        }
    }

    connectNotificationSocket() {
        const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        const wsUrl = `${protocol}//${window.location.host}/ws/notifications/`;

        if (window.DEBUG) console.log('[HeaderBadge] Connecting to notification WebSocket:', wsUrl);
        this.notificationSocket = new WebSocket(wsUrl);

        this.notificationSocket.onopen = () => {
            if (window.DEBUG) {
                console.log('[HeaderBadge] ✅ WebSocket connected');
                console.log('[HeaderBadge]   ReadyState:', this.notificationSocket.readyState);
            }
        };

        this.notificationSocket.onmessage = (event) => {
            const data = JSON.parse(event.data);
            if (window.DEBUG) console.log('[HeaderBadge] 📬 Received notification:', data);

            if (data.type === 'new_message') {
                // Reload message count when new message arrives
                if (window.DEBUG) console.log('[HeaderBadge] New message detected, reloading message count...');
                this.updateMessageBadge();
            } else if (data.type === 'new_notification') {
                // Reload notification count when new notification arrives
                if (window.DEBUG) console.log('[HeaderBadge] New notification detected, reloading notification count...');
                this.updateNotificationBadge();
            }
        };

        this.notificationSocket.onerror = (error) => {
            console.error('[HeaderBadge] ❌ WebSocket error:', error);
        };

        this.notificationSocket.onclose = (event) => {
            if (window.DEBUG) {
                console.log('[HeaderBadge] ❌ WebSocket closed');
                console.log('[HeaderBadge]   Code:', event.code, 'Reason:', event.reason);
                console.log('[HeaderBadge]   Was clean:', event.wasClean);
                console.log('[HeaderBadge] 🔄 Reconnecting in 5s...');
            }

            // Auto-reconnect after 5 seconds and refresh badges
            setTimeout(() => {
                this.connectNotificationSocket();
                // 재연결 성공 시 배지 즉시 업데이트 (누락된 알림 복구)
                if (window.DEBUG) console.log('[HeaderBadge] 🔄 Refreshing badges after reconnection...');
                this.updateMessageBadge();
                this.updateNotificationBadge();
            }, 5000);
        };
    }
}

// Initialize when DOM is ready (only for authenticated users)
// Make it globally accessible for other scripts (like notifications.js)
window.headerBadge = null;

document.addEventListener('DOMContentLoaded', () => {
    if (window.DEBUG) {
        console.log('[HeaderBadge] 📋 Script loaded - initializing...');
        console.log('[HeaderBadge] 👤 User ID:', document.body.dataset.userId);
    }

    // Note: Authentication check is already done in base.html template
    // This script is only loaded for authenticated users
    window.headerBadge = new HeaderBadgeManager();

    if (window.DEBUG) console.log('[HeaderBadge] ✅ Initialization complete');
});
