/**
 * Home Feed - Like and Comment Functionality
 * Handles likes and comments for posts in the home feed
 */

class HomeFeedManager {
    constructor() {
        this.commentPagination = {};  // { postId: { nextUrl, isLoading } }
        this.init();
    }

    init() {
        this.setupEventListeners();
    }

    /**
     * Setup event listeners for like and comment buttons
     */
    setupEventListeners() {
        // Like button click handlers (event delegation)
        document.addEventListener('click', (e) => {
            const likeBtn = e.target.closest('.feed-like-btn');
            if (likeBtn) {
                e.preventDefault();
                this.handleLikeClick(likeBtn);
            }
        });

        // Comment button click handlers (event delegation)
        document.addEventListener('click', (e) => {
            const commentBtn = e.target.closest('.feed-comment-btn');
            if (commentBtn) {
                e.preventDefault();
                this.handleCommentClick(commentBtn);
            }
        });

        // Submit comment button click handlers (event delegation)
        document.addEventListener('click', (e) => {
            const submitBtn = e.target.closest('.submit-comment-btn');
            if (submitBtn) {
                e.preventDefault();
                this.handleSubmitComment(submitBtn);
            }
        });

        // Load more comments button click handlers (event delegation)
        document.addEventListener('click', (e) => {
            const loadMoreBtn = e.target.closest('.load-more-comments-btn');
            if (loadMoreBtn) {
                e.preventDefault();
                const postId = loadMoreBtn.dataset.postId;
                this.loadComments(postId, true);
            }
        });

        // Favorite button click handlers (event delegation)
        document.addEventListener('click', (e) => {
            const favoriteBtn = e.target.closest('.feed-favorite-btn');
            if (favoriteBtn) {
                e.preventDefault();
                this.handleFavoriteClick(favoriteBtn);
            }
        });

        // Enter key in comment textarea
        document.addEventListener('keydown', (e) => {
            const textarea = e.target.closest('.comment-input');
            if (textarea && e.key === 'Enter' && !e.shiftKey) {
                e.preventDefault();
                const postId = textarea.dataset.postId;
                const submitBtn = document.querySelector(`.submit-comment-btn[data-post-id="${postId}"]`);
                if (submitBtn) {
                    submitBtn.click();  // Trigger button click instead of direct call to prevent duplicate submission
                }
            }
        });
    }

    /**
     * Handle like button click
     */
    async handleLikeClick(button) {
        const postId = button.dataset.postId;
        if (!postId) return;

        try {
            const response = await fetch(`/api/posts/${postId}/like/`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRFToken': this.getCsrfToken()
                }
            });

            if (!response.ok) {
                if (response.status === 401) {
                    const i18n = window.APP_I18N || {};
                    alert(i18n.loginRequired || '로그인이 필요합니다.');
                    window.location.href = '/accounts/login/';
                    return;
                }
                throw new Error('Failed to toggle like');
            }

