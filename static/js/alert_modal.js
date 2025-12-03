/**
 * Generic Alert Modal System
 * Displays notifications with different types (success, error, warning, info)
 */

class AlertModal {
    constructor() {
        this.modal = document.getElementById('alert-modal');
        this.icon = document.getElementById('alert-icon');
        this.title = document.getElementById('alert-modal-title');
        this.message = document.getElementById('alert-message');
        this.okBtn = document.getElementById('alert-ok-btn');

        this.init();
    }

    init() {
        if (!this.modal) return;

        // OK button click
        this.okBtn.addEventListener('click', () => this.close());

        // ESC key
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && !this.modal.classList.contains('hidden')) {
                this.close();
            }
        });

        // Click outside to close
        this.modal.addEventListener('click', (e) => {
            if (e.target === this.modal) {
                this.close();
            }
        });
    }

    /**
     * Show alert modal
     * @param {string} message - Message to display
     * @param {string} type - Alert type: 'success', 'error', 'warning', 'info'
     * @param {Object} options - Additional options
     * @param {string} options.title - Custom title (default based on type)
     * @param {number} options.autoDismiss - Auto-dismiss after milliseconds (0 = disabled)
     */
    show(message, type = 'info', options = {}) {
        if (!this.modal) return;

        // Clear previous type classes
        this.modal.classList.remove('alert-success', 'alert-error', 'alert-warning', 'alert-info');

        // Add new type class
        this.modal.classList.add(`alert-${type}`);

        // Set icon based on type
        const icons = {
            success: '✓',
            error: '✕',
            warning: '⚠',
            info: 'ℹ'
        };
        this.icon.textContent = icons[type] || icons.info;

        // Set title (if title element exists)
        if (this.title) {
            const defaultTitles = {
                success: 'Success',
                error: 'Error',
                warning: 'Warning',
                info: 'Notification'
            };
            this.title.textContent = options.title || defaultTitles[type] || defaultTitles.info;
        }

        // Set message
        this.message.textContent = message;

        // Show modal
        this.modal.classList.remove('hidden');
        document.body.classList.add('alert-modal-open');

        // Auto-dismiss if specified
        if (options.autoDismiss && options.autoDismiss > 0) {
            setTimeout(() => this.close(), options.autoDismiss);
        }
    }

    close() {
        if (!this.modal) return;

        this.modal.classList.add('hidden');
        document.body.classList.remove('alert-modal-open');
    }
}

// Initialize on page load
let alertModalInstance;
document.addEventListener('DOMContentLoaded', () => {
    alertModalInstance = new AlertModal();
});

// Global function for easy access
window.showAlert = function(message, type = 'info', options = {}) {
    if (alertModalInstance) {
        alertModalInstance.show(message, type, options);
    }
};
