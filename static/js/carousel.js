/**
 * PostCarousel - Instagram-style image carousel with smooth scrolling
 * Enhances CSS scroll-snap with pagination sync and keyboard navigation
 */
class PostCarousel {
  constructor(container) {
    this.container = container;
    this.gallery = container.querySelector('.post-images-gallery');
    this.images = this.gallery ? Array.from(this.gallery.querySelectorAll('.post-feed-image')) : [];
    this.counter = container.querySelector('.image-counter');
    this.currentIndex = 0;
    this.scrollTimeout = null;

    if (this.images.length > 1) {
      this.init();
    }
  }

  init() {
    // Update pagination on scroll
    this.gallery.addEventListener('scroll', this.handleScroll.bind(this), { passive: true });

    // Keyboard navigation
    this.gallery.setAttribute('tabindex', '0');
    this.gallery.addEventListener('keydown', this.handleKeyboard.bind(this));

    // Intersection Observer for slide tracking
    this.observeSlides();

    // Initialize ARIA attributes
    this.initAccessibility();
  }

  handleScroll() {
    // Debounced scroll handler for performance
    clearTimeout(this.scrollTimeout);
    this.scrollTimeout = setTimeout(() => {
      this.updateCurrentIndex();
      this.updateCounter();
    }, 100);
  }

  updateCurrentIndex() {
    const scrollLeft = this.gallery.scrollLeft;
    const slideWidth = this.images[0].offsetWidth + parseInt(getComputedStyle(this.gallery).gap || 0);
    this.currentIndex = Math.round(scrollLeft / slideWidth);
  }

  updateCounter() {
    if (this.counter) {
      this.counter.textContent = `${this.currentIndex + 1} / ${this.images.length}`;
    }
  }

  handleKeyboard(e) {
    switch(e.key) {
      case 'ArrowLeft':
        e.preventDefault();
        this.scrollToPrevious();
        break;
      case 'ArrowRight':
        e.preventDefault();
        this.scrollToNext();
        break;
      case 'Home':
        e.preventDefault();
        this.scrollToSlide(0);
        break;
      case 'End':
        e.preventDefault();
        this.scrollToSlide(this.images.length - 1);
        break;
    }
  }

  scrollToNext() {
    const nextIndex = Math.min(this.currentIndex + 1, this.images.length - 1);
    this.scrollToSlide(nextIndex);
  }

  scrollToPrevious() {
    const prevIndex = Math.max(this.currentIndex - 1, 0);
    this.scrollToSlide(prevIndex);
  }

  scrollToSlide(index) {
    if (this.images[index]) {
      this.images[index].scrollIntoView({
        behavior: 'smooth',
        block: 'nearest',
        inline: 'start'
      });
    }
  }

  observeSlides() {
    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          const index = this.images.indexOf(entry.target);
          if (index !== -1) {
            this.currentIndex = index;
            this.updateCounter();
          }
        }
      });
    }, {
      root: this.gallery,
      threshold: 0.5
    });

    this.images.forEach(image => observer.observe(image));
  }

  initAccessibility() {
    // Set ARIA attributes for carousel
    this.gallery.setAttribute('role', 'region');
    this.gallery.setAttribute('aria-label', '이미지 갤러리');

    // Set ARIA attributes for each slide
    this.images.forEach((image, index) => {
      image.setAttribute('role', 'group');
      image.setAttribute('aria-roledescription', '슬라이드');
      image.setAttribute('aria-label', `${index + 1} / ${this.images.length}`);
    });

    // Make counter live region for screen readers
    if (this.counter) {
      this.counter.setAttribute('aria-live', 'polite');
      this.counter.setAttribute('aria-atomic', 'true');
    }
  }
}

// Initialize all carousels on page load
document.addEventListener('DOMContentLoaded', () => {
  const carouselContainers = document.querySelectorAll('.post-images-container');
  carouselContainers.forEach(container => {
    new PostCarousel(container);
  });
});

// Re-initialize for dynamically loaded posts (infinite scroll, etc.)
if (typeof window.initializeCarousels === 'undefined') {
  window.initializeCarousels = function() {
    const carouselContainers = document.querySelectorAll('.post-images-container');
    carouselContainers.forEach(container => {
      // Check if already initialized
      if (!container.dataset.carouselInitialized) {
        new PostCarousel(container);
        container.dataset.carouselInitialized = 'true';
      }
    });
  };
}
