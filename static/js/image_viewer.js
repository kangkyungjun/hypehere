/**
 * HypeHere - Image Viewer Modal
 * Simple click-to-enlarge image viewer with navigation and keyboard/mobile support
 */

class ImageViewer {
    constructor() {
        this.modal = null;
        this.viewerImage = null;
        this.closeBtn = null;
        this.prevBtn = null;
        this.nextBtn = null;
        this.imageCounter = null;
        this.currentIndexSpan = null;
        this.totalImagesSpan = null;

        this.images = [];
        this.currentIndex = 0;

        // Touch/swipe support for mobile
        this.touchStartX = 0;
        this.touchEndX = 0;
        this.minSwipeDistance = 50;

        // Pinch-to-zoom support
        this.scale = 1;
        this.minScale = 0.5;
        this.maxScale = 3;
        this.posX = 0;
        this.posY = 0;
        this.initialDistance = 0;
        this.lastScale = 1;
        this.lastPosX = 0;
        this.lastPosY = 0;
        this.isPinching = false;
        this.isDragging = false;
        this.lastTapTime = 0;

        this.init();
    }

    init() {
        // Get modal elements
        this.modal = document.getElementById('image-viewer-modal');
        this.viewerImage = document.getElementById('viewer-image');
        this.closeBtn = document.getElementById('close-image-viewer');
        this.prevBtn = document.getElementById('prev-image-btn');
        this.nextBtn = document.getElementById('next-image-btn');
        this.imageCounter = document.getElementById('viewer-image-counter');
        this.currentIndexSpan = document.getElementById('current-image-index');
        this.totalImagesSpan = document.getElementById('total-images-count');

        if (!this.modal) {
            console.warn('[ImageViewer] Modal element not found');
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

        // Mobile touch support (swipe + pinch-to-zoom)
        if (this.viewerImage) {
            this.viewerImage.addEventListener('touchstart', (e) => this.handleTouchStart(e), { passive: false });
            this.viewerImage.addEventListener('touchmove', (e) => this.handleTouchMove(e), { passive: false });
            this.viewerImage.addEventListener('touchend', (e) => this.handleTouchEnd(e), { passive: false });
        }
    }

    handleSwipe() {
        const swipeDistance = this.touchEndX - this.touchStartX;

        if (Math.abs(swipeDistance) < this.minSwipeDistance) {
            return; // Not a significant swipe
        }

        if (swipeDistance > 0) {
            // Swipe right → show previous image
            this.showPrevious();
        } else {
            // Swipe left → show next image
            this.showNext();
        }
    }

    handleTouchStart(e) {
        // Two-finger pinch detection
        if (e.touches.length === 2) {
            e.preventDefault();
            this.isPinching = true;
            this.initialDistance = this.getDistance(e.touches[0], e.touches[1]);
            this.lastScale = this.scale;
            this.lastPosX = this.posX;
            this.lastPosY = this.posY;
        } else if (e.touches.length === 1) {
            // Single finger - could be swipe or drag when zoomed
            this.touchStartX = e.touches[0].clientX;
            this.touchStartY = e.touches[0].clientY;

            // Check for double-tap to zoom
            const currentTime = new Date().getTime();
            const tapGap = currentTime - this.lastTapTime;

            if (tapGap < 300 && tapGap > 0) {
                // Double tap detected - toggle zoom
                e.preventDefault();
                this.handleDoubleTap(e.touches[0]);
                this.lastTapTime = 0;
            } else {
                this.lastTapTime = currentTime;

                // If zoomed, prepare for dragging
                if (this.scale > 1) {
                    this.isDragging = true;
                    this.lastPosX = this.posX;
                    this.lastPosY = this.posY;
                }
            }
        }
    }

    handleTouchMove(e) {
        if (this.isPinching && e.touches.length === 2) {
            e.preventDefault();

            // Calculate new scale
            const currentDistance = this.getDistance(e.touches[0], e.touches[1]);
            const scaleChange = currentDistance / this.initialDistance;
            this.scale = Math.max(this.minScale, Math.min(this.maxScale, this.lastScale * scaleChange));

            // Apply transform
            this.applyTransform();
        } else if (this.isDragging && e.touches.length === 1 && this.scale > 1) {
            e.preventDefault();

            // Calculate pan offset
            const deltaX = e.touches[0].clientX - this.touchStartX;
            const deltaY = e.touches[0].clientY - this.touchStartY;

            this.posX = this.lastPosX + deltaX;
            this.posY = this.lastPosY + deltaY;

            // Apply transform
            this.applyTransform();
        }
    }

    handleTouchEnd(e) {
        if (this.isPinching) {
            this.isPinching = false;
        }

        if (this.isDragging) {
            this.isDragging = false;
        }

        // Handle swipe for navigation (only when not zoomed)
        if (this.scale === 1 && e.changedTouches.length === 1) {
            this.touchEndX = e.changedTouches[0].clientX;
            this.handleSwipe();
        }
    }

    handleDoubleTap(touch) {
        if (this.scale === 1) {
            // Zoom in to 2x centered on tap position
            this.scale = 2;

            // Calculate position to center zoom on tap point
            const rect = this.viewerImage.getBoundingClientRect();
            const tapX = touch.clientX - rect.left;
            const tapY = touch.clientY - rect.top;

            // Adjust position to zoom toward tap point
            this.posX = (rect.width / 2 - tapX) * (this.scale - 1);
            this.posY = (rect.height / 2 - tapY) * (this.scale - 1);
        } else {
            // Zoom out to reset
            this.resetZoom();
        }

        this.applyTransform();
    }

    getDistance(touch1, touch2) {
        const dx = touch2.clientX - touch1.clientX;
        const dy = touch2.clientY - touch1.clientY;
        return Math.sqrt(dx * dx + dy * dy);
    }

    applyTransform() {
        if (!this.viewerImage) return;

        this.viewerImage.style.transform = `translate(${this.posX}px, ${this.posY}px) scale(${this.scale})`;
        this.viewerImage.style.transition = this.isPinching || this.isDragging ? 'none' : 'transform 0.3s ease';
    }

    resetZoom() {
        this.scale = 1;
        this.posX = 0;
        this.posY = 0;
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

        // Show the modal
        this.modal.classList.remove('hidden');

        // Display the image
        this.displayCurrentImage();

        // Update navigation buttons and counter
        this.updateNavigation();
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

        // Reset zoom
        this.resetZoom();
        this.applyTransform();

        // Clear state
        this.images = [];
        this.currentIndex = 0;
    }

    showPrevious() {
        if (this.images.length <= 1) return;

        this.currentIndex = (this.currentIndex - 1 + this.images.length) % this.images.length;
        this.resetZoom();
        this.applyTransform();
        this.displayCurrentImage('left'); // Slide from left
        this.updateNavigation();
    }

    showNext() {
        if (this.images.length <= 1) return;

        this.currentIndex = (this.currentIndex + 1) % this.images.length;
        this.resetZoom();
        this.applyTransform();
        this.displayCurrentImage('right'); // Slide from right
        this.updateNavigation();
    }

    displayCurrentImage(direction = null) {
        if (!this.viewerImage || this.images.length === 0) return;

        const currentImage = this.images[this.currentIndex];

        // If no direction (initial load), just set image without animation
        if (!direction) {
            this.viewerImage.src = currentImage.src;
            this.viewerImage.alt = currentImage.alt || 'Enlarged image';
            return;
        }

        // Fade-out → swap → fade-in with slide animation
        this.viewerImage.classList.add('fade-out');

        setTimeout(() => {
            // Swap image source
            this.viewerImage.src = currentImage.src;
            this.viewerImage.alt = currentImage.alt || 'Enlarged image';

            // Wait for image to load, then fade-in with slide
            this.viewerImage.onload = () => {
                this.viewerImage.classList.remove('fade-out');

                // Add directional slide animation
                const slideClass = direction === 'left' ? 'slide-from-left' : 'slide-from-right';
                this.viewerImage.classList.add(slideClass);

                // Remove animation class after animation completes
                setTimeout(() => {
                    this.viewerImage.classList.remove(slideClass);
                }, 400); // Match animation duration
            };
        }, 300); // Match fade-out transition duration
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
