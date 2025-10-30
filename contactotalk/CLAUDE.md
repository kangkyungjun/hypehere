# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**ConTacToTalk** is a real-time social platform with 1:1 random matching, open chat rooms, and social features. Built with Django backend and Next.js frontend, deployed on AWS EC2.

**Tech Stack**:
- Backend: Django 5.1.11 + Django Channels 4.0 (WebSocket) + DRF 3.14
- Frontend: Next.js 15.0.3 + React 18 + TypeScript + Tailwind CSS + Zustand
- Database: SQLite (dev), PostgreSQL planned (production)
- Real-time: Django Channels with InMemory layer (dev), Redis planned (prod)
- Deployment: AWS EC2 (Gunicorn + Daphne + Nginx)

**Current Status**: Phase 1 (Authentication) and Phase 2 (Chat & Matching) complete. Open chat rooms implemented. Phase 4+ (SNS, Moderation, Premium) pending.

## Development Commands

### Backend Development

```bash
# Start Django development server (handles both HTTP and WebSocket)
python manage.py runserver

# Run Django system checks
python manage.py check

# Create and apply database migrations
python manage.py makemigrations
python manage.py migrate

# View migration status
python manage.py showmigrations

# Create superuser
python manage.py createsuperuser

# Access Django shell
python manage.py shell

# Collect static files (production)
python manage.py collectstatic --noinput
```

### Frontend Development

```bash
# Navigate to frontend directory first
cd /Users/kyungjunkang/PycharmProjects/contactotalk-frontend

# Start development server
npm run dev

# Build for production
npm run build

# Start production server
npm start

# Run linter
npm run lint

# ⚠️ IMPORTANT: Restart dev server after environment variable changes
./restart-dev.sh
```

### Database Scripts

```bash
# Initialize interest data (191 items across 16 categories)
python scripts/populate_interests.py

# Test matching algorithm (4 scenarios)
python scripts/test_matching.py

# Check interest data integrity
python scripts/check_interests.py

# Create default open chat rooms
python scripts/create_default_rooms.py
```

### Deployment

```bash
# One-command deployment to AWS
./deploy/deploy.sh "commit message"

# Example
./deploy/deploy.sh "Fix matching status API to return matched_room"
```

This script automatically:
1. Runs `python manage.py check`
2. Commits and pushes to git
3. Validates AWS environment variables
4. Deploys backend and restarts services (Gunicorn + Daphne)
5. Creates database backup

**Deployment URLs**:
- Frontend: http://43.200.129.55:3000
- Backend API: http://43.200.129.55:8000/api
- WebSocket: ws://43.200.129.55:8001/ws

## Architecture

### Backend Architecture

**6-Tier Permission System** (`accounts/models.py:User.Role`):
- `visitor`: Pre-registration default
- `user`: Standard member (1 match/day)
- `premiumuser`: Premium member (unlimited matches)
- `manager`: Moderation access
- `prime`: Prime admin
- `owner`: Full system access

**Apps Structure**:
- `accounts`: Authentication, user profiles, interests (191 items in 16 categories)
- `chat`: 1:1 matching, chat rooms, WebSocket consumers, matching algorithm
- `social`: SNS features (posts, comments, follows) - Phase 4 pending
- `moderation`: Reporting and admin tools - Phase 5 pending
- `premium`: Subscription and monetization - Phase 6 pending

**Matching Algorithm** (`chat/matcher.py`):
```python
# Score = location_weight + (interest_overlap * 2)
# location_weight: 50 (same country) or 30 (different country)
# interest_overlap: common_interests * 10
```

Priority: blocked users excluded → active chats excluded → country preference → score descending → FIFO

**WebSocket Architecture** (`contactotalk/asgi.py`):
- ASGI application handles both HTTP (Django) and WebSocket (Channels)
- JWT authentication via custom middleware (`chat/middleware.py:JWTAuthMiddlewareStack`)
- Two consumer types: `ChatConsumer` (1:1 chat) and `OpenChatConsumer` (group chat)
- Channel layers: InMemory (dev), Redis planned (prod)

**WebSocket Endpoints** (`chat/routing.py`):
- `/ws/chat/<room_id>/` - 1:1 chat rooms
- `/ws/open-chat/<room_id>/` - Open chat rooms

**WebSocket Message Types**:
- `connection_established`: Connection successful
- `message`: Chat message
- `typing`: Typing indicator
- `read`: Message read status
- `error`: Error messages

### Frontend Architecture

**State Management** (`src/store/`):
- Zustand for global state (auth, chat, notifications)

