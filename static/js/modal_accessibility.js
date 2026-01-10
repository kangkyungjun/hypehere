/**
 * HypeHere - Modal Accessibility Utilities
 * Provides ESC key handling and Focus Trap for all modals
 * WCAG 2.1 AA Compliance
 */

class ModalAccessibility {
    constructor() {
        this.activeModal = null;
        this.previousFocus = null;
        this.focusableSelectors = 'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])';
        this.init();
    }

    init() {
        // Global ESC key handler for all modals
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                this.handleEscapeKey();
            }
        });

        // Monitor modal open/close events
        this.observeModals();
    }

    /**
     * Handle ESC key press - close the topmost visible modal
     */
    handleEscapeKey() {
        const visibleModal = this.getTopmostVisibleModal();
        if (visibleModal) {
            this.closeModal(visibleModal);
        }
    }

    /**
     * Get the topmost (highest z-index) visible modal
     */
    getTopmostVisibleModal() {
        const allModals = document.querySelectorAll('.modal-overlay:not(.hidden)');
        if (allModals.length === 0) return null;
        if (allModals.length === 1) return allModals[0];

        // Find modal with highest z-index
        let topmostModal = null;
        let highestZIndex = -1;

        allModals.forEach(modal => {
            const zIndex = parseInt(window.getComputedStyle(modal).zIndex) || 0;
            if (zIndex > highestZIndex) {
                highestZIndex = zIndex;
                topmostModal = modal;
            }
        });

        return topmostModal;
    }

    /**
     * Close a modal by triggering its close button or mechanism
     */
    closeModal(modal) {
        // Try to find and click close button
        const closeBtn = modal.querySelector('.modal-close, [id$="-close"], [id^="close-"]');
        if (closeBtn) {
            closeBtn.click();
            return;
        }

        // Fallback: add hidden class
        modal.classList.add('hidden');

        // Restore focus to previous element
        if (this.previousFocus) {
            this.previousFocus.focus();
            this.previousFocus = null;
        }
    }

    /**
     * Setup Focus Trap for a modal
     * @param {HTMLElement} modal - The modal element
     */
    setupFocusTrap(modal) {
        if (!modal) return;

        const focusableElements = modal.querySelectorAll(this.focusableSelectors);
        const firstFocusable = focusableElements[0];
        const lastFocusable = focusableElements[focusableElements.length - 1];

        // Handle Tab key
        const handleTabKey = (e) => {
            if (e.key !== 'Tab') return;

            // If no focusable elements, prevent default
            if (focusableElements.length === 0) {
                e.preventDefault();
                return;
            }

            // Shift + Tab (backwards)
            if (e.shiftKey) {
                if (document.activeElement === firstFocusable) {
                    e.preventDefault();
                    lastFocusable.focus();
                }
            }
            // Tab (forwards)
            else {
                if (document.activeElement === lastFocusable) {
                    e.preventDefault();
                    firstFocusable.focus();
                }
            }
        };

        // Remove existing listener if any
        if (modal._focusTrapHandler) {
            modal.removeEventListener('keydown', modal._focusTrapHandler);
        }

        // Add new listener
        modal._focusTrapHandler = handleTabKey;
        modal.addEventListener('keydown', handleTabKey);

        // Focus first element when modal opens
        if (firstFocusable) {
            // Small delay to ensure modal is visible
            setTimeout(() => {
                firstFocusable.focus();
            }, 100);
        }
    }

    /**
     * Observe DOM for modal changes and setup focus trap automatically
     */
    observeModals() {
        // Use MutationObserver to detect when modals become visible
        const observer = new MutationObserver((mutations) => {
            mutations.forEach((mutation) => {
                if (mutation.type === 'attributes' && mutation.attributeName === 'class') {
                    const modal = mutation.target;

                    // Check if it's a modal that just became visible
                    if (modal.classList.contains('modal-overlay') && !modal.classList.contains('hidden')) {
                        // Save previous focus
                        this.previousFocus = document.activeElement;

                        // Setup focus trap
                        this.setupFocusTrap(modal);

                        // Set active modal
                        this.activeModal = modal;
                    }

                    // Modal just closed
                    if (modal.classList.contains('modal-overlay') && modal.classList.contains('hidden')) {
                        // Restore focus
                        if (this.previousFocus && modal === this.activeModal) {
                            this.previousFocus.focus();
                            this.previousFocus = null;
                            this.activeModal = null;
                        }
                    }
                }
            });
        });

        // Observe all modal overlays
        const observeModalsInDocument = () => {
            const modals = document.querySelectorAll('.modal-overlay');
            modals.forEach(modal => {
                observer.observe(modal, {
                    attributes: true,
                    attributeFilter: ['class']
                });
            });
        };

        // Initial observation
        observeModalsInDocument();

        // Re-observe when DOM changes (for dynamically added modals)
        const documentObserver = new MutationObserver(() => {
            observeModalsInDocument();
        });

        documentObserver.observe(document.body, {
            childList: true,
            subtree: true
        });
    }

    /**
     * Manually setup focus trap for a specific modal (for programmatic use)
     * @param {string} modalId - The modal ID
     */
    enableFocusTrap(modalId) {
        const modal = document.getElementById(modalId);
        if (modal) {
            this.previousFocus = document.activeElement;
            this.setupFocusTrap(modal);
        }
    }

    /**
     * Add ARIA attributes to a modal for screen readers
     * @param {string} modalId - The modal ID
     * @param {string} labelId - The ID of the element that labels the modal
     * @param {string} descId - The ID of the element that describes the modal
     */
    addAriaAttributes(modalId, labelId, descId) {
        const modal = document.getElementById(modalId);
        if (!modal) return;

        modal.setAttribute('role', 'dialog');
        modal.setAttribute('aria-modal', 'true');

        if (labelId) {
            modal.setAttribute('aria-labelledby', labelId);
        }

        if (descId) {
            modal.setAttribute('aria-describedby', descId);
        }
    }
}

// Initialize on DOM ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        window.modalAccessibility = new ModalAccessibility();
    });
} else {
    window.modalAccessibility = new ModalAccessibility();
}

// Export for use in other scripts
if (typeof module !== 'undefined' && module.exports) {
    module.exports = ModalAccessibility;
}