            const data = await response.json();
            this.updateLikeButton(button, data.liked, data.like_count);

        } catch (error) {
            console.error('Error toggling like:', error);
            const i18n = window.APP_I18N || {};
            alert(i18n.likeFailed || '좋아요 처리 중 오류가 발생했습니다.');
        }
    }

    /**
     * Update like button state and count
     */
    updateLikeButton(button, isLiked, likeCount) {
        const likeIcon = button.querySelector('.like-icon');
        const likeText = button.querySelector('.like-text');
        const likeCountEl = button.querySelector('.like-count');

        likeCountEl.textContent = likeCount;

        if (isLiked) {
            button.classList.add('liked');
            likeIcon.setAttribute('fill', 'currentColor');
            likeText.textContent = '좋아요 취소';
        } else {
            button.classList.remove('liked');
            likeIcon.setAttribute('fill', 'none');
            likeText.textContent = '좋아요';
        }
    }

    /**
     * Handle comment button click (toggle comments section)
     */
    async handleCommentClick(button) {
        const postId = button.dataset.postId;
        if (!postId) return;

        const commentsSection = document.getElementById(`comments-${postId}`);
        if (!commentsSection) return;

        // Toggle visibility
        if (commentsSection.classList.contains('hidden')) {
            commentsSection.classList.remove('hidden');
            // Reset pagination and load first page
            delete this.commentPagination[postId];
            await this.loadComments(postId);
        } else {
            commentsSection.classList.add('hidden');
        }
    }

    /**
     * Load comments for a post with pagination support
     */
    async loadComments(postId, append = false) {
        const commentsList = document.querySelector(`.comments-list[data-post-id="${postId}"]`);
        if (!commentsList) return;

        // Ensure comments section is visible when loading (unless appending)
        if (!append) {
            const commentsSection = document.getElementById(`comments-${postId}`);
            if (commentsSection && commentsSection.classList.contains('hidden')) {
                commentsSection.classList.remove('hidden');
            }
        }

        // 로딩 중이면 중복 요청 방지
        if (this.commentPagination[postId]?.isLoading) return;

        // URL 선택: append=false이면 항상 첫 페이지, true이면 다음 페이지
        let url;
        if (!append) {
            // 첫 페이지 로드 (새로고침 또는 초기 로드)
            url = `/api/posts/${postId}/comments/?page_size=5`;
        } else {
            // 더보기: 다음 페이지 URL이 없으면 종료
            if (!this.commentPagination[postId]?.nextUrl) return;
            url = this.commentPagination[postId].nextUrl;
        }

        try {
            // 로딩 상태 설정
            if (!this.commentPagination[postId]) {
                this.commentPagination[postId] = {};
            }
            this.commentPagination[postId].isLoading = true;

            const response = await fetch(url);

            if (!response.ok) {
                throw new Error('Failed to load comments');
            }

            const data = await response.json();

            console.log('[DEBUG] Comments loaded:', {
                postId,
                url,
                append,
                resultsCount: data.results?.length,
                next: data.next,
                results: data.results
            });

            // 페이지네이션 상태 업데이트
            this.commentPagination[postId].nextUrl = data.next;
            this.commentPagination[postId].isLoading = false;

            // 댓글 렌더링
            if (append) {
                console.log('[DEBUG] Appending comments');
                this.appendComments(commentsList, data.results || []);
            } else {
                console.log('[DEBUG] Rendering comments');
                this.renderComments(commentsList, data.results || []);
            }

            // 더보기 버튼 업데이트
            this.updateLoadMoreButton(postId, data.next);

        } catch (error) {
            console.error('Error loading comments:', error);
            if (this.commentPagination[postId]) {
                this.commentPagination[postId].isLoading = false;
            }
            if (!append) {
                const i18n = window.APP_I18N || {};
                commentsList.innerHTML = `<p class="text-center text-light">${i18n.loadCommentsFailed || '댓글을 불러오는 중 오류가 발생했습니다.'}</p>`;
            }
        }
    }

    /**
     * Render comments list
     */
    renderComments(container, comments) {
        console.log('[DEBUG] renderComments called:', {
            container,
            commentsCount: comments.length,
            containerParent: container?.parentElement,
            isHidden: container?.closest('.post-comments')?.classList.contains('hidden'),
            comments: comments
        });

        const i18n = window.APP_I18N || {};
        if (comments.length === 0) {
            container.innerHTML = `<p class="no-comments">${i18n.noComments || '아직 댓글이 없습니다. 첫 번째 댓글을 작성해보세요!'}</p>`;
            return;
        }

        const commentsHTML = comments.map(comment => this.createCommentHTML(comment)).join('');
        container.innerHTML = commentsHTML;

        // Add delete button event listeners
        container.querySelectorAll('.delete-comment-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.preventDefault();
                this.handleDeleteComment(btn);
            });
        });
    }

    /**
     * Prepend a new comment to the top of the list
     */
    prependNewComment(container, comment) {
        console.log('[DEBUG] prependNewComment called:', comment);

        // 빈 목록 메시지 제거
        const noCommentsMsg = container.querySelector('.no-comments');
        if (noCommentsMsg) {
            noCommentsMsg.remove();
        }

        // 새 댓글 HTML 생성 및 최상단에 삽입
        const commentHTML = this.createCommentHTML(comment);
        container.insertAdjacentHTML('afterbegin', commentHTML);

        // 새로 추가된 댓글에 이벤트 리스너 추가
        const newCommentEl = container.firstElementChild;
        const deleteBtn = newCommentEl?.querySelector('.delete-comment-btn');
        if (deleteBtn) {
            deleteBtn.addEventListener('click', (e) => {
                e.preventDefault();
                this.handleDeleteComment(deleteBtn);
            });
        }

        console.log('[DEBUG] New comment prepended to DOM successfully');
    }

    /**
     * Append comments to existing list (for infinite scroll)
     */
    appendComments(container, comments) {
        if (comments.length === 0) return;

        // Remove "no comments" message if it exists
        const noCommentsMsg = container.querySelector('.no-comments');
        if (noCommentsMsg) {
            noCommentsMsg.remove();
        }

        const commentsHTML = comments.map(comment => this.createCommentHTML(comment)).join('');
        container.insertAdjacentHTML('beforeend', commentsHTML);

        // Add delete button event listeners for new comments
        const newComments = container.querySelectorAll('.comment-item:not([data-listeners])');
        newComments.forEach(commentEl => {
            commentEl.setAttribute('data-listeners', 'true');
            const deleteBtn = commentEl.querySelector('.delete-comment-btn');
            if (deleteBtn) {
                deleteBtn.addEventListener('click', (e) => {
                    e.preventDefault();
                    this.handleDeleteComment(deleteBtn);
                });
            }
        });
    }

    /**
     * Update load more button visibility and state
     */
    updateLoadMoreButton(postId, nextUrl) {
        const commentsSection = document.getElementById(`comments-${postId}`);
        if (!commentsSection) return;

        // Find or create load more button container
        let loadMoreContainer = commentsSection.querySelector('.load-more-container');

        if (!loadMoreContainer) {
            loadMoreContainer = document.createElement('div');
            loadMoreContainer.className = 'load-more-container';
            commentsSection.appendChild(loadMoreContainer);
        }

        if (nextUrl) {
            const i18n = window.APP_I18N || {};
            const buttonText = i18n.loadMoreComments || '댓글 더보기';

            loadMoreContainer.innerHTML = `
                <button class="load-more-comments-btn" data-post-id="${postId}">
                    ${buttonText}
                </button>
            `;
        } else {
            loadMoreContainer.innerHTML = '';
        }
    }

    /**
     * Create HTML for a single comment
     */
    createCommentHTML(comment) {
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

        return `
            <div class="comment-item">
                <div class="comment-header">
                    <div class="avatar avatar-sm">
                        ${comment.author.profile_picture ?
                            `<img src="${comment.author.profile_picture}" alt="${comment.author.nickname}">` :
                            `<svg viewBox="0 0 100 100" fill="currentColor" style="color: var(--color-secondary);">
                                <circle cx="50" cy="35" r="20"/>
                                <path d="M15 85 Q15 55 50 55 Q85 55 85 85 Z"/>
                            </svg>`
                        }
                    </div>
                    <div class="comment-info">
                        <a href="/accounts/profile/${comment.author.username}/" class="comment-author">
                            ${comment.author.nickname}
                        </a>
                        <span class="comment-time">${this.formatRelativeTime(comment.created_at)}</span>
                    </div>
                    ${actionButton}
                </div>
                <div class="comment-body">
                    <p>${this.escapeHtml(comment.content)}</p>
                </div>
            </div>
        `;
    }

    /**
     * Handle submit comment
     */
    async handleSubmitComment(button) {
        const postId = button.dataset.postId;

        // Prevent duplicate submission while processing
        if (button.disabled) return;

        button.disabled = true;
        const originalText = button.textContent;
        const i18n = window.APP_I18N || {};
        button.textContent = i18n.sending || '전송 중...';

        const textarea = document.querySelector(`.comment-input[data-post-id="${postId}"]`);

        if (!textarea) {
            button.disabled = false;
            button.textContent = originalText;
            return;
        }

        const content = textarea.value.trim();
        if (!content) {
            const i18n = window.APP_I18N || {};
            alert(i18n.commentPlaceholder || '댓글 내용을 입력해주세요.');
            button.disabled = false;
            button.textContent = originalText;
            return;
        }

        try {
            const response = await fetch(`/api/posts/${postId}/comments/`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRFToken': this.getCsrfToken()
                },
                body: JSON.stringify({ content })
            });

            if (!response.ok) {
                if (response.status === 401) {
                    alert('로그인이 필요합니다.');
                    window.location.href = '/accounts/login/';
                    return;
                }
                throw new Error('Failed to submit comment');
            }

            const newComment = await response.json();
            console.log('[DEBUG] Comment created:', newComment);

            // Clear textarea
            textarea.value = '';

            // Show comments section if hidden (FORCED)
            const commentsSection = document.getElementById(`comments-${postId}`);
            console.log('[DEBUG] Comments section before display:', {
                sectionId: `comments-${postId}`,
                section: commentsSection,
                hasHidden: commentsSection?.classList.contains('hidden'),
                classList: commentsSection ? Array.from(commentsSection.classList) : null,
                display: commentsSection ? window.getComputedStyle(commentsSection).display : null
            });

            if (commentsSection) {
                // 조건 없이 무조건 hidden 제거 및 display 초기화
                commentsSection.classList.remove('hidden');
                commentsSection.style.display = '';  // inline style 초기화
                console.log('[DEBUG] Forced section visible (removed hidden class + reset inline style)');
            } else {
                console.error('[DEBUG] Comments section NOT FOUND!', `comments-${postId}`);
            }

            console.log('[DEBUG] Comments section after display:', {
                hasHidden: commentsSection?.classList.contains('hidden'),
                classList: commentsSection ? Array.from(commentsSection.classList) : null,
                inlineDisplay: commentsSection?.style.display,
                computedDisplay: commentsSection ? window.getComputedStyle(commentsSection).display : null
            });

            // Add new comment directly to DOM (no need to reload)
            const commentsList = document.querySelector(`.comments-list[data-post-id="${postId}"]`);

            if (commentsList) {
                console.log('[DEBUG] Adding new comment directly to DOM');
                this.prependNewComment(commentsList, newComment);
            } else {
                console.error('[DEBUG] Comments list container NOT FOUND for post:', postId);
                // Fallback: reload all comments
                console.log('[DEBUG] Falling back to loadComments');
                delete this.commentPagination[postId];
                await this.loadComments(postId);
            }

            // Update comment count
            this.updateCommentCount(postId, 1);

        } catch (error) {
            console.error('Error submitting comment:', error);
            const i18n = window.APP_I18N || {};
            alert(i18n.commentPostFailed || '댓글 작성 중 오류가 발생했습니다.');
        } finally {
            // Re-enable button
            button.disabled = false;
            button.textContent = originalText;
        }
    }

    /**
     * Handle delete comment
     */
    async handleDeleteComment(button) {
        const i18n = window.APP_I18N || {};
        if (!confirm(i18n.deleteCommentConfirm || '댓글을 삭제하시겠습니까?')) return;

        const commentId = button.dataset.commentId;
        const postId = button.dataset.postId;

        try {
            const response = await fetch(`/api/posts/${postId}/comments/${commentId}/`, {
                method: 'DELETE',
                headers: {
                    'X-CSRFToken': this.getCsrfToken()
                }
            });

            if (!response.ok) {
                throw new Error('Failed to delete comment');
            }

            // Show comments section if hidden
            const commentsSection = document.getElementById(`comments-${postId}`);
            if (commentsSection && commentsSection.classList.contains('hidden')) {
                commentsSection.classList.remove('hidden');
            }

            // Reset pagination and reload comments from first page
            delete this.commentPagination[postId];
            await this.loadComments(postId);

            // Update comment count
            this.updateCommentCount(postId, -1);

        } catch (error) {
            console.error('Error deleting comment:', error);
            const i18n = window.APP_I18N || {};
            alert(i18n.commentDeleteFailed || '댓글 삭제 중 오류가 발생했습니다.');
        }
    }

    /**
     * Update comment count
     */
    updateCommentCount(postId, delta) {
        const commentBtn = document.querySelector(`.feed-comment-btn[data-post-id="${postId}"]`);
        if (!commentBtn) return;

        const countEl = commentBtn.querySelector('.comment-count');
        if (!countEl) return;

        const currentCount = parseInt(countEl.textContent) || 0;
        const newCount = Math.max(0, currentCount + delta);
        countEl.textContent = newCount;
    }

    /**
     * Get CSRF token from cookie
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
     * Format relative time
     */
    formatRelativeTime(timestamp) {
        const now = new Date();
        const past = new Date(timestamp);
        const diffSec = Math.floor((now - past) / 1000);
        const diffMin = Math.floor(diffSec / 60);
        const diffHour = Math.floor(diffMin / 60);
        const diffDay = Math.floor(diffHour / 24);

        const i18n = window.APP_I18N || {};
        if (diffSec < 60) return i18n.timeJustNow || '방금 전';
        if (diffMin < 60) return `${diffMin}${i18n.timeMinutesAgo || '분 전'}`;
        if (diffHour < 24) return `${diffHour}${i18n.timeHoursAgo || '시간 전'}`;
        if (diffDay < 7) return `${diffDay}${i18n.timeDaysAgo || '일 전'}`;
        return past.toLocaleDateString('ko-KR');
    }

    /**
     * Escape HTML to prevent XSS
     */
    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    /**
     * Handle favorite button click
     */
    async handleFavoriteClick(button) {
        const postId = button.dataset.postId;
        if (!postId) return;

        // Check if user is logged in
        if (!window.CURRENT_USER_ID) {
            window.location.href = `/accounts/login/?next=${window.location.pathname}`;
            return;
        }

        try {
            const response = await fetch(`/api/posts/${postId}/favorite/`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRFToken': this.getCsrfToken()
                },
                credentials: 'same-origin'
            });

            if (!response.ok) {
                if (response.status === 401) {
                    alert('로그인이 필요합니다.');
                    window.location.href = '/accounts/login/';
                    return;
                }
                throw new Error('Failed to toggle favorite');
            }

            const data = await response.json();
            this.updateFavoriteButton(button, data.favorited);

        } catch (error) {
            console.error('Error toggling favorite:', error);
            const i18n = window.APP_I18N || {};
            alert(i18n.favoriteFailed || '즐겨찾기 처리 중 오류가 발생했습니다.');
        }
    }

    /**
     * Update favorite button state
     */
    updateFavoriteButton(button, isFavorited) {
        const icon = button.querySelector('.favorite-icon');

        if (isFavorited) {
            button.classList.add('favorited');
            icon.setAttribute('fill', 'currentColor');
        } else {
            button.classList.remove('favorited');
            icon.setAttribute('fill', 'none');
        }
    }
}

