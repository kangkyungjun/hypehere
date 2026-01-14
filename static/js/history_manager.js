// HypeHere - History Management for Mobile Web App
// Prevents app from closing when back button is pressed

(function() {
    'use strict';

    const HistoryManager = {
        // Stack to track modal/state history
        stack: [],

        // Initialize history management
        init: function() {
            // Add initial state
            if (window.history.state === null) {
                window.history.replaceState({ page: 'initial' }, '', window.location.href);
            }

            // Listen for popstate (back/forward button)
            window.addEventListener('popstate', this.handlePopState.bind(this));

            // Intercept modal opens
            this.interceptModalOpens();

            // Intercept tab/view changes
            this.interceptTabChanges();

            console.log('[HistoryManager] Initialized');
        },

        // Handle browser back/forward button
        handlePopState: function(event) {
            console.log('[HistoryManager] popstate:', event.state);

            if (!event.state) {
                // No state = user trying to exit app
                // Push a new state to prevent exit
                window.history.pushState({ page: 'home' }, '', window.location.pathname);
                return;
            }

            const state = event.state;

            // Priority 1: Check if any modal is open - close it first
            const openModals = document.querySelectorAll('.modal.show');
            if (openModals.length > 0) {
                // If modal is open, close it and don't navigate
                if (state.modal) {
                    const modal = document.getElementById(state.modal);
                    if (modal && modal.classList.contains('show')) {
                        this.closeModal(modal, false);
                        return;
                    }
                }

                // Handle specific modal types
                if (state.type === 'post-view') {
                    const postModal = document.getElementById('postViewModal');
                    if (postModal && postModal.classList.contains('show')) {
                        this.closeModal(postModal, false);
                        return;
                    }
                }

                if (state.type === 'image-viewer') {
                    const imageViewer = document.getElementById('imageViewerModal');
                    if (imageViewer && imageViewer.classList.contains('show')) {
                        this.closeModal(imageViewer, false);
                        return;
                    }
                }

                if (state.type === 'create-post') {
                    const createModal = document.getElementById('postCreateModal');
                    if (createModal && createModal.classList.contains('show')) {
                        this.closeModal(createModal, false);
                        return;
                    }
                }

                // Close any remaining open modals
                this.closeAllModals(false);
                return;
            }

            // Priority 2: Handle page navigation
            if (state.page && state.page !== window.location.pathname) {
                // User pressed back to go to a different page
                // Allow normal navigation by reloading
                console.log('[HistoryManager] Navigating to:', state.page);
                window.location.href = state.page;
                return;
            }

            // Handle any other cases
            if (state.page === 'home' || state.page === 'initial') {
                this.closeAllModals(false);
            }
        },

        // Add state to history when opening modal
        pushModalState: function(modalId, type = 'modal') {
            const state = {
                modal: modalId,
                type: type,
                timestamp: Date.now()
            };

            // Push state to browser history
            window.history.pushState(state, '', window.location.href);

            // Add to internal stack
            this.stack.push(state);

            console.log('[HistoryManager] Pushed state:', state);
        },

        // Intercept modal open events
        interceptModalOpens: function() {
            const self = this;

            // Intercept all modal show events using MutationObserver
            const observer = new MutationObserver(function(mutations) {
                mutations.forEach(function(mutation) {
                    if (mutation.attributeName === 'class') {
                        const target = mutation.target;
                        if (target.classList.contains('modal') && target.classList.contains('show')) {
                            // Modal just opened
                            const modalId = target.id;
                            if (modalId && !self.isStateAlreadyPushed(modalId)) {
                                let type = 'modal';

                                // Determine modal type
                                if (modalId === 'postViewModal') type = 'post-view';
                                else if (modalId === 'postCreateModal') type = 'create-post';
                                else if (modalId === 'imageViewerModal') type = 'image-viewer';

                                self.pushModalState(modalId, type);
                            }
                        }
                    }
                });
            });

            // Observe all modals
            const modals = document.querySelectorAll('.modal');
            modals.forEach(function(modal) {
                observer.observe(modal, { attributes: true, attributeFilter: ['class'] });
            });
        },

        // Check if state already pushed (prevent duplicates)
        isStateAlreadyPushed: function(modalId) {
            if (this.stack.length === 0) return false;
            const lastState = this.stack[this.stack.length - 1];
            return lastState.modal === modalId && (Date.now() - lastState.timestamp) < 500;
        },

        // Intercept tab/view changes for app-like navigation
        interceptTabChanges: function() {
            const self = this;
            // Mobile navigation links
            const mobileNavLinks = document.querySelectorAll('.mobile-nav-link');

            mobileNavLinks.forEach(link => {
                link.addEventListener('click', function(e) {
                    const href = this.getAttribute('href');

                    // Skip if it's a hash link or empty
                    if (!href || href === '#' || href.startsWith('#')) {
                        return;
                    }

                    // Skip if it's the current page
                    if (href === window.location.pathname) {
                        e.preventDefault();
                        return;
                    }

                    // Don't intercept - let normal navigation work
                    // But ensure we add to history properly
                    const currentPath = window.location.pathname;

                    // Add current page to history stack if not already there
                    if (!window.history.state || window.history.state.page !== currentPath) {
                        window.history.replaceState({
                            page: currentPath,
                            timestamp: Date.now()
                        }, '', currentPath);
                    }

                    console.log('[HistoryManager] Navigation:', currentPath, '→', href);
                });
            });
        },

        // Close modal (with optional history management)
        closeModal: function(modal, addToHistory = true) {
            if (!modal) return;

            modal.classList.remove('show');
            document.body.style.overflow = '';

            // Remove from internal stack
            this.stack = this.stack.filter(s => s.modal !== modal.id);

            console.log('[HistoryManager] Closed modal:', modal.id);

            // Trigger modal close event for other scripts
            modal.dispatchEvent(new CustomEvent('modalClosed', {
                detail: { modalId: modal.id }
            }));
        },

        // Close all modals
        closeAllModals: function(addToHistory = true) {
            const modals = document.querySelectorAll('.modal.show');
            modals.forEach(modal => {
                this.closeModal(modal, false);
            });
            this.stack = [];
        },

        // Manually add state (for use by other scripts)
        pushState: function(state) {
            window.history.pushState(state, '', window.location.href);
        },

        // Go back programmatically
        goBack: function() {
            window.history.back();
        }
    };

    // Auto-initialize when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', function() {
            HistoryManager.init();
        });
    } else {
        HistoryManager.init();
    }

    // Expose to global scope
    window.HistoryManager = HistoryManager;

    // Prevent exit on initial back press
    // Add proper history state on first load
    window.addEventListener('load', function() {
        const currentPath = window.location.pathname;

        // Always set initial state with current page path
        if (!window.history.state || !window.history.state.page) {
            window.history.replaceState({
                page: currentPath,
                timestamp: Date.now()
            }, '', currentPath);

            // Add one more entry to prevent immediate exit
            window.history.pushState({
                page: currentPath,
                timestamp: Date.now()
            }, '', currentPath);

            console.log('[HistoryManager] Initial history state set for:', currentPath);
        }
    });

})();
