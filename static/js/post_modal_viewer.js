/**
 * Post Modal Viewer with Navigation
 * Instagram-style post viewer with keyboard and swipe support
 */

class PostModalViewer {
    constructor() {
        if (window.DEBUG) console.log('[PostModalViewer] 생성자 실행');
        this.modal = document.getElementById('post-view-modal');
        if (window.DEBUG) console.log('[PostModalViewer] modal 요소:', this.modal);
        this.posts = [];  // 전체 포스트 데이터
        this.currentIndex = 0;
        this.currentPostId = null;  // 현재 포스트 ID
        this.currentComments = [];  // 현재 댓글 목록
        this.touchStartY = 0;
        this.touchEndY = 0;
        this.currentUser = window.CURRENT_USER;  // 현재 로그인한 사용자
        this.currentAuthorUsername = null;  // 현재 게시물 작성자

        this.init();
    }

    init() {
        // 이벤트 리스너 등록
        this.attachEventListeners();
        // 포스트 데이터 로드
        this.loadPostsData();
    }

    /**
     * 페이지의 모든 포스트 데이터 수집
     */
    loadPostsData() {
        if (window.DEBUG) console.log('[PostModalViewer] loadPostsData 시작');

        // Try multiple selectors: .post-grid-item (profile), .post-card (favorites/explore)
        let postElements = document.querySelectorAll('.post-grid-item');
        if (window.DEBUG) console.log('[PostModalViewer] 찾은 .post-grid-item 개수:', postElements.length);

        // If no post-grid-item found, try post-card
        if (postElements.length === 0) {
            postElements = document.querySelectorAll('.post-card');
            if (window.DEBUG) console.log('[PostModalViewer] 찾은 .post-card 개수:', postElements.length);
        }

        // 검색 페이지나 포스트가 없는 페이지는 빈 배열로 초기화
        if (postElements.length === 0) {
            if (window.DEBUG) console.log('[PostModalViewer] 포스트 요소 없음');
            this.posts = [];
        } else {
            // 포스트 요소를 배열로 변환
            this.posts = Array.from(postElements).map((el, index) => ({
                id: el.dataset.postId,
                index: index,
                element: el
            }));
        }

        // 총 포스트 수 업데이트
        const totalCountEl = document.getElementById('total-posts-count');
        if (totalCountEl) {
            totalCountEl.textContent = this.posts.length;
        }
    }

    /**
     * 모달 열기
     * @param {number} postId - 포스트 ID
     * @param {number} index - 포스트 인덱스
     */
    async openModal(postId, index) {
        if (window.DEBUG) {
            console.log('[PostModalViewer] openModal 시작:', {postId, index});
            console.log('[PostModalViewer] 현재 posts 배열:', this.posts);
            console.log('[PostModalViewer] modal 요소 존재:', !!this.modal);
        }

        // 모달 요소 검증
        if (!this.modal) {
            console.error('[PostModalViewer] 모달 요소를 찾을 수 없음!');
            this.modal = document.getElementById('post-view-modal');
            if (!this.modal) {
                console.error('[PostModalViewer] post-view-modal ID를 가진 요소가 DOM에 없음!');
                return;
            }
        }

        this.currentIndex = parseInt(index);
        this.modal.classList.remove('hidden');
        document.body.style.overflow = 'hidden';  // 배경 스크롤 방지

        // 포스트 데이터 로드 및 표시
        await this.loadPostContent(postId);

        // 네비게이션 버튼 상태 업데이트
        this.updateNavigationButtons();

        // 현재 인덱스 표시
        const currentIndexEl = document.getElementById('current-post-index');
        if (currentIndexEl) {
            currentIndexEl.textContent = parseInt(index) + 1;
        }
    }

    /**
     * 모달 닫기
     */
    closeModal() {
        this.modal.classList.add('hidden');
        document.body.style.overflow = '';  // 배경 스크롤 복원
    }

