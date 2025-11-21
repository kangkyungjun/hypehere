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
            deleteBtn.disabled = true;
            deleteBtn.textContent = '삭제 예약됨';
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
                const confirmBtn = document.getElementById('confirm-delete');
                confirmBtn.disabled = e.target.value !== '영구삭제';
            });
        }

        // 삭제 요청 확인
        const confirmDeleteBtn = document.getElementById('confirm-delete');
        if (confirmDeleteBtn) {
            confirmDeleteBtn.addEventListener('click', () => this.requestDeletion());
        }
    },

    async deactivateAccount() {
        try {
            const response = await fetch('/api/accounts/deactivate/', {
                method: 'POST',
                headers: {
                    'X-CSRFToken': this.getCookie('csrftoken')
                },
                credentials: 'same-origin'
            });

            if (response.ok) {
                alert('계정이 비활성화되었습니다. 다시 로그인하면 복구할 수 있습니다.');
                window.location.href = '/accounts/login/';
            } else {
                alert('비활성화에 실패했습니다.');
            }
        } catch (error) {
            console.error('Error deactivating account:', error);
            alert('비활성화 중 오류가 발생했습니다.');
        }
    },

    async requestDeletion() {
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
                alert(data.error || '삭제 요청에 실패했습니다.');
            }
        } catch (error) {
            console.error('Error requesting deletion:', error);
            alert('삭제 요청 중 오류가 발생했습니다.');
        }
    },

    async cancelDeletion() {
        if (!confirm('정말로 삭제를 취소하시겠습니까?')) {
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
                alert('계정 삭제가 취소되었습니다.');
                window.location.reload();
            } else {
                const data = await response.json();
                alert(data.error || '취소에 실패했습니다.');
            }
        } catch (error) {
            console.error('Error cancelling deletion:', error);
            alert('취소 중 오류가 발생했습니다.');
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
