/**
 * WebRTC P2P Video Chat Client
 * Handles peer-to-peer video connections with signaling through WebSocket
 */

class WebRTCClient {
    constructor() {
        // WebRTC Configuration
        this.configuration = {
            iceServers: [
                { urls: 'stun:stun.l.google.com:19302' },
                { urls: 'stun:stun1.l.google.com:19302' },
                { urls: 'stun:stun2.l.google.com:19302' },
                { urls: 'stun:stun3.l.google.com:19302' },
                { urls: 'stun:stun4.l.google.com:19302' }
            ]
        };

        // State
        this.peerConnection = null;
        this.localStream = null;
        this.remoteStream = null;
        this.websocket = null;
        this.isInitiator = false;
        this.isConnected = false;
        this.videoEnabled = true;
        this.audioEnabled = true;

        // DOM Elements (will be set by init)
        this.localVideo = null;
        this.remoteVideo = null;

        // Callbacks
        this.onRemoteStreamCallback = null;
        this.onConnectionStateChangeCallback = null;
        this.onErrorCallback = null;
    }

    /**
     * Initialize WebRTC client with WebSocket connection
     */
    init(websocket, localVideoElement, remoteVideoElement) {
        if (window.DEBUG) console.log('[WebRTC] Initializing...');

        this.websocket = websocket;
        this.localVideo = localVideoElement;
        this.remoteVideo = remoteVideoElement;

        // Setup message handler for WebRTC signals
        this.setupWebSocketHandler();
    }

    /**
     * Setup WebSocket message handler for WebRTC signals
     */
    setupWebSocketHandler() {
        // Note: This will be integrated with existing WebSocket message handler
        // The parent component should call handleSignal() for WebRTC messages
    }

    /**
     * Handle incoming WebRTC signals
     */
    async handleSignal(data) {
        try {
            switch (data.type) {
                case 'video_offer':
                    if (window.DEBUG) console.log('[WebRTC] Received video offer');
                    await this.handleOffer(data.sdp);
                    break;
                case 'video_answer':
                    if (window.DEBUG) console.log('[WebRTC] Received video answer');
                    await this.handleAnswer(data.sdp);
                    break;
                case 'ice_candidate':
                    if (window.DEBUG) console.log('[WebRTC] Received ICE candidate');
                    await this.handleIceCandidate(data.candidate);
                    break;
                case 'video_toggle':
                    if (window.DEBUG) console.log('[WebRTC] Partner toggled video:', data.enabled);
                    this.handleRemoteVideoToggle(data.enabled);
                    break;
                default:
                    console.warn('[WebRTC] Unknown signal type:', data.type);
            }
        } catch (error) {
            console.error('[WebRTC] Error handling signal:', error);
            this.handleError('시그널 처리 중 오류가 발생했습니다.');
        }
    }

    /**
     * Start video call
     */
    async startVideo(isInitiator = false) {
        try {
            if (window.DEBUG) console.log('[WebRTC] Starting video...', { isInitiator });

            this.isInitiator = isInitiator;

            // Request camera and microphone permissions
            await this.getLocalStream();

            // Create peer connection
            this.createPeerConnection();

            // If initiator, create and send offer
            if (this.isInitiator) {
                await this.createAndSendOffer();
            }

            return true;
        } catch (error) {
            console.error('[WebRTC] Error starting video:', error);

            // Handle specific error types
            if (error.name === 'NotAllowedError' || error.name === 'PermissionDeniedError') {
                this.handleError('카메라/마이크 권한이 필요합니다.\n브라우저 설정에서 권한을 허용해주세요.');
            } else if (error.name === 'NotFoundError') {
                this.handleError('카메라 또는 마이크를 찾을 수 없습니다.');
            } else if (error.name === 'NotReadableError') {
                this.handleError('카메라/마이크가 다른 앱에서 사용 중입니다.');
            } else {
                this.handleError('영상 채팅을 시작할 수 없습니다.');
            }

            throw error;
        }
    }

