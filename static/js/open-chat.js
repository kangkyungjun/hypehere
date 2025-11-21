/**
 * Open Chat Room - Main JavaScript
 * Handles search, filtering, and room interactions
 */

/**
 * Get current UI language from HTML lang attribute or default to Korean
 * @returns {string} 'en' or 'ko'
 */
function getCurrentLanguage() {
  // Try HTML lang attribute first
  const htmlLang = document.documentElement.lang;
  if (htmlLang && htmlLang !== '') {
    return htmlLang === 'en' ? 'en' : 'ko';
  }

  // Fallback: read from Django's language cookie
  const cookieMatch = document.cookie.match(/django_language=([^;]+)/);
  if (cookieMatch) {
    return cookieMatch[1] === 'en' ? 'en' : 'ko';
  }

  // Default to Korean
  return 'ko';
}

class OpenChatManager {
  constructor() {
    // i18n support
    this.i18n = window.APP_I18N || {};

    // State
    this.allRooms = [];
    this.filteredRooms = [];
    this.nextPageUrl = null;
    this.isLoadingMore = false;
    this.currentFilters = {
      search: '',
      country: '',
      category: '',
      favoritesOnly: false
    };

    // DOM Elements
    this.searchInput = document.getElementById('search-input');
    this.clearButton = document.getElementById('clear-search');
    this.searchHeader = document.querySelector('.chat-search-header');
    this.roomGrid = document.getElementById('room-grid');
    this.emptyState = document.getElementById('empty-state');
    this.loadingState = document.getElementById('loading-state');
    this.favoritesFilter = document.getElementById('favorites-filter');

    // Selector instances (initialized in init())
    this.countrySelector = null;
    this.categorySelector = null;
    this.fab = document.getElementById('create-room-fab');
    this.createModal = document.getElementById('create-room-modal');
    this.modalOverlay = document.querySelector('.modal-overlay');
    this.createForm = document.getElementById('create-room-form');
    this.cancelButton = document.getElementById('cancel-create');

    // Custom select elements
    this.categorySelect = document.getElementById('category-select');
    this.categoryDisplay = document.getElementById('category-display');
    this.categoryInput = document.getElementById('room-category');

    this.init();
  }

  async init() {
    this.attachEventListeners();
    this.attachScrollListener();
    this.initCustomSelect();
    this.checkURLParameters();
    await this.loadRooms();
  }

  attachEventListeners() {
    // Search input
    if (this.searchInput) {
      this.searchInput.addEventListener('input', (e) => {
        this.currentFilters.search = e.target.value.toLowerCase();
        this.filterRooms();
        this.updateClearButton();
      });
    }

    // Clear search button
    if (this.clearButton) {
      this.clearButton.addEventListener('click', () => {
        this.searchInput.value = '';
        this.currentFilters.search = '';
        this.filterRooms();
        this.updateClearButton();
        this.searchInput.focus();
      });
    }

    // Initialize Country Selector
    if (typeof CountrySelector !== 'undefined' && typeof COUNTRIES !== 'undefined') {
      this.countrySelector = new CountrySelector('country-filter-selector', {
        countries: [
          { code: "all", name: "모든 국가", nameEn: "All Countries" },
          ...COUNTRIES
        ],
        placeholder: '모든 국가',
        initialValue: 'all',
        onChange: (country) => {
          this.currentFilters.country = country.code;
          this.filterRooms();
        }
      });
    }

    // Initialize Category Selector
    if (typeof CategorySelector !== 'undefined' && typeof CATEGORIES !== 'undefined') {
      const lang = getCurrentLanguage();
      this.categorySelector = new CategorySelector('category-filter-selector', {
        categories: CATEGORIES,
        placeholder: lang === 'en' ? 'All Categories' : '모든 카테고리',
        initialValue: 'all',
        onChange: (category) => {
          this.currentFilters.category = category.code;
          this.filterRooms();
        }
      });
    }

    // Favorites filter
    if (this.favoritesFilter) {
      this.favoritesFilter.addEventListener('click', () => {
        this.currentFilters.favoritesOnly = !this.currentFilters.favoritesOnly;
        this.updateFavoritesButton();
        this.filterRooms();
      });
    }

    // FAB button
    if (this.fab) {
      this.fab.addEventListener('click', () => {
        this.openCreateModal();
      });
    }

    // Modal overlay
    if (this.modalOverlay) {
      this.modalOverlay.addEventListener('click', () => {
        this.closeCreateModal();
      });
    }

    // Cancel button
    if (this.cancelButton) {
      this.cancelButton.addEventListener('click', () => {
        this.closeCreateModal();
      });
    }

    // Create form submission
    if (this.createForm) {
      this.createForm.addEventListener('submit', (e) => {
        e.preventDefault();
        this.createRoom();
      });
    }
  }

