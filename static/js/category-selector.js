/**
 * Category Selector Component
 * Custom searchable dropdown for category selection
 * Features:
 * - Search in Korean and English
 * - Keyboard navigation (↑↓, Enter, Esc)
 * - Mobile-optimized (bottom sheet on < 768px)
 * - Accessibility (ARIA attributes)
 * - No external dependencies
 */

/**
 * Get current UI language from HTML lang attribute or default to Korean
 * @returns {string} 'en', 'ja', 'es', or 'ko'
 */
function getCurrentLanguage() {
  // Try HTML lang attribute first
  const htmlLang = document.documentElement.lang;
  if (htmlLang && htmlLang !== '') {
    const lang = htmlLang.toLowerCase();
    if (['en', 'ja', 'es', 'ko'].includes(lang)) {
      return lang;
    }
  }

  // Fallback: read from Django's language cookie
  const cookieMatch = document.cookie.match(/django_language=([^;]+)/);
  if (cookieMatch) {
    const lang = cookieMatch[1].toLowerCase();
    if (['en', 'ja', 'es', 'ko'].includes(lang)) {
      return lang;
    }
  }

  // Default to Korean
  return 'ko';
}

class CategorySelector {
  constructor(elementId, options = {}) {
    this.element = document.getElementById(elementId);
    if (!this.element) {
      console.error(`CategorySelector: Element with id "${elementId}" not found`);
      return;
    }

    const lang = getCurrentLanguage();
    const placeholders = {
      'en': 'Select',
      'ja': '選択',
      'es': 'Seleccionar',
      'ko': '선택하세요'
    };
    const searchPlaceholders = {
      'en': '🔍 Search categories...',
      'ja': '🔍 カテゴリを検索...',
      'es': '🔍 Buscar categorías...',
      'ko': '🔍 카테고리 검색...'
    };
    const emptyTexts = {
      'en': 'No results found',
      'ja': '検索結果がありません',
      'es': 'No se encontraron resultados',
      'ko': '검색 결과가 없습니다'
    };

    this.options = {
      categories: options.categories || CATEGORIES,
      placeholder: options.placeholder || placeholders[lang],
      searchPlaceholder: options.searchPlaceholder || searchPlaceholders[lang],
      emptyText: options.emptyText || emptyTexts[lang],
      onChange: options.onChange || null,
      initialValue: options.initialValue || ''
    };

    this.isOpen = false;
    this.selectedCategory = null;
    this.filteredCategories = [...this.options.categories];
    this.focusedIndex = -1;
    this.isMobile = window.innerWidth < 768;

    // Touch gesture state for swipe-to-dismiss
    this.touchStartY = 0;
    this.touchCurrentY = 0;
    this.isDragging = false;

    this.init();
    this.attachEvents();

    // Set initial value if provided
    if (this.options.initialValue) {
      this.setValueByCode(this.options.initialValue);
    }
  }

  init() {
    const lang = getCurrentLanguage();
    const modalTitles = {
      'ko': '카테고리 선택',
      'en': 'Select Category',
      'ja': 'カテゴリを選択',
      'es': 'Seleccionar categoría'
    };
    const closeLabels = {
      'ko': '닫기',
      'en': 'Close',
      'ja': '閉じる',
      'es': 'Cerrar'
    };
    // Create component HTML structure
    this.element.innerHTML = `
      <button type="button" class="country-selector-toggle form-control"
              aria-haspopup="listbox" aria-expanded="false">
        <span class="country-selector-value">${this.options.placeholder}</span>
        <span class="country-selector-arrow">▼</span>
      </button>
      <div class="country-dropdown" hidden>
        <div class="country-dropdown-header">
          <h3 class="country-dropdown-title">${modalTitles[lang] || modalTitles['ko']}</h3>
          <button type="button" class="country-dropdown-close" aria-label="${closeLabels[lang] || closeLabels['ko']}">✕</button>
        </div>
        <div class="country-search-wrapper">
          <input type="text" class="country-search form-control"
                 placeholder="${this.options.searchPlaceholder}"
                 autocomplete="off"
                 role="searchbox">
        </div>
        <ul class="country-list" role="listbox"></ul>
      </div>
    `;

    // Get DOM references
    this.toggle = this.element.querySelector('.country-selector-toggle');
    this.valueDisplay = this.element.querySelector('.country-selector-value');
    this.arrow = this.element.querySelector('.country-selector-arrow');
    this.dropdown = this.element.querySelector('.country-dropdown');
    this.searchInput = this.element.querySelector('.country-search');
    this.list = this.element.querySelector('.country-list');
    this.closeBtn = this.element.querySelector('.country-dropdown-close');

    // Render initial list
    this.renderList();

    // Attach swipe gesture for mobile
    this.attachSwipeGesture();
  }

