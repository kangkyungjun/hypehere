# MarketLens Role System Testing Guide

## 📋 Overview
This guide provides step-by-step instructions for deploying and testing the 5-tier role-based permission system for MarketLens.

## 🏗️ System Architecture

### Role Hierarchy
```
Master (오너)
  ├── 모든 권한 보유
  ├── Manager 임명 가능
  ├── Gold 승급 가능
  └── 모든 게시글 삭제 가능

Manager (직원)
  ├── Gold 승급 가능
  ├── 모든 게시글 삭제 가능
  └── 사용자 관리 패널 접근

Gold User (유료 회원)
  ├── 광고 제거 (향후 구현)
  └── 프리미엄 기능 (향후 확장)

Regular User (일반 회원)
  └── 게시판 접근 및 댓글 작성

Guest (비회원)
  ├── 게시글 읽기 가능
  └── 댓글 읽기 불가 (회원가입 유도 UI)
```

## 🚀 Deployment Steps

### Step 1: Update AWS Server

SSH into your AWS server and pull the latest code:

```bash
ssh django@43.201.45.60
cd /home/django/hypehere
git pull origin master
```

### Step 2: Restart Django Service

```bash
sudo systemctl restart hypehere
sudo systemctl status hypehere
```

Check that the service is running without errors.

### Step 3: Create Master Account

Run the management command to create your Master account:

```bash
cd /home/django/hypehere
source venv/bin/activate
python manage.py create_master "your-email@example.com" "Your Display Name" "your-secure-password"
```

**Example:**
```bash
python manage.py create_master "admin@marketlens.com" "MarketLens Admin" "SecurePass123!@#"
```

Expected output:
```
✅ Successfully created Master account

============================================================
MASTER ACCOUNT DETAILS
============================================================
  Email:    admin@marketlens.com
  Nickname: MarketLens Admin
  Role:     master
  ID:       1

------------------------------------------------------------
MASTER PERMISSIONS
------------------------------------------------------------
  ✓ isMaster:             True
  ✓ isManagerOrAbove:     True
  ✓ isGoldOrAbove:        True
  ✓ hasAdFreeAccess:      True
  ✓ canDeleteAnyPost:     True
  ✓ canPromoteToGold:     True
  ✓ canPromoteToManager:  True
  ✓ canManageUsers:       True
============================================================
```

## ✅ Testing Checklist

### 1. Master Account Creation
- [ ] Master account created successfully
- [ ] All 8 permission flags return `True`
- [ ] Can login via Flutter app

### 2. Settings Screen Testing
- [ ] Master role badge displays correctly (빨강색 "Master")
- [ ] "관리자 패널" menu item visible in Settings
- [ ] Tapping admin panel navigates to AdminPanelScreen

### 3. Admin Panel UI Testing
- [ ] Admin panel loads without errors
- [ ] User search by email works
- [ ] User search by nickname works
- [ ] Search results display with correct role badges

### 4. Gold Promotion Testing (Manager+ Permission)
- [ ] Create test Regular user via signup
- [ ] Search for test user in admin panel
- [ ] "Gold 승급" button visible for Regular users
- [ ] Tap Gold promotion button
- [ ] Confirmation dialog appears
- [ ] Confirm promotion
- [ ] Success message displays
- [ ] Search results refresh showing new Gold badge
- [ ] Test user's Settings shows Gold badge

### 5. Manager Appointment Testing (Master Only)
- [ ] Create test Regular/Gold user
- [ ] "Manager 임명" button visible only to Master
- [ ] Tap Manager appointment button
- [ ] Confirmation dialog with warning message
- [ ] Confirm appointment
- [ ] Success message displays
- [ ] Test user's Settings shows Manager badge (주황색)
- [ ] Test Manager user can access admin panel
- [ ] Test Manager user CANNOT see "Manager 임명" button
- [ ] Test Manager user CAN see "Gold 승급" button

### 6. Guest Comment Blocking
- [ ] Logout from app (become Guest)
- [ ] Navigate to any post detail
- [ ] Post content is visible
- [ ] Comment section shows signup prompt card
- [ ] "댓글을 보려면 로그인이 필요해요" message visible
- [ ] Tap "로그인" button → navigates to LoginScreen
- [ ] Tap "회원가입" button → navigates to SignupScreen

### 7. Permission API Testing

Test via `curl` or Postman:

```bash
# Get auth token first
TOKEN="your-jwt-token-here"

# Test user search (Manager+ only)
curl -H "Authorization: Bearer $TOKEN" \
  "http://43.201.45.60:8000/api/accounts/users/search/?q=test"

# Test Gold promotion (Manager+ only)
curl -X PATCH \
  -H "Authorization: Bearer $TOKEN" \
  "http://43.201.45.60:8000/api/accounts/users/2/promote-to-gold/"

# Test Manager appointment (Master only)
curl -X PATCH \
  -H "Authorization: Bearer $TOKEN" \
  "http://43.201.45.60:8000/api/accounts/users/3/promote-to-manager/"
```

### 8. Permission Restriction Testing
- [ ] Regular user cannot access `/api/accounts/users/search/` (403)
- [ ] Regular user cannot promote to Gold (403)
- [ ] Manager can promote to Gold (200)
- [ ] Manager CANNOT promote to Manager (403)
- [ ] Master can promote to Manager (200)

## 🐛 Troubleshooting

### Issue: create_master command not found
**Solution:** Make sure you pulled the latest code and the file exists at:
```bash
ls -la accounts/management/commands/create_master.py
```

### Issue: Migration not applied
**Solution:** Run migrations on the server:
```bash
python manage.py migrate accounts
```

### Issue: Admin panel not showing
**Solution:** Check user role in Django shell:
```python
from accounts.models import User
user = User.objects.get(email='your-email@example.com')
print(f"Role: {user.role}")
print(f"isManagerOrAbove: {user.is_manager_or_above()}")
```

### Issue: Permission denied when searching users
**Solution:** Verify authentication token is valid and user has Manager+ role

## 📊 Expected Results

After successful testing, you should have:

1. ✅ Master account with full permissions
2. ✅ Manager account with limited permissions (can promote Gold, cannot promote Manager)
3. ✅ Gold account with premium features
4. ✅ Regular account with basic access
5. ✅ Guest experience with signup prompts

## 🔄 Next Steps

After completing this testing:

1. **Gold Features**: Implement ad removal logic for Gold users
2. **Master/Manager Ad Toggle**: UI toggle to show/hide ads for testing
3. **Additional Gold Benefits**: Discuss and implement premium features
4. **User Reporting System**: Link report counts to permission changes
5. **Admin Dashboard**: Add user management analytics

## 📝 Notes

- **CRITICAL**: Always use AWS server URL `http://43.201.45.60:8000` in Flutter app
- Master account credentials should be kept secure
- Test all permission boundaries thoroughly
- Document any bugs or unexpected behavior
- Consider rate limiting for promotion APIs in production

---

**Testing Status**: Ready for deployment and testing
**Last Updated**: 2025-02-11
**Author**: Claude Code Assistant