    /**
     * API에서 포스트 상세 데이터 가져오기
     * @param {number} postId - 포스트 ID
     */
    async loadPostContent(postId) {
        if (window.DEBUG) console.log('[PostModalViewer] loadPostContent 시작 - postId:', postId);
        try {
            const url = `/api/posts/${postId}/`;
            if (window.DEBUG) console.log('[PostModalViewer] API 호출:', url);
            const response = await fetch(url);

            if (!response.ok) {
                console.error('[PostModalViewer] API 응답 오류:', response.status, response.statusText);
                throw new Error('Failed to load post');
            }

            const post = await response.json();
            if (window.DEBUG) console.log('[PostModalViewer] API 응답 데이터:', post);
            this.renderPost(post);
        } catch (error) {
            console.error('[PostModalViewer] loadPostContent 오류:', error);
            alert('포스트를 불러오는 중 오류가 발생했습니다.');
            this.closeModal();
        }
    }

    /**
     * 포스트 데이터를 모달에 렌더링
     * @param {Object} post - 포스트 데이터
     */
    renderPost(post) {
        if (window.DEBUG) console.log('[PostModalViewer] renderPost 시작 - post:', post);

        // 작성자 정보
        const avatar = document.getElementById('modal-author-avatar');
        if (post.author.profile_picture) {
            avatar.src = post.author.profile_picture;
        } else {
            // 기본 아바타 SVG
            avatar.src = 'data:image/svg+xml,' + encodeURIComponent(`
                <svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
                    <circle cx="50" cy="35" r="20" fill="#4F46E5"/>
                    <path d="M15 85 Q15 55 50 55 Q85 55 85 85 Z" fill="#4F46E5"/>
                </svg>
            `);
        }
        avatar.alt = post.author.nickname;

        const authorName = document.getElementById('modal-author-name');
        authorName.textContent = post.author.nickname;
        authorName.href = `/accounts/profile/${post.author.username}/`;

        // 언어 정보
        const languageInfo = document.getElementById('modal-language-info');
        const languageSeparator = document.getElementById('modal-language-separator');
        if (post.native_language && post.target_language) {
            languageInfo.textContent = `${post.native_language.substring(0, 2)} → ${post.target_language.substring(0, 2)}`;
            languageInfo.style.display = 'inline';
            if (languageSeparator) languageSeparator.style.display = 'inline';
        } else {
            languageInfo.classList.add('hidden');
            if (languageSeparator) languageSeparator.classList.add('hidden');
        }

        // 작성 시간
        const postTime = document.getElementById('modal-post-time');
        postTime.textContent = this.formatTimeAgo(post.created_at);

        // 포스트 본문
        const content = document.getElementById('modal-post-content');
        // Translate deleted post message if needed
        let postContent = post.content;
        if (postContent === '게시물은 신고에 의해 삭제되었습니다.') {
            postContent = window.APP_I18N.deletedPostMessage || postContent;
        }
        content.innerHTML = postContent.replace(/\n/g, '<br>');

        // 해시태그
        const hashtagsContainer = document.getElementById('modal-hashtags');
        hashtagsContainer.innerHTML = '';
        if (post.hashtags && post.hashtags.length > 0) {
            post.hashtags.forEach(tag => {
                const badge = document.createElement('span');
                badge.className = 'badge badge-primary';
                badge.textContent = `#${tag.name}`;
                hashtagsContainer.appendChild(badge);
            });
            hashtagsContainer.classList.remove('hidden');
        } else {
            hashtagsContainer.classList.add('hidden');
        }

        // 현재 포스트 ID 및 작성자 정보 저장
        this.currentPostId = post.id;
        this.currentAuthorUsername = post.author.username;

        // 게시물 옵션 버튼 표시/숨김 (본인 글인지 확인)
        const optionsBtn = document.getElementById('modal-post-options-btn');
        if (optionsBtn) {
            optionsBtn.dataset.postId = post.id;
            optionsBtn.dataset.authorUsername = post.author.username;

            // 디버깅 로그
            console.log('[PostModalViewer] Current user:', this.currentUser);
            console.log('[PostModalViewer] Post author:', this.currentAuthorUsername);
            console.log('[PostModalViewer] Is own post:', this.isOwnPost());
            console.log('[PostModalViewer] Options button element:', optionsBtn);

            if (this.isOwnPost()) {
                optionsBtn.classList.remove('hidden');
                console.log('[PostModalViewer] Button shown');
            } else {
                optionsBtn.classList.add('hidden');
                console.log('[PostModalViewer] Button hidden');
            }
        } else {
            console.error('[PostModalViewer] Options button not found!');
        }

        // 좋아요 버튼 상태 및 카운트 업데이트
        this.updateLikeButton(post.is_liked, post.like_count, post.id);

        // 즐겨찾기 버튼 상태 업데이트
        this.updateFavoriteButton(post.is_favorited, post.id);

        // 댓글 카운트 업데이트
        const commentCount = document.querySelector('.comment-count');
        if (commentCount) {
            commentCount.textContent = post.comment_count || 0;
        }

        // 댓글 섹션 숨김 처리 (초기화)
        const commentsSection = document.getElementById('modal-comments-section');
        if (commentsSection) {
            commentsSection.classList.add('hidden');
        }
    }

