/**
 * Open Chat Room - WebSocket Chat Client
 * Handles real-time messaging in open chat rooms
 */

class OpenChatRoom {
  constructor() {
    // i18n support
    this.i18n = window.APP_I18N || {};

    // Get room data from HTML
    const roomData = document.getElementById('room-data');
    this.roomId = roomData.dataset.roomId;
    this.userId = parseInt(roomData.dataset.userId);
    this.userNickname = roomData.dataset.userNickname;
    this.isFavorited = roomData.dataset.isFavorited === 'true';
    this.isAdmin = roomData.dataset.isAdmin === 'true';
    this.creatorId = roomData.dataset.creatorId ? parseInt(roomData.dataset.creatorId) : null;

    // Participants tracking
    this.participants = new Map(); // Map<userId, {id, nickname, isAdmin, profilePicture}>

    // WebSocket
    this.socket = null;
    this.reconnectAttempts = 0;
    this.maxReconnectAttempts = 5;
    this.reconnectDelay = 1000;

    // Typing indicator
    this.typingTimer = null;
    this.typingDelay = 1000;
    this.isTyping = false;

    // DOM Elements
    this.messagesContainer = document.getElementById('messages-container');
    this.messagesList = document.getElementById('messages-list');
    this.messageForm = document.getElementById('message-form');
    this.messageInput = document.getElementById('message-input');
    this.sendButton = document.querySelector('.btn-send');
    this.backButton = document.getElementById('back-button');
    this.leaveButton = document.getElementById('leave-room-button');
    this.favoriteButton = document.getElementById('favorite-button');
    this.favoriteIcon = document.getElementById('favorite-icon');
    this.creatorBadge = document.getElementById('creator-badge');
    this.typingIndicator = document.getElementById('typing-indicator');
    this.typingUser = document.getElementById('typing-user');
    this.participantCount = document.getElementById('participant-count');
    this.participantSidebar = document.querySelector('.participant-sidebar');
    this.participantList = document.getElementById('participant-list');
    this.toggleParticipantsBtn = document.getElementById('toggle-participants');
    this.closeSidebarBtn = document.getElementById('close-sidebar');

    // Kick modal elements
    this.kickModal = document.getElementById('kick-modal');
    this.kickTargetName = document.getElementById('kick-target-name');
    this.kickReason = document.getElementById('kick-reason');
    this.banDuration = document.getElementById('ban-duration');
    this.confirmKickBtn = document.getElementById('confirm-kick');
    this.cancelKickBtn = document.getElementById('cancel-kick');
    this.closeKickModalBtn = document.getElementById('close-kick-modal');
    this.currentKickTarget = null; // {userId, nickname}

    // Kicked users modal elements
    this.kickedUsersModal = document.getElementById('kicked-users-modal');
    this.kickedUsersList = document.getElementById('kicked-users-list');
    this.viewKickedUsersBtn = document.getElementById('view-kicked-users-button');
    this.closeKickedUsersModalBtn = document.getElementById('close-kicked-users-modal');

    // Leave modal elements
    this.leaveModal = document.getElementById('leave-modal');
    this.confirmLeaveBtn = document.getElementById('confirm-leave');
    this.cancelLeaveBtn = document.getElementById('cancel-leave');
    this.closeLeaveModalBtn = document.getElementById('close-leave-modal');

    // Note: Report and Block modals are now handled by post_actions.js

    this.init();
  }

  async init() {
    await this.loadInitialMessages();
    this.connectWebSocket();
    this.attachEventListeners();
    this.updateFavoriteButton();
  }

  async loadInitialMessages() {
    try {
      const response = await fetch(`/api/chat/api/open-rooms/${this.roomId}/`);
      if (!response.ok) throw new Error('Failed to load messages');

      const data = await response.json();

      // Update room data
      this.isFavorited = data.is_favorited || false;
      this.isAdmin = data.is_admin || false;
      this.creatorId = data.creator_id || null;

      // Load participants
      if (data.participants && data.participants.length > 0) {
        data.participants.forEach(participant => {
          this.participants.set(participant.user_id, {
            id: participant.user_id,
            username: participant.user_username,
            nickname: participant.user_nickname,
            isAdmin: participant.is_admin,
            profilePicture: participant.user_profile_picture
          });
        });
      }

      // Update UI with room data
      if (this.participantCount) {
        this.participantCount.textContent = data.participant_count || 0;
      }

      // Show/hide admin-only buttons
      if (this.viewKickedUsersBtn) {
        if (this.isAdmin) {
          this.viewKickedUsersBtn.classList.remove('hidden');
        } else {
          this.viewKickedUsersBtn.classList.add('hidden');
        }
      }

      // Update favorite button
      this.updateFavoriteButton();

      // Update participant list
      this.updateParticipantList();

      // Show creator badge if user is creator
      if (data.creator_nickname && this.creatorBadge) {
        this.creatorBadge.textContent = `👑 ${data.creator_nickname}`;
        this.creatorBadge.classList.remove('hidden');
      }

      // Render messages
      if (data.messages && data.messages.length > 0) {
        data.messages.forEach(message => {
          this.addMessage(message, false);
        });
      }

      // Scroll to bottom
      this.scrollToBottom();
    } catch (error) {
      console.error('Error loading messages:', error);
      this.showSystemMessage(this.i18n.loadMessagesFailed || '메시지를 불러오는데 실패했습니다.');
    }
  }

