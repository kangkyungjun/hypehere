/**
 * Situation-Based Learning JavaScript
 * Handles interactions for situation learning pages
 */

/**
 * ExpressionSlider Class
 * Handles horizontal card slider with navigation, touch gestures, and bookmarks
 */
class ExpressionSlider {
    constructor() {
        this.container = document.querySelector('.expressions-section');
        if (!this.container) return;

        this.cards = Array.from(document.querySelectorAll('.expression-card'));
        this.currentIndex = 0;
        this.touchStartX = 0;
        this.touchEndX = 0;
        this.bookmarks = this.loadBookmarks();

        this.init();
    }

    init() {
        console.log('[ExpressionSlider] Initialized with', this.cards.length, 'cards');

        this.setupNavigationButtons();
        this.setupTouchGestures();
        this.setupKeyboardNavigation();
        this.setupScrollTracking();
        this.setupBookmarks();
        this.updatePagination();
    }

    // Navigation Buttons (Desktop)
    setupNavigationButtons() {
        const prevBtn = document.querySelector('.slider-nav-prev');
        const nextBtn = document.querySelector('.slider-nav-next');

        if (prevBtn) {
            prevBtn.addEventListener('click', () => this.goToPrevCard());
        }

        if (nextBtn) {
            nextBtn.addEventListener('click', () => this.goToNextCard());
        }
    }

    // Touch Gestures (Mobile)
    setupTouchGestures() {
        this.container.addEventListener('touchstart', (e) => {
            this.touchStartX = e.touches[0].clientX;
        }, { passive: true });

        this.container.addEventListener('touchend', (e) => {
            this.touchEndX = e.changedTouches[0].clientX;
            this.handleSwipe();
        }, { passive: true });
    }

    handleSwipe() {
        const swipeThreshold = 50;
        const diff = this.touchStartX - this.touchEndX;

        if (Math.abs(diff) > swipeThreshold) {
            if (diff > 0) {
                // Swipe left - next card
                this.goToNextCard();
            } else {
                // Swipe right - previous card
                this.goToPrevCard();
            }
        }
    }

    // Keyboard Navigation
    setupKeyboardNavigation() {
        document.addEventListener('keydown', (e) => {
            if (e.key === 'ArrowLeft') {
                e.preventDefault();
                this.goToPrevCard();
            } else if (e.key === 'ArrowRight') {
                e.preventDefault();
                this.goToNextCard();
            }
        });
    }

    // Scroll Tracking for Pagination
    setupScrollTracking() {
        let scrollTimeout;

        this.container.addEventListener('scroll', () => {
            clearTimeout(scrollTimeout);

            scrollTimeout = setTimeout(() => {
                const scrollLeft = this.container.scrollLeft;
                const cardWidth = this.cards[0].offsetWidth;
                this.currentIndex = Math.round(scrollLeft / cardWidth);
                this.updatePagination();
            }, 100);
        }, { passive: true });
    }

    // Card Navigation Methods
    goToCard(index) {
        if (index < 0 || index >= this.cards.length) return;

        const card = this.cards[index];
        card.scrollIntoView({
            behavior: 'smooth',
            block: 'nearest',
            inline: 'start'
        });

        this.currentIndex = index;
        this.updatePagination();
    }

    goToNextCard() {
        const nextIndex = Math.min(this.currentIndex + 1, this.cards.length - 1);
        this.goToCard(nextIndex);
    }

    goToPrevCard() {
        const prevIndex = Math.max(this.currentIndex - 1, 0);
        this.goToCard(prevIndex);
    }

    // Pagination Update
    updatePagination() {
        const currentSpan = document.querySelector('.current-expression');
        if (currentSpan) {
            currentSpan.textContent = this.currentIndex + 1;
        }
    }

    // Bookmark Functionality
    setupBookmarks() {
        const bookmarkBtns = document.querySelectorAll('.bookmark-btn');

        bookmarkBtns.forEach(btn => {
            const expressionId = btn.getAttribute('data-expression-id');

            // Set initial bookmarked state
            if (this.bookmarks.includes(expressionId)) {
                btn.classList.add('bookmarked');
            }

            // Add click handler
            btn.addEventListener('click', (e) => {
                e.stopPropagation(); // Prevent card navigation
                this.toggleBookmark(expressionId, btn);
            });
        });
    }

