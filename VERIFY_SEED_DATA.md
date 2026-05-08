# Seed Data Verification Guide

## Problem: No Demo Users Found After Seed Script

If you ran `database/run_all.sql` but cannot query the demo accounts (`admin`, `operator`, `customer`), this guide will help you troubleshoot.

---

## Step 1: Identify the Issue

Run this query in SSMS to check current status:

```sql
USE EV_Charging_System;
GO

-- Check if demo users exist
SELECT COUNT(*) AS DemoUserCount
FROM [Users].[User]
WHERE Username IN ('admin', 'operator', 'customer');

-- Check total users
SELECT COUNT(*) AS TotalUsers FROM [Users].[User];

-- List all users
SELECT UserID, Username, Email, AccountStatus
FROM [Users].[User]
ORDER BY UserID;
```

### Possible Results:

**A) DemoUserCount = 0, TotalUsers = 0**
- **Cause:** Seed script didn't run successfully
- **Fix:** See "Solution: Re-run Seed Script" below

**B) DemoUserCount = 0, TotalUsers = 9+**
- **Cause:** Database schema is from an older version without demo users
- **Fix:** See "Solution: Manual Insert" below

**C) DemoUserCount = 3, TotalUsers ≥ 12**
- **Status:** ✓ Users are created
- **Next:** Check if credentials are inserted (Step 2)

---

## Step 2: Check If Credentials Are Inserted

Run this query:

```sql
-- Check if demo user credentials exist
SELECT u.UserID, u.Username, uc.PasswordHash, uc.HashAlgorithm
FROM [Users].[User] u
LEFT JOIN Users.UserCredential uc ON u.UserID = uc.UserID
WHERE u.Username IN ('admin', 'operator', 'customer')
ORDER BY u.UserID;
```

### Possible Results:

**A) PasswordHash is NULL**
- **Cause:** Credentials not inserted
- **Fix:** Execute `insert_credentials.sql` (see Step 4)

**B) PasswordHash has values**
- **Status:** ✓ Credentials are set
- **Next:** Verify role assignments (Step 3)

---

## Step 3: Check Role Assignments

Run this query:

```sql
-- Check demo user roles
SELECT u.Username, r.RoleCode, r.RoleName
FROM [Users].[User] u
JOIN Users.UserRole ur ON u.UserID = ur.UserID
JOIN [Access].[Role] r ON ur.RoleID = r.RoleID
WHERE u.Username IN ('admin', 'operator', 'customer')
ORDER BY u.Username;
```

### Expected Result:

| Username | RoleCode | RoleName |
|----------|----------|----------|
| admin | SysAdmin | System Administrator |
| customer | CUSTOMER | Customer |
| operator | Operator | Operator |

If you see different results, see "Solution: Reassign Roles" below.

---

## Solutions

### Solution A: Users Don't Exist (DemoUserCount = 0)

#### Option 1: Re-run Updated Seed Script

1. Backup current database (optional)
2. Update `database/seed/05_SeedData.sql` to include demo users:
   ```sql
   INSERT INTO Users.[User] (Username, Email, Phone, AccountStatus)
   VALUES
       (N'admin',    N'admin@evcharge.com',     N'0900000001', N'Active'),
       (N'operator', N'operator@evcharge.com',  N'0900000002', N'Active'),
       (N'customer', N'customer@evcharge.com',  N'0900000003', N'Active'),
       -- ... other users
   ```
3. Drop and recreate database, then re-run `run_all.sql`

#### Option 2: Manually Insert Demo Users

Run this script in SSMS:

```sql
USE EV_Charging_System;
GO

-- Insert demo users
INSERT INTO [Users].[User] (Username, Email, Phone, AccountStatus)
VALUES
    (N'admin',    N'admin@evcharge.com',     N'0900000001', N'Active'),
    (N'operator', N'operator@evcharge.com',  N'0900000002', N'Active'),
    (N'customer', N'customer@evcharge.com',  N'0900000003', N'Active');
GO

-- Get the UserIDs
SELECT UserID, Username FROM [Users].[User] WHERE Username IN (N'admin', N'operator', N'customer');
GO
```

Remember the UserIDs, then proceed to "Solution B: Insert Credentials"

---

### Solution B: Credentials Not Inserted

1. **Method 1: Use Existing File (Recommended)**
   - Open SSMS
   - File → Open → Select `insert_credentials.sql`
   - Execute (F5)

2. **Method 2: Generate New Hashes**
   - Run: `node generate_demo_credentials.js` in the root folder
   - Copy the SQL output
   - Paste into SSMS and execute