  attachEvents() {
    // Toggle button click
    this.toggle.addEventListener('click', (e) => {
      e.stopPropagation();
      this.toggleDropdown();
    });

    // Close button click (mobile)
    this.closeBtn.addEventListener('click', () => {
      this.closeDropdown();
    });

    // Search input
    this.searchInput.addEventListener('input', (e) => {
      this.filterCategories(e.target.value);
    });

    // Keyboard navigation in search
    this.searchInput.addEventListener('keydown', (e) => {
      this.handleKeyboard(e);
    });

    // Click outside to close - using capture phase for proper timing
    this.outsideClickHandler = (e) => {
      if (!this.isOpen) return;

      // Check if click is on toggle or dropdown
      const clickedToggle = this.toggle.contains(e.target);
      const clickedDropdown = this.dropdown.contains(e.target);

      // For mobile: detect clicks on backdrop area
      const clickedBackdrop = this.isMobile &&
                              e.target === this.dropdown &&
                              !clickedToggle;

      // Close if clicked outside both OR on mobile backdrop
      if (!clickedToggle && (!clickedDropdown || clickedBackdrop)) {
        this.closeDropdown();
      }
    };

    // Add listener with capture phase
    document.addEventListener('click', this.outsideClickHandler, true);

    // Window resize - check if mobile
    let resizeTimer;
    window.addEventListener('resize', () => {
      clearTimeout(resizeTimer);
      resizeTimer = setTimeout(() => {
        const wasMobile = this.isMobile;
        this.isMobile = window.innerWidth < 768;

        // If switched between mobile/desktop, close dropdown
        if (wasMobile !== this.isMobile && this.isOpen) {
          this.closeDropdown();
        }
      }, 150);
    });

    // Escape key to close
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && this.isOpen) {
        this.closeDropdown();
        this.toggle.focus();
      }
    });
  }

  attachSwipeGesture() {
    if (!this.isMobile) return;

    const header = this.dropdown.querySelector('.country-dropdown-header');
    if (!header) return;

    let startY = 0;
    let startTime = 0;
    let currentY = 0;

    const handleTouchStart = (e) => {
      if (!this.isOpen) return;

      startY = e.touches[0].clientY;
      startTime = Date.now();
      currentY = startY;
      this.isDragging = false;

      this.dropdown.style.transition = 'none';
    };

    const handleTouchMove = (e) => {
      if (!this.isOpen || !startY) return;

      currentY = e.touches[0].clientY;
      const deltaY = currentY - startY;

      if (deltaY < 0) return;

      if (!this.isDragging && deltaY > 10) {
        this.isDragging = true;
      }

      if (this.isDragging) {
        e.preventDefault();

        const translateY = Math.min(deltaY * 0.7, 300);
        this.dropdown.style.transform = `translateY(${translateY}px)`;

        const opacity = Math.max(0, 1 - (translateY / 300));
        this.dropdown.style.opacity = opacity;
      }
    };

    const handleTouchEnd = (e) => {
      if (!this.isOpen || !startY) return;

      const deltaY = currentY - startY;
      const deltaTime = Date.now() - startTime;
      const velocity = deltaY / deltaTime;

      this.dropdown.style.transition = '';

      const shouldClose =
        (deltaY > 100) ||
        (velocity > 0.5 && deltaY > 50);

      if (shouldClose && this.isDragging) {
        this.dropdown.style.transform = 'translateY(100%)';
        this.dropdown.style.opacity = '0';

        setTimeout(() => {
          this.closeDropdown();
          this.dropdown.style.transform = '';
          this.dropdown.style.opacity = '';
        }, 200);
      } else {
        this.dropdown.style.transform = '';
        this.dropdown.style.opacity = '';
      }

      startY = 0;
      currentY = 0;
      this.isDragging = false;
    };

    const handleTouchCancel = (e) => {
      if (this.isDragging) {
        this.dropdown.style.transition = '';
        this.dropdown.style.transform = '';
        this.dropdown.style.opacity = '';
        this.isDragging = false;
        startY = 0;
        currentY = 0;
      }
    };

    header.addEventListener('touchstart', handleTouchStart, { passive: true });
    header.addEventListener('touchmove', handleTouchMove, { passive: false });
    header.addEventListener('touchend', handleTouchEnd, { passive: true });
    header.addEventListener('touchcancel', handleTouchCancel, { passive: true });
  }

  toggleDropdown() {
    if (this.isOpen) {
      this.closeDropdown();
    } else {
      this.openDropdown();
    }
  }

  openDropdown() {
    this.isOpen = true;
    this.dropdown.removeAttribute('hidden');
    this.toggle.setAttribute('aria-expanded', 'true');
    this.arrow.textContent = '▲';

    if (this.isMobile) {
      this.dropdown.classList.add('country-dropdown-mobile');
      document.body.style.overflow = 'hidden';
    }

    this.searchInput.value = '';
    this.filterCategories('');

    setTimeout(() => {
      this.searchInput.focus();
    }, 100);
  }

  closeDropdown() {
    this.isOpen = false;
    this.dropdown.setAttribute('hidden', '');
    this.toggle.setAttribute('aria-expanded', 'false');
    this.arrow.textContent = '▼';
    this.focusedIndex = -1;

    if (this.isMobile) {
      this.dropdown.classList.remove('country-dropdown-mobile');
      document.body.style.overflow = '';
    }
  }

  filterCategories(query) {
    const lowerQuery = query.toLowerCase().trim();

    if (!lowerQuery) {
      this.filteredCategories = [...this.options.categories];
    } else {
      this.filteredCategories = this.options.categories.filter(category => {
        return (
          category.name.toLowerCase().includes(lowerQuery) ||
          category.nameEn.toLowerCase().includes(lowerQuery) ||
          (category.nameJa && category.nameJa.toLowerCase().includes(lowerQuery)) ||
          (category.nameEs && category.nameEs.toLowerCase().includes(lowerQuery)) ||
          category.code.toLowerCase().includes(lowerQuery)
        );
      });
    }

    this.focusedIndex = -1;
    this.renderList();
  }

  getCategoryName(category) {
    const lang = getCurrentLanguage();
    const nameMap = {
      'en': category.nameEn,
      'ja': category.nameJa || category.nameEn,
      'es': category.nameEs || category.nameEn,
      'ko': category.name
    };
    return nameMap[lang] || category.nameEn;
  }

  renderList() {
    if (this.filteredCategories.length === 0) {
      this.list.innerHTML = `
        <li class="country-empty">${this.options.emptyText}</li>
      `;
      return;
    }

    this.list.innerHTML = this.filteredCategories.map((category, index) => `
      <li class="country-option"
          role="option"
          data-code="${category.code}"
          data-index="${index}"
          aria-selected="${this.selectedCategory?.code === category.code}">
        <span class="country-name">${this.getCategoryName(category)}</span>
      </li>
    `).join('');

    // Attach click events to options
    this.list.querySelectorAll('.country-option').forEach(option => {
      option.addEventListener('click', () => {
        const code = option.getAttribute('data-code');
        this.selectCategory(code);
      });
    });
  }

  selectCategory(code) {
    const category = this.options.categories.find(c => c.code === code);
    if (!category) return;

    this.selectedCategory = category;
    this.valueDisplay.textContent = this.getCategoryName(category);
    this.valueDisplay.classList.add('has-value');

    // Update hidden select element if exists
    const hiddenSelect = document.getElementById(this.element.id.replace('-selector', ''));
    if (hiddenSelect) {
      hiddenSelect.value = category.code;
    }

    // Call onChange callback
    if (typeof this.options.onChange === 'function') {
      this.options.onChange(category);
    }

    this.closeDropdown();
    this.toggle.focus();
  }

  setValueByCode(code) {
    const category = this.options.categories.find(c => c.code === code);
    if (category) {
      this.selectedCategory = category;
      this.valueDisplay.textContent = this.getCategoryName(category);
      this.valueDisplay.classList.add('has-value');
    }
  }

  handleKeyboard(e) {
    const key = e.key;

    if (key === 'ArrowDown') {
      e.preventDefault();
      this.focusNext();
    } else if (key === 'ArrowUp') {
      e.preventDefault();
      this.focusPrevious();
    } else if (key === 'Enter') {
      e.preventDefault();
      if (this.focusedIndex >= 0 && this.focusedIndex < this.filteredCategories.length) {
        const category = this.filteredCategories[this.focusedIndex];
        this.selectCategory(category.code);
      }
    }
  }

  focusNext() {
    if (this.filteredCategories.length === 0) return;

    this.focusedIndex = (this.focusedIndex + 1) % this.filteredCategories.length;
    this.highlightOption(this.focusedIndex);
  }

  focusPrevious() {
    if (this.filteredCategories.length === 0) return;

    this.focusedIndex = this.focusedIndex <= 0
      ? this.filteredCategories.length - 1
      : this.focusedIndex - 1;
    this.highlightOption(this.focusedIndex);
  }

  highlightOption(index) {
    const options = this.list.querySelectorAll('.country-option');
    options.forEach((opt, i) => {
      if (i === index) {
        opt.classList.add('focused');
        opt.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
      } else {
        opt.classList.remove('focused');
      }
    });
  }

  getValue() {
    return this.selectedCategory?.code || '';
  }

  reset() {
    this.selectedCategory = null;
    this.valueDisplay.textContent = this.options.placeholder;
    this.valueDisplay.classList.remove('has-value');
    this.closeDropdown();
  }
}