  connectWebSocket() {
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const wsUrl = `${protocol}//${window.location.host}/ws/open-chat/${this.roomId}/`;

    this.socket = new WebSocket(wsUrl);

    this.socket.onopen = () => {
      console.log('WebSocket connected');
      this.reconnectAttempts = 0;
      this.showSystemMessage(this.i18n.roomJoined || '채팅방에 입장했습니다');
    };

    this.socket.onmessage = (event) => {
      const data = JSON.parse(event.data);
      this.handleWebSocketMessage(data);
    };

    this.socket.onclose = () => {
      console.log('WebSocket disconnected');
      this.attemptReconnect();
    };

    this.socket.onerror = (error) => {
      console.error('WebSocket error:', error);
    };
  }

  attemptReconnect() {
    if (this.reconnectAttempts < this.maxReconnectAttempts) {
      this.reconnectAttempts++;
      const delay = this.reconnectDelay * this.reconnectAttempts;

      console.log(`Reconnecting in ${delay}ms (attempt ${this.reconnectAttempts})`);

      setTimeout(() => {
        this.connectWebSocket();
      }, delay);
    } else {
      this.showSystemMessage(this.i18n.connectionLost || '연결이 끊어졌습니다. 페이지를 새로고침해주세요.');
    }
  }

  handleWebSocketMessage(data) {
    switch (data.type) {
      case 'message':
        this.addMessage(data);
        break;

      case 'user_joined':
        // Add to participants map
        if (data.user_id) {
          this.participants.set(data.user_id, {
            id: data.user_id,
            username: data.user_username,
            nickname: data.user_nickname,
            isAdmin: data.is_admin || false,
            profilePicture: data.user_profile_picture || null
          });
          this.updateParticipantList();
          this.updateParticipantCountLocally();
        }
        this.showSystemMessage(`${data.user_nickname}${this.i18n.userJoined || '님이 입장했습니다'}`);
        break;

      case 'user_left':
        this.showSystemMessage(`${data.user_nickname}${this.i18n.userLeft || '님이 퇴장했습니다'}`);
        // Remove from participants map
        if (data.user_id) {
          this.participants.delete(data.user_id);
          this.updateParticipantList();
          this.updateParticipantCountLocally();
        }
        break;

      case 'user_kicked':
        this.handleUserKicked(data);
        break;

      case 'admin_changed':
        this.handleAdminChanged(data);
        break;

      case 'typing':
        this.showTypingIndicator(data.user_nickname);
        break;

      default:
        console.log('Unknown message type:', data.type);
    }
  }

  handleUserKicked(data) {
    const { kicked_user_id, kicked_user_nickname, kicked_by_nickname, reason } = data;

    // Check if current user was kicked
    if (kicked_user_id === this.userId) {
      // Close WebSocket
      if (this.socket) {
        this.socket.close();
      }

      // Show alert and redirect
      const message = reason
        ? `${kicked_by_nickname}${this.i18n.kickedWithReason || '님에 의해 강퇴되었습니다.\n사유: '}${reason}`
        : `${kicked_by_nickname}${this.i18n.kickedBy || '님에 의해 강퇴되었습니다.'}`;

      alert(message);
      window.location.href = '/learning/chat/';
      return;
    }

    // Remove kicked user from participants
    this.participants.delete(kicked_user_id);
    this.updateParticipantList();
    this.updateParticipantCount();

    // Show system message
    const message = reason
      ? `${kicked_user_nickname}${this.i18n.kickedReason || '님이 강퇴되었습니다 (사유: '}${reason})`
      : `${kicked_user_nickname}${this.i18n.wasKicked || '님이 강퇴되었습니다'}`;
    this.showSystemMessage(message);
  }

  handleAdminChanged(data) {
    const { user_id, user_nickname, is_admin, granted_by_nickname, revoked_by_nickname } = data;

    // Update participant data
    const participant = this.participants.get(user_id);
    if (participant) {
      participant.isAdmin = is_admin;
      this.participants.set(user_id, participant);
    }

    // Update participant list UI
    this.updateParticipantList();

    // Update current user's admin status if it's them
    if (user_id === this.userId) {
      this.isAdmin = is_admin;
      // Refresh UI to show/hide admin controls
      this.updateParticipantList();
    }

    // Show system message
    const message = is_admin
      ? `${user_nickname}${this.i18n.adminGranted || '님이 관리자로 지정되었습니다'} (by ${granted_by_nickname})`
      : `${user_nickname}${this.i18n.adminRevoked || '님의 관리자 권한이 해제되었습니다'} (by ${revoked_by_nickname})`;
    this.showSystemMessage(message);
  }

