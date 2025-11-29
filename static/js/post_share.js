/**
 * Post Share Manager - Bottom Sheet Modal
 * Handles post sharing with a bottom slide-up modal
 */

class PostShareManager {
    constructor() {
        this.currentPostId = null;
        this.modal = null;
        this.overlay = null;
        this.init();
    }

    init() {
        // Create modal and overlay elements
        this.createModal();

        // Event listeners
        this.attachEventListeners();
    }

    createModal() {
        // Get i18n translations
        const i18n = window.SHARE_I18N || {};

        // Create overlay
        this.overlay = document.createElement('div');
        this.overlay.className = 'share-modal-overlay';
        this.overlay.style.display = 'none';

        // Create modal
        this.modal = document.createElement('div');
        this.modal.className = 'share-modal-bottom';
        this.modal.innerHTML = `
            <div class="share-modal-header">
                <h3 class="share-modal-title">${i18n.shareTitle || '공유하기'}</h3>
                <button class="share-modal-close" aria-label="${i18n.close || '닫기'}">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <line x1="18" y1="6" x2="6" y2="18"></line>
                        <line x1="6" y1="6" x2="18" y2="18"></line>
                    </svg>
                </button>
            </div>
            <div class="share-modal-content">
                <button class="share-option-btn" data-action="copy-link">
                    <div class="share-option-icon">
                        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"></path>
                            <path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"></path>
                        </svg>
                    </div>
                    <div class="share-option-text">
                        <span class="share-option-title">${i18n.copyLink || '링크 복사'}</span>
                        <span class="share-option-desc">${i18n.copyLinkDesc || '게시물 링크를 클립보드에 복사'}</span>
                    </div>
                </button>
            </div>
        `;

        // Append to body
        document.body.appendChild(this.overlay);
        document.body.appendChild(this.modal);
    }

    attachEventListeners() {
        // Share button clicks
        document.addEventListener('click', (e) => {
            const shareBtn = e.target.closest('.share-btn');
            if (shareBtn) {
                e.stopPropagation();
                const postId = shareBtn.dataset.postId;
                this.openModal(postId);
            }
        });

        // Close button click
        const closeBtn = this.modal.querySelector('.share-modal-close');
        closeBtn.addEventListener('click', () => this.closeModal());

        // Overlay click
        this.overlay.addEventListener('click', () => this.closeModal());

        // Share option clicks
        this.modal.addEventListener('click', (e) => {
            const optionBtn = e.target.closest('.share-option-btn');
            if (optionBtn) {
                const action = optionBtn.dataset.action;
                this.handleAction(action);
            }
        });

        // ESC key to close
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && this.modal.classList.contains('active')) {
                this.closeModal();
            }
        });
    }

    openModal(postId) {
        this.currentPostId = postId;

        // Show overlay and modal
        this.overlay.style.display = 'block';

        // Trigger reflow for animation
        requestAnimationFrame(() => {
            this.overlay.classList.add('active');
            this.modal.classList.add('active');
        });

        // Prevent body scroll
        document.body.style.overflow = 'hidden';
    }

    closeModal() {
        this.overlay.classList.remove('active');
        this.modal.classList.remove('active');

        // Wait for animation to complete
        setTimeout(() => {
            this.overlay.style.display = 'none';
            document.body.style.overflow = '';
        }, 300);
    }

    handleAction(action) {
        switch (action) {
            case 'copy-link':
                this.copyPostLink();
                break;
        }
    }

    async copyPostLink() {
        if (!this.currentPostId) return;

        const i18n = window.SHARE_I18N || {};
        const shareUrl = `${window.location.origin}/?postId=${this.currentPostId}`;

        try {
            // Modern Clipboard API
            await navigator.clipboard.writeText(shareUrl);
            this.showSuccessMessage(i18n.linkCopied || '링크가 복사되었습니다');

            // Close modal after short delay
            setTimeout(() => this.closeModal(), 1000);
        } catch (err) {
            // Fallback for older browsers
            this.fallbackCopyToClipboard(shareUrl);
        }
    }

    fallbackCopyToClipboard(text) {
        const i18n = window.SHARE_I18N || {};
        const textarea = document.createElement('textarea');
        textarea.value = text;
        textarea.style.position = 'fixed';
        textarea.style.left = '-999999px';
        textarea.style.top = '-999999px';
        document.body.appendChild(textarea);
        textarea.focus();
        textarea.select();

        try {
            const successful = document.execCommand('copy');
            if (successful) {
                this.showSuccessMessage(i18n.linkCopied || '링크가 복사되었습니다');
                setTimeout(() => this.closeModal(), 1000);
            } else {
                this.showErrorMessage(i18n.copyFailed || '링크 복사에 실패했습니다');
            }
        } catch (err) {
            console.error('Fallback copy failed:', err);
            this.showErrorMessage(i18n.copyFailed || '링크 복사에 실패했습니다');
        } finally {
            document.body.removeChild(textarea);
        }
    }

    showSuccessMessage(message) {
        this.showToast(message, 'success');
    }

    showErrorMessage(message) {
        this.showToast(message, 'error');
    }

    showToast(message, type = 'success') {
        // Create toast element
        const toast = document.createElement('div');
        toast.className = `share-toast share-toast-${type}`;
        toast.innerHTML = `
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                ${type === 'success'
                    ? '<polyline points="20 6 9 17 4 12"></polyline>'
                    : '<circle cx="12" cy="12" r="10"></circle><line x1="12" y1="8" x2="12" y2="12"></line><line x1="12" y1="16" x2="12.01" y2="16"></line>'}
            </svg>
            <span>${message}</span>
        `;

        document.body.appendChild(toast);

        // Show toast
        requestAnimationFrame(() => {
            toast.classList.add('show');
        });

        // Remove after 3 seconds
        setTimeout(() => {
            toast.classList.remove('show');
            setTimeout(() => {
                document.body.removeChild(toast);
            }, 300);
        }, 3000);
    }
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', () => {
    window.postShareManager = new PostShareManager();
});
