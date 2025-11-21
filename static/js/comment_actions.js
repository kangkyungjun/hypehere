/**
 * Comment Actions Manager
 * Handles comment action modal flow (Block, Report)
 */

class CommentActionsManager {
    constructor() {
        this.currentComment = null;
        this.currentPost = null;
        this.init();
    }

    init() {
        // Action modal buttons
        document.querySelectorAll('[data-action="block"]').forEach(btn => {
            btn.addEventListener('click', () => this.handleBlock());
        });

        document.querySelectorAll('[data-action="report"]').forEach(btn => {
            btn.addEventListener('click', () => this.handleReport());
        });

        // Report modal - type selection
        document.querySelectorAll('#comment-report-modal .report-type-btn').forEach(btn => {
            btn.addEventListener('click', (e) => this.selectReportType(e));
        });

        // Report modal - close buttons
        document.getElementById('close-comment-report-modal')?.addEventListener('click', () => {
            this.closeReportModal();
        });

        document.getElementById('cancel-comment-report-btn')?.addEventListener('click', () => {
            this.closeReportModal();
        });

        // Report modal - submit
        document.getElementById('comment-report-form')?.addEventListener('submit', (e) => {
            e.preventDefault();
            this.submitReport();
        });

        // Close modals on overlay click
        document.getElementById('comment-report-modal')?.addEventListener('click', (e) => {
            if (e.target.id === 'comment-report-modal') {
                this.closeReportModal();
            }
        });

        // ESC key to close modals
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                this.closeReportModal();
            }
        });
    }

    openActionModal(commentId, postId, commentAuthorId) {
        this.currentComment = commentId;
        this.currentPost = postId;
        this.currentAuthor = commentAuthorId;

        const modal = document.getElementById('post-action-modal');
        if (modal) {
            modal.classList.remove('hidden');
            document.body.style.overflow = 'hidden';
        }
    }

    closeActionModal() {
        const modal = document.getElementById('post-action-modal');
        if (modal) {
            modal.classList.add('hidden');
            document.body.style.overflow = '';
        }
    }

    async handleBlock() {
        this.closeActionModal();

        if (!this.currentAuthor) {
            console.error('No author ID set for blocking');
            return;
        }

        if (!confirm('이 사용자를 차단하시겠습니까?\n\n차단한 사용자의 게시물과 댓글이 보이지 않습니다.')) {
            return;
        }

        try {
            const response = await fetch(`/api/accounts/block/${this.currentAuthor}/`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRFToken': this.getCsrfToken()
                },
                credentials: 'same-origin'
            });

            if (response.ok) {
                alert('사용자를 차단했습니다.');
                location.reload();
            } else {
                const data = await response.json();
                alert(data.error || '차단에 실패했습니다.');
            }
        } catch (error) {
            console.error('Block error:', error);
            alert('오류가 발생했습니다. 다시 시도해주세요.');
        }
    }

    handleReport() {
        this.closeActionModal();
        this.openReportModal();
    }

    openReportModal() {
        const modal = document.getElementById('comment-report-modal');
        if (modal) {
            // Reset form
            document.getElementById('comment-report-form')?.reset();
            document.getElementById('comment-report-type').value = '';
            document.querySelectorAll('#comment-report-modal .report-type-btn').forEach(btn => {
                btn.classList.remove('selected');
            });

            modal.classList.remove('hidden');
            document.body.style.overflow = 'hidden';
        }
    }

    closeReportModal() {
        const modal = document.getElementById('comment-report-modal');
        if (modal) {
            modal.classList.add('hidden');
            document.body.style.overflow = '';
        }
    }

    selectReportType(event) {
        const btn = event.currentTarget;
        const type = btn.dataset.type;

        // Remove selection from all buttons
        document.querySelectorAll('#comment-report-modal .report-type-btn').forEach(b => {
            b.classList.remove('selected');
        });

        // Mark this button as selected
        btn.classList.add('selected');

        // Set hidden input value
        document.getElementById('comment-report-type').value = type;
    }

    async submitReport() {
        const reportType = document.getElementById('comment-report-type').value;
        const description = document.getElementById('comment-report-description').value;

        if (!reportType) {
            alert('신고 유형을 선택해주세요.');
            return;
        }

        if (!this.currentComment || !this.currentPost) {
            console.error('No comment or post ID set for reporting');
            alert('오류가 발생했습니다. 다시 시도해주세요.');
            return;
        }

        try {
            const response = await fetch(`/api/posts/${this.currentPost}/comments/${this.currentComment}/report/`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRFToken': this.getCsrfToken()
                },
                credentials: 'same-origin',
                body: JSON.stringify({
                    report_type: reportType,
                    description: description || ''
                })
            });

            const data = await response.json();

            if (response.ok) {
                this.closeReportModal();
                alert('신고가 접수되었습니다.\n검토 후 조치하겠습니다.');

                // Reset current comment/post
                this.currentComment = null;
                this.currentPost = null;
                this.currentAuthor = null;
            } else {
                alert(data.error || '신고에 실패했습니다. 다시 시도해주세요.');
            }
        } catch (error) {
            console.error('Report submission error:', error);
            alert('오류가 발생했습니다. 다시 시도해주세요.');
        }
    }

    getCsrfToken() {
        // Try to get from cookie first (more reliable)
        const cookieMatch = document.cookie.match(/csrftoken=([^;]+)/);
        if (cookieMatch) {
            return cookieMatch[1];
        }

        // Fallback: try to get from hidden input
        const tokenInput = document.querySelector('[name=csrfmiddlewaretoken]');
        if (tokenInput) {
            return tokenInput.value;
        }

        console.warn('CSRF token not found');
        return '';
    }
}

// Initialize Comment Actions Manager and export to window
const commentActionsManager = new CommentActionsManager();
window.commentActionsManager = commentActionsManager;
