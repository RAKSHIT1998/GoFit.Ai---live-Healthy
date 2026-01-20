# Login Troubleshooting Guide

## Issue: Cannot login even though email is registered

### What I've Fixed

1. **Improved Error Handling**: The login function now better extracts and displays error messages from the backend
2. **Better Logging**: Added debug logging to help identify issues (only in DEBUG mode)
3. **Email Normalization**: Ensured email is properly trimmed and lowercased before sending

### Common Causes and Solutions

#### 1. **Wrong Password**
- **Symptom**: Error message: "Invalid credentials"
- **Solution**: 
  - Double-check your password
  - Try resetting your password using "Forgot Password?"
  - Make sure there are no extra spaces before/after the password

#### 2. **Apple-Only Account**
- **Symptom**: Error message: "This account was created with Apple Sign In. Please use Apple Sign In to log in."
- **Solution**: 
  - If you signed up with Apple Sign In, you must use Apple Sign In to log in
  - You cannot use email/password login for Apple-only accounts

#### 3. **Email Not Found**
- **Symptom**: Error message: "Invalid credentials"
- **Solution**: 
  - Verify the email is correct (check for typos)
  - Make sure the email is registered (try signing up again if needed)
  - Check if email has any extra spaces

#### 4. **Network/Server Issues**
- **Symptom**: Network error messages or timeout
- **Solution**: 
  - Check your internet connection
  - Try again in a few moments
  - Check if the backend server is running

#### 5. **Email Case Sensitivity**
- **Symptom**: Login fails even with correct credentials
- **Solution**: 
  - The app now automatically lowercases emails, so this should be fixed
  - But if you're still having issues, try using all lowercase in your email

### Debugging Steps

1. **Check Console Logs** (in Xcode):
   - Look for messages starting with `🔵` (info) or `❌` (error)
   - These will show:
     - The normalized email being sent
     - The response status code
     - The error message from the backend

2. **Verify Backend Logs**:
   - Check your backend server logs for:
     - `🔵 Login request received for:`
     - `❌ Login failed:` messages
     - These will tell you exactly what the backend sees

3. **Test with Known Good Credentials**:
   - Try creating a new test account
   - Try logging in with that test account
   - This will help isolate if it's a specific account issue

4. **Check Database**:
   - Verify the user exists in the database
   - Check if `passwordHash` exists (not null/empty)
   - Verify the email in the database matches exactly (should be lowercase)

### Backend Checks

If you have access to the backend, check:

1. **User exists in database**:
   ```javascript
   // In MongoDB
   db.users.findOne({ email: "your-email@example.com" })
   ```

2. **User has password**:
   ```javascript
   // Check if passwordHash exists
   db.users.findOne({ email: "your-email@example.com" }, { passwordHash: 1 })
   ```

3. **Email format**:
   ```javascript
   // Should be lowercase and trimmed
   db.users.findOne({ email: "your-email@example.com" })
   ```

### Testing the Fix

After the update, when you try to login:

1. **In Xcode Console** (DEBUG mode), you should see:
   ```
   🔵 Login request to: https://your-api.com/api/auth/login
   🔵 Email (normalized): your-email@example.com
   🔵 Login response status: 401 (or 200 if successful)
   🔵 Login response: {"message":"Invalid credentials"}
   ```

2. **In the App**, you should see:
   - A clear error message explaining what went wrong
   - Specific messages like:
     - "Invalid credentials" (wrong password or email not found)
     - "This account was created with Apple Sign In..." (Apple-only account)
     - Network error messages (connection issues)

### Next Steps

1. **Try logging in again** with the improved error handling
2. **Check the console logs** to see what error is being returned
3. **Share the error message** you see in the app or console
4. **If it's a password issue**, use "Forgot Password?" to reset it
5. **If it's an Apple-only account**, use Apple Sign In instead

### Still Having Issues?

If you're still unable to login after trying these steps:

1. **Check the exact error message** shown in the app
2. **Check Xcode console logs** for detailed error information
3. **Verify the backend is running** and accessible
4. **Check backend logs** for any errors during login
5. **Try creating a new test account** to see if the issue is account-specific

The improved error handling should now give you much clearer information about what's going wrong!