    /**
     * 이전 포스트로 이동
     */
    goToPrevPost() {
        if (this.currentIndex > 0) {
            const newIndex = this.currentIndex - 1;
            const prevPost = this.posts[newIndex];

            // 데이터 소스 감지: element 속성 있으면 프로필 페이지, 없으면 검색/API 페이지
            const postId = prevPost.id;
            const postIndex = prevPost.index !== undefined ? prevPost.index : newIndex;

            this.openModal(postId, postIndex);
        }
    }

    /**
     * 다음 포스트로 이동
     */
    goToNextPost() {
        if (this.currentIndex < this.posts.length - 1) {
            const newIndex = this.currentIndex + 1;
            const nextPost = this.posts[newIndex];

            // 데이터 소스 감지: element 속성 있으면 프로필 페이지, 없으면 검색/API 페이지
            const postId = nextPost.id;
            const postIndex = nextPost.index !== undefined ? nextPost.index : newIndex;

            this.openModal(postId, postIndex);
        }
    }

    /**
     * 네비게이션 버튼 상태 업데이트
     */
    updateNavigationButtons() {
        const prevBtn = document.getElementById('prev-post-btn');
        const nextBtn = document.getElementById('next-post-btn');

        if (prevBtn) prevBtn.disabled = this.currentIndex === 0;
        if (nextBtn) nextBtn.disabled = this.currentIndex === this.posts.length - 1;
    }

    /**
     * 이벤트 리스너 등록
     */
    attachEventListeners() {
        // 닫기 버튼
        const closeBtn = document.getElementById('close-post-modal');
        if (closeBtn) {
            closeBtn.addEventListener('click', () => {
                this.closeModal();
            });
        }

        // 네비게이션 버튼
        const prevBtn = document.getElementById('prev-post-btn');
        if (prevBtn) {
            prevBtn.addEventListener('click', () => {
                this.goToPrevPost();
            });
        }

        const nextBtn = document.getElementById('next-post-btn');
        if (nextBtn) {
            nextBtn.addEventListener('click', () => {
                this.goToNextPost();
            });
        }

        // 오버레이 클릭 시 닫기
        if (this.modal) {
            this.modal.addEventListener('click', (e) => {
                if (e.target === this.modal) {
                    this.closeModal();
                }
            });
        }

        // 키보드 네비게이션
        document.addEventListener('keydown', (e) => {
            if (this.modal && !this.modal.classList.contains('hidden')) {
                switch(e.key) {
                    case 'Escape':
                        this.closeModal();
                        break;
                    case 'ArrowUp':
                    case 'ArrowLeft':
                        e.preventDefault();
                        this.goToPrevPost();
                        break;
                    case 'ArrowDown':
                    case 'ArrowRight':
                        e.preventDefault();
                        this.goToNextPost();
                        break;
                }
            }
        });

        // 터치 스와이프 (모바일)
        if (this.modal) {
            this.modal.addEventListener('touchstart', (e) => {
                this.touchStartY = e.changedTouches[0].screenY;
            }, { passive: true });

            this.modal.addEventListener('touchend', (e) => {
                this.touchEndY = e.changedTouches[0].screenY;
                this.handleSwipe();
            }, { passive: true });
        }

        // 좋아요 버튼
        const likeBtn = document.getElementById('modal-like-btn');
        if (likeBtn) {
            likeBtn.addEventListener('click', () => {
                this.toggleLike();
            });
        }

        // 즐겨찾기 버튼
        const favoriteBtn = document.getElementById('modal-favorite-btn');
        if (favoriteBtn) {
            favoriteBtn.addEventListener('click', () => {
                this.toggleFavorite();
            });
        }

        // 댓글 버튼
        const commentBtn = document.getElementById('modal-comment-btn');
        if (commentBtn) {
            commentBtn.addEventListener('click', () => {
                this.toggleCommentsSection();
            });
        }

        // 댓글 작성 버튼
        const submitCommentBtn = document.getElementById('submit-comment-btn');
        if (submitCommentBtn) {
            submitCommentBtn.addEventListener('click', () => {
                this.submitComment();
            });
        }

        // 댓글 입력 - Ctrl+Enter로 제출
        const commentInput = document.getElementById('comment-input');
        if (commentInput) {
            commentInput.addEventListener('keydown', (e) => {
                if (e.ctrlKey && e.key === 'Enter') {
                    this.submitComment();
                }
            });
        }

        // 게시물 옵션 버튼 (점 3개)
        const postOptionsBtn = document.getElementById('modal-post-options-btn');
        if (postOptionsBtn) {
            postOptionsBtn.addEventListener('click', (e) => {
                e.preventDefault();
                e.stopPropagation();
                this.openPostOptions();
            });
        }
    }

