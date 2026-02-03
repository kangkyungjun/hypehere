# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**HypeHere** is a language learning social platform with a dual-server architecture:

- **Django 5.1.11**: Main application server handling social features, real-time chat, and WebSocket connections
- **FastAPI** (planned): Read-only analytics API serving pre-computed analytics data

The Django platform combines social networking features (posts, comments, likes, follows) with real-time chat functionality (both regular and anonymous matching-based chat) using Django Channels for WebSocket support.

## Architecture Overview

### Dual-Server Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Nginx Reverse Proxy                    │
│  example.com/          → Django (Daphne ASGI)            │
│  example.com/api/v1/   → FastAPI (Uvicorn) [planned]     │
└─────────────────────────────────────────────────────────┘
           │                              │
           ▼                              ▼
    ┌──────────────┐            ┌──────────────────┐
    │   Django     │            │    FastAPI       │
    │   Port 8000  │            │    Port 8001     │
    │   (Daphne)   │            │    (Uvicorn)     │
    └──────────────┘            └──────────────────┘
           │                              │
           └──────────────┬───────────────┘
                          ▼
              ┌────────────────────────┐
              │  PostgreSQL RDS        │
              │  public.* → Django     │
              │  analytics.* → FastAPI │
              └────────────────────────┘
```

### Component Responsibilities

**Django Server** (Read-Write):
- User management, authentication, social features
- Real-time chat (WebSocket via Django Channels)
- Content management (posts, comments, likes)
- Learning modules and situation-based lessons
- Admin panel and moderation system

**FastAPI Server** (Read-Only, Planned):
- Analytics query API
- Pre-computed statistics serving
- Daily aggregated metrics from Mac mini
- No database writes (consumes analytics.* schema only)

**Data Flow**:
```
Mac mini (daily AI analysis)
    ↓
PostgreSQL analytics.* schema (write results)
    ↓
FastAPI (read-only queries)
    ↓
Mobile App (analytics consumption)
```

## Development Commands

### Django Development

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

### FastAPI Development (Planned)

```bash
# Setup
cd fastapi_analytics
pip install -r requirements.txt

# Run FastAPI server
uvicorn app.main:app --reload --port 8001

# Access interactive API docs
# http://localhost:8001/docs (Swagger UI)
# http://localhost:8001/redoc (ReDoc)
```

### Dual-Server Local Testing

```bash
# Terminal 1: Django server
python manage.py runserver

# Terminal 2: FastAPI server (once implemented)
cd fastapi_analytics && uvicorn app.main:app --reload --port 8001
```

Both servers can run simultaneously for local development.

## Database Architecture

### Schema Separation Strategy

**Production PostgreSQL RDS**:
- Single RDS instance with logical schema separation
- `public.*` → Django ORM (read-write access)
- `analytics.*` → FastAPI (read-only access)

**Development**:
- Django: SQLite (`db.sqlite3`)
- FastAPI: PostgreSQL analytics schema (via DATABASE_ANALYTICS_URL)

### Database Connection Patterns

```bash
# Django (.env)
DATABASE_URL=postgresql://user:pass@host:5432/hypehere

# FastAPI (.env in fastapi_analytics/)
DATABASE_ANALYTICS_URL=postgresql://analytics_user:pass@host:5432/hypehere?options=-c%20search_path=analytics
```

**Connection Strategy**:
- Django connects with full database access (default search_path=public)
- FastAPI connects with read-only access to analytics schema
- Mac mini uploader has write-only access to analytics.* tables

## Core Architecture

### Django Apps Structure

The project follows Django's app-based architecture with 7 main apps:

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

6. **analytics**: Visitor tracking and usage statistics
   - DailyVisitor, UserActivityLog models for tracking
   - AnonymousChatUsageStats for chat analytics
   - Admin dashboard at `/admin-dashboard/`
   - VisitorTrackingMiddleware for automatic page view tracking

7. **specs**: Development notes and requirements tracking
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

## Analytics Integration

### Current Django Analytics

**Django App**: `analytics`
- **Models**: DailyVisitor, UserActivityLog, AnonymousChatUsageStats, DailySummary
- **Middleware**: VisitorTrackingMiddleware automatically tracks page views
- **Dashboard**: Admin-only analytics at `/admin-dashboard/`
- **Purpose**: Track platform usage and user behavior

### Planned FastAPI Analytics API

**Directory Structure**:
```
fastapi_analytics/
├── app/
│   ├── main.py              # FastAPI application entry point
│   ├── routers/             # API route handlers
│   │   └── analytics.py
│   ├── models.py            # SQLAlchemy models for analytics schema
│   ├── schemas.py           # Pydantic request/response schemas
│   ├── database.py          # Database connection configuration
│   └── services/            # Business logic layer
├── venv/                    # FastAPI virtual environment
└── requirements.txt         # FastAPI dependencies
```

**Purpose**: Read-only API for pre-computed analytics data

**Data Source**: PostgreSQL analytics schema (analytics.*)

**Update Frequency**: Mac mini uploads daily analysis results

**Example API Endpoints** (planned):
```
GET /api/v1/analytics/daily-users?start=2025-01-01&end=2025-01-31
GET /api/v1/analytics/chat-usage?granularity=weekly
GET /api/v1/analytics/user-growth
GET /api/v1/analytics/trending-posts
```

### Mac Mini Integration Workflow

```
┌──────────────────────────────────────────────────┐
│ Mac mini (Daily Cron Job)                        │
│  1. Query Django database (public schema)        │
│  2. Run AI-based analytics computations          │
│  3. Generate aggregated statistics               │
│  4. Upload results to analytics.* schema         │
└──────────────────────────────────────────────────┘
                      ↓
