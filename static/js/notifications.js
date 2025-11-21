/**
 * Notifications Page
 * Handles notification list display and real-time updates
 */

class NotificationsApp {
    constructor() {
        this.notifications = [];

        // DOM elements
        this.notificationsList = document.getElementById('notifications-list');
        this.markAllReadBtn = document.getElementById('mark-all-read-btn');

        this.init();
    }

    async init() {
        if (window.DEBUG) console.log('[Notifications] Initializing...');
        await this.loadNotifications();
        this.setupEventListeners();
        this.connectNotificationSocket();
        if (window.DEBUG) console.log('[Notifications] Initialization complete');
    }

    async loadNotifications() {
        try {
            const response = await fetch('/notifications/api/', {
                credentials: 'same-origin'
            });

            if (window.DEBUG) console.log('[Notifications] API Response status:', response.status);

            if (!response.ok) {
                console.error('[Notifications] Failed to load notifications:', response.status);
                return;
            }

            const data = await response.json();
            if (window.DEBUG) console.log('[Notifications] API response data:', data);

            // Handle paginated response (DRF returns {results: [...]})
            this.notifications = data.results || data;
            if (window.DEBUG) console.log('[Notifications] Loaded notifications:', this.notifications.length);

            this.renderNotificationsList();
            this.updateMarkAllReadButton();
        } catch (error) {
            console.error('[Notifications] Error loading notifications:', error);
            this.showError(window.NOTIFICATIONS_I18N.errorLoad);
        }
    }

    renderNotificationsList() {
        if (this.notifications.length === 0) {
            this.notificationsList.innerHTML = `
                <div class="empty-state">
                    <svg width="100" height="100" viewBox="0 0 100 100" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M50 20 C50 20, 30 30, 30 50 L30 70 L20 80 L80 80 L70 70 L70 50 C70 30, 50 20, 50 20"/>
                        <path d="M45 80 Q50 90, 55 80"/>
                    </svg>
                    <p>${window.NOTIFICATIONS_I18N.emptyState}</p>
                </div>
            `;
            return;
        }

        const notificationsHTML = this.notifications.map(notification =>
            this.createNotificationHTML(notification)
        ).join('');
        this.notificationsList.innerHTML = notificationsHTML;

        // Add click listeners
        this.notificationsList.querySelectorAll('.notification-item').forEach(item => {
            item.addEventListener('click', (e) => {
                const notificationId = parseInt(item.dataset.notificationId);
                const targetUrl = item.dataset.targetUrl;
                this.handleNotificationClick(notificationId, targetUrl);
            });
        });
    }

    createNotificationHTML(notification) {
        const sender = notification.sender;
        const readClass = notification.is_read ? 'read' : 'unread';

        // Default avatar
        const avatarSrc = sender?.profile_picture || this.getDefaultAvatar();

        // Notification badge (only show for unread)
        const badge = notification.is_read ? '' : '<div class="notification-badge"></div>';

        // Format time
        const timeStr = this.formatTime(notification.created_at);

        // Text preview (optional)
        const previewHTML = notification.text_preview ?
            `<div class="notification-preview">${this.escapeHtml(notification.text_preview)}</div>` : '';

        return `
            <a href="#" class="notification-item ${readClass}"
               data-notification-id="${notification.id}"
               data-target-url="${notification.target_url || '#'}">
                ${sender ?
                    `<img class="notification-avatar" src="${avatarSrc}" alt="${this.escapeHtml(sender.nickname)}">` :
                    `<div class="notification-avatar">
                        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
                            <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
                        </svg>
                    </div>`
                }
                <div class="notification-content">
                    <div class="notification-text">${this.escapeHtml(notification.notification_display)}</div>
                    ${previewHTML}
                    <div class="notification-time">${timeStr}</div>
                </div>
                ${badge}
            </a>
        `;
    }

    setupEventListeners() {
        // Mark all as read button
        this.markAllReadBtn.addEventListener('click', () => {
            this.markAllAsRead();
        });
    }

    async handleNotificationClick(notificationId, targetUrl) {
        if (window.DEBUG) console.log('[Notifications] Clicked notification:', notificationId);

        // Mark as read
        await this.markAsRead(notificationId);

        // Navigate to target URL
        if (targetUrl && targetUrl !== '#') {
            window.location.href = targetUrl;
        }
    }

    async markAsRead(notificationId) {
        try {
            const response = await fetch(`/notifications/api/${notificationId}/mark_read/`, {
                method: 'POST',
                credentials: 'same-origin',
                headers: {
                    'X-CSRFToken': this.getCookie('csrftoken'),
                    'Content-Type': 'application/json'
                }
            });

            if (response.ok) {
                if (window.DEBUG) console.log('[Notifications] Marked as read:', notificationId);

                // Update local state
                const notification = this.notifications.find(n => n.id === notificationId);
                if (notification) {
                    notification.is_read = true;
                }

                // Update UI
                const item = document.querySelector(`[data-notification-id="${notificationId}"]`);
                if (item) {
                    item.classList.remove('unread');
                    item.classList.add('read');

                    // Remove badge
                    const badge = item.querySelector('.notification-badge');
                    if (badge) {
                        badge.remove();
                    }
                }

                this.updateMarkAllReadButton();

                // Update header badge (if header_badge.js is loaded)
                if (window.headerBadge) {
                    window.headerBadge.updateNotificationBadge();
                }
            }
        } catch (error) {
            console.error('[Notifications] Error marking as read:', error);
        }
    }