  attachScrollListener() {
    let lastScrollY = window.scrollY;

    window.addEventListener('scroll', () => {
      const currentScrollY = window.scrollY;

      if (this.searchHeader) {
        if (currentScrollY > 10) {
          this.searchHeader.classList.add('scrolled');
        } else {
          this.searchHeader.classList.remove('scrolled');
        }
      }

      // Infinite scroll - load more rooms when near bottom
      if (this.isNearBottom() && !this.isLoadingMore && this.nextPageUrl) {
        this.loadMoreRooms();
      }

      lastScrollY = currentScrollY;
    });
  }

  updateClearButton() {
    if (!this.clearButton) return;

    if (this.currentFilters.search.length > 0) {
      this.clearButton.classList.remove('hidden');
    } else {
      this.clearButton.classList.add('hidden');
    }
  }

  async loadRooms() {
    this.showLoading();

    try {
      const response = await fetch('/api/chat/api/open-rooms/');

      if (!response.ok) {
        throw new Error('Failed to load rooms');
      }

      const data = await response.json();
      this.allRooms = data.results || data;
      this.nextPageUrl = data.next || null;
      this.filteredRooms = [...this.allRooms];

      this.hideLoading();
      this.renderRooms();
    } catch (error) {
      console.error('Error loading rooms:', error);
      this.hideLoading();
      this.showError(this.i18n.loadRoomsFailed || '채팅방을 불러오는데 실패했습니다.');
    }
  }

  async loadMoreRooms() {
    if (!this.nextPageUrl || this.isLoadingMore) {
      return;
    }

    this.isLoadingMore = true;

    try {
      const response = await fetch(this.nextPageUrl);

      if (!response.ok) {
        throw new Error('Failed to load more rooms');
      }

      const data = await response.json();
      const newRooms = data.results || data;

      this.allRooms = [...this.allRooms, ...newRooms];
      this.nextPageUrl = data.next || null;

      this.filterRooms();

      this.isLoadingMore = false;
    } catch (error) {
      console.error('Error loading more rooms:', error);
      this.isLoadingMore = false;
    }
  }

  isNearBottom() {
    const scrollPosition = window.scrollY + window.innerHeight;
    const pageHeight = document.documentElement.scrollHeight;
    const threshold = 300; // Load when 300px from bottom

    return scrollPosition >= pageHeight - threshold;
  }

  filterRooms() {
    this.filteredRooms = this.allRooms.filter(room => {
      // Favorites filter
      if (this.currentFilters.favoritesOnly) {
        if (!room.is_favorited) return false;
      }

      // Search filter
      if (this.currentFilters.search) {
        const searchLower = this.currentFilters.search.toLowerCase();
        const nameMatch = room.name.toLowerCase().includes(searchLower);
        if (!nameMatch) return false;
      }

      // Country filter (case-insensitive)
      if (this.currentFilters.country && this.currentFilters.country !== 'all') {
        const roomCountry = (room.country_code || '').toUpperCase();
        const filterCountry = this.currentFilters.country.toUpperCase();
        if (roomCountry !== filterCountry) return false;
      }

      // Category filter
      if (this.currentFilters.category && this.currentFilters.category !== 'all') {
        if (room.category !== this.currentFilters.category) return false;
      }

      return true;
    });

    this.renderRooms();
  }

  updateFavoritesButton() {
    if (!this.favoritesFilter) return;

    if (this.currentFilters.favoritesOnly) {
      this.favoritesFilter.classList.add('active');
    } else {
      this.favoritesFilter.classList.remove('active');
    }
  }

