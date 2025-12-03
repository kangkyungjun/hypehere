/**
 * Post Interaction Tracker
 * Tracks user interactions with posts for recommendation system
 * - View tracking (IntersectionObserver)
 * - Click tracking
 * - Scroll depth tracking
 * - Dwell time tracking
 */

class PostInteractionTracker {
    constructor() {
        this.viewedPosts = new Set();  // Track which posts have been viewed
        this.dwellTimers = new Map();   // Track dwell time per post
        this.scrollDepths = new Map();  // Track max scroll depth per post
        this.batchQueue = [];           // Queue for batched API calls
        this.batchTimeout = null;
        this.batchDelay = 2000;         // Send batch every 2 seconds

        this.initViewObserver();
        this.initClickTracking();
        this.initScrollTracking();
        this.initBeforeUnload();
    }

    /**
     * Initialize IntersectionObserver for view tracking
     */
    initViewObserver() {
        const options = {
            root: null,
            rootMargin: '0px',
            threshold: 0.5  // Post must be 50% visible
        };

        this.viewObserver = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                const postCard = entry.target;
                const postId = this.getPostId(postCard);

                if (!postId) return;

                if (entry.isIntersecting) {
                    // Post entered viewport
                    if (!this.viewedPosts.has(postId)) {
                        this.viewedPosts.add(postId);
                        this.logInteraction(postId, 'view');
                    }

                    // Start dwell timer
                    this.startDwellTimer(postId);
                } else {
                    // Post left viewport
                    this.stopDwellTimer(postId);
                }
            });
        }, options);

        // Observe all post cards
        this.observePostCards();
    }

    /**
     * Find and observe all post cards on the page
     */
    observePostCards() {
        const postCards = document.querySelectorAll('.post-card, [data-post-id]');
        postCards.forEach(card => {
            this.viewObserver.observe(card);
        });
    }

    /**
     * Initialize click tracking on posts
     */
    initClickTracking() {
        document.addEventListener('click', (e) => {
            // Find closest post card
            const postCard = e.target.closest('.post-card, [data-post-id]');
            if (!postCard) return;

            const postId = this.getPostId(postCard);
            if (!postId) return;

            // Determine click target
            const clickTarget = this.getClickTarget(e.target);

            // Log appropriate interaction type
            if (clickTarget === 'like') {
                // Like is handled separately by existing like button code
                return;
            } else if (clickTarget === 'comment') {
                this.logInteraction(postId, 'comment');
            } else if (clickTarget === 'favorite') {
                // Favorite is handled separately
                return;
            } else {
                // General post click
                this.logInteraction(postId, 'click');
            }
        });
    }

    /**
     * Determine what element was clicked within post
     */
    getClickTarget(element) {
        if (element.closest('.like-btn, [data-action="like"]')) {
            return 'like';
        }
        if (element.closest('.comment-btn, [data-action="comment"]')) {
            return 'comment';
        }
        if (element.closest('.favorite-btn, [data-action="favorite"]')) {
            return 'favorite';
        }
        return 'general';
    }

    /**
     * Initialize scroll depth tracking for modal posts
     */
    initScrollTracking() {
        // Track scroll within post modals
        const postModals = document.querySelectorAll('.post-modal, .post-view-modal');

        postModals.forEach(modal => {
            const content = modal.querySelector('.post-content, .modal-body');
            if (!content) return;

            content.addEventListener('scroll', (e) => {
                const postId = this.getPostId(modal);
                if (!postId) return;

                const scrollDepth = this.calculateScrollDepth(content);

                // Update max scroll depth
                const currentMax = this.scrollDepths.get(postId) || 0;
                if (scrollDepth > currentMax) {
                    this.scrollDepths.set(postId, scrollDepth);
                }
            });
        });
    }

    /**
     * Calculate scroll depth percentage
     */
    calculateScrollDepth(element) {
        const scrollTop = element.scrollTop;
        const scrollHeight = element.scrollHeight;
        const clientHeight = element.clientHeight;

        if (scrollHeight === clientHeight) return 100;

        const depth = (scrollTop / (scrollHeight - clientHeight)) * 100;
        return Math.min(Math.round(depth), 100);
    }

    /**
     * Start dwell timer for a post
     */
    startDwellTimer(postId) {
        if (this.dwellTimers.has(postId)) return;  // Already running

        const startTime = Date.now();
        this.dwellTimers.set(postId, startTime);
    }

    /**
     * Stop dwell timer and log dwell time
     */
    stopDwellTimer(postId) {
        const startTime = this.dwellTimers.get(postId);
        if (!startTime) return;

        const dwellTime = (Date.now() - startTime) / 1000;  // Convert to seconds
        this.dwellTimers.delete(postId);

        // Only log if user spent more than 1 second
        if (dwellTime >= 1) {
            const scrollDepth = this.scrollDepths.get(postId) || 0;
            this.logInteraction(postId, 'view', {
                dwell_time: dwellTime,
                scroll_depth: scrollDepth
            });
        }
    }

    /**
     * Get post ID from element
     */
    getPostId(element) {
        // Try data-post-id attribute
        const postId = element.dataset.postId || element.getAttribute('data-post-id');
        if (postId) return parseInt(postId);

        // Try to find from ID attribute (e.g., "post-123")
        const id = element.id;
        if (id && id.startsWith('post-')) {
            return parseInt(id.replace('post-', ''));
        }

        // Try to find from closest parent
        const parent = element.closest('[data-post-id]');
        if (parent) {
            return parseInt(parent.dataset.postId);
        }

        return null;
    }

    /**
     * Log interaction to API
     */
    logInteraction(postId, interactionType, options = {}) {
        const data = {
            post_id: postId,
            interaction_type: interactionType,
            scroll_depth: options.scroll_depth || 0,
            dwell_time: options.dwell_time || 0.0,
            metadata: {
                device: this.getDeviceType(),
                timestamp: new Date().toISOString(),
                ...options.metadata
            }
        };

        // Add to batch queue
        this.batchQueue.push(data);

        // Schedule batch send
        this.scheduleBatchSend();
    }

    /**
     * Schedule batch send with debouncing
     */
    scheduleBatchSend() {
        if (this.batchTimeout) {
            clearTimeout(this.batchTimeout);
        }

        this.batchTimeout = setTimeout(() => {
            this.sendBatch();
        }, this.batchDelay);
    }

    /**
     * Send batched interactions to API
     */
    async sendBatch() {
        if (this.batchQueue.length === 0) return;

        // Get CSRF token
        const csrfToken = this.getCSRFToken();
        if (!csrfToken) {
            console.error('[PostInteractionTracker] CSRF token not found');
            return;
        }

        // Copy queue and clear it
        const batch = [...this.batchQueue];
        this.batchQueue = [];

        // Send each interaction (in production, consider true batching endpoint)
        for (const interaction of batch) {
            try {
                const response = await fetch('/api/posts/log-interaction/', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-CSRFToken': csrfToken
                    },
                    body: JSON.stringify(interaction)
                });

                if (!response.ok) {
                    console.error('[PostInteractionTracker] Failed to log interaction:', await response.text());
                }
            } catch (error) {
                console.error('[PostInteractionTracker] Network error:', error);
            }
        }
    }

    /**
     * Get CSRF token from cookies
     */
    getCSRFToken() {
        const name = 'csrftoken';
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

    /**
     * Detect device type
     */
    getDeviceType() {
        const width = window.innerWidth;
        if (width < 768) return 'mobile';
        if (width < 1024) return 'tablet';
        return 'desktop';
    }

    /**
     * Handle page unload - send remaining interactions
     */
    initBeforeUnload() {
        window.addEventListener('beforeunload', () => {
            // Stop all dwell timers
            this.dwellTimers.forEach((startTime, postId) => {
                this.stopDwellTimer(postId);
            });

            // Send any remaining interactions
            if (this.batchQueue.length > 0) {
                // Use sendBeacon for reliable delivery
                const csrfToken = this.getCSRFToken();
                this.batchQueue.forEach(interaction => {
                    const blob = new Blob([JSON.stringify(interaction)], {
                        type: 'application/json'
                    });
                    navigator.sendBeacon('/api/posts/log-interaction/', blob);
                });
            }
        });
    }

    /**
     * Manually trigger observation of new posts (for infinite scroll)
     */
    observeNewPosts() {
        this.observePostCards();
    }

    /**
     * Clean up resources
     */
    destroy() {
        if (this.viewObserver) {
            this.viewObserver.disconnect();
        }
        if (this.batchTimeout) {
            clearTimeout(this.batchTimeout);
        }
        this.dwellTimers.clear();
        this.scrollDepths.clear();
    }
}

// Initialize tracker when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    window.postInteractionTracker = new PostInteractionTracker();
    console.log('[PostInteractionTracker] Initialized');
});

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = PostInteractionTracker;
}
