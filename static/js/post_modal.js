/**
 * Post Creation Modal JavaScript
 * Handles modal open/close, form submission, and character counting
 */

// CSRF Token Helper (same as auth.js)
function getCookie(name) {
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

const csrftoken = getCookie('csrftoken');

// Wait for DOM to be fully loaded before initializing
document.addEventListener('DOMContentLoaded', function() {
    console.log('[PostModal] DOM loaded, initializing...');

    // Modal Elements
    const modal = document.getElementById('post-modal');
    const modalTitle = document.getElementById('post-modal-title');
    const editPostIdInput = document.getElementById('edit-post-id');
    const openModalBtn = document.querySelector('.mobile-nav-create');
    const closeModalBtn = document.getElementById('close-modal');
    const cancelBtn = document.getElementById('cancel-post');
    const postForm = document.getElementById('post-form');
    const contentTextarea = document.getElementById('post-content');
    const charCounter = document.getElementById('char-counter');
    const submitBtn = document.getElementById('submit-post');
    const submitText = document.getElementById('submit-post-text');
    const submitLoading = document.getElementById('submit-post-loading');
    const errorAlert = document.getElementById('post-error-alert');
    const errorMessage = document.getElementById('post-error-message');

    // Debug: Log element status
    console.log('[PostModal] Elements found:', {
        modal: !!modal,
        openModalBtn: !!openModalBtn,
        postForm: !!postForm
    });

// Modal Functions
function openModal() {
    modal.dataset.mode = 'create';
    modal.classList.remove('hidden');
    document.body.style.overflow = 'hidden';

    // Set title for create mode
    if (modalTitle) {
        modalTitle.textContent = gettext('새 게시물');
    }
    if (submitText) {
        submitText.textContent = gettext('게시하기');
    }

    contentTextarea.focus();
}

async function openEditModal(postId) {
    console.log('Opening edit modal for post:', postId);

    try {
        // Fetch post data
        const response = await fetch(`/api/posts/${postId}/`);
        if (!response.ok) {
            throw new Error('Failed to fetch post data');
        }

        const post = await response.json();
        console.log('Post data loaded:', post);

        // Set mode to edit
        modal.dataset.mode = 'edit';
        editPostIdInput.value = postId;

        // Populate form
        contentTextarea.value = post.content;
        updateCharCounter();

        // Set language selectors
        const nativeSelect = document.getElementById('native-language');
        const targetSelect = document.getElementById('target-language');
        if (nativeSelect) nativeSelect.value = post.native_language || '';
        if (targetSelect) targetSelect.value = post.target_language || '';

        // Trigger language selector UI updates if they exist
        if (window.updateLanguageSelector) {
            window.updateLanguageSelector('native-language-selector', post.native_language || '');
            window.updateLanguageSelector('target-language-selector', post.target_language || '');
        }

        // Update modal title and button text
        if (modalTitle) {
            modalTitle.textContent = gettext('게시물 수정');
        }
        if (submitText) {
            submitText.textContent = gettext('수정하기');
        }

        // Open modal
        modal.classList.remove('hidden');
        document.body.style.overflow = 'hidden';
        contentTextarea.focus();

    } catch (error) {
        console.error('Error loading post for edit:', error);
        alert(window.POST_MODAL_I18N?.errorLoadPost || 'Failed to load post data.');
    }
}

function closeModal() {
    modal.classList.add('hidden');
    document.body.style.overflow = '';
    resetForm();
}

function resetForm() {
    postForm.reset();
    modal.dataset.mode = 'create';
    editPostIdInput.value = '';
    updateCharCounter();
    hideError();
}

function showError(message) {
    errorMessage.textContent = message;
    errorAlert.classList.remove('hidden');
}

function hideError() {
    errorAlert.classList.add('hidden');
    errorMessage.textContent = '';
}

function setLoadingState(isLoading) {
    submitBtn.disabled = isLoading;
    if (isLoading) {
        submitText.classList.add('hidden');
        submitLoading.style.display = 'inline-block';
    } else {
        submitText.style.display = 'inline';
        submitLoading.classList.add('hidden');
    }
}

// Character Counter
function updateCharCounter() {
    const length = contentTextarea.value.length;
    const maxLength = 1000;
    const charText = window.POST_MODAL_I18N?.charCounter || 'chars';
    charCounter.textContent = `${length} / ${maxLength} ${charText}`;

    // Update color based on character count
    if (length > maxLength * 0.9) {
        charCounter.classList.add('danger');
        charCounter.classList.remove('warning');
    } else if (length > maxLength * 0.7) {
        charCounter.classList.add('warning');
        charCounter.classList.remove('danger');
    } else {
        charCounter.classList.remove('warning', 'danger');
    }
}

// Event Listeners
if (openModalBtn) {
    openModalBtn.addEventListener('click', function(e) {
        e.preventDefault();
        openModal();
    });
}

if (closeModalBtn) {
    closeModalBtn.addEventListener('click', closeModal);
}

if (cancelBtn) {
    cancelBtn.addEventListener('click', closeModal);
}

// Close modal when clicking outside
if (modal) {
    modal.addEventListener('click', function(e) {
        if (e.target === modal) {
            closeModal();
        }
    });
}

// Character counter update
if (contentTextarea) {
    contentTextarea.addEventListener('input', updateCharCounter);
    updateCharCounter(); // Initial update
}

// Form submission
if (postForm) {
    postForm.addEventListener('submit', async function(e) {
        e.preventDefault();

        // Hide previous errors
        hideError();

        // Get form data
        const content = contentTextarea.value.trim();
        const nativeLanguage = document.getElementById('native-language').value;
        const targetLanguage = document.getElementById('target-language').value;

        // Validation
        if (!content) {
            showError(window.POST_MODAL_I18N?.errorEmptyContent || 'Please enter post content.');
            return;
        }

        if (content.length > 1000) {
            showError(window.POST_MODAL_I18N?.errorMaxLength || 'Posts can be up to 1000 characters.');
            return;
        }

        // Prepare data
        const data = {
            content: content,
            native_language: nativeLanguage,
            target_language: targetLanguage
        };

        // Determine if we're creating or editing
        const mode = modal.dataset.mode;
        const postId = editPostIdInput.value;
        const isEdit = mode === 'edit' && postId;

        console.log('Form submission:', { mode, postId, isEdit });

        // Set loading state
        setLoadingState(true);

        try {
            // Send AJAX request
            const url = isEdit ? `/api/posts/${postId}/` : '/api/posts/';
            const method = isEdit ? 'PUT' : 'POST';

            console.log('API request:', { url, method, data });

            const response = await fetch(url, {
                method: method,
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRFToken': csrftoken
                },
                credentials: 'same-origin',
                body: JSON.stringify(data)
            });

            const result = await response.json();

            if (response.ok) {
                // Success - close modal and reload page
                const successMsg = isEdit
                    ? (window.POST_MODAL_I18N?.successEdit || 'Post updated successfully.')
                    : (window.POST_MODAL_I18N?.successCreate || 'Post created successfully.');
                console.log(successMsg, result);
                closeModal();
                window.location.reload();
            } else {
                // Error - display error message
                const defaultError = isEdit
                    ? (window.POST_MODAL_I18N?.errorEdit || 'An error occurred while updating the post.')
                    : (window.POST_MODAL_I18N?.errorSubmit || 'An error occurred while creating the post.');
                const errorMsg = result.detail || result.message || defaultError;
                showError(errorMsg);
                setLoadingState(false);
            }

        } catch (error) {
            console.error('Post submission error:', error);
            const networkError = window.POST_MODAL_I18N?.errorNetwork || 'A network error occurred. Please try again.';
            showError(networkError);
            setLoadingState(false);
        }
    });

    // Initialize Language Selectors
    if (typeof LanguageSelector !== 'undefined' && typeof LANGUAGES !== 'undefined') {
        const placeholderNone = window.POST_MODAL_I18N?.placeholderNone || 'None selected';
        const placeholderSearch = window.POST_MODAL_I18N?.placeholderSearch || '🔍 Search languages...';
        const emptyResult = window.POST_MODAL_I18N?.emptySearchResult || 'No results found';
        const modalTitle = window.POST_MODAL_I18N?.modalTitle || 'Select Language';

        // Native Language Selector
        new LanguageSelector('native-language-selector', {
            languages: LANGUAGES,
            placeholder: placeholderNone,
            searchPlaceholder: placeholderSearch,
            emptyText: emptyResult,
            modalTitle: modalTitle,
            initialValue: '',
            onChange: function(language) {
                console.log('Native language selected:', language);
            }
        });

        // Target Language Selector
        new LanguageSelector('target-language-selector', {
            languages: LANGUAGES,
            placeholder: placeholderNone,
            searchPlaceholder: placeholderSearch,
            emptyText: emptyResult,
            modalTitle: modalTitle,
            initialValue: '',
            onChange: function(language) {
                console.log('Target language selected:', language);
            }
        });
    }
}

    // Expose openEditModal to global scope for post_actions.js
    window.openEditModal = openEditModal;

    console.log('[PostModal] Initialization complete');
}); // End of DOMContentLoaded