  renderRooms() {
    if (!this.roomGrid) return;

    // Clear existing rooms
    this.roomGrid.innerHTML = '';

    if (this.filteredRooms.length === 0) {
      this.showEmptyState();
      return;
    }

    this.hideEmptyState();

    // Render room cards
    this.filteredRooms.forEach(room => {
      const card = this.createRoomCard(room);
      this.roomGrid.appendChild(card);
    });
  }

  createRoomCard(room) {
    const card = document.createElement('div');
    card.className = 'chat-room-card';
    card.dataset.roomId = room.id;

    const participantCount = room.participant_count || 0;
    const categoryDisplay = this.getCategoryDisplay(room.category);
    const lastActivity = this.formatLastActivity(room.last_message_time);

    card.innerHTML = `
      <div class="room-header">
        <h3 class="room-title">${this.escapeHtml(room.name)}</h3>
      </div>
      <div class="room-meta">
        <span class="badge badge-primary">${categoryDisplay}</span>
        <div class="room-participants">
          <svg viewBox="0 0 24 24" fill="none">
            <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" stroke-linecap="round" stroke-linejoin="round"/>
            <circle cx="9" cy="7" r="4" stroke-linecap="round" stroke-linejoin="round"/>
            <path d="M23 21v-2a4 4 0 0 0-3-3.87" stroke-linecap="round" stroke-linejoin="round"/>
            <path d="M16 3.13a4 4 0 0 1 0 7.75" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
          <span>${participantCount}${this.i18n.people || '명'}</span>
        </div>
      </div>
      <p class="room-activity">${lastActivity}</p>
    `;

    card.addEventListener('click', () => {
      this.enterRoom(room.id);
    });

    return card;
  }

  getCategoryDisplay(categoryCode) {
    const lang = getCurrentLanguage();
    const category = CATEGORIES.find(c => c.code === categoryCode);
    if (category) {
      return lang === 'en' ? category.nameEn : category.name;
    }
    // Fallback for special cases
    if (categoryCode === 'country') {
      return lang === 'en' ? 'Country' : '국가';
    }
    return categoryCode;
  }

  formatLastActivity(timestamp) {
    if (!timestamp) return '';

    const now = new Date();
    const activity = new Date(timestamp);
    const diffMs = now - activity;
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMins / 60);
    const diffDays = Math.floor(diffHours / 24);

    if (diffMins < 1) return this.i18n.timeJustNow || '방금 전';
    if (diffMins < 60) return `${diffMins}${this.i18n.timeMinutesAgo || '분 전'}`;
    if (diffHours < 24) return `${diffHours}${this.i18n.timeHoursAgo || '시간 전'}`;
    if (diffDays < 7) return `${diffDays}${this.i18n.timeDaysAgo || '일 전'}`;

    // Get current language from HTML or cookie
    const lang = document.documentElement.lang || 'ko';
    const locale = lang === 'en' ? 'en-US' : 'ko-KR';

