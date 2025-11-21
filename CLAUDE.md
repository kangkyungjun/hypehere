# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**HypeHere** is a language learning social platform built with Django 5.1.11 and Django REST Framework. The platform combines social networking features (posts, comments, likes, follows) with real-time chat functionality (both regular and anonymous matching-based chat) using Django Channels for WebSocket support.

## Development Commands

### Setup and Environment
```bash
# Install dependencies
pip install -r requirements.txt

# Run migrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser
# Note: Requires email and nickname (USERNAME_FIELD is 'email', not 'username')
```

### Development Server
```bash
# Run development server (HTTP + WebSocket via Daphne)
python manage.py runserver

# Access admin panel
# http://127.0.0.1:8000/admin/
```

### Database Management
```bash
# Create new migrations after model changes
python manage.py makemigrations

# Show migration SQL without applying
python manage.py sqlmigrate <app_name> <migration_number>

# Check for migration issues
python manage.py check
```

### Django Shell
```bash
# Interactive shell for testing models and queries
python manage.py shell

# Shell plus (if django-extensions installed)
python manage.py shell_plus
```

## Core Architecture

### Apps Structure

The project follows Django's app-based architecture with 6 main apps:

1. **accounts**: Custom user authentication and social relationships
   - Custom User model with email-based authentication (not username)
   - Follow/Block relationship models
   - Auto-generated username from email for Django compatibility
   - Nickname as display name (duplicates allowed)
   - Account moderation: suspension, ban, deactivation, deletion with 30-day grace period
   - Privacy controls: show_followers_list, show_following_list (everyone/followers/nobody)
   - Report tracking: report_count for user behavior monitoring

2. **posts**: Social media content management
   - Posts with hashtags and language fields (native_language, target_language)
   - Comments and Likes with reverse relationships
   - Supports multiple languages for language learning context
   - Soft deletion with moderation: is_deleted_by_report preserves original_content
   - Post/Comment reporting system with status tracking

3. **chat**: Real-time messaging with WebSocket support
   - Regular 1:1 conversations (persistent messages)
   - Anonymous matching-based chat (ephemeral messages, WebRTC signaling)
   - Open group chat rooms with admin system, password protection, participant limits
   - WebSocket consumers for real-time communication
   - Auto-rejoin functionality: inactive users automatically re-added when receiving messages
   - left_at timestamp preserved for accurate unread count calculation

4. **notifications**: Polymorphic notification system
   - Uses Django ContentTypes for flexible content references
   - Supports MESSAGE, FOLLOW, POST, COMMENT, LIKE, REPORT notification types
   - Per-user notification settings with granular control
   - Real-time delivery via WebSocket (NotificationConsumer)

5. **learning**: Situation-based language learning
   - SituationCategory → SituationLesson → SituationExpression hierarchy
   - Vocabulary storage in JSON fields
   - Learning statistics and progress tracking

6. **specs**: Development notes and requirements tracking
   - Internal project management for specifications
   - Categories: feature, design, architecture, api, database, testing, deployment, documentation, bug, enhancement
   - Status tracking: draft, review, approved, implemented, deprecated

### Authentication System

**CRITICAL**: This project uses a custom User model with **email as the login identifier**, not username:

- `USERNAME_FIELD = 'email'` (login with email)
- `username` is auto-generated from email and kept for Django compatibility only
- `nickname` is the user-facing display name (duplicates allowed)
- When creating users programmatically, use `User.objects.create_user(email, nickname, password)`

### WebSocket Architecture

The project uses **Django Channels** for real-time features with **5 WebSocket consumers**:

1. **ChatConsumer** (`/ws/chat/<conversation_id>/`)
   - Regular 1:1 chat with persistent message storage
   - Automatic read receipts via `type: 'read'` messages
   - Auto-rejoin logic: when inactive user receives message, they're automatically re-added to conversation
   - `left_at` timestamp preserved for unread count calculation (messages after left_at are unread)
   - Group-based message broadcasting: `chat_{conversation_id}`

2. **AnonymousChatConsumer** (`/ws/anonymous-chat/<conversation_id>/`)
   - Ephemeral messages (not saved to database, `is_ephemeral=True`)
   - Automatic conversation cleanup when all participants leave
   - Real-time partner connection/disconnection notifications
   - WebRTC signaling support for P2P video chat (offer/answer/ice-candidate)
   - Connection request system for revealing identities
   - Group name: `anonymous_chat_{conversation_id}`

3. **OpenChatConsumer** (`/ws/open-chat/<room_id>/`)
   - Group chat rooms with multiple participants
   - Join/leave events broadcast to all participants
   - Admin system: room creator + granted admins can kick/ban users
   - Typing indicators
   - Password-protected rooms (optional)
   - Participant limits with max_participants
   - Group name: `open_chat_{room_id}`

