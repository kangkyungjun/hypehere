// 개인정보 보호 설정 관리 객체
const PrivacySettings = {
    // 현재 설정값
    settings: {},
    // 현재 모달에서 설정 중인 항목 ('followers' or 'following')
    currentSetting: null,

    // 초기화
    async init() {
        await this.loadSettings();
        this.attachEventListeners();
        this.attachModalListeners();
    },

    // 설정 로드
    async loadSettings() {
        try {
            const response = await fetch('/api/accounts/privacy-settings/', {
                credentials: 'same-origin'
            });

            if (response.ok) {
                this.settings = await response.json();
                this.updateUI();
            } else {
                console.error('Failed to load privacy settings:', response.status);
            }
        } catch (error) {
            console.error('Failed to load privacy settings:', error);
        }
    },

    // UI 업데이트
    updateUI() {
        // 비공개 계정 토글
        const isPrivateToggle = document.getElementById('isPrivate');
        if (isPrivateToggle) {
            isPrivateToggle.checked = this.settings.is_private || false;
        }

        // 팔로워 목록 공개 범위 버튼
        const followersListButton = document.getElementById('showFollowersListButton');
        if (followersListButton) {
            const value = this.settings.show_followers_list || 'everyone';
            this.updateButtonText(followersListButton, value);
            followersListButton.dataset.currentValue = value;
        }

        // 팔로잉 목록 공개 범위 버튼
        const followingListButton = document.getElementById('showFollowingListButton');
        if (followingListButton) {
            const value = this.settings.show_following_list || 'everyone';
            this.updateButtonText(followingListButton, value);
            followingListButton.dataset.currentValue = value;
        }
    },

    // 버튼 텍스트 업데이트
    updateButtonText(button, value) {
        const i18n = window.APP_I18N || {};
        const textMap = {
            'everyone': i18n.everyone || '전체 공개',
            'followers': i18n.followersOnly || '팔로워만',
            'nobody': i18n.nobody || '비공개'
        };

        const selectedValueEl = button.querySelector('.selected-value');
        if (selectedValueEl) {
            selectedValueEl.textContent = textMap[value] || (i18n.everyone || '전체 공개');
        }
    },

    // 이벤트 리스너 등록
    attachEventListeners() {
        // 비공개 계정 토글
        const isPrivateToggle = document.getElementById('isPrivate');
        if (isPrivateToggle) {
            isPrivateToggle.addEventListener('change', async (e) => {
                await this.saveSetting({
                    is_private: e.target.checked
                });
            });
        }

        // 팔로워 목록 공개 범위 버튼
        const followersListButton = document.getElementById('showFollowersListButton');
        if (followersListButton) {
            followersListButton.addEventListener('click', () => {
                this.openModal('followers');
            });
        }

        // 팔로잉 목록 공개 범위 버튼
        const followingListButton = document.getElementById('showFollowingListButton');
        if (followingListButton) {
            followingListButton.addEventListener('click', () => {
                this.openModal('following');
            });
        }
    },

    // 모달 관련 이벤트 리스너 등록
    attachModalListeners() {
        const modal = document.getElementById('privacy-selection-modal');
        const closeButton = document.getElementById('close-privacy-modal');
        const options = document.querySelectorAll('.privacy-option');

        // 닫기 버튼
        if (closeButton) {
            closeButton.addEventListener('click', () => this.closeModal());
        }

        // 모달 외부 클릭
        if (modal) {
            modal.addEventListener('click', (e) => {
                if (e.target === modal) {
                    this.closeModal();
                }
            });
        }

        // 옵션 버튼들
        options.forEach(option => {
            option.addEventListener('click', async () => {
                const value = option.dataset.value;
                await this.selectOption(value);
            });
        });
    },

    // 모달 열기
    openModal(settingType) {
        this.currentSetting = settingType;

        const modal = document.getElementById('privacy-selection-modal');
        const title = document.getElementById('privacy-modal-title');
        const options = document.querySelectorAll('.privacy-option');

        // 모달 제목 설정
        const i18n = window.APP_I18N || {};
        const titleMap = {
            'followers': i18n.followersListVisibility || '팔로워 목록 공개 범위',
            'following': i18n.followingListVisibility || '팔로잉 목록 공개 범위'
        };
        if (title) {
            title.textContent = titleMap[settingType] || '공개 범위 선택';
        }

        // 현재 선택값 가져오기
        const currentValue = settingType === 'followers'
            ? (this.settings.show_followers_list || 'everyone')
            : (this.settings.show_following_list || 'everyone');

        // 옵션 선택 상태 업데이트
        options.forEach(option => {
            const checkIcon = option.querySelector('.check-icon');
            if (option.dataset.value === currentValue) {
                option.classList.add('selected');
                if (checkIcon) checkIcon.classList.remove('hidden');
            } else {
                option.classList.remove('selected');
                if (checkIcon) checkIcon.classList.add('hidden');
            }
        });

        // 모달 표시
        if (modal) {
            modal.classList.remove('hidden');
        }
    },

    // 모달 닫기
    closeModal() {
        const modal = document.getElementById('privacy-selection-modal');
        if (modal) {
            modal.classList.add('hidden');
        }
        this.currentSetting = null;
    },

    // 옵션 선택
    async selectOption(value) {
        if (!this.currentSetting) return;

        const settingKey = this.currentSetting === 'followers'
            ? 'show_followers_list'
            : 'show_following_list';

        // API 호출하여 저장
        await this.saveSetting({
            [settingKey]: value
        });

        // 모달 닫기
        this.closeModal();
    },

    // 설정 저장
    async saveSetting(data) {
        try {
            const response = await fetch('/api/accounts/privacy-settings/', {
                method: 'PATCH',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRFToken': this.getCookie('csrftoken')
                },
                credentials: 'same-origin',
                body: JSON.stringify(data)
            });

            if (response.ok) {
                this.settings = await response.json();
                this.updateUI();
                this.showSaveIndicator();
            } else {
                console.error('Failed to save privacy settings:', response.status);
                alert('설정 저장에 실패했습니다.');
                // Revert toggle on error
                this.updateUI();
            }
        } catch (error) {
            console.error('Failed to save privacy settings:', error);
            alert('설정 저장에 실패했습니다.');
            // Revert toggle on error
            this.updateUI();
        }
    },

    // 저장 완료 표시
    showSaveIndicator() {
        const indicator = document.getElementById('saveIndicator');
        if (indicator) {
            indicator.classList.add('show');

            setTimeout(() => {
                indicator.classList.remove('show');
            }, 2000);
        }
    },

    // CSRF 토큰 가져오기
    getCookie(name) {
        const match = document.cookie.match(new RegExp('(^| )' + name + '=([^;]+)'));
        return match ? match[2] : null;
    }
};

// 페이지 로드 시 초기화
document.addEventListener('DOMContentLoaded', () => {
    PrivacySettings.init();
});