3. **Manual SQL Insert** (if you know the UserIDs from Step 1):
   ```sql
   USE EV_Charging_System;
   GO
   
   -- Replace UserID values with actual IDs from Step 1
   INSERT INTO Users.UserCredential (UserID, PasswordHash, PasswordSalt, HashAlgorithm, MFAEnabled, CreatedAt)
   VALUES 
       (2, '$2a$12$v3lWXmrEbwjPCKyGDLQrleROYfBfYbdEWPzMW9EnnK0Z.SbKxXmjm', '', 'bcryptjs', 0, GETDATE()),
       (3, '$2a$12$9NeCpb7L99gzMgnGXffUhOkIn87CFO7MD7mSsgDSARcAjtlJqxckS', '', 'bcryptjs', 0, GETDATE()),
       (4, '$2a$12$FfU05PRrpwTm/hh96gCpDuip7pTBp8kU5yMM2gT/1mc8pLqQcg/jC', '', 'bcryptjs', 0, GETDATE());
   GO
   ```

---

### Solution C: Credentials Exist But Roles Are Missing

1. Get the correct RoleIDs:
   ```sql
   SELECT RoleID, RoleCode, RoleName FROM [Access].[Role];
   ```

2. Assign roles:
   ```sql
   USE EV_Charging_System;
   GO
   
   -- Get UserIDs
   DECLARE @AdminID INT = (SELECT UserID FROM [Users].[User] WHERE Username = N'admin');
   DECLARE @OperatorID INT = (SELECT UserID FROM [Users].[User] WHERE Username = N'operator');
   DECLARE @CustomerID INT = (SELECT UserID FROM [Users].[User] WHERE Username = N'customer');
   DECLARE @SysAdminRoleID INT = (SELECT RoleID FROM [Access].[Role] WHERE RoleCode = N'SysAdmin');
   DECLARE @OperatorRoleID INT = (SELECT RoleID FROM [Access].[Role] WHERE RoleCode = N'Operator');
   DECLARE @CustomerRoleID INT = (SELECT RoleID FROM [Access].[Role] WHERE RoleCode = N'CUSTOMER');
   
   -- Insert role assignments
   INSERT INTO Users.UserRole (UserID, RoleID) VALUES (@AdminID, @SysAdminRoleID);
   INSERT INTO Users.UserRole (UserID, RoleID) VALUES (@OperatorID, @OperatorRoleID);
   INSERT INTO Users.UserRole (UserID, RoleID) VALUES (@CustomerID, @CustomerRoleID);
   GO
   ```

---

## Complete Verification Checklist

After applying any solution, run this script to verify everything:

```sql
USE EV_Charging_System;
GO

-- 1. Check users exist
SELECT COUNT(*) AS 'Demo Users Count' 
FROM [Users].[User]
WHERE Username IN (N'admin', N'operator', N'customer');

-- 2. Check credentials exist
SELECT COUNT(*) AS 'Demo Credentials Count'
FROM Users.UserCredential uc
JOIN [Users].[User] u ON uc.UserID = u.UserID
WHERE u.Username IN (N'admin', N'operator', N'customer');

-- 3. Check roles assigned
SELECT COUNT(*) AS 'Demo Roles Count'
FROM Users.UserRole ur
JOIN [Users].[User] u ON ur.UserID = u.UserID
WHERE u.Username IN (N'admin', N'operator', N'customer');

-- 4. Detailed view
SELECT 
    u.UserID,
    u.Username,
    u.Email,
    u.AccountStatus,
    CASE WHEN uc.PasswordHash IS NOT NULL THEN 'Yes' ELSE 'No' END AS 'Password Set',
    r.RoleCode,
    r.RoleName
FROM [Users].[User] u
LEFT JOIN Users.UserCredential uc ON u.UserID = uc.UserID
LEFT JOIN Users.UserRole ur ON u.UserID = ur.UserID
LEFT JOIN [Access].[Role] r ON ur.RoleID = r.RoleID
WHERE u.Username IN (N'admin', N'operator', N'customer')
ORDER BY u.UserID;
GO
```

**Expected Output:**
- Demo Users Count: 3
- Demo Credentials Count: 3
- Demo Roles Count: 3
- Detailed view shows all three users with their roles and password status

---

## Backend Login Test

Once everything is verified, test the backend API:

```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "Email": "admin@evcharge.com",
    "Password": "123456"
  }'
```

Expected response:
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIs...",
    "refreshToken": "...",
    "user": {
      "UserID": 2,
      "Username": "admin",
      "Email": "admin@evcharge.com",
      "roles": ["SysAdmin"]
    }
  }
}
```

---

## Quick Reference

| Issue | Check | Fix |
|-------|-------|-----|
| Login fails | User exists? | Insert user |
| Login fails | Credentials set? | Execute `insert_credentials.sql` |
| Login succeeds but no role | Role assigned? | Run role assignment query |
| Wrong role shown | Role value | Check RoleCode matches (SysAdmin vs admin) |
| Password wrong | Hash correct? | Regenerate with `generate_demo_credentials.js` |

---

## Additional Help

- Check database logs: `SELECT * FROM [Audit].[AuditLog] ORDER BY CreatedAt DESC;`
- Verify seed script ran: `SELECT COUNT(*) FROM [Infrastructure].[Country];` (should be > 0)
- Check for FK violations: Run database integrity check in SSMS

