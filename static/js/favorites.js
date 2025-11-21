/**
 * Favorites Page - Main JavaScript
 * Handles loading and displaying all favorited content
 */

class FavoritesManager {
  constructor() {
    // State
    this.chatRoomFavorites = [];
    this.postFavorites = [];
    this.currentTab = 'chat-rooms';

    // DOM Elements
    this.tabs = document.querySelectorAll('.tab-button');
    this.tabContents = document.querySelectorAll('.tab-content');
    this.loadingState = document.getElementById('loading-state');

    // Chat room elements
    this.chatGrid = document.getElementById('chat-rooms-grid');
    this.chatEmpty = document.getElementById('chat-empty-state');
    this.chatCount = document.getElementById('chat-count');

    // Post elements
    this.postsFeed = document.getElementById('posts-feed');
    this.postsEmpty = document.getElementById('posts-empty-state');
    this.postCount = document.getElementById('post-count');

    this.init();
  }

  async init() {
    this.attachEventListeners();
    await this.loadFavorites();
  }

  attachEventListeners() {
    // Tab switching
    this.tabs.forEach(tab => {
      tab.addEventListener('click', () => {
        const tabName = tab.dataset.tab;
        this.switchTab(tabName);
      });
    });

    // Post like buttons (event delegation)
    document.addEventListener('click', (e) => {
      const likeBtn = e.target.closest('.feed-like-btn');
      if (likeBtn && this.currentTab === 'posts') {
        e.preventDefault();
        this.handlePostLike(likeBtn);
      }
    });

    // Post favorite buttons (event delegation)
    document.addEventListener('click', (e) => {
      const favoriteBtn = e.target.closest('.post-favorite-btn');
      if (favoriteBtn && this.currentTab === 'posts') {
        e.preventDefault();
        this.handlePostUnfavorite(favoriteBtn);
      }
    });

    // Post card clicks to open modal (event delegation)
    document.addEventListener('click', (e) => {
      const postCard = e.target.closest('.post-card');
      if (postCard && this.currentTab === 'posts' && !e.target.closest('button') && !e.target.closest('a')) {
        e.preventDefault();
        const postId = postCard.dataset.postId;
        const index = Array.from(document.querySelectorAll('.post-card')).indexOf(postCard);
        if (window.postModalViewer) {
          window.postModalViewer.openModal(postId, index);
        }
      }
    });
  }

  switchTab(tabName) {
    this.currentTab = tabName;

    // Update tab buttons
    this.tabs.forEach(tab => {
      if (tab.dataset.tab === tabName) {
        tab.classList.add('active');
      } else {
        tab.classList.remove('active');
      }
    });

    // Update tab contents
    this.tabContents.forEach(content => {
      if (content.id === `${tabName}-tab`) {
        content.classList.add('active');
      } else {
        content.classList.remove('active');
      }
    });
  }

  async loadFavorites() {
    this.showLoading();

    try {
      const response = await fetch('/accounts/api/favorites/');

      if (!response.ok) {
        throw new Error('Failed to load favorites');
      }

      const data = await response.json();
      this.chatRoomFavorites = data.chat_rooms || [];
      this.postFavorites = data.posts || [];

      this.updateCounts();
      this.renderChatRooms();
      this.renderPosts();
      this.hideLoading();
    } catch (error) {
      console.error('Error loading favorites:', error);
      this.hideLoading();
      this.showError('즐겨찾기를 불러오는데 실패했습니다.');
    }
  }

  updateCounts() {
    if (this.chatCount) {
      this.chatCount.textContent = this.chatRoomFavorites.length;
    }
    if (this.postCount) {
      this.postCount.textContent = this.postFavorites.length;
    }
  }

  renderChatRooms() {
    if (!this.chatGrid) return;

    // Clear existing content
    this.chatGrid.innerHTML = '';

    if (this.chatRoomFavorites.length === 0) {
      this.showChatEmpty();
      return;
    }

    this.hideChatEmpty();
    this.chatGrid.classList.remove('hidden');

    // Render chat room cards
    this.chatRoomFavorites.forEach(favorite => {
      const card = this.createChatRoomCard(favorite);
      this.chatGrid.appendChild(card);
    });
  }