    async markAllAsRead() {
        try {
            const response = await fetch('/notifications/api/mark_all_read/', {
                method: 'POST',
                credentials: 'same-origin',
                headers: {
                    'X-CSRFToken': this.getCookie('csrftoken'),
                    'Content-Type': 'application/json'
                }
            });

            if (response.ok) {
                if (window.DEBUG) console.log('[Notifications] All notifications marked as read');

                // Update local state
                this.notifications.forEach(notification => {
                    notification.is_read = true;
                });

                // Update UI
                document.querySelectorAll('.notification-item.unread').forEach(item => {
                    item.classList.remove('unread');
                    item.classList.add('read');

                    // Remove badge
                    const badge = item.querySelector('.notification-badge');
                    if (badge) {
                        badge.remove();
                    }
                });

                this.updateMarkAllReadButton();

                // Update header badge
                if (window.headerBadge) {
                    window.headerBadge.updateNotificationBadge();
                }
            }
        } catch (error) {
            console.error('[Notifications] Error marking all as read:', error);
            this.showError(window.NOTIFICATIONS_I18N.errorMarkRead);
        }
    }

    updateMarkAllReadButton() {
        const hasUnread = this.notifications.some(n => !n.is_read);
        this.markAllReadBtn.disabled = !hasUnread;
    }

    formatTime(timestamp) {
        const date = new Date(timestamp);
        const now = new Date();
        const diffMs = now - date;
        const diffSec = Math.floor(diffMs / 1000);
        const diffMin = Math.floor(diffSec / 60);
        const diffHour = Math.floor(diffMin / 60);
        const diffDay = Math.floor(diffHour / 24);

        if (diffSec < 60) return window.NOTIFICATIONS_I18N.timeJustNow;
        if (diffMin < 60) return `${diffMin}${window.NOTIFICATIONS_I18N.timeMinutesAgo}`;
        if (diffHour < 24) return `${diffHour}${window.NOTIFICATIONS_I18N.timeHoursAgo}`;
        if (diffDay < 7) return `${diffDay}${window.NOTIFICATIONS_I18N.timeDaysAgo}`;

        // Format as date
        return date.toLocaleDateString(window.NOTIFICATIONS_I18N.locale, {
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

    getCookie(name) {
        let cookieValue = null;
        if (document.cookie && document.cookie !== '') {
            const cookies = document.cookie.split(';');
            for (let i = 0; i < cookies.length; i++) {
                const cookie = cookies[i].trim();
                if (cookie.substring(0, name.length + 1) === (name + '=')) {
                    cookieValue = decodeURIComponent(cookie.substring(name.length + 1));
                    break;
                }
            }
        }
        return cookieValue;
    }

    showError(message) {
        alert(message);
    }

    // WebSocket notification handling
    connectNotificationSocket() {
        const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        const wsUrl = `${protocol}//${window.location.host}/ws/notifications/`;

        if (window.DEBUG) console.log('[Notifications] 🔌 Connecting to notification WebSocket:', wsUrl);
        this.notificationSocket = new WebSocket(wsUrl);

        this.notificationSocket.onopen = () => {
            if (window.DEBUG) console.log('[Notifications] ✅ Notification WebSocket connected');
        };

        this.notificationSocket.onmessage = (event) => {
            const data = JSON.parse(event.data);
            if (window.DEBUG) console.log('[Notifications] 📬 Received notification:', data);

            if (data.type === 'new_notification') {
                this.handleNewNotification(data);
            }
        };

        this.notificationSocket.onerror = (error) => {
            console.error('[Notifications] ❌ Notification WebSocket error:', error);
        };

        this.notificationSocket.onclose = (event) => {
            if (window.DEBUG) {
                console.log('[Notifications] ❌ Notification WebSocket closed');
                console.log('[Notifications] 🔄 Reconnecting in 5s...');
            }
            setTimeout(() => this.connectNotificationSocket(), 5000);
        };
    }

    handleNewNotification(data) {
        if (window.DEBUG) console.log('[Notifications] 📬 Handling new notification');

        // Reload notifications to get the latest
        this.loadNotifications();

        // Update header badge
        if (window.headerBadge) {
            window.headerBadge.updateNotificationBadge();
        }
    }
}

// Initialize when DOM is ready
let notificationsApp;
document.addEventListener('DOMContentLoaded', () => {
    notificationsApp = new NotificationsApp();
});