**API Client** (`src/lib/api/`):
- Axios-based client with JWT token handling
- Modules: `accounts.ts`, `chat.ts`, `interests.ts`, `moderation.ts`, `openChat.ts`

**WebSocket Client** (`src/lib/websocket/`):
- Reconnection logic with exponential backoff
- Automatic JWT token injection

**App Structure** (`src/app/`):
- Next.js 15 App Router with file-based routing
- Pages: `/login`, `/register`, `/profile`, `/chat`, `/open-chat`, `/social`

### Key Models

**User** (`accounts/models.py`):
- Custom user model extending AbstractUser
- Uses email as USERNAME_FIELD (not username)
- Tracks: role, country_code, bio, gender, premium_until, daily_match_count, last_match_date

**Interest** (`accounts/models.py`):
- 191 predefined interests across 16 categories (sports, music, movies, books, gaming, travel, food, art, education, tech, fashion, pets, volunteering, finance, hobbies, culture)

**ChatRoom** (`chat/models.py`):
- 1:1 chat rooms with matching_score, country_code
- Tracks: is_active, created_at, last_message_at

**OpenChatRoom** (`chat/models.py`):
- Public/private rooms with optional passwords
- Tracks: name, description, country_code, creator, participant_count, is_public

**MatchingQueue** (`chat/models.py`):
- FIFO queue with country_preference
- One user can only be in queue once (OneToOneField)

**Message** (`chat/models.py`):
- Messages with read status and timestamps
- Supports message_type (text/system) and blocked_for_user (soft delete)

## REST API Endpoints

### Authentication (`accounts/urls.py`)
- `POST /api/accounts/register/` - Register (requires 3+ interests)
- `POST /api/accounts/login/` - Login (returns nested token format: `{token: {access, refresh}}`)
- `POST /api/accounts/token/refresh/` - Refresh JWT token
- `GET /api/accounts/profile/` - Get profile
- `PUT /api/accounts/profile/` - Update profile
- `DELETE /api/accounts/profile/` - Delete account
- `POST /api/accounts/profile/password/` - Change password
- `GET /api/accounts/interests/` - List interests (filterable by category)
- `GET /api/accounts/match/check/` - Check daily match availability

### Chat & Matching (`chat/urls.py`)
- `POST /api/chat/matching/start/` - Start matching
- `POST /api/chat/matching/cancel/` - Cancel matching
- `GET /api/chat/matching/status/` - Get matching status
- `GET /api/chat/rooms/` - List my chat rooms
- `GET /api/chat/rooms/<id>/` - Get room details
- `POST /api/chat/rooms/<id>/leave/` - Leave room
- `GET /api/chat/rooms/<id>/messages/` - List messages (paginated)
- `POST /api/chat/rooms/<id>/messages/send/` - Send message
- `POST /api/chat/rooms/<id>/messages/read/` - Mark as read
- `POST /api/chat/block/` - Block user
- `POST /api/chat/unblock/<user_id>/` - Unblock user
- `GET /api/chat/blocked/` - List blocked users

### Open Chat (`chat/urls.py`)
- `GET /api/chat/open-chat/` - List all rooms
- `POST /api/chat/open-chat/` - Create room
- `GET /api/chat/open-chat/<id>/` - Get room details
- `PUT /api/chat/open-chat/<id>/` - Update room
- `DELETE /api/chat/open-chat/<id>/` - Delete room
- `POST /api/chat/open-chat/<id>/join/` - Join room
- `POST /api/chat/open-chat/<id>/leave/` - Leave room
- `GET /api/chat/open-chat/<id>/messages/` - List messages

## Critical Configuration

### Environment Variables

**Frontend** (Next.js requires restart after changes):
```bash
# Local: contactotalk-frontend/.env.local
NEXT_PUBLIC_API_URL=http://43.200.129.55:8000/api
NEXT_PUBLIC_WS_URL=ws://43.200.129.55:8001/ws

# Production: /home/ubuntu/contactotalk-frontend/.env.production
NEXT_PUBLIC_API_URL=http://43.200.129.55:8000/api
NEXT_PUBLIC_WS_URL=ws://43.200.129.55:8001/ws
```

⚠️ **CRITICAL**: After changing `.env.local`, you MUST restart the dev server:
```bash
cd /Users/kyungjunkang/PycharmProjects/contactotalk-frontend
./restart-dev.sh
```

Symptoms of stale environment variables:
- 401 errors on login/API calls
- Empty interest lists
- WebSocket connection failures

