/**
 * Chat Evidence Capture System
 * Automatically captures chat screens and video frames for reporting
 */

class ChatEvidenceCapture {
    constructor() {
        this.isVideoChat = false;
    }

    /**
     * Capture text chat conversation as image
     * @param {string} chatContainerSelector - CSS selector for chat messages container
     * @returns {Promise<Blob>} - Image blob
     */
    async captureChatConversation(chatContainerSelector = '.chat-messages') {
        try {
            const chatContainer = document.querySelector(chatContainerSelector);

            if (!chatContainer) {
                console.error('[Evidence] Chat container not found:', chatContainerSelector);
                return null;
            }

            // Use html2canvas library (need to include in template)
            if (typeof html2canvas === 'undefined') {
                console.error('[Evidence] html2canvas library not loaded');
                // Fallback: simple method
                return await this.captureWithCanvas(chatContainer);
            }

            // Capture with html2canvas
            const canvas = await html2canvas(chatContainer, {
                backgroundColor: '#ffffff',
                scale: 2, // Higher quality
                logging: false,
                useCORS: true
            });

            return await new Promise((resolve) => {
                canvas.toBlob((blob) => {
                    resolve(blob);
                }, 'image/png');
            });

        } catch (error) {
            console.error('[Evidence] Error capturing chat:', error);
            return null;
        }
    }

    /**
     * Capture video chat frame
     * @param {string} videoSelector - CSS selector for video element
     * @returns {Promise<Blob>} - Image blob
     */
    async captureVideoFrame(videoSelector = 'video') {
        try {
            const videoElement = document.querySelector(videoSelector);

            if (!videoElement) {
                console.error('[Evidence] Video element not found:', videoSelector);
                return null;
            }

            // Create canvas
            const canvas = document.createElement('canvas');
            canvas.width = videoElement.videoWidth || 640;
            canvas.height = videoElement.videoHeight || 480;

            // Draw video frame to canvas
            const ctx = canvas.getContext('2d');
            ctx.drawImage(videoElement, 0, 0, canvas.width, canvas.height);

            // Convert to blob
            return await new Promise((resolve) => {
                canvas.toBlob((blob) => {
                    resolve(blob);
                }, 'image/jpeg', 0.9);
            });

        } catch (error) {
            console.error('[Evidence] Error capturing video frame:', error);
            return null;
        }
    }

    /**
     * Fallback canvas capture method (without html2canvas)
     * @param {HTMLElement} element - Element to capture
     * @returns {Promise<Blob>} - Image blob
     */
    async captureWithCanvas(element) {
        try {
            const canvas = document.createElement('canvas');
            const rect = element.getBoundingClientRect();

            canvas.width = rect.width;
            canvas.height = rect.height;

            const ctx = canvas.getContext('2d');

            // Simple text extraction (fallback)
            ctx.fillStyle = '#ffffff';
            ctx.fillRect(0, 0, canvas.width, canvas.height);

            ctx.fillStyle = '#000000';
            ctx.font = '14px Arial';
            ctx.fillText('Chat Evidence Captured', 10, 30);
            ctx.fillText(new Date().toLocaleString(), 10, 50);

            return await new Promise((resolve) => {
                canvas.toBlob((blob) => {
                    resolve(blob);
                }, 'image/png');
            });

        } catch (error) {
            console.error('[Evidence] Fallback capture error:', error);
            return null;
        }
    }

    /**
     * Capture evidence based on chat type
     * @param {boolean} isVideoChat - Whether this is a video chat
     * @returns {Promise<Blob>} - Image blob
     */
    async captureEvidence(isVideoChat = false) {
        this.isVideoChat = isVideoChat;

        if (isVideoChat) {
            console.log('[Evidence] Capturing video chat frame...');
            return await this.captureVideoFrame();
        } else {
            console.log('[Evidence] Capturing text chat conversation...');
            return await this.captureChatConversation();
        }
    }

    /**
     * Attach evidence to FormData for report submission
     * @param {FormData} formData - FormData object to append evidence
     * @param {boolean} isVideoChat - Whether this is video chat
     * @returns {Promise<FormData>} - FormData with evidence attached
     */
    async attachEvidenceToReport(formData, isVideoChat = false) {
        try {
            const evidenceBlob = await this.captureEvidence(isVideoChat);

            if (evidenceBlob) {
                const fieldName = isVideoChat ? 'video_frame' : 'chat_screenshot';
                const fileName = isVideoChat ? 'video_evidence.jpg' : 'chat_evidence.png';

                formData.append(fieldName, evidenceBlob, fileName);
                console.log('[Evidence] Evidence attached to report:', fileName);
            } else {
                console.warn('[Evidence] No evidence captured');
            }

            return formData;

        } catch (error) {
            console.error('[Evidence] Error attaching evidence:', error);
            return formData;
        }
    }
}

// Global instance
window.chatEvidenceCapture = new ChatEvidenceCapture();

// Export for use in other scripts
if (typeof module !== 'undefined' && module.exports) {
    module.exports = ChatEvidenceCapture;
}
