/**
 * Anonymous Chat Matching System
 * Handles matching preferences, WebSocket connections, and chat functionality
 */

const MatchingSystem = {
    // State
    currentScreen: 'preferences',
    matchingWebSocket: null,
    chatWebSocket: null,
    conversationId: null,
    otherUserId: null,
    otherUserUsername: null,
    isConnected: false,
    countrySelector: null,

    // WebRTC State
    webrtcClient: null,
    isVideoMode: false,

    // Connection Request State
    currentRequestId: null,
    isFollowing: false,

    // UI State
    isMobile: false,

    /**
     * Initialize matching system
     */
    init() {
        this.showPreferencesScreen(); // Explicitly set initial state
        this.checkMobile();
        this.initCountrySelector();
        this.attachEventListeners();
        this.loadSavedPreferences();

        // Initialize WebRTC client
        if (WebRTCClient && WebRTCClient.isSupported()) {
            this.webrtcClient = new WebRTCClient();
            if (window.DEBUG) console.log('[Matching] WebRTC client initialized');
        } else {
            console.warn('[Matching] WebRTC not supported in this browser');
        }
    },

    /**
     * Initialize CountrySelector component
     */
    initCountrySelector() {
        if (typeof COUNTRIES === 'undefined' || typeof CountrySelector === 'undefined') {
            console.error('CountrySelector or COUNTRIES not loaded');
            return;
        }

        const savedCountry = localStorage.getItem('matching_preferred_country') || '';

        this.countrySelector = new CountrySelector('preferred-country-selector', {
            countries: COUNTRIES,
            placeholder: window.MATCHING_I18N?.countryPlaceholder || 'All Countries',
            searchPlaceholder: window.MATCHING_I18N?.countrySearchPlaceholder || 'Search countries...',
            modalTitle: window.MATCHING_I18N?.countryModalTitle || 'Select Country',
            initialValue: savedCountry,
            onChange: (value) => {
                // Auto-save on change
                localStorage.setItem('matching_preferred_country', value);
            }
        });
    },

    /**
     * Load saved preferences from localStorage
     */
    loadSavedPreferences() {
        const savedGender = localStorage.getItem('matching_preferred_gender') || 'any';
        const savedChatMode = localStorage.getItem('matching_chat_mode');

        // Update gender selection
        if (savedGender) {
            this.updateGenderSelection(savedGender);
        }

        if (savedChatMode) {
            const chatModeRadio = document.querySelector(`input[name="chat_mode"][value="${savedChatMode}"]`);
            if (chatModeRadio) {
                chatModeRadio.checked = true;
            }
        }
        // Country is handled by CountrySelector's initialValue
    },

    /**
     * Save preferences to localStorage
     */
    savePreferences(gender, country, chatMode) {
        localStorage.setItem('matching_preferred_gender', gender);
        localStorage.setItem('matching_preferred_country', country);
        localStorage.setItem('matching_chat_mode', chatMode);
    },

    /**
     * Attach event listeners
     */
    attachEventListeners() {
        // Matching form submission
        document.getElementById('matching-form')?.addEventListener('submit', (e) => {
            e.preventDefault();
            this.startMatching();
        });

        // Cancel matching
        document.getElementById('cancel-matching-btn')?.addEventListener('click', () => {
            this.stopMatching();
        });

        // Chat input form
        document.getElementById('chat-input-form')?.addEventListener('submit', (e) => {
            e.preventDefault();
            this.sendMessage();
        });

        // Leave chat button
        document.getElementById('leave-chat-btn')?.addEventListener('click', () => {
            this.showLeaveModal();
        });

        // Leave modal actions
        document.getElementById('cancel-leave-btn')?.addEventListener('click', () => {
            this.hideLeaveModal();
        });

        document.getElementById('confirm-leave-btn')?.addEventListener('click', () => {
            this.leaveChat();
        });

        // Follow button
        document.getElementById('follow-btn')?.addEventListener('click', () => {
            this.followUser();
        });

        // Report button
        document.getElementById('report-btn')?.addEventListener('click', () => {
            this.showReportModal();
        });

        document.getElementById('cancel-report-btn')?.addEventListener('click', () => {
            this.hideReportModal();
        });

        document.getElementById('report-form')?.addEventListener('submit', (e) => {
            e.preventDefault();
            this.submitReport();
        });

        // Connection request buttons
        document.getElementById('accept-connection-btn')?.addEventListener('click', () => {
            this.acceptConnection();
        });

        document.getElementById('reject-connection-btn')?.addEventListener('click', () => {
            this.rejectConnection();
        });

        // Block button
        document.getElementById('block-btn')?.addEventListener('click', () => {
            this.blockUser();
        });

        // Gender selector button
        document.getElementById('gender-selector-btn')?.addEventListener('click', () => {
            this.showGenderModal();
        });

        // Gender option buttons
        document.querySelectorAll('.gender-option').forEach(btn => {
            btn.addEventListener('click', (e) => {
                this.selectGender(e.currentTarget.dataset.value);
            });
        });

        // Gender modal close button
        document.querySelector('.gender-modal-close')?.addEventListener('click', () => {
            this.hideGenderModal();
        });

        // Camera toggle
        document.getElementById('camera-toggle')?.addEventListener('click', () => {
            this.toggleCamera();
        });

        // Mic toggle
        document.getElementById('mic-toggle')?.addEventListener('click', () => {
            this.toggleMic();
        });

        // Close modals when clicking overlay
        document.querySelectorAll('.modal-overlay').forEach(overlay => {
            overlay.addEventListener('click', (e) => {
                if (e.target === overlay) {
                    this.hideLeaveModal();
                    this.hideReportModal();
                    this.hideGenderModal();
                }
            });
        });

        // Window resize for mobile detection
        window.addEventListener('resize', () => {
            this.checkMobile();
        });
    },

    /**
     * Start matching process
     */
    async startMatching() {
        // Clear any previous chat UI and resources
        this.clearChatUI();

        const preferredGender = document.getElementById('preferred-gender').value;
        const preferredCountry = this.countrySelector ? this.countrySelector.getValue() : '';
        const chatMode = document.querySelector('input[name="chat_mode"]:checked')?.value || 'text';

        // Save preferences
        this.savePreferences(preferredGender, preferredCountry, chatMode);

        try {
            // Start matching via API
            const response = await fetch('/api/chat/matching/start/', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRFToken': this.getCSRFToken()
                },
                body: JSON.stringify({
                    preferred_gender: preferredGender,
                    preferred_country: preferredCountry,
                    chat_mode: chatMode
                })
            });

            const data = await response.json();

            if (data.status === 'matched') {
                // Match found immediately
                this.conversationId = data.conversation_id;
                this.connectToChat();
            } else if (data.status === 'queued') {
                // Added to queue - show waiting screen
                this.showWaitingScreen();
                this.updateQueueInfo(data.position, data.queue_size);
                this.connectToMatchingWebSocket();
            }
        } catch (error) {
            console.error('Error starting matching:', error);
            showAlertModal(window.MATCHING_I18N.error, window.MATCHING_I18N.matchingStartError);
        }
    },

    /**
     * Stop matching process
     */
    async stopMatching() {
        try {
            await fetch('/api/chat/matching/stop/', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRFToken': this.getCSRFToken()
                }
            });

            // Disconnect WebSocket
            if (this.matchingWebSocket) {
                this.matchingWebSocket.close();
                this.matchingWebSocket = null;
            }

            // Reset state
            this.isFollowing = false;

            // Show preferences screen
            this.showPreferencesScreen();
        } catch (error) {
            console.error('Error stopping matching:', error);
        }
    },

    /**
     * Connect to matching WebSocket for real-time updates
     */
    connectToMatchingWebSocket() {
        const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        const wsUrl = `${protocol}//${window.location.host}/ws/matching/`;

        this.matchingWebSocket = new WebSocket(wsUrl);

        this.matchingWebSocket.onmessage = (event) => {
            const data = JSON.parse(event.data);

            if (data.type === 'match_found') {
                // Match found!
                this.conversationId = data.conversation_id;
                this.matchingWebSocket.close();
                this.matchingWebSocket = null;
                this.connectToChat();
            } else if (data.type === 'queue_update') {
                // Queue position updated
                this.updateQueueInfo(data.position, data.queue_size);
            }
        };

        this.matchingWebSocket.onerror = (error) => {
            console.error('Matching WebSocket error:', error);
        };

        this.matchingWebSocket.onclose = () => {
            console.log('Matching WebSocket closed');
        };
    },

    /**
     * Connect to anonymous chat WebSocket
     */
    connectToChat() {
        // Clear previous chat UI and resources before connecting to new conversation
        this.clearChatUI();

        this.showChatScreen();

        const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        const wsUrl = `${protocol}//${window.location.host}/ws/anonymous-chat/${this.conversationId}/`;

        this.chatWebSocket = new WebSocket(wsUrl);

        this.chatWebSocket.onopen = () => {
            this.isConnected = true;
            this.updateChatStatus(window.MATCHING_I18N.connected);

            // Initialize WebRTC client with WebSocket connection
            if (this.webrtcClient) {
                const localVideo = document.getElementById('local-video');
                const remoteVideo = document.getElementById('remote-video');
                this.webrtcClient.init(this.chatWebSocket, localVideo, remoteVideo);

                // Setup error callback
                this.webrtcClient.onError((message) => {
                    showAlertModal(window.MATCHING_I18N.error, message);
                });

                // Auto-start video if chat mode is video
                const savedChatMode = localStorage.getItem('matching_chat_mode');
                if (savedChatMode === 'video') {
                    // Delay to ensure partner is also connected
                    setTimeout(() => {
                        this.startVideo();
                    }, 1000);
                }
            }
        };

        this.chatWebSocket.onmessage = (event) => {
            const data = JSON.parse(event.data);

            if (data.type === 'init') {
                // 상대방 정보 저장
                this.otherUserId = data.other_user_id;
                this.otherUserUsername = data.other_user_username;
            } else if (data.type === 'message') {
                this.displayMessage(data);
            } else if (data.type === 'partner_connected') {
                const translatedMessage = window.MATCHING_I18N[data.message] || data.message;
                this.addSystemMessage(translatedMessage);
                this.updateChatStatus(window.MATCHING_I18N.connected);
            } else if (data.type === 'partner_left') {
                const translatedMessage = window.MATCHING_I18N[data.message] || data.message;
                this.addSystemMessage(translatedMessage);
                this.updateChatStatus(window.MATCHING_I18N.partnerLeft, true);
                this.showRematchButton();
                // Stop video if active
                if (this.isVideoMode) {
                    this.stopVideo();
                }
            }
            // WebRTC signal handling
            else if (data.type === 'video_offer' || data.type === 'video_answer' ||
                     data.type === 'ice_candidate' || data.type === 'video_toggle') {
                if (this.webrtcClient) {
                    this.webrtcClient.handleSignal(data);
                }
            }
            // Connection request handling
            else if (data.type === 'connection_request') {
                this.handleConnectionRequest(data.request_id);
            } else if (data.type === 'connection_accepted') {
                this.isFollowing = true;
                const followBtn = document.getElementById('follow-btn');
                if (followBtn) {
                    followBtn.disabled = false;
                    followBtn.style.opacity = '1';
                }
                showAlertModal(window.MATCHING_I18N.success, window.MATCHING_I18N.connectionAccepted);
            } else if (data.type === 'connection_rejected') {
                const followBtn = document.getElementById('follow-btn');
                if (followBtn) {
                    followBtn.disabled = false;
                    followBtn.style.opacity = '1';
                }
                showAlertModal(window.MATCHING_I18N.notification, window.MATCHING_I18N.connectionRejected);
            }
        };

        this.chatWebSocket.onerror = (error) => {
            console.error('Chat WebSocket error:', error);
            this.updateChatStatus(window.MATCHING_I18N.connectionError, true);
        };

        this.chatWebSocket.onclose = () => {
            this.isConnected = false;
            console.log('Chat WebSocket closed');
        };
    },

    /**
     * Send chat message
     */
    sendMessage() {
        const input = document.getElementById('chat-input');
        const content = input.value.trim();

        if (!content || !this.chatWebSocket || !this.isConnected) return;

        this.chatWebSocket.send(JSON.stringify({
            type: 'message',
            content: content
        }));

        input.value = '';
    },

    /**
     * Display received message
     */
    displayMessage(data) {
        const messagesContainer = document.getElementById('chat-messages');
        const currentUserId = this.getCurrentUserId();

        const messageDiv = document.createElement('div');
        messageDiv.className = `message ${data.sender_id === currentUserId ? 'sent' : 'received'}`;

        const bubble = document.createElement('div');
        bubble.className = 'message-bubble';
        bubble.textContent = data.content;

        const time = document.createElement('span');
        time.className = 'message-time';
        time.textContent = this.formatTime(data.created_at);

        messageDiv.appendChild(bubble);
        messageDiv.appendChild(time);
        messagesContainer.appendChild(messageDiv);

        // Scroll to bottom
        messagesContainer.scrollTop = messagesContainer.scrollHeight;
    },

    /**
     * Add system message
     */
    addSystemMessage(message) {
        const messagesContainer = document.getElementById('chat-messages');

        const messageDiv = document.createElement('div');
        messageDiv.className = 'system-message';
        messageDiv.textContent = message;

        messagesContainer.appendChild(messageDiv);
        messagesContainer.scrollTop = messagesContainer.scrollHeight;
    },

    /**
     * Show rematch button when partner leaves
     */
    showRematchButton() {
        const messagesContainer = document.getElementById('chat-messages');

        const rematchDiv = document.createElement('div');
        rematchDiv.className = 'system-message';
        rematchDiv.innerHTML = `
            <button type="button" class="btn btn-primary" onclick="MatchingSystem.rematch()">
                ${window.MATCHING_I18N.startMatching}
            </button>
        `;

        messagesContainer.appendChild(rematchDiv);
        messagesContainer.scrollTop = messagesContainer.scrollHeight;
    },

    /**
     * Rematch - go back to preferences
     */
    rematch() {
        // Clear chat UI and resources before rematch
        this.clearChatUI();

        if (this.chatWebSocket) {
            this.chatWebSocket.close();
            this.chatWebSocket = null;
        }
        this.conversationId = null;
        this.showPreferencesScreen();
    },

    /**
     * Leave chat
     */
    async leaveChat() {
        this.hideLeaveModal();

        // Clear chat UI and resources
        this.clearChatUI();

        if (this.chatWebSocket) {
            this.chatWebSocket.close();
            this.chatWebSocket = null;
        }

        if (this.conversationId) {
            // Leave conversation via API
            try {
                await fetch(`/api/chat/conversations/${this.conversationId}/leave/`, {
                    method: 'POST',
                    headers: {
                        'X-CSRFToken': this.getCSRFToken()
                    }
                });
            } catch (error) {
                console.error('Error leaving conversation:', error);
            }
        }

        this.conversationId = null;
        this.showPreferencesScreen();
    },

    /**
     * Follow user from anonymous chat
     */
    async followUser() {
        if (!this.conversationId) return;

        // Check if already following
        if (this.isFollowing) {
            showAlertModal(window.MATCHING_I18N.notification, window.MATCHING_I18N.alreadyFollowing);
            return;
        }

        const followBtn = document.getElementById('follow-btn');

        try {
            // Disable button while waiting for response
            followBtn.disabled = true;
            followBtn.style.opacity = '0.5';

            const response = await fetch('/api/chat/anonymous/connection-request/', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRFToken': this.getCSRFToken()
                },
                body: JSON.stringify({
                    conversation_id: this.conversationId
                })
            });

            const data = await response.json();

            if (response.ok) {
                showAlertModal(window.MATCHING_I18N.success, window.MATCHING_I18N.connectionRequestSent);
                // Keep button disabled until response
            } else {
                showAlertModal(window.MATCHING_I18N.error, data.error || window.MATCHING_I18N.connectionRequestError);
                // Re-enable button on error
                followBtn.disabled = false;
                followBtn.style.opacity = '1';
            }
        } catch (error) {
            console.error('Error sending connection request:', error);
            showAlertModal(window.MATCHING_I18N.error, window.MATCHING_I18N.connectionRequestError);
            // Re-enable button on error
            followBtn.disabled = false;
            followBtn.style.opacity = '1';
        }
    },

    /**
     * Handle connection request received
     */
    handleConnectionRequest(requestId) {
        this.currentRequestId = requestId;
        this.showModal('connection-request-modal');
    },

    /**
     * Accept connection request
     */
    async acceptConnection() {
        if (!this.currentRequestId) return;

        try {
            const response = await fetch('/api/chat/anonymous/connection-respond/', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRFToken': this.getCSRFToken()
                },
                body: JSON.stringify({
                    request_id: this.currentRequestId,
                    accept: true
                })
            });

            const data = await response.json();

            if (response.ok) {
                this.hideModal('connection-request-modal');
                showAlertModal(window.MATCHING_I18N.success, window.MATCHING_I18N.acceptConnectionSuccess);
            } else {
                showAlertModal(window.MATCHING_I18N.error, data.error || window.MATCHING_I18N.genericError);
            }
        } catch (error) {
            console.error('Error accepting connection:', error);
            showAlertModal(window.MATCHING_I18N.error, window.MATCHING_I18N.genericError);
        }

        this.currentRequestId = null;
    },

    /**
     * Reject connection request
     */
    async rejectConnection() {
        if (!this.currentRequestId) return;

        try {
            const response = await fetch('/api/chat/anonymous/connection-respond/', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRFToken': this.getCSRFToken()
                },
                body: JSON.stringify({
                    request_id: this.currentRequestId,
                    accept: false
                })
            });

            const data = await response.json();

            if (response.ok) {
                this.hideModal('connection-request-modal');
                showAlertModal(window.MATCHING_I18N.notification, window.MATCHING_I18N.rejectConnectionNotice);
            } else {
                showAlertModal(window.MATCHING_I18N.error, data.error || window.MATCHING_I18N.genericError);
            }
        } catch (error) {
            console.error('Error rejecting connection:', error);
            showAlertModal(window.MATCHING_I18N.error, window.MATCHING_I18N.genericError);
        }

        this.currentRequestId = null;
    },

    /**
     * Submit report
     */
    async submitReport() {
        const reportType = document.getElementById('report-type').value;
        const description = document.getElementById('report-description').value;

        if (!reportType) return;

        try {
            // Use FormData for file + data transmission
            const formData = new FormData();
            formData.append('reported_user', this.otherUserId);
            formData.append('conversation', this.conversationId);
            formData.append('report_type', reportType);
            formData.append('description', description || '');

            // Capture video frame if in video mode (with retry logic)
            if (this.isVideoMode) {
                console.log('[Report] Video mode detected, capturing video frame...');
                let videoFrame = null;
                const maxAttempts = 3;
                const retryDelay = 1000; // 1 second

                for (let attempt = 1; attempt <= maxAttempts; attempt++) {
                    console.log(`[Report] Video capture attempt ${attempt}/${maxAttempts}`);
                    videoFrame = await this.captureVideoFrame();

                    if (videoFrame) {
                        console.log(`[Report] Video frame captured successfully on attempt ${attempt}`);
                        break;
                    }

                    // If not the last attempt, wait before retrying
                    if (attempt < maxAttempts) {
                        console.log(`[Report] Waiting ${retryDelay}ms before retry...`);
                        await new Promise(resolve => setTimeout(resolve, retryDelay));
                    }
                }

                if (videoFrame) {
                    formData.append('video_frame', videoFrame, 'video_evidence.png');
                    console.log('[Report] Video frame attached to report');
                } else {
                    console.warn(`[Report] Failed to capture video frame after ${maxAttempts} attempts`);
                }
            }

            const response = await fetch('/api/chat/report/', {
                method: 'POST',
                headers: {
                    'X-CSRFToken': this.getCSRFToken()
                    // Content-Type removed - browser sets multipart/form-data automatically
                },
                body: formData
            });

            if (response.ok) {
                showAlertModal(window.MATCHING_I18N.success, window.MATCHING_I18N.reportSubmitted);
                this.hideReportModal();
                document.getElementById('report-form').reset();
            }
        } catch (error) {
            console.error('Error submitting report:', error);
            showAlertModal(window.MATCHING_I18N.error, window.MATCHING_I18N.reportError);
        }
    },

    /**
     * Capture video frame from remote video element
     * @returns {Promise<Blob|null>} PNG blob of video frame or null if capture fails
     */
    async captureVideoFrame() {
        try {
            const remoteVideo = document.getElementById('remote-video');

            // Check if remote video element exists and has video data
            if (!remoteVideo) {
                console.warn('[Report] Remote video element not found');
                return null;
            }

            if (!remoteVideo.videoWidth || !remoteVideo.videoHeight) {
                console.warn('[Report] Remote video has no dimensions (not playing)');
                return null;
            }

            // Create canvas element
            const canvas = document.createElement('canvas');
            canvas.width = remoteVideo.videoWidth;
            canvas.height = remoteVideo.videoHeight;

            // Draw video frame to canvas
            const ctx = canvas.getContext('2d');
            ctx.drawImage(remoteVideo, 0, 0, canvas.width, canvas.height);

            console.log(`[Report] Captured video frame: ${canvas.width}x${canvas.height}`);

            // Convert canvas to PNG blob
            return new Promise((resolve) => {
                canvas.toBlob((blob) => {
                    if (blob) {
                        console.log(`[Report] Video frame blob created: ${blob.size} bytes`);
                        resolve(blob);
                    } else {
                        console.error('[Report] Failed to create blob from canvas');
                        resolve(null);
                    }
                }, 'image/png');
            });
        } catch (error) {
            console.error('[Report] Error capturing video frame:', error);
            return null;
        }
    },

    /**
     * Clear chat UI for new conversation
     * Removes all messages, resets video state, and cleans up resources
     */
    clearChatUI() {
        // 메시지 컨테이너 비우기
        const messagesContainer = document.getElementById('chat-messages');
        if (messagesContainer) {
            messagesContainer.innerHTML = '';
            console.log('[Matching] Chat messages cleared');
        }

        // 비디오 컨테이너 숨기기 및 초기화
        const videoContainer = document.getElementById('video-container');
        if (videoContainer) {
            videoContainer.classList.add('hidden');
            console.log('[Matching] Video container hidden');
        }

        // 비디오 스트림 정리
        this.stopVideoStreams();

        // 상태 변수 초기화
        this.otherUserId = null;
        this.otherUserUsername = null;
        this.isFollowing = false;
        this.currentRequestId = null;

        console.log('[Matching] Chat UI cleared for new conversation');
    },

    /**
     * Stop and clean up video streams
     * Releases WebRTC resources and resets video elements
     */
    stopVideoStreams() {
        // WebRTC client cleanup
        if (this.webrtcClient && this.isVideoMode) {
            this.webrtcClient.stopVideo();
            console.log('[Matching] WebRTC client stopped');
        }

        // Reset video mode flag
        this.isVideoMode = false;

        // Video 엘리먼트 초기화
        const localVideo = document.getElementById('local-video');
        const remoteVideo = document.getElementById('remote-video');

        if (localVideo) {
            localVideo.srcObject = null;
            console.log('[Matching] Local video cleared');
        }
        if (remoteVideo) {
            remoteVideo.srcObject = null;
            console.log('[Matching] Remote video cleared');
        }

        console.log('[Matching] Video streams cleaned up');
    },

    /**
     * Block user (placeholder - implement block API)
     */
    async blockUser() {
        this.showBlockConfirmModal();
    },

    /**
     * Show block confirmation modal
     */
    showBlockConfirmModal() {
        const modal = document.getElementById('block-confirm-modal');
        const confirmBtn = document.getElementById('block-confirm-btn');
        const cancelBtn = document.getElementById('block-cancel-btn');

        if (!modal || !confirmBtn || !cancelBtn) {
            console.error('[BlockModal] Block modal elements not found');
            return;
        }

        if (!this.otherUserUsername) {
            console.error('[BlockModal] No other user username available');
            showAlertModal(window.MATCHING_I18N.error, window.MATCHING_I18N.blockUserNotFound);
            return;
        }

        modal.classList.remove('hidden');

        // Remove existing event listeners by cloning
        const newConfirmBtn = confirmBtn.cloneNode(true);
        const newCancelBtn = cancelBtn.cloneNode(true);
        confirmBtn.parentNode.replaceChild(newConfirmBtn, confirmBtn);
        cancelBtn.parentNode.replaceChild(newCancelBtn, cancelBtn);

        // Add event listeners
        newConfirmBtn.addEventListener('click', async () => {
            modal.classList.add('hidden');
            await this.executeBlock();
        });

        newCancelBtn.addEventListener('click', () => {
            modal.classList.add('hidden');
        });
    },

    /**
     * Execute block user
     */
    async executeBlock() {
        if (!this.otherUserUsername) {
            showAlertModal(window.MATCHING_I18N.error, window.MATCHING_I18N.blockUserNotFound);
            return;
        }

        try {
            const response = await fetch(`/api/accounts/${this.otherUserUsername}/block/`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRFToken': this.getCSRFToken()
                }
            });

            if (response.ok) {
                showAlertModal(window.MATCHING_I18N.success, window.MATCHING_I18N.blockSuccess);
                // 차단 후 채팅 종료
                setTimeout(() => {
                    this.leaveChat();
                }, 1500);
            } else {
                const data = await response.json();
                showAlertModal(window.MATCHING_I18N.error, data.error || window.MATCHING_I18N.blockFailed);
            }
        } catch (error) {
            console.error('Block error:', error);
            showAlertModal(window.MATCHING_I18N.error, window.MATCHING_I18N.blockError);
        }
    },

    /**
     * WebRTC Video Chat Functions
     */

    /**
     * Start video chat - 50:50 split layout
     */
    async startVideo() {
        try {
            if (window.DEBUG) console.log('[Matching] Starting video...');

            // Determine if we are initiator (randomly for P2P)
            const isInitiator = Math.random() < 0.5;

            await this.webrtcClient.startVideo(isInitiator);

            this.isVideoMode = true;

            // Update UI - Show video container and minimize chat
            const videoContainer = document.getElementById('video-container');
            const chatMessages = document.getElementById('chat-messages');

            if (videoContainer) videoContainer.classList.remove('hidden');
            if (chatMessages) chatMessages.classList.add('minimized');

            if (window.DEBUG) console.log('[Matching] Video started - 50:50 split layout');
        } catch (error) {
            console.error('[Matching] Failed to start video:', error);
            this.isVideoMode = false;
        }
    },

    /**
     * Stop video chat
     */
    stopVideo() {
        if (window.DEBUG) console.log('[Matching] Stopping video...');

        if (this.webrtcClient) {
            this.webrtcClient.stopVideo();
        }

        this.isVideoMode = false;

        // Update UI - Hide video container and restore chat
        const videoContainer = document.getElementById('video-container');
        const chatMessages = document.getElementById('chat-messages');

        if (videoContainer) videoContainer.classList.add('hidden');
        if (chatMessages) chatMessages.classList.remove('minimized');

        if (window.DEBUG) console.log('[Matching] Video stopped');
    },

    /**
     * Toggle camera on/off
     */
    toggleCamera() {
        if (!this.webrtcClient || !this.isVideoMode) return;

        const enabled = this.webrtcClient.toggleVideo();
        const cameraBtn = document.getElementById('camera-toggle');

        if (cameraBtn) {
            if (enabled) {
                cameraBtn.classList.remove('off');
                cameraBtn.title = window.MATCHING_I18N.cameraOff;
            } else {
                cameraBtn.classList.add('off');
                cameraBtn.title = window.MATCHING_I18N.cameraOn;
            }
        }
    },

    /**
     * Toggle microphone on/off
     */
    toggleMic() {
        if (!this.webrtcClient || !this.isVideoMode) return;

        const enabled = this.webrtcClient.toggleAudio();
        const micBtn = document.getElementById('mic-toggle');

        if (micBtn) {
            if (enabled) {
                micBtn.classList.remove('off');
                micBtn.title = window.MATCHING_I18N.micOff;
            } else {
                micBtn.classList.add('off');
                micBtn.title = window.MATCHING_I18N.micOn;
            }
        }
    },

    /**
     * UI Screen Management
     */
    showPreferencesScreen() {
        this.hideAllScreens();
        document.getElementById('preferences-screen').classList.remove('hidden');
        this.currentScreen = 'preferences';

        // Disable fullscreen chat mode
        document.body.classList.remove('fullscreen-chat');
    },

    showWaitingScreen() {
        this.hideAllScreens();
        document.getElementById('waiting-screen').classList.remove('hidden');
        this.currentScreen = 'waiting';

        // Disable fullscreen chat mode
        document.body.classList.remove('fullscreen-chat');
    },

    showChatScreen() {
        this.hideAllScreens();
        document.getElementById('chat-screen').classList.remove('hidden');
        this.currentScreen = 'chat';

        // Enable fullscreen chat mode
        document.body.classList.add('fullscreen-chat');
    },

    hideAllScreens() {
        document.querySelectorAll('.matching-screen').forEach(screen => {
            screen.classList.add('hidden');
        });
    },

    /**
     * Modal Management
     */
    showLeaveModal() {
        document.getElementById('leave-modal').classList.remove('hidden');
    },

    hideLeaveModal() {
        document.getElementById('leave-modal').classList.add('hidden');
    },

    showReportModal() {
        document.getElementById('report-modal').classList.remove('hidden');
    },

    hideReportModal() {
        document.getElementById('report-modal').classList.add('hidden');
    },

    /**
     * Check if device is mobile
     */
    checkMobile() {
        this.isMobile = window.innerWidth < 768;
    },

    /**
     * Show gender selection modal
     */
    showGenderModal() {
        const modal = document.getElementById('gender-modal');
        modal.classList.remove('hidden');

        // 모바일일 때 Bottom Sheet 애니메이션
        if (this.isMobile) {
            modal.classList.add('gender-modal-mobile');
            document.body.style.overflow = 'hidden'; // 배경 스크롤 방지
        }
    },

    /**
     * Hide gender selection modal
     */
    hideGenderModal() {
        const modal = document.getElementById('gender-modal');

        if (this.isMobile) {
            modal.classList.remove('gender-modal-mobile');
            document.body.style.overflow = ''; // 스크롤 복원
        }

        modal.classList.add('hidden');
    },

    /**
     * Select gender and update UI
     */
    selectGender(value) {
        this.updateGenderSelection(value);
        localStorage.setItem('matching_preferred_gender', value);
        this.hideGenderModal();
    },

    /**
     * Update gender selection UI
     */
    updateGenderSelection(value) {
        // Read translated labels from data attributes
        const genderButton = document.getElementById('gender-selector-btn');
        const genderLabels = {
            'any': genderButton?.dataset.labelAll || 'All',
            'male': genderButton?.dataset.labelMale || 'Male',
            'female': genderButton?.dataset.labelFemale || 'Female',
            'other': genderButton?.dataset.labelOther || 'Other'
        };

        // Update button text
        const textElement = document.getElementById('selected-gender-text');
        if (textElement) {
            textElement.textContent = genderLabels[value] || genderLabels['any'];
        }

        // Update hidden input
        const hiddenInput = document.getElementById('preferred-gender');
        if (hiddenInput) {
            hiddenInput.value = value;
        }

        // Update active class on modal buttons
        document.querySelectorAll('.gender-option').forEach(btn => {
            if (btn.dataset.value === value) {
                btn.classList.add('active');
            } else {
                btn.classList.remove('active');
            }
        });
    },

    /**
     * Show modal helper
     */
    showModal(modalId) {
        document.getElementById(modalId)?.classList.remove('hidden');
    },

    /**
     * Hide modal helper
     */
    hideModal(modalId) {
        document.getElementById(modalId)?.classList.add('hidden');
    },

    /**
     * Update queue information
     */
    updateQueueInfo(position, size) {
        document.getElementById('queue-position').textContent = position || '-';
        document.getElementById('queue-size').textContent = size || '-';
    },

    /**
     * Update chat status
     */
    updateChatStatus(status, disconnected = false) {
        const statusEl = document.getElementById('chat-status');
        if (statusEl) {
            statusEl.textContent = status;
            if (disconnected) {
                statusEl.classList.add('disconnected');
            } else {
                statusEl.classList.remove('disconnected');
            }
        }
    },

    /**
     * Utility Functions
     */
    getCSRFToken() {
        return document.querySelector('[name=csrfmiddlewaretoken]')?.value ||
               document.cookie.match(/csrftoken=([^;]+)/)?.[1] || '';
    },

    getCurrentUserId() {
        // Get from meta tag or global variable
        return window.currentUserId || null;
    },

    formatTime(timestamp) {
        const date = new Date(timestamp);
        return date.toLocaleTimeString('ko-KR', {
            hour: '2-digit',
            minute: '2-digit'
        });
    }
};

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    MatchingSystem.init();
});