    /**
     * Get local media stream (camera + microphone)
     */
    async getLocalStream() {
        try {
            if (window.DEBUG) console.log('[WebRTC] Requesting media devices...');

            // Request video and audio
            const constraints = {
                video: {
                    width: { ideal: 854, max: 1280 },
                    height: { ideal: 480, max: 720 },
                    frameRate: { ideal: 30, max: 30 }
                },
                audio: {
                    echoCancellation: true,
                    noiseSuppression: true,
                    autoGainControl: true
                }
            };

            this.localStream = await navigator.mediaDevices.getUserMedia(constraints);

            if (window.DEBUG) console.log('[WebRTC] Got local stream');

            // Display local video
            if (this.localVideo) {
                this.localVideo.srcObject = this.localStream;
            }

            return this.localStream;
        } catch (error) {
            console.error('[WebRTC] Error getting local stream:', error);
            throw error;
        }
    }

    /**
     * Create RTCPeerConnection
     */
    createPeerConnection() {
        if (window.DEBUG) console.log('[WebRTC] Creating peer connection...');

        this.peerConnection = new RTCPeerConnection(this.configuration);

        // Add local stream tracks to peer connection
        if (this.localStream) {
            this.localStream.getTracks().forEach(track => {
                this.peerConnection.addTrack(track, this.localStream);
                if (window.DEBUG) console.log('[WebRTC] Added track:', track.kind);
            });
        }

        // Handle ICE candidates
        this.peerConnection.onicecandidate = (event) => {
            if (event.candidate) {
                if (window.DEBUG) console.log('[WebRTC] Sending ICE candidate');
                this.sendSignal({
                    type: 'ice_candidate',
                    candidate: event.candidate
                });
            }
        };

        // Handle remote stream
        this.peerConnection.ontrack = (event) => {
            if (window.DEBUG) console.log('[WebRTC] Received remote track:', event.track.kind);

            if (!this.remoteStream) {
                this.remoteStream = new MediaStream();
                if (this.remoteVideo) {
                    this.remoteVideo.srcObject = this.remoteStream;
                }
            }

            this.remoteStream.addTrack(event.track);

            if (this.onRemoteStreamCallback) {
                this.onRemoteStreamCallback(this.remoteStream);
            }
        };

        // Handle connection state changes
        this.peerConnection.onconnectionstatechange = () => {
            const state = this.peerConnection.connectionState;
            if (window.DEBUG) console.log('[WebRTC] Connection state:', state);

            if (state === 'connected') {
                this.isConnected = true;
            } else if (state === 'disconnected' || state === 'failed' || state === 'closed') {
                this.isConnected = false;
            }

            if (this.onConnectionStateChangeCallback) {
                this.onConnectionStateChangeCallback(state);
            }
        };

        // Handle ICE connection state
        this.peerConnection.oniceconnectionstatechange = () => {
            const state = this.peerConnection.iceConnectionState;
            if (window.DEBUG) console.log('[WebRTC] ICE connection state:', state);

            if (state === 'failed') {
                // Restart ICE
                if (window.DEBUG) console.log('[WebRTC] ICE failed, attempting restart...');
                this.peerConnection.restartIce();
            }
        };
    }

    /**
     * Create and send offer
     */
    async createAndSendOffer() {
        try {
            if (window.DEBUG) console.log('[WebRTC] Creating offer...');

            const offer = await this.peerConnection.createOffer();
            await this.peerConnection.setLocalDescription(offer);

            if (window.DEBUG) console.log('[WebRTC] Sending offer');

            this.sendSignal({
                type: 'video_offer',
                sdp: offer
            });
        } catch (error) {
            console.error('[WebRTC] Error creating offer:', error);
            throw error;
        }
    }

    /**
     * Handle received offer
     */
    async handleOffer(sdp) {
        try {
            if (window.DEBUG) console.log('[WebRTC] Handling offer...');

            await this.peerConnection.setRemoteDescription(new RTCSessionDescription(sdp));

            // Create answer
            const answer = await this.peerConnection.createAnswer();
            await this.peerConnection.setLocalDescription(answer);

            if (window.DEBUG) console.log('[WebRTC] Sending answer');

            this.sendSignal({
                type: 'video_answer',
                sdp: answer
            });
        } catch (error) {
            console.error('[WebRTC] Error handling offer:', error);
            throw error;
        }
    }