  attachEventListeners() {
    // Message form submission
    if (this.messageForm) {
      this.messageForm.addEventListener('submit', (e) => {
        e.preventDefault();
        this.sendMessage();
      });
    }

    // Typing indicator
    if (this.messageInput) {
      this.messageInput.addEventListener('input', () => {
        this.handleTyping();
      });
    }

    // Back button
    if (this.backButton) {
      this.backButton.addEventListener('click', () => {
        window.location.href = '/learning/chat/';
      });
    }

    // Leave button
    if (this.leaveButton) {
      this.leaveButton.addEventListener('click', () => {
        this.leaveRoom();
      });
    }

    // Favorite button
    if (this.favoriteButton) {
      this.favoriteButton.addEventListener('click', () => {
        this.toggleFavorite();
      });
    }

    // Toggle participants sidebar
    if (this.toggleParticipantsBtn) {
      this.toggleParticipantsBtn.addEventListener('click', () => {
        this.toggleParticipantSidebar();
      });
    }

    // Close sidebar
    if (this.closeSidebarBtn) {
      this.closeSidebarBtn.addEventListener('click', () => {
        this.closeParticipantSidebar();
      });
    }

    // Kick modal event listeners
    if (this.confirmKickBtn) {
      this.confirmKickBtn.addEventListener('click', () => {
        this.confirmKick();
      });
    }

    if (this.cancelKickBtn) {
      this.cancelKickBtn.addEventListener('click', () => {
        this.closeKickModal();
      });
    }

    if (this.closeKickModalBtn) {
      this.closeKickModalBtn.addEventListener('click', () => {
        this.closeKickModal();
      });
    }

    // Kicked users modal event listeners
    if (this.viewKickedUsersBtn) {
      this.viewKickedUsersBtn.addEventListener('click', () => {
        this.openKickedUsersModal();
      });
    }

    if (this.closeKickedUsersModalBtn) {
      this.closeKickedUsersModalBtn.addEventListener('click', () => {
        this.closeKickedUsersModal();
      });
    }

    // Leave modal event listeners
    if (this.confirmLeaveBtn) {
      this.confirmLeaveBtn.addEventListener('click', () => {
        this.confirmLeave();
      });
    }

    if (this.cancelLeaveBtn) {
      this.cancelLeaveBtn.addEventListener('click', () => {
        this.closeLeaveModal();
      });
    }

    if (this.closeLeaveModalBtn) {
      this.closeLeaveModalBtn.addEventListener('click', () => {
        this.closeLeaveModal();
      });
    }

    // Note: Report and Block modals are now handled by post_actions.js

    // Close modals on backdrop click
    if (this.kickModal) {
      this.kickModal.addEventListener('click', (e) => {
        if (e.target === this.kickModal) {
          this.closeKickModal();
        }
      });
    }

    if (this.kickedUsersModal) {
      this.kickedUsersModal.addEventListener('click', (e) => {
        if (e.target === this.kickedUsersModal) {
          this.closeKickedUsersModal();
        }
      });
    }

    if (this.leaveModal) {
      this.leaveModal.addEventListener('click', (e) => {
        if (e.target === this.leaveModal) {
          this.closeLeaveModal();
        }
      });
    }

    if (this.reportModal) {
      this.reportModal.addEventListener('click', (e) => {
        if (e.target === this.reportModal) {
          this.closeReportModal();
        }
      });
    }

    if (this.blockUserModal) {
      this.blockUserModal.addEventListener('click', (e) => {
        if (e.target === this.blockUserModal) {
          this.closeBlockUserModal();
        }
      });
    }
  }

  sendMessage() {
    const content = this.messageInput.value.trim();
    if (!content || !this.socket || this.socket.readyState !== WebSocket.OPEN) {
      return;
    }

    // Send message via WebSocket
    this.socket.send(JSON.stringify({
      type: 'message',
      content: content
    }));

    // Clear input
    this.messageInput.value = '';
    this.messageInput.focus();
  }

  handleTyping() {
    if (!this.isTyping) {
      this.isTyping = true;
      if (this.socket && this.socket.readyState === WebSocket.OPEN) {
        this.socket.send(JSON.stringify({
          type: 'typing'
        }));
      }
    }

    clearTimeout(this.typingTimer);
    this.typingTimer = setTimeout(() => {
      this.isTyping = false;
    }, this.typingDelay);
  }

  addMessage(message, shouldScroll = true) {
    const messageDiv = document.createElement('div');
    messageDiv.className = 'message';

    const isOwnMessage = message.sender_id === this.userId;
    if (isOwnMessage) {
      messageDiv.classList.add('own-message');
    }

    // Avatar
    const avatar = document.createElement('div');
    avatar.className = 'message-avatar';

    if (message.sender_profile_picture) {
      const img = document.createElement('img');
      img.src = message.sender_profile_picture;
      img.alt = message.sender_nickname;
      avatar.appendChild(img);
    } else {
      avatar.textContent = message.sender_nickname.charAt(0).toUpperCase();
    }

    // Content
    const contentDiv = document.createElement('div');
    contentDiv.className = 'message-content';

    // Header (nickname + time)
    const headerDiv = document.createElement('div');
    headerDiv.className = 'message-header';

    const nickname = document.createElement('span');
    nickname.className = 'message-nickname';
    nickname.textContent = message.sender_nickname;

    const time = document.createElement('span');
    time.className = 'message-time';
    time.textContent = this.formatTime(message.created_at);

    headerDiv.appendChild(nickname);
    headerDiv.appendChild(time);

    // Bubble
    const bubble = document.createElement('div');
    bubble.className = 'message-bubble';
    bubble.textContent = message.content;

    contentDiv.appendChild(headerDiv);
    contentDiv.appendChild(bubble);

    messageDiv.appendChild(avatar);
    messageDiv.appendChild(contentDiv);

    this.messagesList.appendChild(messageDiv);

    if (shouldScroll) {
      this.scrollToBottom();
    }
  }

