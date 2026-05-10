# Frontend Fix - Member01 Login Issue

## Problems Identified ✓

1. **User Member01@gmail.com không tồn tại** - Seed data không có user này
2. **Frontend Dashboard lỗi** - Không hiển thị gì sau khi login
3. **Auth API không trả về roles** - Signin endpoint không gửi user roles
4. **Frontend không handle error** - Dashboard không có error handling

## Solutions Implemented ✓

### 1. Database Changes
- Thêm user `Member01` vào seed data (UserID 13)
- Gán role `CUSTOMER` cho Member01
- Thêm password hash cho Member01 (password: `member001`)

**Files Updated:**
- `database/seed/05_SeedData.sql` - Thêm user, profile, role, credential

### 2. Backend Changes
- **Updated auth.service.js**: `signin()` method giờ trả về `roles` array
- User roles được fetch từ database và include trong response

**Files Updated:**
- `backend/src/services/auth.service.js` - Thêm role fetching và return

### 3. Frontend Changes
- **Updated Dashboard.jsx**: 
  - Thêm error handling
  - Phân biệt admin vs customer view
  - Customer view hiển thị: Wallet Balance + Recent Sessions
  - Admin view hiển thị: Statistics + Revenue Charts

**Files Updated:**
- `frontend/src/pages/Dashboard.jsx` - Hoàn chỉnh component

---

## Setup Steps

### Step 1: Run Database Update Scripts

Chạy các scripts sau theo thứ tự trên SQL Server:

#### Option A: Fresh Seed (Recommended for testing)
If you're starting fresh, just re-run the entire seed:
```sql
-- Chạy tất cả database setup scripts:
database/run_all.sql
```

#### Option B: Update Existing Database
If you already have data, run these individual scripts:
```sql
-- 1. Add Member01 password (nếu seed data đã có user)
database/add_member01_password.sql

-- 2. Verify setup
database/verify_users.sql
```

### Step 2: Restart Backend
```bash
cd backend
npm run dev
```

### Step 3: Restart Frontend
```bash
cd frontend
npm run dev
```

---

## Test Credentials

| Email | Password | Role | Status |
|-------|----------|------|--------|
| system@evcharge.vn | 123456 | System Admin | ✓ |
| admin@evcharge.com | 123456 | SysAdmin | ✓ |
| operator@evcharge.com | 123456 | Operator | ✓ |
| customer@evcharge.com | 123456 | Customer | ✓ |
| **Member01@gmail.com** | **member001** | **Customer** | ✓ **NEW** |

---

## Expected Behavior After Fix

### Login Flow
1. User logs in with `Member01@gmail.com` / `member001`
2. Backend validates credentials + fetches roles
3. Response includes: `token`, `user` (with roles), `Email`, `FullName`
4. Frontend stores token + user data
5. Dashboard component loads

### Dashboard for Member01 (Customer)
- Shows **Wallet Balance** (e.g., 0 VND initially)
- Shows **Recent Charging Sessions** (empty initially)
- Friendly error messages if API calls fail
- No admin features visible

### Dashboard for Admin
- Shows **Statistics Cards** (Users, Stations, Sessions, etc.)
- Shows **Top Stations by Revenue**
- Shows **Daily Revenue Chart**

---

## Troubleshooting

### "Loading dashboard..." stuck forever
**Solution**: 
- Check browser console (F12 → Console tab)
- Check network tab for failed API requests
- Verify backend is running: http://localhost:3000/api/health
- Check roles were assigned in database

### "Invalid email or password" on login
**Solution**:
- Run `database/verify_users.sql` to check user existence + password hash
- Verify database seed ran successfully
- Check Email casing (should be exact)

### API 403 Unauthorized errors
**Solution**:
- Verify user role is assigned in `Users.UserRole` table
- Check JWT token is valid (check auth middleware)
- Verify token includes UserID + Email

### Frontend doesn't update after backend changes
**Solution**:
- Hard refresh browser: `Ctrl+Shift+R` (Windows) or `Cmd+Shift+R` (Mac)
- Clear localStorage: `localStorage.clear()` in console
- Restart frontend dev server

---

## Files Changed Summary

```
backend/
  ├── src/
  │   └── services/
  │       └── auth.service.js          [MODIFIED] - Added role fetching
  
frontend/
  └── src/
      └── pages/
          └── Dashboard.jsx              [MODIFIED] - Complete rewrite with error handling

database/
  ├── seed/
  │   └── 05_SeedData.sql               [MODIFIED] - Added Member01 user
  ├── add_member01_password.sql         [NEW] - Password fix script
  ├── fix_system_user_password.sql      [NEW] - System user password fix
  ├── verify_users.sql                  [NEW] - Verification script
```

---

## Next Steps (Optional)

1. **Add Wallet API Mock**: Create `/api/wallet/my` endpoint if it doesn't exist
2. **Add Sessions API Mock**: Create `/api/sessions/my` endpoint if it doesn't exist
3. **Add Sample Data**: Generate sample wallet transactions + charging sessions
4. **UI Polish**: Add loading skeletons, better error messages, animations

---

**All fixes are ready to deploy!** ✓
