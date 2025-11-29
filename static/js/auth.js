/**
 * HypeHere Authentication JavaScript
 * Handles registration, login, and form validation
 */

// CSRF Token Helper
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

// Show/Hide Alert Messages
function showAlert(type, message) {
    const alertId = type === 'error' ? 'error-alert' : 'success-alert';
    const messageId = type === 'error' ? 'error-message' : 'success-message';

    const alertElement = document.getElementById(alertId);
    const messageElement = document.getElementById(messageId);

    if (alertElement && messageElement) {
        // Use innerHTML for error messages to support HTML formatting (bullet points)
        if (type === 'error') {
            messageElement.innerHTML = message;
        } else {
            messageElement.textContent = message;
        }
        alertElement.classList.remove('hidden');

        // Auto-hide success messages after 3 seconds
        if (type === 'success') {
            setTimeout(() => {
                alertElement.classList.add('hidden');
            }, 3000);
        }
    }
}

// Parse all registration errors from server response
function parseRegistrationErrors(data) {
    const errors = [];

    // Collect errors from all fields
    if (data.email) {
        const emailErrors = Array.isArray(data.email) ? data.email : [data.email];
        errors.push(...emailErrors);
    }
    if (data.nickname) {
        const nicknameErrors = Array.isArray(data.nickname) ? data.nickname : [data.nickname];
        errors.push(...nicknameErrors);
    }
    if (data.password) {
        const passwordErrors = Array.isArray(data.password) ? data.password : [data.password];
        errors.push(...passwordErrors);
    }
    if (data.password_confirm) {
        const confirmErrors = Array.isArray(data.password_confirm) ? data.password_confirm : [data.password_confirm];
        errors.push(...confirmErrors);
    }
    if (data.gender) {
        const genderErrors = Array.isArray(data.gender) ? data.gender : [data.gender];
        errors.push(...genderErrors);
    }
    if (data.country) {
        const countryErrors = Array.isArray(data.country) ? data.country : [data.country];
        errors.push(...countryErrors);
    }
    if (data.native_language) {
        const nativeLanguageErrors = Array.isArray(data.native_language) ? data.native_language : [data.native_language];
        errors.push(...nativeLanguageErrors);
    }
    if (data.target_language) {
        const targetLanguageErrors = Array.isArray(data.target_language) ? data.target_language : [data.target_language];
        errors.push(...targetLanguageErrors);
    }
    if (data.non_field_errors) {
        const nonFieldErrors = Array.isArray(data.non_field_errors) ? data.non_field_errors : [data.non_field_errors];
        errors.push(...nonFieldErrors);
    }
    if (data.detail) {
        errors.push(data.detail);
    }
    if (data.message) {
        errors.push(data.message);
    }

    // Format multiple errors with bullet points
    if (errors.length > 1) {
        return errors.map(err => `• ${err}`).join('<br>');
    } else if (errors.length === 1) {
        return errors[0];
    } else {
        return '회원가입 중 오류가 발생했습니다.';
    }
}

function hideAlerts() {
    const errorAlert = document.getElementById('error-alert');
    const successAlert = document.getElementById('success-alert');

    if (errorAlert) errorAlert.classList.add('hidden');
    if (successAlert) successAlert.classList.add('hidden');
}

// Show/Hide Field Error
function showFieldError(fieldName, message) {
    const errorElement = document.getElementById(`${fieldName}-error`);
    const inputElement = document.getElementById(fieldName);

    if (errorElement) {
        errorElement.textContent = message;
        errorElement.classList.remove('hidden');
    }

    if (inputElement) {
        inputElement.classList.add('is-invalid');
    }
}

function clearFieldErrors() {
    const errorElements = document.querySelectorAll('.form-error');
    errorElements.forEach(element => {
        element.textContent = '';
        element.classList.add('hidden');
    });

    const inputs = document.querySelectorAll('.form-control');
    inputs.forEach(input => {
        input.classList.remove('is-invalid');
        input.classList.remove('is-valid');
    });
}