4. **MatchingConsumer** (`/ws/matching/`)
   - Notifies users when anonymous chat matches are found
   - Queue position updates for matching system
   - User-specific groups: `matching_{user_id}`

5. **NotificationConsumer** (`/ws/notifications/`)
   - Real-time notification delivery to users
   - Automatic notification creation on various events
   - User-specific groups: `user_notifications_{user_id}`

**Channel Layer Configuration**:
- Development: In-memory channel layer (no Redis required)
- Production: Switch to Redis-based channel layer (commented in settings.py:162-170)

**ASGI Configuration** (`hypehere/asgi.py`):
```python
application = ProtocolTypeRouter({
    'http': django_asgi_app,
    'websocket': AuthMiddlewareStack(
        URLRouter(routing.websocket_urlpatterns)
    ),
})
```

### URL Structure

```
/                           - Home view
/explore/                   - Explore view
/learning/*                 - Learning views (statistics, materials, matching, chat)
/admin/                     - Django admin
/accounts/*                 - Account views (login, signup, profile, settings)
/api/accounts/*             - Account REST API endpoints
/api/posts/*                - Post/Comment/Like REST API endpoints
/messages/                  - Chat views + /api/chat/ for chat API
/notifications/             - Notifications views + /notifications/api/ for notification API
/learning/api/*             - Learning REST API endpoints
/i18n/                      - Language switching
/jsi18n/                    - JavaScript i18n catalog

# WebSocket URLs
/ws/chat/<id>/              - 1:1 chat WebSocket
/ws/anonymous-chat/<id>/    - Anonymous chat WebSocket
/ws/open-chat/<room_id>/    - Open chat room WebSocket
/ws/matching/               - Matching notifications WebSocket
/ws/notifications/          - Real-time notifications WebSocket
```

### Model Relationships

**User Relationships**:
- `User.following` → Follow objects where user is follower
- `User.followers` → Follow objects where user is being followed
- `User.blocking` → Block objects where user is blocker
- `User.blocked_by` → Block objects where user is blocked

**Chat Relationships**:
- `Conversation.participants` → ManyToMany through `ConversationParticipant`
- `ConversationParticipant` tracks `is_active`, `left_at`, `joined_at` per user
- `Message.conversation` → Messages belong to conversations
- `Conversation.is_anonymous` → Distinguishes regular vs anonymous chats
- `Conversation.is_ephemeral` → Messages not saved to DB when True
- `OpenChatRoom.participants` → ManyToMany through `OpenChatParticipant`
- `OpenChatParticipant` tracks `is_active`, `is_admin`, `joined_at` per user
- `OpenChatRoom` features: password protection, participant limits, admin system

**Notification Relationships**:
- Uses Django ContentTypes for polymorphic relationships
- `Notification.content_object` can reference Message, Post, Comment, Like, etc.
- `NotificationSettings.user` → OneToOne relationship for per-user preferences

### Moderation System

**Soft Deletion Pattern**:
- Posts/Comments preserve `original_content` when deleted
- `is_deleted_by_report` flag indicates moderation deletion
- User sees: "게시물은 신고에 의해 삭제되었습니다."
- Admins can view original content for review

**Report System** (3 types):
1. **PostReport** - Content moderation for posts
2. **CommentReport** - Comment moderation
3. **Report** (chat) - User behavior in chat

**Report Lifecycle**:
- Status: pending → reviewing → resolved/dismissed
- User `report_count` auto-incremented on resolution
- Active reports tracked in 30-day window
- Admin resolution includes notes

**User Moderation**:
- **Suspension**: Temporary ban with `suspended_until` timestamp, auto-lifted by middleware
- **Ban**: Permanent account ban (`is_banned=True`)
- **Deactivation**: User-initiated, reversible within 30 days (`is_deactivated=True`)
- **Deletion**: Permanent deletion after 30-day grace period (`deletion_requested_at`)

**Custom Middleware**:
- `SuspensionCheckMiddleware` - Auto-lifts expired suspensions on each request

### Internationalization (i18n)

**Supported Languages**:
```python
LANGUAGES = [
    ('ko', '한국어'),  # Default
    ('en', 'English'),
    ('ja', '日本語'),
    ('es', 'Español'),
]
```

**Features**:
- `LocaleMiddleware` for automatic language detection
- Translation files in `/locale/` directory
- JavaScript i18n: `/jsi18n/` endpoint
- Language switcher: `/i18n/` URL

### Static Files and Media

- Static files directory: `static/` (configured in STATICFILES_DIRS)
- Media uploads directory: `media/` (profile pictures, etc.)
- Templates directory: `templates/` at project root

## Important Implementation Notes

### User Model Queries
```python
# CORRECT: Use email for authentication
user = User.objects.get(email='user@example.com')
User.objects.create_user(email='user@example.com', nickname='Display Name', password='pass')

# INCORRECT: Don't rely on username for user identification
# username is auto-generated and not user-facing
```