    toggleBookmark(expressionId, btn) {
        const index = this.bookmarks.indexOf(expressionId);

        if (index > -1) {
            // Remove bookmark
            this.bookmarks.splice(index, 1);
            btn.classList.remove('bookmarked');
            console.log('[Bookmark] Removed:', expressionId);
        } else {
            // Add bookmark
            this.bookmarks.push(expressionId);
            btn.classList.add('bookmarked');
            console.log('[Bookmark] Added:', expressionId);
        }

        this.saveBookmarks();
    }

    loadBookmarks() {
        const saved = localStorage.getItem('expression_bookmarks');
        return saved ? JSON.parse(saved) : [];
    }

    saveBookmarks() {
        localStorage.setItem('expression_bookmarks', JSON.stringify(this.bookmarks));
    }
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    console.log('[Situation Learning] Initialized');

    // Initialize Expression Slider if on detail page
    const expressionsSection = document.querySelector('.expressions-section');
    if (expressionsSection && expressionsSection.closest('.expression-slider-wrapper')) {
        new ExpressionSlider();
    }

    // Add smooth scroll behavior for anchor links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });

    // Add hover effects to category and lesson cards
    const cards = document.querySelectorAll('.category-card, .lesson-card');
    cards.forEach(card => {
        card.addEventListener('mouseenter', function() {
            this.style.transition = 'all 0.3s ease';
        });
    });

    // Track category clicks for analytics (future feature)
    const categoryCards = document.querySelectorAll('.category-card');
    categoryCards.forEach(card => {
        card.addEventListener('click', function() {
            const category = this.getAttribute('data-category');
            console.log('[Analytics] Category clicked:', category);
        });
    });

    // Lazy load animations for expression cards
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('visible');
            }
        });
    }, observerOptions);

    document.querySelectorAll('.expression-card').forEach(card => {
        observer.observe(card);
    });

    // Admin Expression CRUD Functionality (Staff Only)
    setupAdminFunctionality();
});

/**
 * Admin Expression CRUD Functionality
 * Handles create, update, and delete operations for situation expressions
 */
