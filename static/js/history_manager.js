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

            // Handle modal close
            if (state.modal) {
                const modal = document.getElementById(state.modal);
                if (modal && modal.classList.contains('show')) {
                    this.closeModal(modal, false); // Don't add to history
                }
            }

            // Handle post view modal
            if (state.type === 'post-view') {
                const postModal = document.getElementById('postViewModal');
                if (postModal && postModal.classList.contains('show')) {
                    this.closeModal(postModal, false);
                }
            }

            // Handle image viewer
            if (state.type === 'image-viewer') {
                const imageViewer = document.getElementById('imageViewerModal');
                if (imageViewer && imageViewer.classList.contains('show')) {
                    this.closeModal(imageViewer, false);
                }
            }

            // Handle create post modal
            if (state.type === 'create-post') {
                const createModal = document.getElementById('postCreateModal');
                if (createModal && createModal.classList.contains('show')) {
                    this.closeModal(createModal, false);
                }
            }

            // Handle any other modals
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

        // Intercept tab/view changes (for future SPA-like navigation)
        interceptTabChanges: function() {
            // Mobile navigation links
            const mobileNavLinks = document.querySelectorAll('.mobile-nav-link');
            mobileNavLinks.forEach(link => {
                // Don't intercept for now - let normal navigation work
                // This is for future SPA implementation
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
    // Add a dummy history entry on first load
    window.addEventListener('load', function() {
        // Check if we're on the main pages
        const isMainPage = ['/', '/home/', '/explore/'].some(path =>
            window.location.pathname === path || window.location.pathname.endsWith(path)
        );

        if (isMainPage) {
            // Add initial history entry to prevent immediate exit
            window.history.pushState({ page: 'home' }, '', window.location.href);
        }
    });

})();
