/**
 * Utility functions for HypeHere
 */

/**
 * Format timestamp to relative time with i18n support
 * Supports Korean and English based on current language setting
 * e.g., "방금 전" / "just now", "2분 전" / "2 minutes ago"
 */
function formatRelativeTime(timestamp) {
    const now = new Date();
    const past = new Date(timestamp);
    const diffMs = now - past;
    const diffSec = Math.floor(diffMs / 1000);
    const diffMin = Math.floor(diffSec / 60);
    const diffHour = Math.floor(diffMin / 60);
    const diffDay = Math.floor(diffHour / 24);
    const diffWeek = Math.floor(diffDay / 7);
    const diffMonth = Math.floor(diffDay / 30);
    const diffYear = Math.floor(diffDay / 365);

    // Get current language setting
    const lang = document.documentElement.lang || 'ko';

    if (diffSec < 60) {
        return lang === 'en' ? 'just now' : '방금 전';
    } else if (diffMin < 60) {
        return lang === 'en' ? `${diffMin} minute${diffMin > 1 ? 's' : ''} ago` : `${diffMin}분 전`;
    } else if (diffHour < 24) {
        return lang === 'en' ? `${diffHour} hour${diffHour > 1 ? 's' : ''} ago` : `${diffHour}시간 전`;
    } else if (diffDay < 7) {
        return lang === 'en' ? `${diffDay} day${diffDay > 1 ? 's' : ''} ago` : `${diffDay}일 전`;
    } else if (diffWeek < 4) {
        return lang === 'en' ? `${diffWeek} week${diffWeek > 1 ? 's' : ''} ago` : `${diffWeek}주 전`;
    } else if (diffMonth < 12) {
        return lang === 'en' ? `${diffMonth} month${diffMonth > 1 ? 's' : ''} ago` : `${diffMonth}개월 전`;
    } else {
        return lang === 'en' ? `${diffYear} year${diffYear > 1 ? 's' : ''} ago` : `${diffYear}년 전`;
    }
}

/**
 * Update all timestamps on the page
 */
function updateAllTimestamps() {
    const timeElements = document.querySelectorAll('.post-time[data-timestamp]');
    timeElements.forEach(element => {
        const timestamp = element.getAttribute('data-timestamp');
        element.textContent = formatRelativeTime(timestamp);
    });
}

// Update timestamps on page load
document.addEventListener('DOMContentLoaded', function() {
    updateAllTimestamps();
});

// Update timestamps every minute
setInterval(updateAllTimestamps, 60000);

/**
 * Get CSRF token from cookies
 * Required for Django CSRF protection
 */
function getCookie(name) {
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

// Expose getCookie to global scope for use in other scripts
window.getCookie = getCookie;
