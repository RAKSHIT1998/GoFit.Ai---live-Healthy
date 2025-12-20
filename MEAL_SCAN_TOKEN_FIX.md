# Meal Scanning Token Error Fix

## Issue
Users were getting "invalid token" error when trying to scan meals.

## Root Cause
The photo upload endpoint requires authentication, but the app wasn't properly:
1. Checking if a token exists before attempting upload
2. Handling token expiration gracefully
3. Providing clear error messages

## Solution

### 1. Enhanced Token Validation (`MealScannerView3.swift`)
- Added check to ensure user is logged in before upload
- Added explicit token validation before upload attempt
- Improved error messages to guide users

### 2. Network Manager Update (`NetworkManager+Auth.swift`)
- Changed token check from optional to required
- Throws clear error if token is missing
- Ensures Authorization header is always present when token exists

### 3. Error Handling
- Detects 401 (Unauthorized) errors
- Automatically logs out user if token is invalid/expired
- Provides user-friendly error messages

## Code Changes

### Before:
```swift
func uploadImage(_ image: UIImage) async {
    // No token validation
    let resp = try await NetworkManager.shared.uploadMealImage(...)
}
```

### After:
```swift
func uploadImage(_ image: UIImage) async {
    // Validate login status
    guard authVM.isLoggedIn else {
        errorMsg = "Please log in to scan meals"
        return
    }
    
    // Validate token exists
    guard let token = AuthService.shared.readToken()?.accessToken, !token.isEmpty else {
        errorMsg = "Authentication required. Please log in again."
        return
    }
    
    // Upload with proper error handling
    // ...
}
```

## Testing

### Test Cases:
1. ✅ Upload with valid token - should work
2. ✅ Upload without token - should show clear error
3. ✅ Upload with expired token - should prompt re-login
4. ✅ Upload when not logged in - should show login prompt

## User Experience

### Error Messages:
- **Not logged in**: "Please log in to scan meals"
- **No token**: "Authentication required. Please log in again."
- **Expired token**: "Session expired. Please log in again."
- **Invalid token**: "Authentication failed. Please log in again."

### Auto-Logout:
If token is invalid or expired, the app will automatically log out the user to prevent further errors.

## Prevention

To prevent this issue in the future:
1. Always check `authVM.isLoggedIn` before making authenticated requests
2. Validate token exists before API calls
3. Handle 401 errors by logging out and prompting re-login
4. Provide clear, actionable error messages

## Related Files
- `GoFit.Ai - live Healthy/Features/MealScanner/MealScannerView3.swift`
- `GoFit.Ai - live Healthy/Services/NetworkManager+Auth.swift`
- `backend/middleware/authMiddleware.js`