┌──────────────────────────────────────────────────┐
│ PostgreSQL (analytics schema)                    │
│  - analytics.scores                              │
│  - analytics.tickers                             │
│  - analytics.likes                               │
│  - analytics.daily_metrics                       │
└──────────────────────────────────────────────────┘
                      ↓
┌──────────────────────────────────────────────────┐
│ FastAPI (Read-Only Queries)                      │
│  - Serves fresh analytics data                   │
│  - High-performance async queries                │
│  - No database writes                            │
└──────────────────────────────────────────────────┘
                      ↓
┌──────────────────────────────────────────────────┐
│ Mobile App                                       │
│  - Consumes analytics via /api/v1/ endpoints     │
└──────────────────────────────────────────────────┘
```

## Deployment Architecture

### Nginx Routing Configuration

```nginx
server {
    listen 80;
    server_name example.com;

    # Django (main application + WebSocket)
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # WebSocket upgrade for Django Channels
    location /ws/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # FastAPI analytics API (planned)
    location /api/v1/ {
        proxy_pass http://127.0.0.1:8001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # Static files
    location /static/ {
        alias /home/django/hypehere/staticfiles/;
    }

    # Media files
    location /media/ {
        alias /home/django/hypehere/media/;
    }
}
```

### Service Management

**Systemd Services**:

```bash
# Django service (Daphne ASGI server)
sudo systemctl status hypehere
sudo systemctl restart hypehere
sudo systemctl stop hypehere

# FastAPI service (Uvicorn, planned)
sudo systemctl status fastapi-analytics
sudo systemctl restart fastapi-analytics
sudo systemctl stop fastapi-analytics

# Nginx web server
sudo systemctl restart nginx
sudo systemctl status nginx
```

### Deployment Scripts

```bash
# Deploy Django changes (existing)
bash scripts/deploy.sh "commit message"

# Deploy FastAPI changes (planned)
bash scripts/deploy_fastapi.sh "commit message"

# Update server with git pull (existing)
bash scripts/update_server.sh
```

**Deployment Independence**:
- Django and FastAPI deploy independently
- FastAPI deployment does NOT restart Django
- Both services can scale independently
- Database schema separation prevents conflicts

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
- Development: SQLite (db.sqlite3) for Django, PostgreSQL for FastAPI analytics
- Production: PostgreSQL RDS with schema separation (public.* vs analytics.*)
- All timestamp fields use `auto_now_add=True` or `auto_now=True`
- Indexes are optimized for common queries (see model Meta classes)
- `unique_together` constraints prevent duplicate follows/blocks/likes

### Database Access Patterns

```python
# Django (ORM, read-write on public schema)
from posts.models import Post
Post.objects.create(content='Hello', author=user)

# FastAPI (SQLAlchemy, read-only on analytics schema, planned)
# Example: Query pre-computed analytics tables
# from app.models import DailyMetrics
# metrics = session.query(DailyMetrics).filter(date >= start_date).all()
```

### Schema Migration Strategy

```bash
# Django migrations (public schema only)
python manage.py makemigrations
python manage.py migrate

# Analytics schema (managed by Mac mini uploader)
# No Django migrations for analytics.*
# FastAPI only reads, never writes
# Schema created/updated by Mac mini upload scripts
```

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

### Django Server
- **Backend**: Django 5.1.11
- **API**: Django REST Framework 3.14.0+
- **WebSockets**: Django Channels with Daphne
- **Image Processing**: Pillow 10.0.0+
- **Database ORM**: Django ORM
- **Channel Layer**: In-memory (development), Redis/ElastiCache (production)

### FastAPI Server (Planned)
- **Framework**: FastAPI 0.109+
- **Server**: Uvicorn (ASGI)
- **ORM**: SQLAlchemy 2.0+ (read-only)
- **Database**: PostgreSQL (analytics schema)
- **Validation**: Pydantic v2
- **Async**: Native async/await support

### Infrastructure
- **Database**: PostgreSQL RDS (dual schema: public + analytics)
- **Cache**: ElastiCache Redis (Django Channels)
- **Storage**: S3 (static/media files in production)
- **Web Server**: Nginx (reverse proxy + path-based routing)
- **ASGI Servers**: Daphne (Django), Uvicorn (FastAPI)

## Key Files to Reference

### Django Files
- `hypehere/settings.py` - Django configuration, app registration, channel layers
- `hypehere/urls.py` - Main URL routing
- `hypehere/asgi.py` - ASGI configuration for WebSocket support
- `hypehere/views.py` - Main views including admin dashboard
- `accounts/models.py` - Custom User model and authentication
- `chat/consumers.py` - WebSocket consumer implementations (5 consumers)
- `chat/routing.py` - WebSocket URL routing
- `notifications/models.py` - Polymorphic notification system
- `analytics/models.py` - Django analytics models (DailyVisitor, etc.)
- `analytics/middleware.py` - VisitorTrackingMiddleware

### FastAPI Files (Planned)
- `fastapi_analytics/app/main.py` - FastAPI application entry point
- `fastapi_analytics/app/routers/analytics.py` - API route handlers
- `fastapi_analytics/app/models.py` - SQLAlchemy models for analytics schema
- `fastapi_analytics/app/schemas.py` - Pydantic request/response models
- `fastapi_analytics/app/database.py` - Database connection configuration
- `fastapi_analytics/requirements.txt` - FastAPI dependencies

### Deployment Files
- `scripts/deploy.sh` - Django deployment automation
- `scripts/update_server.sh` - Server update script (git pull)
- `scripts/deploy_fastapi.sh` - FastAPI deployment (planned)
- `/etc/nginx/sites-available/hypehere` - Nginx configuration
- `/etc/systemd/system/hypehere.service` - Django systemd service (Daphne)
- `/etc/systemd/system/fastapi-analytics.service` - FastAPI systemd service (planned)

## Migration Notes

When creating or modifying models:
1. The custom User model (`accounts.User`) is already in use - avoid changing `AUTH_USER_MODEL`
2. Always check for existing migrations before creating new ones
3. Test migrations with `--dry-run` flag when dealing with complex data migrations
4. Through models (`ConversationParticipant`, `OpenChatParticipant`) - handle ManyToMany changes carefully

## Architecture Patterns Summary

**Key Patterns Used**:

### Django Patterns
1. **Email-based authentication** - USERNAME_FIELD='email', not username-based
2. **Through models for state tracking** - ConversationParticipant, OpenChatParticipant track per-user state
3. **Polymorphic relationships** - Django ContentTypes for flexible Notification.content_object
4. **Soft deletion** - Preserve original_content with is_deleted_by_report flag
5. **WebSocket consumer architecture** - 5 specialized consumers for different real-time features
6. **Auto-rejoin logic** - Inactive users automatically re-added to conversations on message receipt
7. **Report aggregation** - Multiple report types feeding user.report_count for moderation
8. **Middleware-based suspension** - SuspensionCheckMiddleware auto-lifts expired suspensions

### Dual-Server Architecture Patterns
1. **Path-based routing** - Nginx routes by URL path prefix (/ → Django, /api/v1/ → FastAPI)
2. **Schema separation** - Single database with logical schema isolation (public vs analytics)
3. **Read-write isolation** - Django writes, FastAPI only reads analytics data
4. **Independent deployment** - Each server deploys and scales independently
5. **Async optimization** - FastAPI uses async/await for high-throughput read queries
6. **External data pipeline** - Mac mini computes and uploads analytics daily
7. **Service independence** - No shared code or direct communication between Django and FastAPI

### Database Schema Organization
```
PostgreSQL RDS (hypehere database)
├── public schema (Django read-write)
│   ├── accounts_user
│   ├── posts_post
│   ├── chat_conversation
│   ├── analytics_dailyvisitor
│   └── ... (all Django models)
│
└── analytics schema (FastAPI read-only)
    ├── scores
    ├── tickers
    ├── likes
    └── daily_metrics
```