// Cleanup on page unload
window.addEventListener('beforeunload', () => {
    if (MatchingSystem.matchingWebSocket) {
        MatchingSystem.matchingWebSocket.close();
    }
    if (MatchingSystem.chatWebSocket) {
        MatchingSystem.chatWebSocket.close();
    }
});

/**
 * Show alert modal instead of browser alert
 * @param {string} title - Modal title
 * @param {string} message - Modal message
 */
function showAlertModal(title, message) {
    const modal = document.getElementById('alert-modal');
    const titleEl = document.getElementById('alert-modal-title');
    const messageEl = document.getElementById('alert-modal-message');
    const confirmBtn = document.getElementById('alert-modal-confirm-btn');

    if (!modal || !titleEl || !messageEl || !confirmBtn) {
        console.error('[AlertModal] Modal elements not found');
        alert(message); // Fallback to browser alert
        return;
    }

    titleEl.textContent = title;
    messageEl.textContent = message;
    modal.classList.remove('hidden');

    // Remove existing event listeners by cloning
    const newConfirmBtn = confirmBtn.cloneNode(true);
    confirmBtn.parentNode.replaceChild(newConfirmBtn, confirmBtn);

    // Add new event listener
    newConfirmBtn.addEventListener('click', () => {
        modal.classList.add('hidden');
    });
}
