/**
 * Gender Selector Component
 * Modal-based gender selection
 * Features:
 * - Keyboard navigation (↑↓, Enter, Esc)
 * - Mobile-optimized (bottom sheet on < 768px)
 * - Multi-language support (Korean/English/Japanese/Spanish)
 * - Accessibility (ARIA attributes)
 * - Based on CountrySelector pattern (simplified - no search)
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

class GenderSelector {
  constructor(elementId, options = {}) {
    this.element = document.getElementById(elementId);
    if (!this.element) {
      console.error(`GenderSelector: Element with id "${elementId}" not found`);
      return;
    }

    this.options = {
      genders: options.genders || GENDERS,
      placeholder: options.placeholder || this.getDefaultPlaceholder(),
      modalTitle: options.modalTitle || this.getDefaultModalTitle(),
      onChange: options.onChange || null,
      initialValue: options.initialValue || ''
    };

    this.isOpen = false;
    this.selectedGender = null;
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

  getDefaultPlaceholder() {
    const lang = getCurrentLanguage();
    const placeholders = {
      'en': 'Not selected',
      'ja': '選択なし',
      'es': 'No seleccionado',
      'ko': '선택 안 함'
    };
    return placeholders[lang] || placeholders['ko'];
  }

  getDefaultModalTitle() {
    const lang = getCurrentLanguage();
    const titles = {
      'en': 'Select Gender',
      'ja': '性別を選択',
      'es': 'Seleccionar género',
      'ko': '성별 선택'
    };
    return titles[lang] || titles['ko'];
  }

  init() {
    const lang = getCurrentLanguage();
    const closeLabels = {
      'ko': '닫기',
      'en': 'Close',
      'ja': '閉じる',
      'es': 'Cerrar'
    };
    const closeLabel = closeLabels[lang] || closeLabels['en'];

    // Create component HTML structure
    this.element.innerHTML = `
      <button type="button" class="gender-selector-toggle form-control"
              aria-haspopup="listbox" aria-expanded="false">
        <span class="gender-selector-value">${this.options.placeholder}</span>
        <span class="gender-selector-arrow">▼</span>
      </button>
      <div class="gender-dropdown" hidden>
        <div class="gender-dropdown-header">
          <h3 class="gender-dropdown-title">${this.options.modalTitle}</h3>
          <button type="button" class="gender-dropdown-close" aria-label="${closeLabel}">✕</button>
        </div>
        <ul class="gender-list" role="listbox"></ul>
      </div>
    `;

    // Get DOM references
    this.toggle = this.element.querySelector('.gender-selector-toggle');
    this.valueDisplay = this.element.querySelector('.gender-selector-value');
    this.arrow = this.element.querySelector('.gender-selector-arrow');
    this.dropdown = this.element.querySelector('.gender-dropdown');
    this.list = this.element.querySelector('.gender-list');
    this.closeBtn = this.element.querySelector('.gender-dropdown-close');

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

    // List item click
    this.list.addEventListener('click', (e) => {
      const item = e.target.closest('.gender-option');
      if (item) {
        const value = item.dataset.value;
        this.selectGender(value);
      }
    });

    // Keyboard navigation
    document.addEventListener('keydown', (e) => {
      if (!this.isOpen) return;

      switch(e.key) {
        case 'ArrowDown':
          e.preventDefault();
          this.focusNext();
          break;
        case 'ArrowUp':
          e.preventDefault();
          this.focusPrevious();
          break;
        case 'Enter':
          e.preventDefault();
          this.selectFocused();
          break;
        case 'Escape':
          e.preventDefault();
          this.closeDropdown();
          break;
      }
    });

    // Click outside to close
    document.addEventListener('click', (e) => {
      if (this.isOpen && !this.element.contains(e.target)) {
        this.closeDropdown();
      }
    });

    // Handle window resize
    window.addEventListener('resize', () => {
      this.isMobile = window.innerWidth < 768;
      if (this.isOpen) {
        this.updateMobileClass();
      }
    });
  }

  attachSwipeGesture() {
    this.dropdown.addEventListener('touchstart', (e) => {
      if (!this.isMobile) return;
      this.touchStartY = e.touches[0].clientY;
      this.isDragging = false;
    });

    this.dropdown.addEventListener('touchmove', (e) => {
      if (!this.isMobile) return;
      this.touchCurrentY = e.touches[0].clientY;
      const diff = this.touchCurrentY - this.touchStartY;

      if (diff > 10) {
        this.isDragging = true;
        this.dropdown.style.transform = `translateY(${diff}px)`;
      }
    });

    this.dropdown.addEventListener('touchend', () => {
      if (!this.isMobile) return;

      const diff = this.touchCurrentY - this.touchStartY;
      if (this.isDragging && diff > 100) {
        this.closeDropdown();
      }

      this.dropdown.style.transform = '';
      this.isDragging = false;
    });
  }

  renderList() {
    const lang = getCurrentLanguage();
    const genderItems = this.options.genders.map(gender => {
      const label = {
        'en': gender.labelEn,
        'ja': gender.labelJa || gender.labelEn,
        'es': gender.labelEs || gender.labelEn,
        'ko': gender.labelKo
      }[lang] || gender.labelKo;
      const isSelected = this.selectedGender && this.selectedGender.value === gender.value;

      return `
        <li class="gender-option"
            role="option"
            data-value="${gender.value}"
            aria-selected="${isSelected ? 'true' : 'false'}">
          <span class="gender-label">${label}</span>
          ${isSelected ? '<span class="gender-check">✓</span>' : ''}
        </li>
      `;
    }).join('');

    this.list.innerHTML = genderItems;
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
    this.dropdown.hidden = false;
    this.toggle.setAttribute('aria-expanded', 'true');
    this.arrow.style.transform = 'rotate(180deg)';

    // Update mobile/desktop class
    this.updateMobileClass();

    // Focus first item or selected item
    const selectedItem = this.list.querySelector('[aria-selected="true"]');
    if (selectedItem) {
      this.focusedIndex = Array.from(this.list.children).indexOf(selectedItem);
    } else {
      this.focusedIndex = 0;
    }
    this.updateFocus();
  }

  closeDropdown() {
    this.isOpen = false;
    this.dropdown.hidden = true;
    this.toggle.setAttribute('aria-expanded', 'false');
    this.arrow.style.transform = '';
    this.dropdown.classList.remove('gender-dropdown-mobile');
    this.focusedIndex = -1;
  }

  updateMobileClass() {
    if (this.isMobile) {
      this.dropdown.classList.add('gender-dropdown-mobile');
    } else {
      this.dropdown.classList.remove('gender-dropdown-mobile');
    }
  }

  selectGender(value) {
    const lang = getCurrentLanguage();
    this.selectedGender = this.options.genders.find(g => g.value === value);

    if (this.selectedGender) {
      const label = {
        'en': this.selectedGender.labelEn,
        'ja': this.selectedGender.labelJa || this.selectedGender.labelEn,
        'es': this.selectedGender.labelEs || this.selectedGender.labelEn,
        'ko': this.selectedGender.labelKo
      }[lang] || this.selectedGender.labelKo;
      this.valueDisplay.textContent = label;

      // Update hidden input value
      const hiddenInput = document.getElementById('gender');
      if (hiddenInput) {
        hiddenInput.value = value;
      }

      // Call onChange callback
      if (this.options.onChange) {
        this.options.onChange(this.selectedGender);
      }
    }

    this.renderList();
    this.closeDropdown();
  }

  setValueByCode(code) {
    const lang = getCurrentLanguage();
    const gender = this.options.genders.find(g => g.value === code);
    if (gender) {
      this.selectedGender = gender;
      const label = {
        'en': gender.labelEn,
        'ja': gender.labelJa || gender.labelEn,
        'es': gender.labelEs || gender.labelEn,
        'ko': gender.labelKo
      }[lang] || gender.labelKo;
      this.valueDisplay.textContent = label;
      this.renderList();
    }
  }

  // Keyboard navigation helpers
  focusNext() {
    this.focusedIndex = Math.min(this.focusedIndex + 1, this.options.genders.length - 1);
    this.updateFocus();
  }

  focusPrevious() {
    this.focusedIndex = Math.max(this.focusedIndex - 1, 0);
    this.updateFocus();
  }

  updateFocus() {
    const items = this.list.querySelectorAll('.gender-option');
    items.forEach((item, index) => {
      if (index === this.focusedIndex) {
        item.classList.add('focused');
        item.scrollIntoView({ block: 'nearest' });
      } else {
        item.classList.remove('focused');
      }
    });
  }

  selectFocused() {
    const items = this.list.querySelectorAll('.gender-option');
    if (items[this.focusedIndex]) {
      const value = items[this.focusedIndex].dataset.value;
      this.selectGender(value);
    }
  }
}
