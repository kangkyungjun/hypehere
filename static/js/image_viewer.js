/**
 * HypeHere - Image Viewer Modal (Instagram-style carousel)
 * Click-to-enlarge image viewer with smooth carousel navigation
 */

class ImageViewer {
    constructor() {
        this.modal = null;
        this.carousel = null;
        this.closeBtn = null;
        this.prevBtn = null;
        this.nextBtn = null;
        this.imageCounter = null;
        this.currentIndexSpan = null;
        this.totalImagesSpan = null;

        this.images = [];
        this.currentIndex = 0;
        this.scrollTimeout = null;

        this.init();
    }

    init() {
        // Get modal elements
        this.modal = document.getElementById('image-viewer-modal');
        this.carousel = document.getElementById('viewer-carousel');
        this.closeBtn = document.getElementById('close-image-viewer');
        this.prevBtn = document.getElementById('prev-image-btn');
        this.nextBtn = document.getElementById('next-image-btn');
        this.imageCounter = document.getElementById('viewer-image-counter');
        this.currentIndexSpan = document.getElementById('current-image-index');
        this.totalImagesSpan = document.getElementById('total-images-count');

        if (!this.modal || !this.carousel) {
            console.warn('[ImageViewer] Modal or carousel element not found');
            return;
        }

        // Bind event listeners
        this.bindEvents();
    }

    bindEvents() {
        // Close button
        if (this.closeBtn) {
            this.closeBtn.addEventListener('click', () => this.close());
        }

        // Navigation buttons
        if (this.prevBtn) {
            this.prevBtn.addEventListener('click', () => this.showPrevious());
        }
        if (this.nextBtn) {
            this.nextBtn.addEventListener('click', () => this.showNext());
        }

        // Click outside modal to close (on overlay background)
        if (this.modal) {
            this.modal.addEventListener('click', (e) => {
                if (e.target === this.modal) {
                    this.close();
                }
            });
        }

        // Keyboard navigation
        document.addEventListener('keydown', (e) => {
            if (!this.isOpen()) return;

            switch(e.key) {
                case 'Escape':
                    this.close();
                    break;
                case 'ArrowLeft':
                    this.showPrevious();
                    break;
                case 'ArrowRight':
                    this.showNext();
                    break;
            }
        });

        // Scroll event for updating counter
        if (this.carousel) {
            this.carousel.addEventListener('scroll', () => this.handleScroll(), { passive: true });
        }
    }

    handleScroll() {
        // Debounced scroll handler
        clearTimeout(this.scrollTimeout);
        this.scrollTimeout = setTimeout(() => {
            this.updateCurrentIndex();
            this.updateCounter();
        }, 100);
    }

    updateCurrentIndex() {
        if (!this.carousel) return;

        const scrollLeft = this.carousel.scrollLeft;
        const slideWidth = this.carousel.offsetWidth;
        this.currentIndex = Math.round(scrollLeft / slideWidth);
    }

    updateCounter() {
        if (this.currentIndexSpan) {
            this.currentIndexSpan.textContent = this.currentIndex + 1;
        }
    }

    open(imageElement, allImageElements = null) {
        if (!this.modal || !imageElement) return;

        // If allImageElements is provided, set up navigation for multiple images
        if (allImageElements && allImageElements.length > 0) {
            this.images = Array.from(allImageElements);
            this.currentIndex = this.images.indexOf(imageElement);
        } else {
            // Single image mode
            this.images = [imageElement];
            this.currentIndex = 0;
        }

        // Save scroll position
        this.scrollY = window.scrollY || window.pageYOffset;

        // iOS/Mobile compatible body scroll lock
        document.body.style.overflow = 'hidden';
        document.body.style.position = 'fixed';
        document.body.style.top = `-${this.scrollY}px`;
        document.body.style.width = '100%';

        // Build carousel
        this.buildCarousel();

        // Show the modal
        this.modal.classList.remove('hidden');

        // Scroll to current image after DOM update
        setTimeout(() => {
            this.scrollToImage(this.currentIndex, false);
        }, 0);

        // Update navigation buttons and counter
        this.updateNavigation();
    }

