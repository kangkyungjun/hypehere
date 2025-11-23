/**
 * Comment Owner Actions Manager
 * Handles edit and delete actions for comment owners
 */

class CommentOwnerActionsManager {
    constructor() {
        this.modal = document.getElementById('comment-owner-action-modal');
        this.editModal = document.getElementById('comment-edit-modal');
        this.deleteConfirmModal = document.getElementById('comment-delete-confirm-modal');
        this.currentCommentId = null;
        this.currentPostId = null;
        this.currentCommentContent = '';

        this.init();
    }

    getCookie(name) {
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

    init() {
        this.setupEventListeners();
    }

    setupEventListeners() {
        // Close owner action modal
        const closeBtn = document.getElementById('close-comment-owner-modal');
        if (closeBtn) {
            closeBtn.addEventListener('click', () => this.closeModal());
        }

        // Click outside to close
        if (this.modal) {
            this.modal.addEventListener('click', (e) => {
                if (e.target === this.modal) {
                    this.closeModal();
                }
            });
        }

        // Action buttons (edit/delete)
        if (this.modal) {
            this.modal.addEventListener('click', (e) => {
                const actionBtn = e.target.closest('.action-item');
                if (actionBtn) {
                    const action = actionBtn.dataset.action;
                    if (action === 'edit') {
                        this.handleEdit();
                    } else if (action === 'delete') {
                        this.handleDelete();
                    }
                }
            });
        }

        // Edit modal listeners
        this.setupEditModalListeners();

        // Delete confirmation modal listeners
        this.setupDeleteConfirmListeners();
    }

    setupEditModalListeners() {
        // Close edit modal
        const closeEditBtn = document.getElementById('close-comment-edit-modal');
        if (closeEditBtn) {
            closeEditBtn.addEventListener('click', () => this.closeEditModal());
        }

        const cancelBtn = document.getElementById('cancel-comment-edit');
        if (cancelBtn) {
            cancelBtn.addEventListener('click', () => this.closeEditModal());
        }

        // Click outside to close
        if (this.editModal) {
            this.editModal.addEventListener('click', (e) => {
                if (e.target === this.editModal) {
                    this.closeEditModal();
                }
            });
        }

        // Form submission
        const editForm = document.getElementById('comment-edit-form');
        if (editForm) {
            editForm.addEventListener('submit', (e) => {
                e.preventDefault();
                this.submitEdit();
            });
        }

        // Character counter
        const textarea = document.getElementById('comment-edit-content');
        const charCount = document.getElementById('comment-edit-char-count');
        if (textarea && charCount) {
            textarea.addEventListener('input', () => {
                charCount.textContent = textarea.value.length;
            });
        }
    }

    setupDeleteConfirmListeners() {
        // Close delete confirm modal
        const closeBtn = document.getElementById('close-comment-delete-confirm');
        if (closeBtn) {
            closeBtn.addEventListener('click', () => this.closeDeleteConfirmModal());
        }

        const cancelBtn = document.getElementById('cancel-comment-delete');
        if (cancelBtn) {
            cancelBtn.addEventListener('click', () => this.closeDeleteConfirmModal());
        }

        // Click outside to close
        if (this.deleteConfirmModal) {
            this.deleteConfirmModal.addEventListener('click', (e) => {
                if (e.target === this.deleteConfirmModal) {
                    this.closeDeleteConfirmModal();
                }
            });
        }

        // Confirm delete button
        const confirmBtn = document.getElementById('confirm-comment-delete');
        if (confirmBtn) {
            confirmBtn.addEventListener('click', () => {
                this.closeDeleteConfirmModal();
                this.deleteComment();
            });
        }
    }

    openModal(commentId, postId) {
        this.currentCommentId = commentId;
        this.currentPostId = postId;

        // Get current comment content for editing
        const commentElement = document.querySelector(`[data-comment-id="${commentId}"]`)?.closest('.comment-item');
        if (commentElement) {
            const contentElement = commentElement.querySelector('.comment-body p');
            this.currentCommentContent = contentElement?.textContent.trim() || '';
        }

        this.modal.classList.remove('hidden');
        document.body.style.overflow = 'hidden';
    }

    closeModal() {
        this.modal.classList.add('hidden');
        document.body.style.overflow = '';
    }

    handleEdit() {
        this.closeModal();
        this.openEditModal();
    }

    handleDelete() {
        this.closeModal();
        this.openDeleteConfirmModal();
    }

    openEditModal() {
        const textarea = document.getElementById('comment-edit-content');
        const charCount = document.getElementById('comment-edit-char-count');

        if (textarea) {
            textarea.value = this.currentCommentContent;
            textarea.focus();

            if (charCount) {
                charCount.textContent = this.currentCommentContent.length;
            }
        }

        this.editModal.classList.remove('hidden');
        document.body.style.overflow = 'hidden';
    }

    closeEditModal() {
        this.editModal.classList.add('hidden');
        document.body.style.overflow = '';
    }

    openDeleteConfirmModal() {
        this.deleteConfirmModal.classList.remove('hidden');
        document.body.style.overflow = 'hidden';
    }

    closeDeleteConfirmModal() {
        this.deleteConfirmModal.classList.add('hidden');
        document.body.style.overflow = '';
    }

    async submitEdit() {
        const textarea = document.getElementById('comment-edit-content');
        const newContent = textarea.value.trim();

        if (!newContent) {
            alert('댓글 내용을 입력해주세요.');
            return;
        }

        const saveBtn = document.getElementById('save-comment-edit');
        if (saveBtn) {
            saveBtn.disabled = true;
            saveBtn.textContent = '저장 중...';
        }

        try {
            const csrfToken = this.getCookie('csrftoken');

            const response = await fetch(`/api/posts/${this.currentPostId}/comments/${this.currentCommentId}/`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRFToken': csrfToken
                },
                credentials: 'same-origin',
                body: JSON.stringify({
                    content: newContent
                })
            });

            if (response.ok) {
                // Update comment content in DOM
                const commentElement = document.querySelector(`[data-comment-id="${this.currentCommentId}"]`)?.closest('.comment-item');
                if (commentElement) {
                    const contentElement = commentElement.querySelector('.comment-body p');
                    if (contentElement) {
                        contentElement.textContent = newContent;
                    }
                }

                this.closeEditModal();

                // Show success message
                if (window.alertModal) {
                    window.alertModal.show('댓글이 수정되었습니다.');
                }
            } else {
                throw new Error('Failed to update comment');
            }
        } catch (error) {
            console.error('Error updating comment:', error);
            alert('댓글 수정 중 오류가 발생했습니다.');
        } finally {
            if (saveBtn) {
                saveBtn.disabled = false;
                saveBtn.textContent = '저장';
            }
        }
    }

    async deleteComment() {
        try {
            const csrfToken = this.getCookie('csrftoken');

            const response = await fetch(`/api/posts/${this.currentPostId}/comments/${this.currentCommentId}/`, {
                method: 'DELETE',
                headers: {
                    'X-CSRFToken': csrfToken
                },
                credentials: 'same-origin'
            });

            if (response.ok) {
                // Remove comment from DOM
                const commentElement = document.querySelector(`[data-comment-id="${this.currentCommentId}"]`)?.closest('.comment-item');
                if (commentElement) {
                    commentElement.remove();
                }

                // Update comment count
                const commentCountElement = document.querySelector(`[data-post-id="${this.currentPostId}"] .comment-count`);
                if (commentCountElement) {
                    const currentCount = parseInt(commentCountElement.textContent) || 0;
                    commentCountElement.textContent = Math.max(0, currentCount - 1);
                }

                // Show success message
                if (window.alertModal) {
                    window.alertModal.show('댓글이 삭제되었습니다.');
                }
            } else {
                throw new Error('Failed to delete comment');
            }
        } catch (error) {
            console.error('Error deleting comment:', error);
            alert('댓글 삭제 중 오류가 발생했습니다.');
        }
    }
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.commentOwnerManager = new CommentOwnerActionsManager();
});