### WebSocket Message Format
```python
# Regular chat message
{'type': 'message', 'content': 'Hello'}

# Mark messages as read
{'type': 'read'}

# Anonymous chat (same format, but messages not persisted)
{'type': 'message', 'content': 'Hello'}
```

### Channel Layer Groups
- Regular chat: `chat_{conversation_id}`
- Anonymous chat: `anonymous_chat_{conversation_id}`
- Open chat: `open_chat_{room_id}`
- User notifications: `user_notifications_{user_id}`
- Matching: `matching_{user_id}`

### Testing WebSocket Connections
When testing WebSocket consumers, remember:
1. User must be authenticated (`scope['user'].is_authenticated`)
2. User must be a participant in the conversation
3. For anonymous chats, conversation must have `is_anonymous=True`

### Database Considerations
- SQLite in development (db.sqlite3)
- All timestamp fields use `auto_now_add=True` or `auto_now=True`
- Indexes are optimized for common queries (see model Meta classes)
- `unique_together` constraints prevent duplicate follows/blocks/likes

### REST Framework Configuration
- TokenAuthentication and SessionAuthentication enabled
- Default permission: IsAuthenticatedOrReadOnly
- Page size: 10 items per page
- API endpoints follow `/api/<app_name>/` convention

## Common Patterns

### Creating Notifications
```python
# Use class methods for consistency
Notification.create_message_notification(recipient=user, sender=sender, conversation=conv)
Notification.create_follow_notification(recipient=user, sender=follower)
Notification.create_post_notification(recipient=follower, sender=author, post=post)
```

### Follow/Block Checks
```python
# User model provides convenience methods
user.is_following(other_user)
user.is_blocked_by(other_user)
user.is_blocking(other_user)
user.get_follower_count()
user.get_following_count()
```

### Conversation Helpers
```python
# Get the other participant in 1:1 chat
other_user = conversation.get_other_user(current_user)

# Get unread message count for a user (based on left_at timestamp)
unread_count = conversation.get_unread_count(user)

# Get last message
last_message = conversation.get_last_message()
```

### Report Count Management
```python
# On report resolution
user.increment_report_count()  # Increases report_count

# On report dismissal
user.decrement_report_count()  # Decreases report_count

# Check active reports (30-day window)
active_count = user.get_active_report_count()
```

### User Moderation Checks
```python
# Check if user is currently suspended
if user.is_currently_suspended():
    raise PermissionDenied('Account is suspended')

# Account status checks
if user.is_banned:
    # Permanent ban
if user.is_deactivated:
    # Temporarily deactivated by user
if user.deletion_requested_at:
    # Scheduled for deletion
```

### Open Chat Room Management
```python
# Check admin permissions
if room.is_user_admin(user):
    # User is admin (creator or granted admin)

# Kick user from room
room.kick_user(user, kicked_by_admin, duration_minutes=30)

# Ban user permanently
room.ban_user(user, banned_by_admin)

# Check if room is full
if room.is_full():
    raise ValidationError('Room is full')
```

## Technology Stack

- **Backend**: Django 5.1.11
- **API**: Django REST Framework 3.14.0+
- **WebSockets**: Django Channels with Daphne
- **Image Processing**: Pillow 10.0.0+
- **Database**: SQLite (development), ready for PostgreSQL (production)
- **Channel Layer**: In-memory (development), Redis (production)

## Key Files to Reference

- `hypehere/settings.py` - Django configuration, app registration, channel layers
- `hypehere/urls.py` - Main URL routing
- `hypehere/asgi.py` - ASGI configuration for WebSocket support
- `accounts/models.py` - Custom User model and authentication
- `chat/consumers.py` - WebSocket consumer implementations
- `chat/routing.py` - WebSocket URL routing
- `notifications/models.py` - Polymorphic notification system

## Migration Notes

When creating or modifying models:
1. The custom User model (`accounts.User`) is already in use - avoid changing `AUTH_USER_MODEL`
2. Always check for existing migrations before creating new ones
3. Test migrations with `--dry-run` flag when dealing with complex data migrations
4. Through models (`ConversationParticipant`, `OpenChatParticipant`) - handle ManyToMany changes carefully

## Architecture Patterns Summary

**Key Patterns Used**:
1. **Email-based authentication** - USERNAME_FIELD='email', not username-based
2. **Through models for state tracking** - ConversationParticipant, OpenChatParticipant track per-user state
3. **Polymorphic relationships** - Django ContentTypes for flexible Notification.content_object
4. **Soft deletion** - Preserve original_content with is_deleted_by_report flag
5. **WebSocket consumer architecture** - 5 specialized consumers for different real-time features
6. **Auto-rejoin logic** - Inactive users automatically re-added to conversations on message receipt
7. **Report aggregation** - Multiple report types feeding user.report_count for moderation
8. **Middleware-based suspension** - SuspensionCheckMiddleware auto-lifts expired suspensions