**Backend** (`contactotalk/settings.py`):
- SECRET_KEY: Django secret (change in production)
- DEBUG: Currently True (must be False in production)
- ALLOWED_HOSTS: ['43.200.129.55', 'localhost', '127.0.0.1', '*']
- CORS_ALLOWED_ORIGINS: Frontend URLs for CORS

### Django Settings Structure

**Main Settings** (`contactotalk/settings.py`):
- ASGI_APPLICATION: "contactotalk.asgi.application"
- AUTH_USER_MODEL: "accounts.User"
- Channel layers: InMemory (dev), Redis (prod)
- JWT: 1-hour access token, 7-day refresh token, rotation enabled

**ASGI Configuration** (`contactotalk/asgi.py`):
- ProtocolTypeRouter with HTTP and WebSocket support
- JWTAuthMiddlewareStack for WebSocket authentication
- AllowedHostsOriginValidator for security

**URL Configuration** (`contactotalk/urls.py`):
- Admin: `/admin/`
- API: `/api/accounts/`, `/api/chat/`, `/api/social/`, `/api/moderation/`, `/api/premium/`
- Debug toolbar: `/__debug__/`

## Testing

### Running Tests

```bash
# Run all tests
python manage.py test

# Run tests for specific app
python manage.py test accounts
python manage.py test chat

# Run specific test file
python manage.py test chat.tests.TestMatchingAlgorithm

# Run with verbose output
python manage.py test --verbosity=2
```

### Custom Test Scripts

```bash
# Test matching algorithm with 4 scenarios
python scripts/test_matching.py
```

## Common Development Tasks

### Adding New Interests

Edit `scripts/populate_interests.py` and add to the INTERESTS_DATA dictionary. Then run:
```bash
python scripts/populate_interests.py
```

### Database Migrations

When modifying models:
```bash
python manage.py makemigrations
python manage.py migrate
```

For production deployment, migrations are applied automatically by `deploy.sh`.

### WebSocket Development

Test WebSocket connections using browser DevTools Console:
```javascript
const ws = new WebSocket('ws://localhost:8000/ws/chat/1/');

ws.onopen = () => {
  ws.send(JSON.stringify({
    type: 'message',
    content: 'Hello!'
  }));
};

ws.onmessage = (event) => {
  console.log('Received:', JSON.parse(event.data));
};
```

### Deployment Troubleshooting

Check service status on AWS:
```bash
ssh -i ~/Downloads/contactotalk-key.pem ubuntu@43.200.129.55
ps aux | grep gunicorn  # REST API server
ps aux | grep daphne    # WebSocket server
```

View logs:
```bash
tail -f logs/gunicorn.log
tail -f logs/daphne.log
```

Restart services manually:
```bash
pkill -f gunicorn
pkill -f daphne
nohup gunicorn --config deploy/gunicorn.conf.py contactotalk.wsgi:application > /dev/null 2>&1 &
nohup daphne -b 0.0.0.0 -p 8001 contactotalk.asgi:application > /dev/null 2>&1 &
```

### WebSocket Connection Troubleshooting

#### Environment Configuration

**Local Development**:
- Frontend connects directly: `ws://localhost:8000/ws`
- Daphne binds to: `127.0.0.1:8001` or `0.0.0.0:8001`
- No Nginx proxy needed

**AWS Production**:
- Frontend connects via Nginx: `ws://43.200.129.55/ws` or `wss://domain.com/ws`
- Nginx proxies to Daphne: `127.0.0.1:8001`
- **IMPORTANT**: Do NOT use `ws://43.200.129.55:8001/ws` (port 8001 not exposed to public)

#### Environment Variables

**Correct Frontend Configuration (.env.production)**:
```bash
# Use Nginx proxy path (port 80/443)
NEXT_PUBLIC_WS_URL=ws://43.200.129.55/ws
```

**Incorrect Configuration** ❌:
```bash
# Direct Daphne access won't work (port 8001 not exposed)
NEXT_PUBLIC_WS_URL=ws://43.200.129.55:8001/ws
```

#### Common Issues and Solutions

**1. Connection Refused**
- **Symptom**: WebSocket connection fails immediately
- **Check**: `ps aux | grep daphne` (verify Daphne is running)
- **Solution**: Restart Daphne service
  ```bash
  ssh ubuntu@43.200.129.55
  sudo systemctl restart daphne
  sudo systemctl status daphne
  ```