  createChatRoomCard(favorite) {
    const room = favorite.room;
    const card = document.createElement('div');
    card.className = 'favorite-chat-card';
    card.dataset.favoriteId = favorite.id;
    card.dataset.roomId = room.id;

    const categoryDisplay = this.getCategoryDisplay(room.category);
    const participantCount = room.participant_count || 0;

    card.innerHTML = `
      <div class="card-header">
        <h3 class="card-title">${this.escapeHtml(room.name)}</h3>
        <button class="btn-unfavorite" data-favorite-id="${favorite.id}" aria-label="즐겨찾기 해제">
          <svg viewBox="0 0 24 24" fill="currentColor">
            <path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/>
          </svg>
        </button>
      </div>
      <div class="card-meta">
        <span class="badge badge-primary">${categoryDisplay}</span>
        <div class="participant-info">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
            <circle cx="9" cy="7" r="4"/>
            <path d="M23 21v-2a4 4 0 0 0-3-3.87"/>
            <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
          </svg>
          <span>${participantCount}명</span>
        </div>
      </div>
      <div class="card-actions">
        <button class="btn btn-primary btn-enter" data-room-id="${room.id}">
          입장하기
        </button>
      </div>
    `;

    // Add event listeners
    const unfavoriteBtn = card.querySelector('.btn-unfavorite');
    unfavoriteBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      this.unfavoriteRoom(favorite.id, room.id);
    });

    const enterBtn = card.querySelector('.btn-enter');
    enterBtn.addEventListener('click', () => {
      window.location.href = `/learning/chat/${room.id}/`;
    });

    return card;
  }

  getCategoryDisplay(category) {
    const categories = {
      'language': '언어교환',
      'study': '스터디',
      'culture': '문화교류',
      'qa': '질문답변',
      'freetalk': '자유대화',
      'country': '국가'
    };
    return categories[category] || category;
  }

  renderPosts() {
    if (!this.postsFeed) return;

    // Clear existing content
    this.postsFeed.innerHTML = '';

    if (this.postFavorites.length === 0) {
      this.showPostsEmpty();
      return;
    }

    this.hidePostsEmpty();
    this.postsFeed.classList.remove('hidden');

    // Render post cards
    this.postFavorites.forEach(favorite => {
      const card = this.createPostCard(favorite);
      this.postsFeed.appendChild(card);
    });

    // Initialize post modal viewer with new posts
    if (window.postModalViewer) {
      window.postModalViewer.loadPostsData();
    }
  }

  createPostCard(favorite) {
    const post = favorite.post;
    const card = document.createElement('div');
    card.className = 'post-card';
    card.dataset.postId = post.id;
    card.dataset.authorUsername = post.author.username;

    // Format time
    const createdAt = new Date(post.created_at);
    const timeAgo = this.getTimeAgo(createdAt);

    // Create hashtags HTML
    let hashtagsHTML = '';
    if (post.hashtags && post.hashtags.length > 0) {
      hashtagsHTML = `
        <div class="flex gap-xs mt-sm">
          ${post.hashtags.map(tag => `<span class="badge badge-primary">#${this.escapeHtml(tag.name)}</span>`).join('')}
        </div>
      `;
    }

    // Create language info
    let languageInfo = '';
    if (post.native_language && post.target_language) {
      languageInfo = `
        <span>${this.getLanguageDisplay(post.native_language)} → ${this.getLanguageDisplay(post.target_language)}</span>
        <span>•</span>
      `;
    }

    card.innerHTML = `
      <div class="post-header">
        <div class="avatar">
          ${post.author.profile_picture ?
            `<img src="${post.author.profile_picture}" alt="${this.escapeHtml(post.author.nickname)}">` :
            `<svg viewBox="0 0 100 100" fill="currentColor" style="color: var(--color-secondary);">
              <circle cx="50" cy="35" r="20"/>
              <path d="M15 85 Q15 55 50 55 Q85 55 85 85 Z"/>
            </svg>`
          }
        </div>
        <div class="post-author-info">
          <a href="/accounts/profile/${post.author.username}/" class="post-author-name">${this.escapeHtml(post.author.nickname)}</a>
          <div class="post-meta">
            ${languageInfo}
            <span class="post-time">${timeAgo}</span>
          </div>
        </div>
        <button class="post-favorite-btn" data-post-id="${post.id}" data-favorite-id="${favorite.id}" title="즐겨찾기 해제">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor" stroke="currentColor" stroke-width="2">
            <path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/>
          </svg>
        </button>
      </div>

      <div class="post-content">
        <p>${this.escapeHtml(post.content).replace(/\n/g, '<br>')}</p>
        ${hashtagsHTML}
      </div>

      <div class="post-actions">
        <button class="post-action-btn feed-like-btn${post.is_liked ? ' liked' : ''}" data-post-id="${post.id}">
          <svg width="20" height="20" viewBox="0 0 24 24" ${post.is_liked ? 'fill="currentColor"' : 'fill="none"'} stroke="currentColor" stroke-width="2" class="like-icon">
            <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/>
          </svg>
          <span class="like-text">${post.is_liked ? '좋아요 취소' : '좋아요'}</span>
          <span class="like-count">${post.like_count || 0}</span>
        </button>
        <button class="post-action-btn" data-post-id="${post.id}">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"/>
          </svg>
          <span>댓글</span>
          <span class="comment-count">${post.comment_count || 0}</span>
        </button>
      </div>
    `;

    return card;
  }

  getLanguageDisplay(langCode) {
    // Get first 2 characters of language display
    const languages = {
      'ko': '한국어',
      'en': 'English',
      'ja': '日本語',
      'zh': '中文',
      'es': 'Español',
      'fr': 'Français',
      'de': 'Deutsch',
      'it': 'Italiano',
      'pt': 'Português',
      'ru': 'Русский'
    };
    const fullName = languages[langCode] || langCode;
    return fullName.substring(0, 2);
  }

  getTimeAgo(date) {
    const seconds = Math.floor((new Date() - date) / 1000);
    const intervals = {
      년: 31536000,
      개월: 2592000,
      주: 604800,
      일: 86400,
      시간: 3600,
      분: 60
    };

    for (const [unit, secondsInUnit] of Object.entries(intervals)) {
      const interval = Math.floor(seconds / secondsInUnit);
      if (interval >= 1) {
        return `${interval}${unit} 전`;
      }
    }
    return '방금 전';
  }

  async handlePostLike(button) {
    const postId = button.dataset.postId;
    if (!postId) return;

    try {
      const response = await fetch(`/api/posts/${postId}/like/`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRFToken': this.getCSRFToken()
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
      this.updateLikeButton(button, data.liked, data.like_count);

    } catch (error) {
      console.error('Error toggling like:', error);
      alert('좋아요 처리 중 오류가 발생했습니다.');
    }
  }

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

  async handlePostUnfavorite(button) {
    const postId = button.dataset.postId;
    const favoriteId = button.dataset.favoriteId;

    if (!confirm('즐겨찾기를 해제하시겠습니까?')) {
      return;
    }

    try {
      const response = await fetch(`/api/posts/${postId}/favorite/`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRFToken': this.getCSRFToken()
        }
      });

      if (!response.ok) {
        throw new Error('Failed to unfavorite');
      }

      // Remove from local state
      this.postFavorites = this.postFavorites.filter(fav => fav.id.toString() !== favoriteId);

      // Update UI
      this.updateCounts();
      this.renderPosts();

    } catch (error) {
      console.error('Error unfavoriting post:', error);
      alert('즐겨찾기 해제에 실패했습니다.');
    }
  }

  async unfavoriteRoom(favoriteId, roomId) {
    if (!confirm('즐겨찾기를 해제하시겠습니까?')) {
      return;
    }

    try {
      const response = await fetch(`/api/chat/api/open-rooms/${roomId}/unfavorite/`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRFToken': this.getCSRFToken()
        }
      });

      if (!response.ok) {
        throw new Error('Failed to unfavorite');
      }

      // Remove from local state
      this.chatRoomFavorites = this.chatRoomFavorites.filter(
        fav => fav.id !== favoriteId
      );

      // Update UI
      this.updateCounts();
      this.renderChatRooms();

    } catch (error) {
      console.error('Error unfavoriting room:', error);
      alert('즐겨찾기 해제에 실패했습니다.');
    }
  }

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

  escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }

  showLoading() {
    if (this.loadingState) {
      this.loadingState.classList.remove('hidden');
    }
    if (this.chatGrid) {
      this.chatGrid.classList.add('hidden');
    }
    if (this.chatEmpty) {
      this.chatEmpty.classList.add('hidden');
    }
    if (this.postsFeed) {
      this.postsFeed.classList.add('hidden');
    }
    if (this.postsEmpty) {
      this.postsEmpty.classList.add('hidden');
    }
  }

  hideLoading() {
    if (this.loadingState) {
      this.loadingState.classList.add('hidden');
    }
  }

  showChatEmpty() {
    if (this.chatEmpty) {
      this.chatEmpty.classList.remove('hidden');
    }
    if (this.chatGrid) {
      this.chatGrid.classList.add('hidden');
    }
  }

  hideChatEmpty() {
    if (this.chatEmpty) {
      this.chatEmpty.classList.add('hidden');
    }
  }

  showPostsEmpty() {
    if (this.postsEmpty) {
      this.postsEmpty.classList.remove('hidden');
    }
    if (this.postsFeed) {
      this.postsFeed.classList.add('hidden');
    }
  }

  hidePostsEmpty() {
    if (this.postsEmpty) {
      this.postsEmpty.classList.add('hidden');
    }
  }

  showError(message) {
    console.error(message);
    alert(message);
  }
}

// Initialize when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    window.favoritesManager = new FavoritesManager();
  });
} else {
  window.favoritesManager = new FavoritesManager();
}
