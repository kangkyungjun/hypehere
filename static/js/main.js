// HypeHere - Main JavaScript

document.addEventListener('DOMContentLoaded', function() {
    // Auto-hide messages after 5 seconds
    const messages = document.querySelectorAll('.alert');
    messages.forEach(function(message) {
        setTimeout(function() {
            message.style.transition = 'opacity 0.3s ease';
            message.style.opacity = '0';
            setTimeout(function() {
                message.remove();
            }, 300);
        }, 5000);
    });

    // Modal functionality
    const modalTriggers = document.querySelectorAll('[data-modal-target]');
    const modals = document.querySelectorAll('.modal');
    const modalCloses = document.querySelectorAll('.modal-close, .modal-backdrop');

    modalTriggers.forEach(function(trigger) {
        trigger.addEventListener('click', function(e) {
            e.preventDefault();
            const targetId = this.getAttribute('data-modal-target');
            const modal = document.getElementById(targetId);
            if (modal) {
                modal.classList.add('show');
                document.body.style.overflow = 'hidden';
            }
        });
    });

    modalCloses.forEach(function(close) {
        close.addEventListener('click', function() {
            modals.forEach(function(modal) {
                modal.classList.remove('show');
            });
            document.body.style.overflow = '';
        });
    });

    // Close modal on Escape key
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
            modals.forEach(function(modal) {
                modal.classList.remove('show');
            });
            document.body.style.overflow = '';
        }
    });
});

// Fetch API helper
async function apiRequest(url, options = {}) {
    const defaultOptions = {
        headers: {
            'Content-Type': 'application/json',
            'X-CSRFToken': getCookie('csrftoken')
        },
        ...options
    };

    try {
        const response = await fetch(url, defaultOptions);
        const data = await response.json();

        if (!response.ok) {
            throw new Error(data.message || 'An error occurred');
        }

        return data;
    } catch (error) {
        console.error('API Error:', error);
        throw error;
    }
}

// Get CSRF token from cookies
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

// Show loading spinner
function showLoading(button) {
    const originalText = button.innerHTML;
    button.disabled = true;
    button.innerHTML = '<span class="spinner"></span> 처리 중...';
    return originalText;
}

// Hide loading spinner
function hideLoading(button, originalText) {
    button.disabled = false;
    button.innerHTML = originalText;
}

// Show alert message
function showAlert(message, type = 'info') {
    const alertHTML = `
        <div class="alert alert-${type}">
            ${message}
        </div>
    `;

    const messagesContainer = document.querySelector('.messages-container') || createMessagesContainer();
    messagesContainer.insertAdjacentHTML('beforeend', alertHTML);

    // Auto-hide after 5 seconds
    const alert = messagesContainer.lastElementChild;
    setTimeout(function() {
        alert.style.transition = 'opacity 0.3s ease';
        alert.style.opacity = '0';
        setTimeout(function() {
            alert.remove();
        }, 300);
    }, 5000);
}

function createMessagesContainer() {
    const container = document.createElement('div');
    container.className = 'messages-container';
    const mainContent = document.querySelector('.main-content');
    mainContent.insertBefore(container, mainContent.firstChild);
    return container;
}

// Export functions for global use
window.HypeHere = {
    apiRequest,
    showLoading,
    hideLoading,
    showAlert,
    getCookie
};