function setupAdminFunctionality() {
    const modal = document.getElementById('expressionModal');
    if (!modal) return; // Not staff user

    const modalTitle = document.getElementById('modalTitle');
    const expressionForm = document.getElementById('expressionForm');
    const closeBtn = modal.querySelector('.modal-close-btn');
    const cancelBtn = modal.querySelector('.btn-cancel');
    const overlay = modal.querySelector('.modal-overlay');

    // Get CSRF token
    function getCSRFToken() {
        return document.querySelector('[name=csrfmiddlewaretoken]')?.value || '';
    }

    // Open modal
    function openModal(mode = 'create', data = {}) {
        if (mode === 'create') {
            modalTitle.textContent = '표현 추가';
            expressionForm.reset();
            document.getElementById('expressionId').value = '';
        } else {
            modalTitle.textContent = '표현 수정';
            populateForm(data);
        }
        modal.classList.remove('hidden');
        document.body.style.overflow = 'hidden';
    }

    // Close modal
    function closeModal() {
        modal.classList.add('hidden');
        document.body.style.overflow = '';
        expressionForm.reset();
    }

    // Populate form with existing data
    function populateForm(data) {
        document.getElementById('expressionId').value = data.id;
        document.getElementById('expression').value = data.expression;
        document.getElementById('translation').value = data.translation;
        document.getElementById('pronunciation').value = data.pronunciation;
        document.getElementById('situationContext').value = data.situation_context;

        // Handle vocabulary (convert array to comma-separated string)
        if (data.vocabulary && Array.isArray(data.vocabulary)) {
            document.getElementById('vocabulary').value = data.vocabulary.join(', ');
        }

        document.getElementById('order').value = data.order || '';
    }

    // Parse vocabulary from textarea
    function parseVocabulary(text) {
        if (!text || !text.trim()) return [];
        return text.split(',').map(v => v.trim()).filter(v => v);
    }

    // Add Expression Button
    const addBtn = document.querySelector('.admin-add-btn');
    if (addBtn) {
        addBtn.addEventListener('click', () => {
            openModal('create');
        });
    }

    // Edit Expression Buttons
    document.querySelectorAll('.admin-edit-btn').forEach(btn => {
        btn.addEventListener('click', async (e) => {
            e.stopPropagation();
            const expressionId = btn.getAttribute('data-expression-id');

            // Get current expression data from the card
            const card = btn.closest('.expression-card');
            const data = {
                id: expressionId,
                expression: card.querySelector('.expression-korean')?.textContent || '',
                translation: card.querySelector('.expression-translation')?.textContent || '',
                pronunciation: card.querySelector('.expression-pronunciation')?.textContent.replace(/[\[\]]/g, '') || '',
                situation_context: card.querySelector('.context-text')?.textContent.trim() || '',
                vocabulary: [],
                order: card.getAttribute('data-order') || ''
            };

            // Get vocabulary if exists
            const vocabItems = card.querySelectorAll('.vocab-item');
            if (vocabItems.length > 0) {
                data.vocabulary = Array.from(vocabItems).map(item => {
                    const word = item.querySelector('.vocab-word')?.textContent || '';
                    const meaning = item.querySelector('.vocab-meaning')?.textContent || '';
                    return `${word}: ${meaning}`;
                });
            }

            openModal('edit', data);
        });
    });

    // Delete Expression Buttons
    document.querySelectorAll('.admin-delete-btn').forEach(btn => {
        btn.addEventListener('click', async (e) => {
            e.stopPropagation();
            const expressionId = btn.getAttribute('data-expression-id');

            if (!confirm('이 표현을 삭제하시겠습니까?')) {
                return;
            }

            try {
                const response = await fetch(`/learning/api/expressions/${expressionId}/delete/`, {
                    method: 'DELETE',
                    headers: {
                        'X-CSRFToken': getCSRFToken(),
                        'Content-Type': 'application/json',
                    },
                });

                if (response.ok) {
                    alert('표현이 삭제되었습니다.');
                    location.reload();
                } else {
                    const error = await response.json();
                    alert(`삭제 실패: ${error.error || '알 수 없는 오류'}`);
                }
            } catch (error) {
                console.error('Delete error:', error);
                alert('삭제 중 오류가 발생했습니다.');
            }
        });
    });

    // Form Submission
    expressionForm.addEventListener('submit', async (e) => {
        e.preventDefault();

        const expressionId = document.getElementById('expressionId').value;
        const lessonId = document.getElementById('lessonId').value;
        const isEdit = !!expressionId;

        const formData = {
            lesson: lessonId,
            expression: document.getElementById('expression').value,
            translation: document.getElementById('translation').value,
            pronunciation: document.getElementById('pronunciation').value,
            situation_context: document.getElementById('situationContext').value,
            vocabulary: parseVocabulary(document.getElementById('vocabulary').value),
        };

        const orderValue = document.getElementById('order').value;
        if (orderValue) {
            formData.order = parseInt(orderValue);
        }

        try {
            let url, method;

            if (isEdit) {
                url = `/learning/api/expressions/${expressionId}/`;
                method = 'PATCH';
            } else {
                url = '/learning/api/expressions/';
                method = 'POST';
            }

            const response = await fetch(url, {
                method: method,
                headers: {
                    'X-CSRFToken': getCSRFToken(),
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(formData),
            });

            if (response.ok) {
                alert(isEdit ? '표현이 수정되었습니다.' : '표현이 추가되었습니다.');
                closeModal();
                location.reload();
            } else {
                const error = await response.json();
                alert(`저장 실패: ${JSON.stringify(error)}`);
            }
        } catch (error) {
            console.error('Save error:', error);
            alert('저장 중 오류가 발생했습니다.');
        }
    });

    // Close modal handlers
    closeBtn.addEventListener('click', closeModal);
    cancelBtn.addEventListener('click', closeModal);
    overlay.addEventListener('click', closeModal);

    // Close on Escape key
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && modal.style.display === 'block') {
            closeModal();
        }
    });
}