    /**
     * 스와이프 제스처 처리
     */
    handleSwipe() {
        const swipeThreshold = 50;  // 최소 스와이프 거리 (px)
        const diff = this.touchStartY - this.touchEndY;

        if (Math.abs(diff) > swipeThreshold) {
            if (diff > 0) {
                // 위로 스와이프 → 다음 포스트
                this.goToNextPost();
            } else {
                // 아래로 스와이프 → 이전 포스트
                this.goToPrevPost();
            }
        }
    }

    /**
     * 상대 시간 포맷
     * @param {string} timestamp - ISO 타임스탬프
     * @returns {string} - 예: "3시간 전"
     */
    formatTimeAgo(timestamp) {
        const now = new Date();
        const postDate = new Date(timestamp);
        const diffMs = now - postDate;
        const diffMins = Math.floor(diffMs / 60000);
        const diffHours = Math.floor(diffMs / 3600000);
        const diffDays = Math.floor(diffMs / 86400000);

        if (diffMins < 1) return '방금 전';
        if (diffMins < 60) return `${diffMins}분 전`;
        if (diffHours < 24) return `${diffHours}시간 전`;
        if (diffDays < 7) return `${diffDays}일 전`;

        return postDate.toLocaleDateString('ko-KR');
    }

    /**
     * 좋아요 버튼 상태 업데이트
     */
    updateLikeButton(isLiked, likeCount, postId) {
        const likeBtn = document.getElementById('modal-like-btn');
        const likeIcon = likeBtn.querySelector('.like-icon');
        const likeText = likeBtn.querySelector('.like-text');
        const likeCountEl = likeBtn.querySelector('.like-count');

        likeBtn.dataset.postId = postId;
        likeCountEl.textContent = likeCount || 0;

        if (isLiked) {
            likeBtn.classList.add('liked');
            likeIcon.setAttribute('fill', 'currentColor');
            likeText.textContent = '좋아요 취소';
        } else {
            likeBtn.classList.remove('liked');
            likeIcon.setAttribute('fill', 'none');
            likeText.textContent = '좋아요';
        }
    }

    /**
     * 좋아요 토글
     */
    async toggleLike() {
        if (!this.currentPostId) return;

        try {
            const response = await fetch(`/api/posts/${this.currentPostId}/like/`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRFToken': this.getCsrfToken()
                }
            });

            if (!response.ok) {
                if (response.status === 401) {
                    alert('로그인이 필요합니다.');
                    return;
                }
                throw new Error('Failed to toggle like');
            }

