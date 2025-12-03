/**
 * Profile Picture Modal
 * Handles profile picture preview, edit, and delete actions
 */

class ProfilePictureModal {
    constructor() {
        this.previewModal = document.getElementById('profile-picture-modal');
        this.actionsSheet = document.getElementById('profile-picture-actions-sheet');
        this.previewImage = document.getElementById('preview-image');
        this.closeBtn = document.getElementById('close-preview-btn');
        this.actionsBtn = document.getElementById('picture-actions-btn');
        this.editAction = document.getElementById('edit-picture-action');
        this.deleteAction = document.getElementById('delete-picture-action');
        this.reportAction = document.getElementById('report-user-action');
        this.fileInput = document.getElementById('profile-picture-input');
        this.avatar = document.getElementById('profile-avatar');
        this.avatarImg = document.getElementById('avatar-img');
        this.reportModal = document.getElementById('user-report-modal');
        this.reportForm = document.getElementById('user-report-form');
        this.deleteConfirmModal = document.getElementById('profile-picture-delete-confirm-modal');
        this.confirmDeleteBtn = document.getElementById('confirm-picture-delete-btn');
        this.cancelDeleteBtn = document.getElementById('cancel-picture-delete-btn');

        this.init();
    }

    init() {
        if (!this.previewModal || !this.actionsSheet) return;

        // Avatar click handler
        if (this.avatar) {
            this.avatar.addEventListener('click', (e) => this.handleAvatarClick(e));
        }

        // Close button
        if (this.closeBtn) {
            this.closeBtn.addEventListener('click', () => this.closePreview());
        }

        // Actions button (three dots)
        if (this.actionsBtn) {
            this.actionsBtn.addEventListener('click', (e) => {
                e.stopPropagation();
                this.showActions();
            });
        }

        // Edit action
        if (this.editAction) {
            this.editAction.addEventListener('click', () => this.editPicture());
        }

        // Delete action
        if (this.deleteAction) {
            this.deleteAction.addEventListener('click', () => this.deletePicture());
        }

        // Report action
        if (this.reportAction) {
            this.reportAction.addEventListener('click', () => this.reportUser());
        }

        // Report form submission
        if (this.reportForm) {
            this.reportForm.addEventListener('submit', (e) => this.handleReportSubmit(e));
        }

        // Delete confirmation modal buttons
        if (this.confirmDeleteBtn) {
            this.confirmDeleteBtn.addEventListener('click', () => this.executeDeletePicture());
        }
        if (this.cancelDeleteBtn) {
            this.cancelDeleteBtn.addEventListener('click', () => this.closeDeleteConfirmModal());
        }

        // Close delete confirmation modal on click outside
        if (this.deleteConfirmModal) {
            this.deleteConfirmModal.addEventListener('click', (e) => {
                if (e.target === this.deleteConfirmModal) {
                    this.closeDeleteConfirmModal();
                }
            });
        }

        // Click outside to close
        this.previewModal.addEventListener('click', (e) => {
            if (e.target === this.previewModal) {
                this.closePreview();
            }
        });

        this.actionsSheet.addEventListener('click', (e) => {
            if (e.target === this.actionsSheet) {
                this.closeActions();
            }
        });

        // ESC key to close
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                if (!this.deleteConfirmModal.classList.contains('hidden')) {
                    this.closeDeleteConfirmModal();
                } else if (!this.actionsSheet.classList.contains('hidden')) {
                    this.closeActions();
                } else if (!this.previewModal.classList.contains('hidden')) {
                    this.closePreview();
                }
            }
        });
    }

    handleAvatarClick(e) {
        e.preventDefault();

        // Always show preview modal (requirement: always show modal)
        const imageSrc = (this.avatarImg && this.avatarImg.src) || '';
        this.showPreview(imageSrc);
    }

    showPreview(imageSrc) {
        this.previewImage.src = imageSrc;
        this.previewModal.classList.remove('hidden');
        document.body.style.overflow = 'hidden';
    }

    closePreview() {
        this.previewModal.classList.add('hidden');
        document.body.style.overflow = '';
        this.closeActions();
    }

    showActions() {
        this.actionsSheet.classList.remove('hidden');
    }

    closeActions() {
        this.actionsSheet.classList.add('hidden');
    }

    editPicture() {
        this.closeActions();
        this.closePreview();
        // Trigger file input
        this.fileInput.click();
    }

    deletePicture() {
        this.closeActions();
        this.openDeleteConfirmModal();
    }

    openDeleteConfirmModal() {
        if (this.deleteConfirmModal) {
            this.deleteConfirmModal.classList.remove('hidden');
            document.body.style.overflow = 'hidden';
        }
    }

    closeDeleteConfirmModal() {
        if (this.deleteConfirmModal) {
            this.deleteConfirmModal.classList.add('hidden');
            document.body.style.overflow = '';
        }
    }

    async executeDeletePicture() {
        this.closeDeleteConfirmModal();

        // Get translations
        const successMsg = window.APP_I18N?.profilePictureDeleted || '프로필 사진이 삭제되었습니다';
        const errorMsg = window.APP_I18N?.deleteFailed || '삭제에 실패했습니다';

        try {
            // Get CSRF token
            const csrfToken = document.querySelector('[name=csrfmiddlewaretoken]')?.value ||
                            document.querySelector('meta[name="csrf-token"]')?.content;

            const response = await fetch('/api/accounts/profile-picture/', {
                method: 'DELETE',
                headers: {
                    'X-CSRFToken': csrfToken,
                    'Content-Type': 'application/json',
                },
            });

            if (response.ok) {
                // Success - update UI
                this.closePreview();

                // Replace image with default SVG avatar
                const avatarContainer = document.getElementById('profile-avatar');
                avatarContainer.innerHTML = `
                    <svg viewBox="0 0 100 100" fill="currentColor" style="color: var(--color-primary);" id="avatar-svg">
                        <circle cx="50" cy="35" r="20"/>
                        <path d="M15 85 Q15 55 50 55 Q85 55 85 85 Z"/>
                    </svg>
                    <div id="avatar-loading" class="hidden" style="position:absolute; top:0; left:0; right:0; bottom:0; background:rgba(0,0,0,0.5); border-radius:50%; align-items:center; justify-content:center;">
                        <span class="spinner spinner-primary"></span>
                    </div>
                `;

                // Re-attach click handler
                const newAvatar = document.getElementById('profile-avatar');
                newAvatar.addEventListener('click', (e) => this.handleAvatarClick(e));
                this.avatar = newAvatar;
                this.avatarImg = document.getElementById('avatar-img');

                // Show success message
                if (window.showAlert) {
                    window.showAlert(successMsg, 'success');
                } else {
                    alert(successMsg);
                }
            } else {
                throw new Error('Delete failed');
            }
        } catch (error) {
            console.error('Error deleting profile picture:', error);
            if (window.showAlert) {
                window.showAlert(errorMsg, 'error');
            } else {
                alert(errorMsg);
            }
        }
    }

    reportUser() {
        this.closeActions();

        // Get reported user ID from page data
        const reportedUserId = document.querySelector('[data-user-id]')?.getAttribute('data-user-id');

        if (!reportedUserId) {
            console.error('Cannot find reported user ID');
            return;
        }

        // Set the hidden input field value
        const reportedUserInput = document.getElementById('reported-user-id');
        if (reportedUserInput) {
            reportedUserInput.value = reportedUserId;
        }

        // Show the report modal
        if (this.reportModal) {
            this.reportModal.style.display = 'flex';
        }
    }

    async handleReportSubmit(e) {
        e.preventDefault();

        // Get translations
        const successMsg = window.APP_I18N?.userReportSuccess || '사용자 신고가 접수되었습니다';
        const errorMsg = window.APP_I18N?.reportFailed || '신고 접수에 실패했습니다';
        const duplicateMsg = window.APP_I18N?.duplicateReport || '이미 신고한 사용자입니다';
        const selfReportMsg = window.APP_I18N?.cannotReportSelf || '자신을 신고할 수 없습니다';

        try {
            // Get form data
            const formData = new FormData(this.reportForm);
            const reportData = {
                reported_user: formData.get('reported_user'),
                report_type: formData.get('report_type'),
                description: formData.get('description') || ''
            };

            // Get CSRF token
            const csrfToken = document.querySelector('[name=csrfmiddlewaretoken]')?.value ||
                            document.querySelector('meta[name="csrf-token"]')?.content;

            const response = await fetch('/api/accounts/users/report/', {
                method: 'POST',
                headers: {
                    'X-CSRFToken': csrfToken,
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(reportData)
            });

            const result = await response.json();

            if (response.ok) {
                // Success - close modal and show success message
                if (window.closeUserReportModal) {
                    window.closeUserReportModal();
                } else if (this.reportModal) {
                    this.reportModal.style.display = 'none';
                }

                // Reset form
                this.reportForm.reset();

                // Show success message
                if (window.showAlert) {
                    window.showAlert(successMsg, 'success');
                } else {
                    alert(successMsg);
                }
            } else {
                // Handle different error cases
                let message = errorMsg;

                if (result.error) {
                    if (result.error.includes('already reported') || result.error.includes('이미 신고')) {
                        message = duplicateMsg;
                    } else if (result.error.includes('yourself') || result.error.includes('자신')) {
                        message = selfReportMsg;
                    } else {
                        message = result.error;
                    }
                }

                if (window.showAlert) {
                    window.showAlert(message, 'error');
                } else {
                    alert(message);
                }
            }
        } catch (error) {
            console.error('Error submitting report:', error);
            if (window.showAlert) {
                window.showAlert(errorMsg, 'error');
            } else {
                alert(errorMsg);
            }
        }
    }
}

// Initialize on DOM ready
document.addEventListener('DOMContentLoaded', () => {
    window.profilePictureModal = new ProfilePictureModal();
});
