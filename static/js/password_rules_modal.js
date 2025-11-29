/**
 * Password Rules Modal
 * Handles showing/hiding password rules modal when info icon is clicked
 */

const PasswordRulesModal = {
    modal: null,
    overlay: null,
    closeButton: null,
    okButton: null,
    triggerButton: null,

    init() {
        // Get modal elements
        this.modal = document.getElementById('password-rules-modal');
        this.overlay = this.modal;
        this.closeButton = document.getElementById('password-rules-modal-close');
        this.okButton = document.getElementById('password-rules-ok-btn');
        this.triggerButton = document.getElementById('password-rules-trigger');

        if (!this.modal || !this.triggerButton) {
            console.error('Password rules modal elements not found');
            return;
        }

        this.attachEventListeners();
    },

    attachEventListeners() {
        // Open modal when trigger button clicked
        this.triggerButton.addEventListener('click', (e) => {
            e.preventDefault();
            this.show();
        });

        // Close modal when close button clicked
        if (this.closeButton) {
            this.closeButton.addEventListener('click', () => {
                this.hide();
            });
        }

        // Close modal when OK button clicked
        if (this.okButton) {
            this.okButton.addEventListener('click', () => {
                this.hide();
            });
        }

        // Close modal when overlay clicked (outside modal)
        this.overlay.addEventListener('click', (e) => {
            if (e.target === this.overlay) {
                this.hide();
            }
        });

        // Close modal on Escape key
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && !this.modal.classList.contains('hidden')) {
                this.hide();
            }
        });
    },

    show() {
        this.modal.classList.remove('hidden');
        document.body.classList.add('password-rules-modal-open');

        // Focus the close button for accessibility
        if (this.closeButton) {
            setTimeout(() => {
                this.closeButton.focus();
            }, 100);
        }
    },

    hide() {
        this.modal.classList.add('hidden');
        document.body.classList.remove('password-rules-modal-open');

        // Return focus to trigger button
        if (this.triggerButton) {
            this.triggerButton.focus();
        }
    }
};

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    PasswordRulesModal.init();
});