// Client-side Validation
function validateRegistrationForm(formData) {
    const errors = {};

    // Email validation
    const email = formData.get('email');
    if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
        errors.email = '올바른 이메일 형식이 아닙니다.';
    }

    // Nickname validation
    const nickname = formData.get('nickname');
    if (!nickname || nickname.length < 1) {
        errors.nickname = '닉네임을 입력해주세요.';
    } else if (nickname.length > 50) {
        errors.nickname = '닉네임은 최대 50자까지 가능합니다.';
    }

    // Password validation
    const password = formData.get('password');
    if (!password || password.length < 8) {
        errors.password = '비밀번호는 최소 8자 이상이어야 합니다.';
    } else if (!/(?=.*[A-Za-z])(?=.*\d)/.test(password)) {
        errors.password = '비밀번호는 영문과 숫자를 포함해야 합니다.';
    }

    // Password confirmation
    const passwordConfirm = formData.get('password_confirm');
    if (password !== passwordConfirm) {
        errors.password_confirm = '비밀번호가 일치하지 않습니다.';
    }

    return errors;
}

// Toggle Loading State
function setLoadingState(isLoading) {
    const submitBtn = document.getElementById('submit-btn');
    const submitText = document.getElementById('submit-text');
    const submitLoading = document.getElementById('submit-loading');

    if (submitBtn) {
        submitBtn.disabled = isLoading;
    }

    if (submitText && submitLoading) {
        if (isLoading) {
            submitText.classList.add('hidden');
            submitLoading.classList.remove('hidden');
        } else {
            submitText.classList.remove('hidden');
            submitLoading.classList.add('hidden');
        }
    }
}

