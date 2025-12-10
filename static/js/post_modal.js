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

    // Image Upload Elements
    const uploadImagesBtn = document.getElementById('upload-images-btn');
    const postImagesInput = document.getElementById('post-images');
    const imagePreviewGrid = document.getElementById('image-preview-grid');

    // Store selected images
    let selectedImages = [];

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

    // Clear selected images
    selectedImages = [];
    if (imagePreviewGrid) {
        imagePreviewGrid.innerHTML = '';
    }
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

// Image Upload Functions
function handleImageSelection(e) {
    const files = Array.from(e.target.files);

    // Validate total number of images (existing + new)
    if (selectedImages.length + files.length > 5) {
        const errorMsg = window.POST_MODAL_I18N?.errorMaxImages || 'Maximum 5 images allowed per post.';
        showError(errorMsg);
        e.target.value = ''; // Clear file input
        return;
    }

    // Add new files to selectedImages array
    files.forEach(file => {
        // Validate file type
        if (!file.type.match('image/(jpeg|jpg|png|heic)')) {
            console.warn('Invalid file type:', file.type);
            return;
        }

        selectedImages.push(file);
    });

    // Update preview display
    displayImagePreviews();

    // Update button state
    updateUploadButtonState();

    // Clear file input to allow selecting same files again
    e.target.value = '';
}

function displayImagePreviews() {
    if (!imagePreviewGrid) return;

    // Clear existing previews
    imagePreviewGrid.innerHTML = '';

    // Create preview for each selected image
    selectedImages.forEach((file, index) => {
        const reader = new FileReader();

        reader.onload = function(e) {
            const previewItem = document.createElement('div');
            previewItem.className = 'image-preview-item';
            previewItem.innerHTML = `
                <img src="${e.target.result}" alt="Preview ${index + 1}">
                <button type="button" class="image-preview-remove" data-index="${index}">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <line x1="18" y1="6" x2="6" y2="18"/>
                        <line x1="6" y1="6" x2="18" y2="18"/>
                    </svg>
                </button>
            `;

            imagePreviewGrid.appendChild(previewItem);

            // Add remove button event listener
            const removeBtn = previewItem.querySelector('.image-preview-remove');
            removeBtn.addEventListener('click', () => removeImage(index));
        };

        reader.readAsDataURL(file);
    });
}

function removeImage(index) {
    // Remove image from selectedImages array
    selectedImages.splice(index, 1);

    // Update preview display
    displayImagePreviews();

    // Update button state
    updateUploadButtonState();
}

// Update button state based on image count
function updateUploadButtonState() {
    const imageCountBadge = document.getElementById('image-count-badge');
    const uploadBtn = document.getElementById('upload-images-btn');

    if (!imageCountBadge || !uploadBtn) return;

    const imageCount = selectedImages.length;

    // Show/hide badge based on image count
    if (imageCount > 0) {
        imageCountBadge.textContent = imageCount;
        imageCountBadge.classList.remove('hidden');
    } else {
        imageCountBadge.classList.add('hidden');
    }

    // Disable button when 5 images selected
    uploadBtn.disabled = (imageCount >= 5);
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

// Image upload event listeners
if (uploadImagesBtn && postImagesInput) {
    // Trigger file input when button is clicked
    uploadImagesBtn.addEventListener('click', function() {
        postImagesInput.click();
    });

    // Handle file selection
    postImagesInput.addEventListener('change', handleImageSelection);
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

        // Determine if we're creating or editing
        const mode = modal.dataset.mode;
        const postId = editPostIdInput.value;
        const isEdit = mode === 'edit' && postId;

        console.log('Form submission:', { mode, postId, isEdit });

        // Prepare FormData for multipart/form-data upload
        const formData = new FormData();
        formData.append('content', content);
        formData.append('native_language', nativeLanguage);
        formData.append('target_language', targetLanguage);

        // Append images to FormData
        selectedImages.forEach((file, index) => {
            formData.append('images', file);
        });

        console.log('FormData prepared:', {
            content: content.substring(0, 50) + '...',
            native_language: nativeLanguage,
            target_language: targetLanguage,
            images: selectedImages.length
        });

        // Set loading state
        setLoadingState(true);

        try {
            // Send AJAX request
            const url = isEdit ? `/api/posts/${postId}/` : '/api/posts/';
            const method = isEdit ? 'PUT' : 'POST';

            console.log('API request:', { url, method, imageCount: selectedImages.length });

            const response = await fetch(url, {
                method: method,
                headers: {
                    // Don't set Content-Type - browser will set it automatically with boundary for multipart/form-data
                    'X-CSRFToken': csrftoken
                },
                credentials: 'same-origin',
                body: formData
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
