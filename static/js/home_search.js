/**
 * Home Search Functionality
 * Handles search input on home page and redirects to explore page
 */

document.addEventListener('DOMContentLoaded', function() {
    const searchInput = document.getElementById('home-search-input');

    if (!searchInput) return;

    // Enter key event handler
    searchInput.addEventListener('keydown', function(e) {
        if (e.key === 'Enter') {
            const query = searchInput.value.trim();

            if (query) {
                // Redirect to explore page with search query
                window.location.href = `/explore/?q=${encodeURIComponent(query)}`;
            } else {
                // If empty, just go to explore page
                window.location.href = '/explore/';
            }
        }
    });

    // Optional: Clear search on Escape key
    searchInput.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
            searchInput.value = '';
            searchInput.blur();
        }
    });
});