// Initialize on DOMContentLoaded
document.addEventListener('DOMContentLoaded', () => {
    new HomeFeedManager();
});

/**
 * Global function to handle comment options button click
 */
function handleCommentOptions(button, event) {
    event.preventDefault();
    event.stopPropagation();

    const commentId = button.dataset.commentId;
    const postId = button.dataset.postId;
    const authorId = button.dataset.authorId;
    const isAuthor = button.dataset.isAuthor === 'true';

    if (isAuthor) {
        // Show delete confirmation for own comment
        const i18n = window.APP_I18N || {};
        if (confirm(i18n.deleteCommentConfirm || '댓글을 삭제하시겠습니까?')) {
            deleteComment(commentId, postId);
        }
    } else {
        // Show action modal for others' comments (block/report)
        if (window.commentActionsManager) {
            window.commentActionsManager.openActionModal(commentId, postId, authorId);
        }
    }
}

/**
 * Delete comment function
 */
async function deleteComment(commentId, postId) {
    try {
        const csrfToken = document.querySelector('[name=csrfmiddlewaretoken]')?.value || '';

        const response = await fetch(`/api/posts/${postId}/comments/${commentId}/`, {
            method: 'DELETE',
            headers: {
                'X-CSRFToken': csrfToken
            },
            credentials: 'same-origin'
        });

        if (response.ok) {
            // Remove comment from DOM or reload
            location.reload();
        } else {
            const i18n = window.APP_I18N || {};
            alert(i18n.commentDeleteFailed || '댓글 삭제에 실패했습니다.');
        }
    } catch (error) {
        console.error('Delete comment error:', error);
        const i18n = window.APP_I18N || {};
        alert(i18n.error || '오류가 발생했습니다. 다시 시도해주세요.');
    }
}