// Registration Form Handler
document.addEventListener('DOMContentLoaded', function() {
    const registerForm = document.getElementById('register-form');

    if (registerForm) {
        // Initialize Gender Selector
        let genderSelector = null;
        const genderContainer = document.getElementById('gender-selector-container');
        const genderInput = document.getElementById('gender');

        if (genderContainer && genderInput && typeof GenderSelector !== 'undefined') {
            genderSelector = new GenderSelector('gender-selector-container', {
                onChange: (gender) => {
                    genderInput.value = gender ? gender.value : '';
                }
            });
        }

        // Initialize Country Selector
        let countrySelector = null;
        const countryContainer = document.getElementById('country-selector-container');
        const countryInput = document.getElementById('country');

        if (countryContainer && countryInput && typeof CountrySelector !== 'undefined') {
            countrySelector = new CountrySelector('country-selector-container', {
                onChange: (country) => {
                    countryInput.value = country ? country.name : '';
                }
            });
        }

        // Initialize UI Language Selector (with instant language switching)
        let uiLanguageSelector = null;
        const uiLanguageContainer = document.getElementById('ui-language-selector-container');
        const uiLanguageInput = document.getElementById('ui_language');

        if (uiLanguageContainer && uiLanguageInput && typeof LanguageSelector !== 'undefined') {
            // Filter languages to only show those supported by Django i18n
            // Django LANGUAGES: ko, en, ja, es (from settings.py)
            const supportedUiLanguages = LANGUAGES.filter(lang =>
                ['KO', 'EN', 'JA', 'ES'].includes(lang.code)
            );

            uiLanguageSelector = new LanguageSelector('ui-language-selector-container', {
                languages: supportedUiLanguages,  // Only show supported languages
                useNativeNames: true,  // Show languages in their native scripts
                onChange: async (language) => {
                    uiLanguageInput.value = language ? language.code : '';

                    // Instantly change page language
                    if (language && language.code) {
                        console.log('Language selected:', language.code);

                        const formData = new FormData();
                        formData.append('language', language.code.toLowerCase());

                        try {
                            console.log('Sending language change request...');
                            const response = await fetch('/i18n/setlang/', {
                                method: 'POST',
                                headers: {
                                    'X-CSRFToken': csrftoken
                                },
                                body: formData
                            });

                            console.log('Language change response:', response.status);

                            // Reload page to apply new language
                            window.location.reload();
                        } catch (error) {
                            console.error('Language switch error:', error);
                        }
                    }
                }
            });
        }

        registerForm.addEventListener('submit', async function(e) {
            e.preventDefault();

            // Clear previous errors
            hideAlerts();
            clearFieldErrors();

            // Get form data
            const formData = new FormData(registerForm);

            // Client-side validation
            const validationErrors = validateRegistrationForm(formData);
            if (Object.keys(validationErrors).length > 0) {
                Object.keys(validationErrors).forEach(field => {
                    showFieldError(field, validationErrors[field]);
                });
                showAlert('error', '입력 정보를 확인해주세요.');
                return;
            }

            // Prepare JSON data
            const data = {
                email: formData.get('email'),
                nickname: formData.get('nickname'),
                password: formData.get('password'),
                password_confirm: formData.get('password_confirm'),
                gender: formData.get('gender') || '',
                country: formData.get('country') || '',
                native_language: formData.get('native_language') || '',
                target_language: formData.get('target_language') || ''
            };

            // Set loading state
            setLoadingState(true);

            try {
                // Send AJAX request to API
                const response = await fetch('/api/accounts/register/', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-CSRFToken': csrftoken
                    },
                    body: JSON.stringify(data)
                });

                const result = await response.json();

                if (response.ok) {
                    // Success - Show message and redirect
                    showAlert('success', '회원가입 성공! 로그인 중...');

                    // Store token if provided (for API authentication)
                    if (result.token) {
                        localStorage.setItem('authToken', result.token);
                    }

                    // Redirect to home page after 1.5 seconds
                    setTimeout(() => {
                        window.location.href = '/';
                    }, 1500);

                } else {
                    // Error - Parse and display all errors
                    const errorMessage = parseRegistrationErrors(result);
                    showAlert('error', errorMessage);
                    setLoadingState(false);
                }

            } catch (error) {
                console.error('Registration error:', error);
                showAlert('error', '네트워크 오류가 발생했습니다. 다시 시도해주세요.');
                setLoadingState(false);
            }
        });

        // Real-time password match validation
        const passwordInput = document.getElementById('password');
        const passwordConfirmInput = document.getElementById('password_confirm');

        if (passwordConfirmInput) {
            passwordConfirmInput.addEventListener('input', function() {
                const password = passwordInput.value;
                const passwordConfirm = passwordConfirmInput.value;

                if (passwordConfirm && password !== passwordConfirm) {
                    showFieldError('password_confirm', '비밀번호가 일치하지 않습니다.');
                } else if (passwordConfirm && password === passwordConfirm) {
                    const errorElement = document.getElementById('password_confirm-error');
                    if (errorElement) {
                        errorElement.textContent = '';
                        errorElement.classList.add('hidden');
                    }
                    passwordConfirmInput.classList.remove('is-invalid');
                    passwordConfirmInput.classList.add('is-valid');
                }
            });
        }
    }
});