  showSystemMessage(text) {
    const messageDiv = document.createElement('div');
    messageDiv.className = 'system-message';
    messageDiv.textContent = text;

    this.messagesList.appendChild(messageDiv);
    this.scrollToBottom();
  }

  showTypingIndicator(nickname) {
    if (this.typingIndicator && this.typingUser) {
      this.typingUser.textContent = `${nickname}${this.i18n.typing || '님이 입력 중'}`;
      this.typingIndicator.classList.remove('hidden');

      clearTimeout(this.typingIndicatorTimer);
      this.typingIndicatorTimer = setTimeout(() => {
        this.typingIndicator.classList.add('hidden');
      }, 3000);
    }
  }

  formatTime(timestamp) {
    const date = new Date(timestamp);
    const now = new Date();

    // Get current language from HTML or cookie
    const lang = document.documentElement.lang || 'ko';
    const locale = lang === 'en' ? 'en-US' : 'ko-KR';

    const isToday = date.toDateString() === now.toDateString();

    if (isToday) {
      return date.toLocaleTimeString(locale, {
        hour: '2-digit',
        minute: '2-digit'
      });
    } else {
      return date.toLocaleDateString(locale, {
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      });
    }
  }

  scrollToBottom() {
    if (this.messagesContainer) {
      this.messagesContainer.scrollTop = this.messagesContainer.scrollHeight;
    }
  }

  async updateParticipantCount() {
    try {
      const response = await fetch(`/api/chat/api/open-rooms/${this.roomId}/`);
      if (!response.ok) return;

      const data = await response.json();
      if (this.participantCount) {
        this.participantCount.textContent = data.participant_count || 0;
      }
    } catch (error) {
      console.error('Error updating participant count:', error);
    }
  }

  updateParticipantCountLocally() {
    const count = this.participants.size;
    if (this.participantCount) {
      this.participantCount.textContent = count;
    }
  }

  leaveRoom() {
    this.openLeaveModal();
  }

  openLeaveModal() {
    if (this.leaveModal) {
      this.leaveModal.classList.remove('hidden');
      document.body.style.overflow = 'hidden';
    }
  }

  closeLeaveModal() {
    if (this.leaveModal) {
      this.leaveModal.classList.add('hidden');
      document.body.style.overflow = '';
    }
  }

  async confirmLeave() {
    this.closeLeaveModal();

    try {
      const response = await fetch(`/api/chat/api/open-rooms/${this.roomId}/leave/`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRFToken': this.getCSRFToken()
        }
      });

