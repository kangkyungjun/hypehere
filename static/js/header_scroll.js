/**
 * Header Scroll Behavior
 * Hides header when scrolling down, shows when scrolling up
 */

(function() {
    'use strict';

    let lastScrollTop = 0;
    const scrollThreshold = 5;  // Minimum scroll distance to trigger
    const hideThreshold = 100;  // Minimum scroll position before hiding header
    let ticking = false;

    const header = document.querySelector('.header');

    if (!header) {
        console.warn('Header element not found');
        return;
    }

    /**
     * Update header visibility based on scroll direction
     * @param {number} scrollTop - Current scroll position
     */
    function updateHeader(scrollTop) {
        // Scrolling down - hide header
        if (scrollTop > lastScrollTop && scrollTop > hideThreshold) {
            header.classList.add('header-hidden');
            header.classList.remove('header-visible');
        }
        // Scrolling up - show header
        else if (scrollTop < lastScrollTop) {
            header.classList.remove('header-hidden');
            header.classList.add('header-visible');
        }

        lastScrollTop = scrollTop <= 0 ? 0 : scrollTop;
    }

    /**
     * Scroll event handler with requestAnimationFrame for performance
     */
    function onScroll() {
        if (!ticking) {
            window.requestAnimationFrame(function() {
                const scrollTop = window.pageYOffset || document.documentElement.scrollTop;

                // Only update if scroll distance exceeds threshold
                if (Math.abs(scrollTop - lastScrollTop) > scrollThreshold) {
                    updateHeader(scrollTop);
                }

                ticking = false;
            });

            ticking = true;
        }
    }

    // Attach scroll listener with passive option for better performance
    window.addEventListener('scroll', onScroll, { passive: true });

    // Initialize header as visible
    header.classList.add('header-visible');

})();
