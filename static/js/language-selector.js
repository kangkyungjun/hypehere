/**
 * Language Selector Component
 * Custom searchable dropdown for language selection
 * Features:
 * - Search in Korean and English
 * - Keyboard navigation (↑↓, Enter, Esc)
 * - Mobile-optimized (bottom sheet on < 768px)
 * - Accessibility (ARIA attributes)
 * - No external dependencies
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

class LanguageSelector {
  constructor(elementId, options = {}) {
    this.element = document.getElementById(elementId);
    if (!this.element) {
      console.error(`LanguageSelector: Element with id "${elementId}" not found`);
      return;
    }

    this.options = {
      languages: options.languages || LANGUAGES,
      placeholder: options.placeholder || '선택하세요',
      searchPlaceholder: options.searchPlaceholder || '🔍 언어 검색...',
      emptyText: options.emptyText || '검색 결과가 없습니다',
      onChange: options.onChange || null,
      initialValue: options.initialValue || ''
    };

    this.isOpen = false;
    this.selectedLanguage = null;
    this.filteredLanguages = [...this.options.languages];
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
    // Create component HTML structure
    this.element.innerHTML = `
      <button type="button" class="country-selector-toggle form-control"
              aria-haspopup="listbox" aria-expanded="false">
        <span class="country-selector-value">${this.options.placeholder}</span>
        <span class="country-selector-arrow">▼</span>
      </button>
      <div class="country-dropdown" hidden>
        <div class="country-dropdown-header">
          <h3 class="country-dropdown-title">언어 선택</h3>
          <button type="button" class="country-dropdown-close" aria-label="닫기">✕</button>
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
      this.filterLanguages(e.target.value);
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

      // For mobile: detect clicks on backdrop area (the dropdown container itself, not its children)
      const clickedBackdrop = this.isMobile &&
                              e.target === this.dropdown &&
                              !clickedToggle;

      // Close if clicked outside both OR on mobile backdrop
      if (!clickedToggle && (!clickedDropdown || clickedBackdrop)) {
        this.closeDropdown();
      }
    };

    // Add listener with capture phase (true) - runs before target element handlers
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

      // Remove animation for smooth dragging
      this.dropdown.style.transition = 'none';
    };

    const handleTouchMove = (e) => {
      if (!this.isOpen || !startY) return;

      currentY = e.touches[0].clientY;
      const deltaY = currentY - startY;

      // Only handle downward swipes
      if (deltaY < 0) return;

      // Start dragging if moved more than 10px vertically
      if (!this.isDragging && deltaY > 10) {
        this.isDragging = true;
      }

      if (this.isDragging) {
        // Prevent default scrolling behavior
        e.preventDefault();

        // Apply transform with resistance (0.7x for smoother feel)
        const translateY = Math.min(deltaY * 0.7, 300);
        this.dropdown.style.transform = `translateY(${translateY}px)`;

        // Add opacity fade effect
        const opacity = Math.max(0, 1 - (translateY / 300));
        this.dropdown.style.opacity = opacity;
      }
    };

    const handleTouchEnd = (e) => {
      if (!this.isOpen || !startY) return;

      const deltaY = currentY - startY;
      const deltaTime = Date.now() - startTime;
      const velocity = deltaY / deltaTime; // px per ms

      // Restore transition for snap-back animation
      this.dropdown.style.transition = '';

      // Determine if should close
      const shouldClose =
        (deltaY > 100) || // Dragged far enough
        (velocity > 0.5 && deltaY > 50); // Quick flick

      if (shouldClose && this.isDragging) {
        // Animate out before closing
        this.dropdown.style.transform = 'translateY(100%)';
        this.dropdown.style.opacity = '0';

        setTimeout(() => {
          this.closeDropdown();
          // Reset styles
          this.dropdown.style.transform = '';
          this.dropdown.style.opacity = '';
        }, 200);
      } else {
        // Snap back to original position
        this.dropdown.style.transform = '';
        this.dropdown.style.opacity = '';
      }

      // Reset state
      startY = 0;
      currentY = 0;
      this.isDragging = false;
    };

    const handleTouchCancel = (e) => {
      // User navigated away or touch was interrupted
      if (this.isDragging) {
        this.dropdown.style.transition = '';
        this.dropdown.style.transform = '';
        this.dropdown.style.opacity = '';
        this.isDragging = false;
        startY = 0;
        currentY = 0;
      }
    };

    // Attach listeners to header (not content, to avoid scroll conflicts)
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

    // Add mobile class if needed
    if (this.isMobile) {
      this.dropdown.classList.add('country-dropdown-mobile');
      document.body.style.overflow = 'hidden'; // Prevent background scroll
    }

    // Reset search and focus
    this.searchInput.value = '';
    this.filterLanguages('');

    // Focus search input after animation
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

    // Remove mobile class
    if (this.isMobile) {
      this.dropdown.classList.remove('country-dropdown-mobile');
      document.body.style.overflow = ''; // Restore scroll
    }
  }

  filterLanguages(query) {
    const lowerQuery = query.toLowerCase().trim();

    if (!lowerQuery) {
      this.filteredLanguages = [...this.options.languages];
    } else {
      this.filteredLanguages = this.options.languages.filter(language => {
        return (
          language.name.toLowerCase().includes(lowerQuery) ||
          language.nameEn.toLowerCase().includes(lowerQuery) ||
          language.code.toLowerCase().includes(lowerQuery)
        );
      });
    }

    this.focusedIndex = -1;
    this.renderList();
  }

  renderList() {
    if (this.filteredLanguages.length === 0) {
      this.list.innerHTML = `
        <li class="country-empty">${this.options.emptyText}</li>
      `;
      return;
    }

    const lang = getCurrentLanguage();
    this.list.innerHTML = this.filteredLanguages.map((language, index) => `
      <li class="country-option"
          role="option"
          data-code="${language.code}"
          data-index="${index}"
          aria-selected="${this.selectedLanguage?.code === language.code}">
        <span class="country-name">${language.flag} ${lang === 'en' ? language.nameEn : language.name}</span>
      </li>
    `).join('');

    // Attach click events to options
    this.list.querySelectorAll('.country-option').forEach(option => {
      option.addEventListener('click', () => {
        const code = option.getAttribute('data-code');
        this.selectLanguage(code);
      });
    });
  }

  selectLanguage(code) {
    const language = this.options.languages.find(l => l.code === code);
    if (!language) return;

    this.selectedLanguage = language;
    this.valueDisplay.textContent = `${language.flag} ${language.name}`;
    this.valueDisplay.classList.add('has-value');

    // Update hidden select element if exists
    const hiddenSelect = document.getElementById(this.element.id.replace('-selector', ''));
    if (hiddenSelect) {
      hiddenSelect.value = language.code;
    }

    // Call onChange callback
    if (typeof this.options.onChange === 'function') {
      this.options.onChange(language);
    }

    this.closeDropdown();
    this.toggle.focus();
  }

  setValueByCode(code) {
    const language = this.options.languages.find(l => l.code === code);
    if (language) {
      this.selectedLanguage = language;
      this.valueDisplay.textContent = `${language.flag} ${language.name}`;
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
      if (this.focusedIndex >= 0 && this.focusedIndex < this.filteredLanguages.length) {
        const language = this.filteredLanguages[this.focusedIndex];
        this.selectLanguage(language.code);
      }
    }
  }

  focusNext() {
    if (this.filteredLanguages.length === 0) return;

    this.focusedIndex = (this.focusedIndex + 1) % this.filteredLanguages.length;
    this.highlightOption(this.focusedIndex);
  }

  focusPrevious() {
    if (this.filteredLanguages.length === 0) return;

    this.focusedIndex = this.focusedIndex <= 0
      ? this.filteredLanguages.length - 1
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
    return this.selectedLanguage?.code || '';
  }

  reset() {
    this.selectedLanguage = null;
    this.valueDisplay.textContent = this.options.placeholder;
    this.valueDisplay.classList.remove('has-value');
    this.closeDropdown();
  }
}