      if (response.ok) {
        // Close WebSocket
        if (this.socket) {
          this.socket.close();
        }

        // Redirect to chat list
        window.location.href = '/learning/chat/';
      } else {
        alert(this.i18n.leaveRoomFailed || '채팅방 나가기에 실패했습니다.');
      }
    } catch (error) {
      console.error('Error leaving room:', error);
      alert(this.i18n.errorOccurred || '오류가 발생했습니다.');
    }
  }

  async toggleFavorite() {
    const endpoint = this.isFavorited ? 'unfavorite' : 'favorite';

    try {
      const response = await fetch(`/api/chat/api/open-rooms/${this.roomId}/${endpoint}/`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRFToken': this.getCSRFToken()
        }
      });

      if (response.ok) {
        this.isFavorited = !this.isFavorited;
        this.updateFavoriteButton();

        const message = this.isFavorited ? (this.i18n.favoriteAdded || '즐겨찾기에 추가되었습니다') : (this.i18n.favoriteRemoved || '즐겨찾기에서 제거되었습니다');
        this.showSystemMessage(message);
      } else {
        const error = await response.json();
        alert(error.message || error.error || (this.i18n.errorOccurred || '오류가 발생했습니다'));
      }
    } catch (error) {
      console.error('Error toggling favorite:', error);
      alert(this.i18n.errorOccurred || '오류가 발생했습니다');
    }
  }

  updateFavoriteButton() {
    if (!this.favoriteButton || !this.favoriteIcon) return;

    if (this.isFavorited) {
      this.favoriteIcon.setAttribute('fill', 'currentColor');
      this.favoriteButton.classList.add('favorited');
      this.favoriteButton.setAttribute('aria-label', this.i18n.unfavorite || '즐겨찾기 해제');
      this.favoriteButton.setAttribute('title', this.i18n.unfavorite || '즐겨찾기 해제');
    } else {
      this.favoriteIcon.setAttribute('fill', 'none');
      this.favoriteButton.classList.remove('favorited');
      this.favoriteButton.setAttribute('aria-label', this.i18n.favorite || '즐겨찾기');
      this.favoriteButton.setAttribute('title', this.i18n.favorite || '즐겨찾기');
    }
  }

  updateParticipantList() {
    if (!this.participantList) return;

    // Clear existing list
    this.participantList.innerHTML = '';

    // Sort participants: admins first, then alphabetically
    const sortedParticipants = Array.from(this.participants.values()).sort((a, b) => {
      if (a.isAdmin && !b.isAdmin) return -1;
      if (!a.isAdmin && b.isAdmin) return 1;
      return a.nickname.localeCompare(b.nickname);
    });

    // Render each participant
    sortedParticipants.forEach(participant => {
      const item = document.createElement('div');
      item.className = 'participant-item';
      item.dataset.userId = participant.id;

      // Avatar
      const avatar = document.createElement('div');
      avatar.className = 'participant-avatar';
      if (participant.profilePicture) {
        const img = document.createElement('img');
        img.src = participant.profilePicture;
        img.alt = participant.nickname;
        avatar.appendChild(img);
      } else {
        avatar.textContent = participant.nickname.charAt(0).toUpperCase();
      }

      // Info
      const info = document.createElement('div');
      info.className = 'participant-info';

      const name = document.createElement('span');
      name.className = 'participant-name';
      name.textContent = participant.nickname;

      if (participant.isAdmin) {
        const badge = document.createElement('span');
        badge.className = 'admin-badge';
        badge.textContent = '👑';
        badge.title = 'Admin';
        name.appendChild(badge);
      }

      if (participant.id === this.userId) {
        const youBadge = document.createElement('span');
        youBadge.className = 'you-badge';
        youBadge.textContent = '(Me)';
        name.appendChild(youBadge);
      }

      // Wrap name in a container for left-side alignment
      const nameWrapper = document.createElement('div');
      nameWrapper.className = 'participant-name-wrapper';
      nameWrapper.appendChild(name);
      info.appendChild(nameWrapper);

      // Action buttons (only for other users, not self)
      if (participant.id !== this.userId) {
        const actionsContainer = document.createElement('div');
        actionsContainer.className = 'participant-actions';

        // Follow button
        const followBtn = document.createElement('button');
        followBtn.className = 'btn-follow';
        followBtn.textContent = this.i18n.follow || 'Follow';
        followBtn.title = `${this.i18n.follow || 'Follow'} ${participant.nickname}`;
        followBtn.addEventListener('click', (e) => {
          e.stopPropagation();
          this.toggleFollow(participant.username, participant.nickname);
        });
        actionsContainer.appendChild(followBtn);

        // Message button
        const messageBtn = document.createElement('button');
        messageBtn.className = 'btn-message';
        messageBtn.textContent = this.i18n.message || 'Message';
        messageBtn.title = `${this.i18n.sendMessageTo || 'Send message to'} ${participant.nickname}`;
        messageBtn.addEventListener('click', (e) => {
          e.stopPropagation();
          this.sendDirectMessage(participant.id, participant.nickname);
        });
        actionsContainer.appendChild(messageBtn);

        // More actions button (⋯)
        const moreBtn = document.createElement('button');
        moreBtn.className = 'btn-more';
        moreBtn.innerHTML = `
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <circle cx="12" cy="12" r="1"/>
            <circle cx="12" cy="5" r="1"/>
            <circle cx="12" cy="19" r="1"/>
          </svg>
        `;
        moreBtn.title = this.i18n.more || 'More';
        moreBtn.addEventListener('click', (e) => {
          e.stopPropagation();
          this.showParticipantActionModal(participant);
        });
        actionsContainer.appendChild(moreBtn);

        info.appendChild(actionsContainer);
      }

      item.appendChild(avatar);
      item.appendChild(info);
      this.participantList.appendChild(item);
    });
  }

  toggleParticipantSidebar() {
    if (!this.participantSidebar) return;

    if (this.participantSidebar.classList.contains('open')) {
      this.closeParticipantSidebar();
    } else {
      this.participantSidebar.classList.add('open');
    }
  }

  closeParticipantSidebar() {
    if (!this.participantSidebar) return;
    this.participantSidebar.classList.remove('open');
  }

  /**
   * Show participant action modal with context-specific options
   * @param {Object} participant - Participant object with id, nickname, etc.
   */
  showParticipantActionModal(participant) {
    const isAdmin = this.roomData?.admins?.includes(this.userId);
    const isTargetAdmin = this.roomData?.admins?.includes(participant.id);

    // Create modal HTML
    const modalHtml = `
      <div class="participant-action-modal active" id="participant-action-modal">
        <div class="participant-action-content">
          <div class="participant-action-header">
            <h3>${this.escapeHtml(participant.nickname)}</h3>
            <button class="btn-close" onclick="window.openChatRoom.closeParticipantActionModal()">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <line x1="18" y1="6" x2="6" y2="18"/>
                <line x1="6" y1="6" x2="18" y2="18"/>
              </svg>
            </button>
          </div>
          <div class="participant-action-body">
            ${isAdmin ? `
              <button class="action-item" onclick="window.openChatRoom.toggleAdmin(${participant.id}, '${this.escapeHtml(participant.nickname)}', ${isTargetAdmin})">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
                  <circle cx="8.5" cy="7" r="4"/>
                  <polyline points="17 11 19 13 23 9"/>
                </svg>
                <span>${isTargetAdmin ? (this.i18n.revokeAdmin || 'Revoke Admin') : (this.i18n.grantAdmin || 'Grant Admin')}</span>
              </button>
              <button class="action-item danger" onclick="window.openChatRoom.kickParticipant(${participant.id}, '${this.escapeHtml(participant.nickname)}')">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/>
                  <polyline points="16 17 21 12 16 7"/>
                  <line x1="21" y1="12" x2="9" y2="12"/>
                </svg>
                <span>${this.i18n.kick || 'Kick'}</span>
              </button>
            ` : ''}
            <button class="action-item" data-action="report" data-user-id="${participant.id}" data-nickname="${this.escapeHtml(participant.nickname)}">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/>
                <line x1="12" y1="9" x2="12" y2="13"/>
                <line x1="12" y1="17" x2="12.01" y2="17"/>
              </svg>
              <span>${this.i18n.report || 'Report'}</span>
            </button>
            <button class="action-item danger" data-action="block" data-user-id="${participant.id}" data-nickname="${this.escapeHtml(participant.nickname)}">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="12" cy="12" r="10"/>
                <line x1="4.93" y1="4.93" x2="19.07" y2="19.07"/>
              </svg>
              <span>${this.i18n.block || 'Block'}</span>
            </button>
          </div>
        </div>
      </div>
    `;

    // Remove existing modal if any
    const existing = document.getElementById('participant-action-modal');
    if (existing) {
      existing.remove();
    }

    // Add to body
    document.body.insertAdjacentHTML('beforeend', modalHtml);

    // Add click outside to close
    const modal = document.getElementById('participant-action-modal');
    modal.addEventListener('click', (e) => {
      if (e.target === modal) {
        this.closeParticipantActionModal();
      }
    });

    // Add event listeners for block and report buttons
    const blockBtn = modal.querySelector('[data-action="block"]');
    const reportBtn = modal.querySelector('[data-action="report"]');

    if (blockBtn) {
      blockBtn.addEventListener('click', () => {
        const username = blockBtn.dataset.nickname;
        this.closeParticipantActionModal();

        // Use post_actions.js method
        if (window.postActionsManager) {
          window.postActionsManager.currentAuthorUsername = username;
          window.postActionsManager.openBlockUserModal(username);
        }
      });
    }

    if (reportBtn) {
      reportBtn.addEventListener('click', () => {
        const userId = reportBtn.dataset.userId;
        const username = reportBtn.dataset.nickname;
        this.closeParticipantActionModal();

        // Use post_actions.js method
        if (window.postActionsManager) {
          window.postActionsManager.currentAuthorUsername = username;
          window.postActionsManager.currentReportUserId = parseInt(userId);
          window.postActionsManager.openReportModal();
        }
      });
    }
  }

  /**
   * Close participant action modal
   */
  closeParticipantActionModal() {
    const modal = document.getElementById('participant-action-modal');
    if (modal) {
      modal.classList.remove('active');
      setTimeout(() => modal.remove(), 300);
    }
  }

  /**
   * Toggle follow/unfollow for a user
   * @param {string} username - Username to follow/unfollow
   * @param {string} nickname - User nickname
   */
  async toggleFollow(username, nickname) {
    this.closeParticipantActionModal();

    try {
      const response = await fetch(`/api/accounts/${username}/follow/`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRFToken': this.getCSRFToken()
        }
      });

      if (response.ok) {
        const data = await response.json();
        this.showSystemMessage(data.message || `${this.i18n.followed || 'Followed'} ${nickname}`);
      } else {
        const error = await response.json();
        if (typeof window.showAlert === 'function') {
          window.showAlert(error.error || error.message || (this.i18n.followFailed || 'Failed to follow user'), 'error');
        } else {
          alert(error.error || error.message || (this.i18n.followFailed || 'Failed to follow user'));
        }
      }
    } catch (error) {
      console.error('Error toggling follow:', error);
      if (typeof window.showAlert === 'function') {
        window.showAlert(this.i18n.errorOccurred || 'An error occurred', 'error');
      } else {
        alert(this.i18n.errorOccurred || 'An error occurred');
      }
    }
  }

  /**
   * Navigate to direct message with user
   * @param {number} userId - User ID to message
   * @param {string} nickname - User nickname
   */
  async sendDirectMessage(userId, nickname) {
    this.closeParticipantActionModal();

    try {
      // Create or get existing conversation with the user
      const response = await fetch('/api/chat/api/conversations/', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRFToken': this.getCSRFToken()
        },
        body: JSON.stringify({
          user_id: userId
        })
      });

      if (response.ok) {
        const data = await response.json();
        // Navigate to the conversation page with conversation ID
        window.location.href = `/messages/${data.id}/`;
      } else {
        const error = await response.json();
        alert(error.error || (this.i18n.conversationFailed || 'Failed to create conversation'));
      }
    } catch (error) {
      console.error('Error creating conversation:', error);
      alert(this.i18n.conversationError || 'An error occurred while creating conversation');
    }
  }

  /**
   * Toggle admin status for a participant
   * @param {number} userId - User ID
   * @param {string} nickname - User nickname
   * @param {boolean} isAdmin - Current admin status
   */
  async toggleAdmin(userId, nickname, isAdmin) {
    this.closeParticipantActionModal();

    if (isAdmin) {
      await this.revokeAdmin(userId, nickname);
    } else {
      await this.grantAdmin(userId, nickname);
    }
  }

  /**
   * Kick participant wrapper for modal button
   * @param {number} userId - User ID to kick
   * @param {string} nickname - User nickname
   */
  kickParticipant(userId, nickname) {
    this.closeParticipantActionModal();
    this.kickUser(userId, nickname);
  }

  // Note: Report and Block functionality are now handled by post_actions.js

  /**
   * Escape HTML to prevent XSS attacks
   * @param {string} text - Text to escape
   * @returns {string} Escaped text
   */
  escapeHtml(text) {
    if (!text) return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }

  kickUser(userId, nickname) {
    // Set current kick target
    this.currentKickTarget = { userId, nickname };

    // Update modal content
    this.kickTargetName.textContent = `${nickname}${this.i18n.kickConfirm || '님을 강퇴하시겠습니까?'}`;
    this.kickReason.value = '';
    this.banDuration.value = 'permanent';

    // Open modal
    this.openKickModal();
  }

  openKickModal() {
    if (this.kickModal) {
      this.kickModal.classList.remove('hidden');
    }
  }

  closeKickModal() {
    if (this.kickModal) {
      this.kickModal.classList.add('hidden');
      this.currentKickTarget = null;
      this.kickReason.value = '';
      this.banDuration.value = 'permanent';
    }
  }

  async confirmKick() {
    if (!this.currentKickTarget) return;

    const { userId, nickname } = this.currentKickTarget;
    const reason = this.kickReason.value.trim();
    const duration = this.banDuration.value;

    // Calculate ban_until based on duration
    let banUntil = null;
    if (duration !== 'permanent') {
      const now = new Date();
      switch (duration) {
        case '1h':
          now.setHours(now.getHours() + 1);
          break;
        case '1d':
          now.setDate(now.getDate() + 1);
          break;
        case '1w':
          now.setDate(now.getDate() + 7);
          break;
        case '1m':
          now.setMonth(now.getMonth() + 1);
          break;
      }
      banUntil = now.toISOString();
    }

    // Close modal first
    this.closeKickModal();

    try {
      const requestBody = {
        user_id: userId,
        reason: reason || ''
      };

      if (banUntil) {
        requestBody.ban_until = banUntil;
      }

      const response = await fetch(`/api/chat/api/open-rooms/${this.roomId}/kick_user/`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRFToken': this.getCSRFToken()
        },
        body: JSON.stringify(requestBody)
      });

      if (response.ok) {
        const data = await response.json();
        this.showSystemMessage(data.message || `${nickname}${this.i18n.wasKicked || '님이 강퇴되었습니다'}`);
        // WebSocket will handle the rest
      } else {
        const error = await response.json();
        alert(error.error || error.message || (this.i18n.kickFailed || '강퇴에 실패했습니다'));
      }
    } catch (error) {
      console.error('Error kicking user:', error);
      alert(this.i18n.errorOccurred || '오류가 발생했습니다');
    }
  }

  async grantAdmin(userId, nickname) {
    if (!confirm(`${nickname}${this.i18n.grantAdminConfirm || '님에게 관리자 권한을 부여하시겠습니까?'}`)) return;

    try {
      const response = await fetch(`/api/chat/api/open-rooms/${this.roomId}/grant_admin/`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRFToken': this.getCSRFToken()
        },
        body: JSON.stringify({
          user_id: userId
        })
      });

      if (response.ok) {
        const data = await response.json();
        this.showSystemMessage(data.message || `${nickname}${this.i18n.adminGranted || '님이 관리자로 지정되었습니다'}`);
        // WebSocket will handle the rest
      } else {
        const error = await response.json();
        alert(error.error || error.message || (this.i18n.grantAdminFailed || '관리자 권한 부여에 실패했습니다'));
      }
    } catch (error) {
      console.error('Error granting admin:', error);
      alert(this.i18n.errorOccurred || '오류가 발생했습니다');
    }
  }

  async revokeAdmin(userId, nickname) {
    if (!confirm(`${nickname}${this.i18n.revokeAdminConfirm || '님의 관리자 권한을 해제하시겠습니까?'}`)) return;

    try {
      const response = await fetch(`/api/chat/api/open-rooms/${this.roomId}/revoke_admin/`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRFToken': this.getCSRFToken()
        },
        body: JSON.stringify({
          user_id: userId
        })
      });

      if (response.ok) {
        const data = await response.json();
        this.showSystemMessage(data.message || `${nickname}${this.i18n.adminRevoked || '님의 관리자 권한이 해제되었습니다'}`);
        // WebSocket will handle the rest
      } else {
        const error = await response.json();
        alert(error.error || error.message || (this.i18n.revokeAdminFailed || '관리자 권한 해제에 실패했습니다'));
      }
    } catch (error) {
      console.error('Error revoking admin:', error);
      alert(this.i18n.errorOccurred || '오류가 발생했습니다');
    }
  }

  async openKickedUsersModal() {
    if (!this.kickedUsersModal) return;

    // Show modal
    this.kickedUsersModal.classList.remove('hidden');

    // Fetch kicked users list
    try {
      const response = await fetch(`/api/chat/api/open-rooms/${this.roomId}/get_kicked_users/`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRFToken': this.getCSRFToken()
        }
      });

      if (response.ok) {
        const data = await response.json();
        this.renderKickedUsersList(data.kicked_users || []);
      } else {
        const error = await response.json();
        alert(error.error || error.message || (this.i18n.kickedListFailed || '강퇴 목록을 불러오는데 실패했습니다'));
        this.closeKickedUsersModal();
      }
    } catch (error) {
      console.error('Error fetching kicked users:', error);
      alert(this.i18n.errorOccurred || '오류가 발생했습니다');
      this.closeKickedUsersModal();
    }
  }

  closeKickedUsersModal() {
    if (this.kickedUsersModal) {
      this.kickedUsersModal.classList.add('hidden');
      this.kickedUsersList.innerHTML = '';
    }
  }

  renderKickedUsersList(kickedUsers) {
    if (!this.kickedUsersList) return;

    // Clear existing list
    this.kickedUsersList.innerHTML = '';

    if (kickedUsers.length === 0) {
      this.kickedUsersList.innerHTML = `<p style="text-align: center; color: var(--color-text-light); padding: var(--space-lg);">${this.i18n.noKickedUsers || '강퇴된 사용자가 없습니다'}</p>`;
      return;
    }

    // Render each kicked user
    kickedUsers.forEach(kickData => {
      const item = document.createElement('div');
      item.className = 'kicked-user-item';

      // Avatar
      const avatar = document.createElement('div');
      avatar.className = 'kicked-user-avatar';
      if (kickData.profile_picture) {
        const img = document.createElement('img');
        img.src = kickData.profile_picture;
        img.alt = kickData.nickname;
        avatar.appendChild(img);
      } else {
        avatar.textContent = kickData.nickname.charAt(0).toUpperCase();
      }

      // Info
      const info = document.createElement('div');
      info.className = 'kicked-user-info';

      const name = document.createElement('div');
      name.className = 'kicked-user-name';
      name.textContent = kickData.nickname;

      const details = document.createElement('div');
      details.className = 'kicked-user-details';

      // Kicked by and date
      const kickedBy = document.createElement('span');
      const lang = document.documentElement.lang || 'ko';
      const locale = lang === 'en' ? 'en-US' : 'ko-KR';
      const kickedDate = new Date(kickData.kicked_at).toLocaleString(locale);
      kickedBy.textContent = `${this.i18n.kickedBy2 || '강퇴자:'} ${kickData.kicked_by_nickname} | ${kickedDate}`;
      details.appendChild(kickedBy);

      // Reason
      if (kickData.reason) {
        const reason = document.createElement('span');
        reason.textContent = `${this.i18n.reason || '사유:'} ${kickData.reason}`;
        details.appendChild(reason);
      }

      // Ban status
      const banStatus = document.createElement('span');
      if (kickData.is_permanent) {
        banStatus.textContent = this.i18n.permanentBan || '영구 차단';
        banStatus.className = 'ban-status active';
      } else if (kickData.is_ban_active) {
        const lang = document.documentElement.lang || 'ko';
        const locale = lang === 'en' ? 'en-US' : 'ko-KR';
        const banUntil = new Date(kickData.ban_until).toLocaleString(locale);
        banStatus.textContent = `${this.i18n.bannedUntil || '차단'} (${banUntil}${this.i18n.until || '까지'})`;
        banStatus.className = 'ban-status active';
      } else {
        banStatus.textContent = this.i18n.banExpired || '차단 해제됨';
        banStatus.className = 'ban-status expired';
      }
      details.appendChild(banStatus);

      info.appendChild(name);
      info.appendChild(details);

      // Unban button
      if (kickData.is_ban_active) {
        const unbanBtn = document.createElement('button');
        unbanBtn.className = 'btn-unban';
        unbanBtn.textContent = this.i18n.unban || '차단 해제';
        unbanBtn.addEventListener('click', () => {
          this.unbanUser(kickData.user_id, kickData.nickname);
        });
        item.appendChild(avatar);
        item.appendChild(info);
        item.appendChild(unbanBtn);
      } else {
        item.appendChild(avatar);
        item.appendChild(info);
      }

      this.kickedUsersList.appendChild(item);
    });
  }

  async unbanUser(userId, nickname) {
    if (!confirm(`${nickname}${this.i18n.unbanConfirm || '님의 차단을 해제하시겠습니까?'}`)) return;

    try {
      const response = await fetch(`/api/chat/api/open-rooms/${this.roomId}/unban_user/`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRFToken': this.getCSRFToken()
        },
        body: JSON.stringify({
          user_id: userId
        })
      });

      if (response.ok) {
        const data = await response.json();
        alert(data.message || `${nickname}${this.i18n.unbanned || '님의 차단이 해제되었습니다'}`);
        // Refresh the kicked users list
        this.openKickedUsersModal();
      } else {
        const error = await response.json();
        alert(error.error || error.message || (this.i18n.unbanFailed || '차단 해제에 실패했습니다'));
      }
    } catch (error) {
      console.error('Error unbanning user:', error);
      alert(this.i18n.errorOccurred || '오류가 발생했습니다');
    }
  }

  getCSRFToken() {
    const name = 'csrftoken';
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
}

// Initialize when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    window.openChatRoom = new OpenChatRoom();
  });
} else {
  window.openChatRoom = new OpenChatRoom();
}