// Profile Update Form Handler
document.addEventListener('DOMContentLoaded', function() {
    const profileUpdateForm = document.getElementById('profile-update-form');

    if (profileUpdateForm) {
        // Character counter for bio field
        const bioTextarea = document.getElementById('bio');
        const bioCounter = document.getElementById('bio-counter');

        if (bioTextarea && bioCounter) {
            // Update counter on page load
            bioCounter.textContent = `${bioTextarea.value.length} / 200${window.AUTH_I18N.charCounter}`;

            // Update counter on input
            bioTextarea.addEventListener('input', function() {
                bioCounter.textContent = `${bioTextarea.value.length} / 200${window.AUTH_I18N.charCounter}`;
            });
        }

        // Image preview
        const profilePictureInput = document.getElementById('profile_picture');
        const imagePreview = document.getElementById('image-preview');
        const previewImg = document.getElementById('preview-img');

        if (profilePictureInput) {
            profilePictureInput.addEventListener('change', function(e) {
                const file = e.target.files[0];

                if (file) {
                    // Validate file type
                    if (!file.type.startsWith('image/')) {
                        showFieldError('profile_picture', window.AUTH_I18N.errorImageOnly);
                        profilePictureInput.value = '';
                        imagePreview.classList.add('hidden');
                        return;
                    }

                    // Validate file size (5MB)
                    if (file.size > 5 * 1024 * 1024) {
                        showFieldError('profile_picture', window.AUTH_I18N.errorFileSize);
                        profilePictureInput.value = '';
                        imagePreview.classList.add('hidden');
                        return;
                    }

                    // Show preview
                    const reader = new FileReader();
                    reader.onload = function(e) {
                        previewImg.src = e.target.result;
                        imagePreview.classList.remove('hidden');
                    };
                    reader.readAsDataURL(file);

                    // Clear error
                    const errorElement = document.getElementById('profile_picture-error');
                    if (errorElement) {
                        errorElement.textContent = '';
                        errorElement.classList.add('hidden');
                    }
                } else {
                    imagePreview.classList.add('hidden');
                }
            });
        }

        // Form submission
        profileUpdateForm.addEventListener('submit', async function(e) {
            e.preventDefault();

            // Clear previous errors
            hideAlerts();
            clearFieldErrors();

            // Get form data
            const formData = new FormData(profileUpdateForm);

            // Remove disabled email field from FormData
            formData.delete('email');

            // Client-side validation
            const nickname = formData.get('nickname');
            if (!nickname || nickname.trim().length < 1) {
                showFieldError('nickname', window.AUTH_I18N.errorNicknameRequired);
                showAlert('error', window.AUTH_I18N.errorCheckInput);
                return;
            }
            if (nickname.length > 50) {
                showFieldError('nickname', window.AUTH_I18N.errorNicknameLength);
                showAlert('error', window.AUTH_I18N.errorCheckInput);
                return;
            }

            const bio = formData.get('bio');
            if (bio && bio.length > 200) {
                showFieldError('bio', window.AUTH_I18N.errorBioLength);
                showAlert('error', window.AUTH_I18N.errorCheckInput);
                return;
            }

            // Set loading state
            setLoadingState(true);

            try {
                // Send AJAX request to API using FormData for file upload
                const response = await fetch('/api/accounts/update/', {
                    method: 'PATCH',
                    headers: {
                        'X-CSRFToken': csrftoken
                        // Note: Don't set Content-Type header - browser will set it with boundary for multipart/form-data
                    },
                    body: formData
                });

                const result = await response.json();

                if (response.ok) {
                    // Success - Show message and redirect
                    showAlert('success', window.AUTH_I18N.successUpdate);

                    // Redirect to profile page after 1 second
                    setTimeout(() => {
                        window.location.href = '/accounts/profile/';
                    }, 1000);

                } else {
                    // Error - Display field-specific or general errors
                    if (result.nickname) {
                        showFieldError('nickname', Array.isArray(result.nickname) ? result.nickname[0] : result.nickname);
                    }
                    if (result.date_of_birth) {
                        showFieldError('date_of_birth', Array.isArray(result.date_of_birth) ? result.date_of_birth[0] : result.date_of_birth);
                    }
                    if (result.bio) {
                        showFieldError('bio', Array.isArray(result.bio) ? result.bio[0] : result.bio);
                    }
                    if (result.profile_picture) {
                        showFieldError('profile_picture', Array.isArray(result.profile_picture) ? result.profile_picture[0] : result.profile_picture);
                    }
                    if (result.country) {
                        showFieldError('country', Array.isArray(result.country) ? result.country[0] : result.country);
                    }
                    if (result.city) {
                        showFieldError('city', Array.isArray(result.city) ? result.city[0] : result.city);
                    }
                    if (result.gender) {
                        showFieldError('gender', Array.isArray(result.gender) ? result.gender[0] : result.gender);
                    }

                    // Show general error message
                    const errorMessage = result.detail || result.message || window.AUTH_I18N.errorUpdateFailed;
                    showAlert('error', errorMessage);

                    setLoadingState(false);
                }

            } catch (error) {
                console.error('Profile update error:', error);
                showAlert('error', window.AUTH_I18N.errorNetwork);
                setLoadingState(false);
            }
        });
    }
});

// Login Form Handler (to be implemented)
document.addEventListener('DOMContentLoaded', function() {
    const loginForm = document.getElementById('login-form');

    if (loginForm) {
        // TODO: Implement login form handler
        console.log('Login form detected - handler to be implemented');
    }
});