            const data = await response.json();
            this.updateLikeButton(data.liked, data.like_count, this.currentPostId);

        } catch (error) {
            console.error('Error toggling like:', error);
            alert('좋아요 처리 중 오류가 발생했습니다.');
        }
    }

    /**
     * 즐겨찾기 버튼 상태 업데이트
     */
    updateFavoriteButton(isFavorited, postId) {
        const favoriteBtn = document.getElementById('modal-favorite-btn');
        const favoriteIcon = favoriteBtn.querySelector('.favorite-icon');
        const favoriteText = favoriteBtn.querySelector('.favorite-text');

        favoriteBtn.dataset.postId = postId;

        if (isFavorited) {
            favoriteBtn.classList.add('favorited');
            favoriteIcon.setAttribute('fill', 'currentColor');
            favoriteText.textContent = '즐겨찾기 취소';
        } else {
            favoriteBtn.classList.remove('favorited');
            favoriteIcon.setAttribute('fill', 'none');
            favoriteText.textContent = '즐겨찾기';
        }
    }

    /**
     * 즐겨찾기 토글
     */
    async toggleFavorite() {
        if (!this.currentPostId) return;

        try {
            const response = await fetch(`/api/posts/${this.currentPostId}/favorite/`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRFToken': this.getCsrfToken()
                }
            });

            if (!response.ok) {
                if (response.status === 401) {
                    alert('로그인이 필요합니다.');
                    return;
                }
                throw new Error('Failed to toggle favorite');
            }

            const data = await response.json();
            this.updateFavoriteButton(data.favorited, this.currentPostId);

        } catch (error) {
            console.error('Error toggling favorite:', error);
            alert('즐겨찾기 처리 중 오류가 발생했습니다.');
        }
    }

    /**
     * 댓글 목록 로드
     */
    async loadComments() {
        if (!this.currentPostId) return;

        try {
            const response = await fetch(`/api/posts/${this.currentPostId}/comments/`);
            if (!response.ok) throw new Error('Failed to load comments');

            const data = await response.json();
            this.currentComments = data.results || data;
            this.renderComments(this.currentComments);

        } catch (error) {
            console.error('Error loading comments:', error);
        }
    }

    /**
     * 댓글 목록 렌더링
     */
    renderComments(comments) {
        const commentsList = document.getElementById('comments-list');
        commentsList.innerHTML = '';

        if (comments.length === 0) {
            commentsList.innerHTML = '<p class="no-comments">댓글이 없습니다.</p>';
            return;
        }

        comments.forEach(comment => {
            const commentEl = document.createElement('div');
            commentEl.className = 'comment-item';
            commentEl.dataset.commentId = comment.id;

            const avatarSrc = comment.author.profile_picture || this.getDefaultAvatar();
            const timeAgo = this.formatTimeAgo(comment.created_at);

            // Get current user ID
            const currentUser = document.querySelector('[data-user-id]')?.dataset.userId;
            const isAuthor = currentUser && parseInt(currentUser) === comment.author.id;

            // Show ... button for all comments
            const actionButton = `
                <button class="comment-options-btn"
                        data-comment-id="${comment.id}"
                        data-post-id="${comment.post}"
                        data-author-id="${comment.author.id}"
                        data-is-author="${isAuthor}"
                        onclick="handleCommentOptions(this, event)">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <circle cx="12" cy="12" r="1"/>
                        <circle cx="19" cy="12" r="1"/>
                        <circle cx="5" cy="12" r="1"/>
                    </svg>
                </button>
            `;

            commentEl.innerHTML = `
                <div class="comment-header">
                    <div class="avatar avatar-sm">
                        <img src="${avatarSrc}" alt="${comment.author.nickname}">
                    </div>
                    <div class="comment-info">
                        <a href="/accounts/profile/${comment.author.username}/" class="comment-author">
                            ${comment.author.nickname}
                        </a>
                        <span class="comment-time">${timeAgo}</span>
                    </div>
                    ${actionButton}
                </div>
                <div class="comment-body">
                    <p>${this.escapeHtml(comment.content)}</p>
                </div>
            `;

            commentsList.appendChild(commentEl);
        });
    }

    /**
     * 댓글 작성
     */
    async submitComment() {
        if (!this.currentPostId) return;

        const commentInput = document.getElementById('comment-input');
        const content = commentInput.value.trim();

        if (!content) {
            const i18n = window.APP_I18N || {};
            alert(i18n.commentPlaceholder || '댓글 내용을 입력해주세요.');
            return;
        }

        try {
            const response = await fetch(`/api/posts/${this.currentPostId}/comments/`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRFToken': this.getCsrfToken()
                },
                body: JSON.stringify({ content })
            });

            if (!response.ok) {
                if (response.status === 401) {
                    const i18n = window.APP_I18N || {};
                    alert(i18n.loginRequired || '로그인이 필요합니다.');
                    return;
                }
                throw new Error('Failed to post comment');
            }

            const comment = await response.json();

            // Clear input
            commentInput.value = '';

            // Ensure comments section is visible (강화된 표시 로직)
            const commentsSection = document.getElementById('modal-comments-section');
            if (commentsSection) {
                commentsSection.classList.remove('hidden');
                commentsSection.style.display = 'block';  // 강제로 block 설정
                commentsSection.style.visibility = 'visible';  // 추가 안전장치
                console.log('[PostModalViewer] Comments section forced visible');
            }

            // Add new comment to the beginning of the list
            this.currentComments.unshift(comment);

            // Re-render comments with new comment included
            this.renderComments(this.currentComments);

            // Update comment count in modal header
            const commentCountEl = document.querySelector('.comment-count');
            if (commentCountEl) {
                const currentCount = parseInt(commentCountEl.textContent) || 0;
                commentCountEl.textContent = currentCount + 1;
            }

            // Also update comment count in feed (if visible)
            const feedCommentCount = document.querySelector(`.feed-comment-btn[data-post-id="${this.currentPostId}"] .comment-count`);
            if (feedCommentCount) {
                const feedCurrentCount = parseInt(feedCommentCount.textContent) || 0;
                feedCommentCount.textContent = feedCurrentCount + 1;
            }

            console.log('[PostModalViewer] Comment added successfully:', comment);

        } catch (error) {
            console.error('Error posting comment:', error);
            const i18n = window.APP_I18N || {};
            alert(i18n.commentPostFailed || '댓글 작성 중 오류가 발생했습니다.');
        }
    }

    /**
     * 댓글 섹션 토글
     */
    toggleCommentsSection() {
        const commentsSection = document.getElementById('modal-comments-section');

        if (commentsSection.classList.contains('hidden')) {
            commentsSection.classList.remove('hidden');
            this.loadComments();
        } else {
            commentsSection.classList.add('hidden');
        }
    }

    /**
     * CSRF 토큰 가져오기
     */
    getCsrfToken() {
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
     * 기본 아바타 SVG 가져오기
     */
    getDefaultAvatar() {
        return 'data:image/svg+xml,' + encodeURIComponent(`
            <svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
                <circle cx="50" cy="35" r="20" fill="#4F46E5"/>
                <path d="M15 85 Q15 55 50 55 Q85 55 85 85 Z" fill="#4F46E5"/>
            </svg>
        `);
    }

    /**
     * HTML 이스케이프 (XSS 방지)
     */
    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    /**
     * 본인 게시물인지 확인
     */
    isOwnPost() {
        return this.currentAuthorUsername === this.currentUser;
    }

    /**
     * 게시물 옵션 모달 열기
     */
    openPostOptions() {
        if (window.postActionsManager && this.currentPostId) {
            // PostActionsManager에 현재 게시물 정보 전달
            window.postActionsManager.currentPostId = this.currentPostId;
            window.postActionsManager.currentAuthorUsername = this.currentAuthorUsername;
            window.postActionsManager.openModal();
        }
    }
}

// 전역 함수 (HTML onclick에서 호출)
window.postModalViewer = null;

function openPostModal(postId, index) {
    if (window.DEBUG) console.log('[전역] openPostModal 호출됨:', {postId, index});

    if (!window.postModalViewer) {
        if (window.DEBUG) console.log('[전역] PostModalViewer 생성 중...');
        window.postModalViewer = new PostModalViewer();
    }

    if (window.DEBUG) console.log('[전역] 현재 posts 배열:', window.postModalViewer.posts);
    window.postModalViewer.openModal(postId, index);
}

// DOM 로드 후 초기화
document.addEventListener('DOMContentLoaded', () => {
    window.postModalViewer = new PostModalViewer();
});