    return activity.toLocaleDateString(locale, {
      month: 'short',
      day: 'numeric'
    });
  }

  escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }

  async enterRoom(roomId) {
    try {
      // Try to join the room first
      const response = await fetch(`/api/chat/api/open-rooms/${roomId}/join/`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRFToken': this.getCSRFToken()
        }
      });

      // 200 = joined successfully, 400 = already joined (both OK to proceed)
      if (response.ok || response.status === 400) {
        window.location.href = `/learning/chat/${roomId}/`;
      } else {
        const data = await response.json();
        alert(data.error || (this.i18n.cannotEnterRoom || '채팅방에 입장할 수 없습니다.'));
      }
    } catch (error) {
      console.error('Error joining room:', error);
      alert(this.i18n.enterRoomError || '채팅방 입장 중 오류가 발생했습니다.');
    }
  }

  openCreateModal() {
    if (this.createModal) {
      this.createModal.classList.remove('hidden');
      document.body.style.overflow = 'hidden';
    }
  }

  closeCreateModal() {
    if (this.createModal) {
      this.createModal.classList.add('hidden');
      document.body.style.overflow = '';
      if (this.createForm) {
        this.createForm.reset();
      }
      // Reset custom select
      if (this.categorySelect) {
        this.categorySelect.classList.remove('open');
        this.categoryDisplay.value = '';
        this.categoryInput.value = '';
        const options = this.categorySelect.querySelectorAll('.custom-select-option');
        options.forEach(opt => opt.classList.remove('selected'));
      }
    }
  }

  async createRoom() {
    if (!this.createForm) return;

    const formData = new FormData(this.createForm);
    const isPublic = formData.get('is_public') === 'true';
    const password = formData.get('password');

    // Client-side validation: password required for private rooms
    if (!isPublic && !password) {
      alert(this.i18n.passwordRequired || '비밀방은 비밀번호가 필요합니다.');
      return;
    }

    const data = {
      name: formData.get('name'),
      category: formData.get('category'),
      is_public: isPublic,
      password: password || null
    };

    try {
      const response = await fetch('/api/chat/api/open-rooms/', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRFToken': this.getCSRFToken()
        },
        body: JSON.stringify(data)
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.password || errorData.detail || 'Failed to create room');
      }

      const newRoom = await response.json();

      // Add to rooms list and refresh
      this.allRooms.unshift(newRoom);
      this.filterRooms();

      // Close modal and redirect to new room
      this.closeCreateModal();
      this.enterRoom(newRoom.id);

    } catch (error) {
      console.error('Error creating room:', error);
      alert(error.message || (this.i18n.createRoomFailed || '채팅방 생성에 실패했습니다.'));
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

  showLoading() {
    if (this.loadingState) {
      this.loadingState.classList.remove('hidden');
    }
    if (this.emptyState) {
      this.emptyState.classList.add('hidden');
    }
    if (this.roomGrid) {
      this.roomGrid.classList.add('hidden');
    }
  }

  hideLoading() {
    if (this.loadingState) {
      this.loadingState.classList.add('hidden');
    }
    if (this.roomGrid) {
      this.roomGrid.classList.remove('hidden');
    }
  }

  showEmptyState() {
    if (this.emptyState) {
      this.emptyState.classList.remove('hidden');
    }
  }

  hideEmptyState() {
    if (this.emptyState) {
      this.emptyState.classList.add('hidden');
    }
  }

  showError(message) {
    // TODO: Implement proper error UI
    console.error(message);
    if (this.emptyState) {
      this.emptyState.querySelector('h3').textContent = this.i18n.error || '오류';
      this.emptyState.querySelector('p').textContent = message;
      this.showEmptyState();
    }
  }

  initCustomSelect() {
    if (!this.categorySelect) return;

    const wrapper = this.categorySelect;
    const display = this.categoryDisplay;
    const hiddenInput = this.categoryInput;
    const dropdown = wrapper.querySelector('.custom-select-dropdown');

    // Populate category options dynamically based on language
    if (typeof CATEGORIES !== 'undefined' && dropdown) {
      const lang = getCurrentLanguage();
      dropdown.innerHTML = CATEGORIES
        .filter(cat => cat.code !== 'all') // Exclude "All Categories" from modal
        .map(cat => {
          const displayName = lang === 'en' ? cat.nameEn : cat.name;
          return `<div class="custom-select-option" data-value="${cat.code}">${displayName}</div>`;
        })
        .join('');
    }

    const options = wrapper.querySelectorAll('.custom-select-option');

    // Toggle dropdown on click
    display.addEventListener('click', () => {
      wrapper.classList.toggle('open');
    });

    // Handle option selection
    options.forEach(option => {
      option.addEventListener('click', () => {
        const value = option.dataset.value;
        const text = option.textContent;

        // Update display and hidden input
        display.value = text;
        hiddenInput.value = value;

        // Update selected state
        options.forEach(opt => opt.classList.remove('selected'));
        option.classList.add('selected');

        // Close dropdown
        wrapper.classList.remove('open');
      });
    });

    // Close dropdown when clicking outside
    document.addEventListener('click', (e) => {
      if (!wrapper.contains(e.target)) {
        wrapper.classList.remove('open');
      }
    });

    // Prevent form submission when clicking dropdown
    dropdown.addEventListener('click', (e) => {
      e.stopPropagation();
    });
  }

  checkURLParameters() {
    const urlParams = new URLSearchParams(window.location.search);
    const showFavorites = urlParams.get('favorites');

    if (showFavorites === 'true') {
      this.currentFilters.favoritesOnly = true;
      this.updateFavoritesButton();
    }
  }
}

// Initialize when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    window.openChatManager = new OpenChatManager();
  });
} else {
  window.openChatManager = new OpenChatManager();
}