**2. 401 Unauthorized**
- **Symptom**: WebSocket connection rejected with 401 error
- **Cause**: Invalid or expired JWT token
- **Solution**: Check token in query parameter, refresh token if expired
  ```javascript
  // Correct token passing in frontend
  const wsUrl = `${WS_BASE_URL}/chat/${roomId}/?token=${validJwtToken}`;
  ```

**3. Origin Not Allowed**
- **Symptom**: WebSocket connection rejected during handshake
- **Cause**: Frontend URL not in Django `ALLOWED_HOSTS`
- **Solution**: Add frontend URL to `ALLOWED_HOSTS` in `settings/production.py`
  ```python
  # .env.production
  ALLOWED_HOSTS=43.200.129.55,localhost,127.0.0.1
  ```

**4. No Messages in Chat**
- **Symptom**: Connection established but messages don't appear
- **Check**: Browser DevTools Console for WebSocket connection logs
- **Verify**:
  ```javascript
  // Should see this in console
  console.log('WebSocket connected')
  ```
- **Debug**: Check Daphne logs
  ```bash
  sudo journalctl -u daphne -f
  ```

**5. Connection Drops Frequently**
- **Symptom**: WebSocket connection closes unexpectedly
- **Cause**: Nginx timeout settings too short
- **Solution**: Verify Nginx proxy timeout (deploy/nginx.conf:108-110)
  ```nginx
  proxy_connect_timeout 7d;
  proxy_send_timeout 7d;
  proxy_read_timeout 7d;
  ```

#### Verification Checklist

- [ ] Daphne service running: `sudo systemctl status daphne`
- [ ] Nginx `/ws/` proxy configured correctly
- [ ] Frontend uses Nginx proxy URL (not direct port 8001)
- [ ] JWT token valid and included in WebSocket URL
- [ ] Frontend origin in Django `ALLOWED_HOSTS`
- [ ] CORS settings include frontend URL
- [ ] Browser DevTools shows "WebSocket connected" message

#### Debug Commands

```bash
# Check Daphne process and binding
ps aux | grep daphne
# Should show: daphne -b 0.0.0.0 -p 8001

# Test WebSocket endpoint (from server)
curl -i -N -H "Connection: Upgrade" -H "Upgrade: websocket" http://localhost:8001/ws/chat/1/

# Monitor Daphne logs
sudo journalctl -u daphne -f

# Check Nginx access logs for WebSocket requests
tail -f /var/log/nginx/access.log | grep "/ws/"
```

## Project Phases

- ✅ **Phase 1**: Authentication and permissions (100%)
- ✅ **Phase 2**: Chat and matching (100%)
- ✅ **Phase 3**: Open chat rooms (100%)
- ⏳ **Phase 4**: SNS features (0%)
- ⏳ **Phase 5**: Moderation tools (0%)
- ⏳ **Phase 6**: Premium and monetization (0%)

**Overall Progress**: 50% (3/6 phases complete)

## Code Style and Patterns

### Django Patterns

- Use Django ORM with select_related/prefetch_related for query optimization
- Follow REST API naming: plural nouns for collections (e.g., `/rooms/`, not `/room/`)
- Custom permissions inherit from BasePermission (`accounts/permissions.py`)
- Signals in `apps.py` ready() method for app initialization (`chat/apps.py`)

### Frontend Patterns

- TypeScript strict mode enabled
- API responses typed in `src/types/index.ts`
- Error handling with try-catch and user-friendly messages
- Loading states for async operations
- Zustand stores follow single responsibility pattern

### WebSocket Patterns

- JWT token in query string for authentication (`?token=<jwt>`)
- Message types validated in consumers
- Graceful disconnect handling
- Reconnection with exponential backoff

## Known Issues and Limitations

1. **SQLite in production**: Not suitable for concurrent writes, plan migration to PostgreSQL
2. **InMemory channel layer**: Doesn't scale across multiple servers, plan migration to Redis
3. **No rate limiting**: Vulnerable to abuse, needs implementation
4. **DEBUG=True**: Must be set to False in production
5. **SECRET_KEY exposed**: Hardcoded in settings.py, must use environment variables

## Security Considerations

- JWT tokens in WebSocket URLs (visible in logs) - consider WebSocket subprotocol
- CORS configured for specific origins only
- User blocking prevents matching but not API access
- No input sanitization for XSS - DRF serializers provide basic protection
- No SQL injection protection beyond Django ORM

## Database Schema Notes

- User email is unique and used for login (not username)
- ChatRoom.matching_score stores compatibility score
- Message.blocked_for_user enables soft delete without affecting other user
- OpenChatRoom.participant_count denormalized for performance
- MatchingQueue uses OneToOneField to prevent duplicate entries