    buildCarousel() {
        if (!this.carousel) return;

        // Clear existing content
        this.carousel.innerHTML = '';

        // Add all images to carousel
        this.images.forEach((img, index) => {
            const viewerImg = document.createElement('img');
            viewerImg.src = img.src;
            viewerImg.alt = img.alt || `Image ${index + 1}`;
            viewerImg.className = 'viewer-image';
            viewerImg.dataset.index = index;

            this.carousel.appendChild(viewerImg);
        });
    }

    close() {
        if (!this.modal) return;

        this.modal.classList.add('hidden');

        // iOS/Mobile compatible body scroll restoration
        document.body.style.overflow = '';
        document.body.style.position = '';
        document.body.style.top = '';
        document.body.style.width = '';

        // Restore scroll position
        window.scrollTo(0, this.scrollY || 0);

        // Clear state
        this.images = [];
        this.currentIndex = 0;
    }

    showPrevious() {
        if (this.images.length <= 1) return;

        this.currentIndex = (this.currentIndex - 1 + this.images.length) % this.images.length;
        this.scrollToImage(this.currentIndex);
        this.updateNavigation();
    }

    showNext() {
        if (this.images.length <= 1) return;

        this.currentIndex = (this.currentIndex + 1) % this.images.length;
        this.scrollToImage(this.currentIndex);
        this.updateNavigation();
    }

    scrollToImage(index, smooth = true) {
        if (!this.carousel) return;

        const slideWidth = this.carousel.offsetWidth;
        const scrollLeft = index * slideWidth;

        if (smooth) {
            this.carousel.scrollTo({
                left: scrollLeft,
                behavior: 'smooth'
            });
        } else {
            this.carousel.scrollLeft = scrollLeft;
        }
    }

    updateNavigation() {
        const hasMultipleImages = this.images.length > 1;

        // Show/hide navigation buttons
        if (this.prevBtn) {
            if (hasMultipleImages) {
                this.prevBtn.classList.remove('hidden');
                this.prevBtn.disabled = false;
            } else {
                this.prevBtn.classList.add('hidden');
            }
        }

        if (this.nextBtn) {
            if (hasMultipleImages) {
                this.nextBtn.classList.remove('hidden');
                this.nextBtn.disabled = false;
            } else {
                this.nextBtn.classList.add('hidden');
            }
        }

        // Show/hide and update image counter
        if (this.imageCounter) {
            if (hasMultipleImages) {
                this.imageCounter.classList.remove('hidden');
                if (this.currentIndexSpan) {
                    this.currentIndexSpan.textContent = this.currentIndex + 1;
                }
                if (this.totalImagesSpan) {
                    this.totalImagesSpan.textContent = this.images.length;
                }
            } else {
                this.imageCounter.classList.add('hidden');
            }
        }
    }

    isOpen() {
        return this.modal && !this.modal.classList.contains('hidden');
    }
}

// Initialize image viewer when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    window.imageViewer = new ImageViewer();
});

/**
 * Helper function to attach click handlers to images
 * Usage: attachImageViewers('.post-feed-image') or attachImageViewers('.post-grid-image img')
 */
function attachImageViewers(selector) {
    const images = document.querySelectorAll(selector);

    images.forEach(image => {
        // Skip if already has click handler
        if (image.dataset.imageViewerAttached) return;

        image.style.cursor = 'pointer';
        image.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();

            // Find all sibling images in the same container
            const container = this.closest('.post-images-gallery') || this.closest('.post-grid-item');
            let siblingImages = container ? Array.from(container.querySelectorAll(selector)) : [this];

            // Open viewer with navigation if multiple images exist
            if (window.imageViewer) {
                window.imageViewer.open(this, siblingImages.length > 1 ? siblingImages : null);
            }
        });

        image.dataset.imageViewerAttached = 'true';
    });
}
