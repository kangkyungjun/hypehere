const AccountManagement = {
    status: {},

    async init() {
        await this.loadStatus();
        this.attachEventListeners();
    },

    async loadStatus() {
        try {
            const response = await fetch('/api/accounts/account-status/', {
                credentials: 'same-origin'
            });

            if (response.ok) {
                this.status = await response.json();
                this.updateUI();
            }
        } catch (error) {
            console.error('Failed to load account status:', error);
        }
    },

    updateUI() {
        // 삭제 예약 상태 표시
        if (this.status.deletion_requested_at) {
            const alert = document.getElementById('deletion-alert');
            alert.classList.remove('hidden');

            document.getElementById('days-remaining').textContent =
                this.status.days_until_deletion || 30;

            // 삭제 버튼 비활성화
            const deleteBtn = document.getElementById('btn-delete');
            const i18n = window.APP_I18N || {};
            deleteBtn.disabled = true;
            deleteBtn.textContent = i18n.deletionScheduled || '삭제 예약됨';
            deleteBtn.style.opacity = '0.5';
        }
    },

    attachEventListeners() {
        // Event delegation for modal close actions
        document.addEventListener('click', (e) => {
            const target = e.target.closest('[data-action]');
            if (!target) return;

            const action = target.dataset.action;
            if (action === 'close-modal') {
                this.hideModal(target.dataset.modalId);
            }
        });

        // 비활성화 버튼
        const deactivateBtn = document.getElementById('btn-deactivate');
        if (deactivateBtn) {
            deactivateBtn.addEventListener('click', () => {
                this.showModal('deactivate-modal');
            });
        }

        // 재활성화 버튼
        const reactivateBtn = document.getElementById('btn-reactivate');
        if (reactivateBtn) {
            reactivateBtn.addEventListener('click', () => {
                this.showModal('reactivate-modal');
            });
        }

        // 삭제 버튼
        const deleteBtn = document.getElementById('btn-delete');
        if (deleteBtn) {
            deleteBtn.addEventListener('click', () => {
                this.showModal('delete-modal-step1');
            });
        }

        // 삭제 취소 버튼
        const cancelDeletionBtn = document.getElementById('btn-cancel-deletion');
        if (cancelDeletionBtn) {
            cancelDeletionBtn.addEventListener('click', () => this.cancelDeletion());
        }

        // 비활성화 확인
        const confirmDeactivateBtn = document.getElementById('confirm-deactivate');
        if (confirmDeactivateBtn) {
            confirmDeactivateBtn.addEventListener('click', () => this.deactivateAccount());
        }

        // 삭제 Step 2로 이동
        const nextStep2Btn = document.getElementById('next-step2');
        if (nextStep2Btn) {
            nextStep2Btn.addEventListener('click', () => {
                this.hideModal('delete-modal-step1');
                this.showModal('delete-modal-step2');
            });
        }

        // 삭제 확인 텍스트 입력
        const deleteConfirmText = document.getElementById('delete-confirm-text');
        if (deleteConfirmText) {
            deleteConfirmText.addEventListener('input', (e) => {
                const i18n = window.APP_I18N || {};
                const confirmBtn = document.getElementById('confirm-delete');
                confirmBtn.disabled = e.target.value !== (i18n.confirmDeleteText || '영구삭제');
            });
        }

        // 삭제 요청 확인
        const confirmDeleteBtn = document.getElementById('confirm-delete');
        if (confirmDeleteBtn) {
            confirmDeleteBtn.addEventListener('click', () => this.requestDeletion());
        }

        // 비활성화 성공 모달 확인 버튼
        const deactivateSuccessOk = document.getElementById('deactivate-success-ok');
        if (deactivateSuccessOk) {
            deactivateSuccessOk.addEventListener('click', () => {
                window.location.reload();
            });
        }

        // 재활성화 확인
        const confirmReactivateBtn = document.getElementById('confirm-reactivate');
        if (confirmReactivateBtn) {
            confirmReactivateBtn.addEventListener('click', () => this.reactivateAccount());
        }

        // 재활성화 성공 모달 확인 버튼
        const reactivateSuccessOk = document.getElementById('reactivate-success-ok');
        if (reactivateSuccessOk) {
            reactivateSuccessOk.addEventListener('click', () => {
                window.location.reload();
            });
        }

        // 비밀번호 변경 버튼
        const changePasswordBtn = document.getElementById('btn-change-password');
        if (changePasswordBtn) {
            changePasswordBtn.addEventListener('click', () => {
                this.showModal('password-change-modal');
            });
        }

        // 비밀번호 변경 확인
        const confirmPasswordChangeBtn = document.getElementById('confirm-password-change');
        if (confirmPasswordChangeBtn) {
            confirmPasswordChangeBtn.addEventListener('click', () => this.changePassword());
        }

        // 비밀번호 변경 성공 모달 확인 버튼
        const passwordChangeSuccessOk = document.getElementById('password-change-success-ok');
        if (passwordChangeSuccessOk) {
            passwordChangeSuccessOk.addEventListener('click', () => {
                window.location.href = '/accounts/login/';
            });
        }
    },

    async deactivateAccount() {
        const i18n = window.APP_I18N || {};
        try {
            const response = await fetch('/api/accounts/deactivate/', {
                method: 'POST',
                headers: {
                    'X-CSRFToken': this.getCookie('csrftoken')
                },
                credentials: 'same-origin'
            });

            if (response.ok) {
                this.hideModal('deactivate-modal');
                this.showModal('deactivate-success-modal');
            } else {
                alert(i18n.deactivateFailed || '비활성화에 실패했습니다.');
            }
        } catch (error) {
            console.error('Error deactivating account:', error);
            alert(i18n.deactivateError || '비활성화 중 오류가 발생했습니다.');
        }
    },

    async reactivateAccount() {
        const i18n = window.APP_I18N || {};
        try {
            const response = await fetch('/api/accounts/reactivate/', {
                method: 'POST',
                headers: {
                    'X-CSRFToken': this.getCookie('csrftoken'),
                    'Content-Type': 'application/json'
                },
                credentials: 'same-origin'
            });

            if (response.ok) {
                this.hideModal('reactivate-modal');
                this.showModal('reactivate-success-modal');
            } else {
                const data = await response.json();
                alert(data.error || i18n.reactivateFailed || '재활성화에 실패했습니다.');
            }
        } catch (error) {
            console.error('Error reactivating account:', error);
            alert(i18n.reactivateError || '재활성화 중 오류가 발생했습니다.');
        }
    },

    async requestDeletion() {
        const i18n = window.APP_I18N || {};
        try {
            const response = await fetch('/api/accounts/request-deletion/', {
                method: 'POST',
                headers: {
                    'X-CSRFToken': this.getCookie('csrftoken')
                },
                credentials: 'same-origin'
            });

            if (response.ok) {
                const data = await response.json();
                alert(data.message);
                window.location.reload();
            } else {
                const data = await response.json();
                alert(data.error || i18n.deletionRequestFailed || '삭제 요청에 실패했습니다.');
            }
        } catch (error) {
            console.error('Error requesting deletion:', error);
            alert(i18n.deletionRequestError || '삭제 요청 중 오류가 발생했습니다.');
        }
    },

    async cancelDeletion() {
        const i18n = window.APP_I18N || {};
        if (!confirm(i18n.cancelDeletionConfirm || '정말로 삭제를 취소하시겠습니까?')) {
            return;
        }

        try {
            const response = await fetch('/api/accounts/cancel-deletion/', {
                method: 'POST',
                headers: {
                    'X-CSRFToken': this.getCookie('csrftoken')
                },
                credentials: 'same-origin'
            });

            if (response.ok) {
                alert(i18n.cancelDeletionSuccess || '계정 삭제가 취소되었습니다.');
                window.location.reload();
            } else {
                const data = await response.json();
                alert(data.error || i18n.cancelDeletionFailed || '취소에 실패했습니다.');
            }
        } catch (error) {
            console.error('Error cancelling deletion:', error);
            alert(i18n.cancelDeletionError || '취소 중 오류가 발생했습니다.');
        }
    },

    async changePassword() {
        const i18n = window.PASSWORD_CHANGE_I18N || {};

        // Get form values
        const oldPassword = document.getElementById('old_password').value;
        const newPassword = document.getElementById('new_password').value;
        const newPasswordConfirm = document.getElementById('new_password_confirm').value;

        // Hide previous errors
        this.hidePasswordError();

        // Client-side validation
        if (!oldPassword || !newPassword || !newPasswordConfirm) {
            this.showPasswordError(i18n.allFieldsRequired || '모든 필드를 입력해주세요.');
            return;
        }

        if (newPassword !== newPasswordConfirm) {
            this.showPasswordError(i18n.passwordMismatch || '새 비밀번호가 일치하지 않습니다.');
            return;
        }

        if (newPassword.length < 8) {
            this.showPasswordError(i18n.passwordTooShort || '비밀번호는 최소 8자 이상이어야 합니다.');
            return;
        }

        try {
            const response = await fetch('/api/accounts/change-password/', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRFToken': this.getCookie('csrftoken')
                },
                credentials: 'same-origin',
                body: JSON.stringify({
                    old_password: oldPassword,
                    new_password: newPassword,
                    new_password_confirm: newPasswordConfirm
                })
            });

            const data = await response.json();

            if (response.ok) {
                // Clear form
                document.getElementById('password-change-form').reset();

                // Hide change modal and show success modal
                this.hideModal('password-change-modal');
                this.showModal('password-change-success-modal');
            } else {
                // Parse ALL errors from server response
                const allErrors = this.parseAllPasswordErrors(data, i18n);
                this.showPasswordError(allErrors);
            }
        } catch (error) {
            console.error('Error changing password:', error);
            this.showPasswordError(i18n.networkError || '네트워크 오류가 발생했습니다. 다시 시도해주세요.');
        }
    },

    parseAllPasswordErrors(data, i18n) {
        const errors = [];

        // Collect all errors from all fields
        if (data.old_password) {
            const oldPwdErrors = Array.isArray(data.old_password) ? data.old_password : [data.old_password];
            errors.push(...oldPwdErrors);
        }
        if (data.new_password) {
            const newPwdErrors = Array.isArray(data.new_password) ? data.new_password : [data.new_password];
            errors.push(...newPwdErrors);
        }
        if (data.new_password_confirm) {
            const confirmErrors = Array.isArray(data.new_password_confirm) ? data.new_password_confirm : [data.new_password_confirm];
            errors.push(...confirmErrors);
        }
        if (data.non_field_errors) {
            const nonFieldErrors = Array.isArray(data.non_field_errors) ? data.non_field_errors : [data.non_field_errors];
            errors.push(...nonFieldErrors);
        }
        if (data.error) {
            errors.push(data.error);
        }

        // Format multiple errors with bullet points
        if (errors.length > 1) {
            return errors.map(err => `• ${err}`).join('<br>');
        } else if (errors.length === 1) {
            return errors[0];
        } else {
            return i18n.passwordChangeFailed || '비밀번호 변경에 실패했습니다.';
        }
    },

    showPasswordError(message) {
        const errorAlert = document.getElementById('password-error-alert');
        const errorMessage = document.getElementById('password-error-message');

        if (errorAlert && errorMessage) {
            // Support HTML for multi-line errors with bullet points
            errorMessage.innerHTML = message;
            errorAlert.classList.remove('hidden');
        }
    },

    hidePasswordError() {
        const errorAlert = document.getElementById('password-error-alert');
        if (errorAlert) {
            errorAlert.classList.add('hidden');
        }
    },

    showModal(modalId) {
        document.getElementById(modalId).classList.remove('hidden');
    },

    hideModal(modalId) {
        document.getElementById(modalId).classList.add('hidden');
    },

    getCookie(name) {
        const match = document.cookie.match(new RegExp('(^| )' + name + '=([^;]+)'));
        return match ? match[2] : null;
    }
};

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    AccountManagement.init();
});
