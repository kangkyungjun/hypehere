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
    const htmlLang = document.documentElement.lang;
    let lang = 'ko';
    if (htmlLang && htmlLang !== '') {
        const langLower = htmlLang.toLowerCase();
        if (['en', 'ja', 'es', 'ko'].includes(langLower)) {
            lang = langLower;
        }
    }

    // Time format dictionaries for all supported languages
    const timeFormats = {
        justNow: {
            'ko': '방금 전',
            'en': 'just now',
            'ja': 'たった今',
            'es': 'justo ahora'
        },
        minute: {
            'ko': (n) => `${n}분 전`,
            'en': (n) => `${n} minute${n > 1 ? 's' : ''} ago`,
            'ja': (n) => `${n}分前`,
            'es': (n) => `hace ${n} minuto${n > 1 ? 's' : ''}`
        },
        hour: {
            'ko': (n) => `${n}시간 전`,
            'en': (n) => `${n} hour${n > 1 ? 's' : ''} ago`,
            'ja': (n) => `${n}時間前`,
            'es': (n) => `hace ${n} hora${n > 1 ? 's' : ''}`
        },
        day: {
            'ko': (n) => `${n}일 전`,
            'en': (n) => `${n} day${n > 1 ? 's' : ''} ago`,
            'ja': (n) => `${n}日前`,
            'es': (n) => `hace ${n} día${n > 1 ? 's' : ''}`
        },
        week: {
            'ko': (n) => `${n}주 전`,
            'en': (n) => `${n} week${n > 1 ? 's' : ''} ago`,
            'ja': (n) => `${n}週間前`,
            'es': (n) => `hace ${n} semana${n > 1 ? 's' : ''}`
        },
        month: {
            'ko': (n) => `${n}개월 전`,
            'en': (n) => `${n} month${n > 1 ? 's' : ''} ago`,
            'ja': (n) => `${n}ヶ月前`,
            'es': (n) => `hace ${n} mes${n > 1 ? 'es' : ''}`
        },
        year: {
            'ko': (n) => `${n}년 전`,
            'en': (n) => `${n} year${n > 1 ? 's' : ''} ago`,
            'ja': (n) => `${n}年前`,
            'es': (n) => `hace ${n} año${n > 1 ? 's' : ''}`
        }
    };

    if (diffSec < 60) {
        return timeFormats.justNow[lang] || timeFormats.justNow['en'];
    } else if (diffMin < 60) {
        return timeFormats.minute[lang](diffMin);
    } else if (diffHour < 24) {
        return timeFormats.hour[lang](diffHour);
    } else if (diffDay < 7) {
        return timeFormats.day[lang](diffDay);
    } else if (diffWeek < 4) {
        return timeFormats.week[lang](diffWeek);
    } else if (diffMonth < 12) {
        return timeFormats.month[lang](diffMonth);
    } else {
        return timeFormats.year[lang](diffYear);
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