    /**
     * Handle received answer
     */
    async handleAnswer(sdp) {
        try {
            if (window.DEBUG) console.log('[WebRTC] Handling answer...');

            await this.peerConnection.setRemoteDescription(new RTCSessionDescription(sdp));
        } catch (error) {
            console.error('[WebRTC] Error handling answer:', error);
            throw error;
        }
    }

    /**
     * Handle received ICE candidate
     */
    async handleIceCandidate(candidate) {
        try {
            if (window.DEBUG) console.log('[WebRTC] Adding ICE candidate');

            await this.peerConnection.addIceCandidate(new RTCIceCandidate(candidate));
        } catch (error) {
            console.error('[WebRTC] Error adding ICE candidate:', error);
        }
    }

    /**
     * Handle remote video toggle
     */
    handleRemoteVideoToggle(enabled) {
        // This can be used to show/hide UI elements when partner toggles video
        if (window.DEBUG) console.log('[WebRTC] Remote video toggled:', enabled);
    }

    /**
     * Send signal through WebSocket
     */
    sendSignal(data) {
        if (this.websocket && this.websocket.readyState === WebSocket.OPEN) {
            this.websocket.send(JSON.stringify(data));
        } else {
            console.error('[WebRTC] WebSocket not connected');
        }
    }

    /**
     * Toggle video on/off
     */
    toggleVideo() {
        if (this.localStream) {
            const videoTrack = this.localStream.getVideoTracks()[0];
            if (videoTrack) {
                videoTrack.enabled = !videoTrack.enabled;
                this.videoEnabled = videoTrack.enabled;

                if (window.DEBUG) console.log('[WebRTC] Video toggled:', this.videoEnabled);

                // Notify partner
                this.sendSignal({
                    type: 'video_toggle',
                    enabled: this.videoEnabled
                });

                return this.videoEnabled;
            }
        }
        return false;
    }

    /**
     * Toggle audio on/off
     */
    toggleAudio() {
        if (this.localStream) {
            const audioTrack = this.localStream.getAudioTracks()[0];
            if (audioTrack) {
                audioTrack.enabled = !audioTrack.enabled;
                this.audioEnabled = audioTrack.enabled;

                if (window.DEBUG) console.log('[WebRTC] Audio toggled:', this.audioEnabled);

                return this.audioEnabled;
            }
        }
        return false;
    }

    /**
     * Stop video call and cleanup
     */
    stopVideo() {
        if (window.DEBUG) console.log('[WebRTC] Stopping video...');

        // Stop local stream
        if (this.localStream) {
            this.localStream.getTracks().forEach(track => {
                track.stop();
            });
            this.localStream = null;
        }

        // Clear video elements
        if (this.localVideo) {
            this.localVideo.srcObject = null;
        }
        if (this.remoteVideo) {
            this.remoteVideo.srcObject = null;
        }

        // Close peer connection
        if (this.peerConnection) {
            this.peerConnection.close();
            this.peerConnection = null;
        }

        // Reset state
        this.remoteStream = null;
        this.isConnected = false;
        this.videoEnabled = true;
        this.audioEnabled = true;

        if (window.DEBUG) console.log('[WebRTC] Video stopped');
    }

    /**
     * Handle errors
     */
    handleError(message) {
        console.error('[WebRTC] Error:', message);

        if (this.onErrorCallback) {
            this.onErrorCallback(message);
        }
    }

    /**
     * Set callbacks
     */
    onRemoteStream(callback) {
        this.onRemoteStreamCallback = callback;
    }

    onConnectionStateChange(callback) {
        this.onConnectionStateChangeCallback = callback;
    }

    onError(callback) {
        this.onErrorCallback = callback;
    }

    /**
     * Check if WebRTC is supported
     */
    static isSupported() {
        return !!(
            navigator.mediaDevices &&
            navigator.mediaDevices.getUserMedia &&
            window.RTCPeerConnection
        );
    }
}

// Export for use in other scripts
window.WebRTCClient = WebRTCClient;
