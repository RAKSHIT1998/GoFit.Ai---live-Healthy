# Backend Subscription Tracking Implementation

## Overview
Enhanced backend subscription tracking system that keeps track of premium active users, cancelled subscriptions, and calculates days remaining accurately.

## Backend Enhancements

### 1. Enhanced `/subscriptions/status` Endpoint

**Location:** `backend/routes/subscriptions.js`

**New Features:**
- **Detailed Status Information:**
  - `isPremiumActive`: True if user has active paid subscription (not trial)
  - `isInTrial`: True if user is in trial period
  - `isCancelled`: True if subscription is cancelled (user still has access until endDate)
  - `isExpired`: True if subscription has expired
  - `hasActiveSubscription`: True if user has any active subscription (trial or premium)

- **Days Calculations:**
  - `trialDaysRemaining`: Days left in trial period
  - `subscriptionDaysRemaining`: Days left in paid subscription
  - `daysRemaining`: Appropriate days remaining based on current status

- **Automatic Status Updates:**
  - Automatically checks if trial has expired and updates status
  - Automatically checks if subscription has expired and updates status
  - Transitions from trial to active when trial ends but subscription is still active

**Response Format:**
```json
{
  "hasActiveSubscription": true,
  "isPremiumActive": true,
  "isInTrial": false,
  "isCancelled": false,
  "isExpired": false,
  "subscription": {
    "status": "active",
    "plan": "monthly",
    "startDate": "2026-01-01T00:00:00.000Z",
    "endDate": "2026-02-01T00:00:00.000Z",
    "trialEndDate": null,
    "appleTransactionId": "1234567890",
    "appleOriginalTransactionId": "0987654321"
  },
  "trialDaysRemaining": 0,
  "subscriptionDaysRemaining": 15,
  "daysRemaining": 15,
  "statusDetails": {
    "isPremium": true,
    "isTrial": false,
    "isCancelled": false,
    "isExpired": false,
    "canAccessPremium": true
  }
}
```

### 2. Enhanced `/subscriptions/verify` Endpoint

**New Features:**
- **Better Status Determination:**
  - Properly distinguishes between trial and active premium subscriptions
  - Handles revoked transactions (cancelled subscriptions)
  - Calculates trial end dates accurately

- **Days Calculations:**
  - Returns `trialDaysRemaining` and `subscriptionDaysRemaining`
  - Returns `daysRemaining` (appropriate value based on status)
  - Returns `isPremiumActive` and `isInTrial` flags

**Response Format:**
```json
{
  "success": true,
  "subscriptionStatus": "active",
  "plan": "monthly",
  "expiresDate": "2026-02-01T00:00:00.000Z",
  "trialDaysRemaining": 0,
  "subscriptionDaysRemaining": 15,
  "daysRemaining": 15,
  "isPremiumActive": true,
  "isInTrial": false
}
```

### 3. New `/subscriptions/sync` Endpoint

**Purpose:** Periodic sync endpoint to automatically update subscription status

**Features:**
- Automatically checks and updates expired subscriptions
- Transitions trial to active when appropriate
- Returns `statusChanged` flag to indicate if status was updated

**Response Format:**
```json
{
  "success": true,
  "subscription": { ... },
  "statusChanged": false
}
```

### 4. Enhanced `/subscriptions/cancel` Endpoint

**New Features:**
- Adds `cancelledAt` timestamp when subscription is cancelled
- Returns `daysRemaining` until cancellation takes effect (user still has access until endDate)

**Response Format:**
```json
{
  "message": "Subscription cancelled",
  "subscription": { ... },
  "daysRemaining": 15
}
```

### 5. User Model Updates

**Location:** `backend/models/User.js`

**New Field:**
- `subscription.cancelledAt`: Date when subscription was cancelled (user still has access until endDate)

## App Enhancements

### 1. Enhanced Subscription Status Checking

**Location:** `GoFit.Ai - live Healthy/Features/Paywall/PurchaseManager.swift`

**New Features:**
- **Enhanced Backend Response Parsing:**
  - Parses `isPremiumActive`, `isCancelled`, `isExpired` flags
  - Uses `trialDaysRemaining` and `subscriptionDaysRemaining` from backend
  - Properly handles cancelled subscriptions (user still has access)

- **Periodic Backend Sync:**
  - New `syncSubscriptionStatusWithBackend()` function
  - Called every 5 minutes in background
  - Automatically refreshes status when backend detects changes

- **Improved Status Logic:**
  - Distinguishes between premium active and trial users
  - Handles cancelled subscriptions properly (user still has access)
  - Uses backend days calculations for accuracy

### 2. Days Calculations

**Backend Calculations:**
- Trial days: Calculated from `trialEndDate` to current date
- Subscription days: Calculated from `endDate` to current date
- Uses `Math.ceil()` to round up partial days
- Returns `Math.max(0, days)` to ensure non-negative values

**App Calculations:**
- Uses backend values when available (more accurate)
- Falls back to local calculations if backend unavailable
- Updates `trialDaysRemaining` from backend response

## Subscription Status Flow

### Status Transitions:

1. **New User → Trial:**
   - User signs up → `status: 'trial'`
   - `trialEndDate` set to 3 days from signup
   - `trialDaysRemaining` calculated

2. **Trial → Active (Premium):**
   - User purchases subscription during trial
   - `status: 'active'` (premium active)
   - `endDate` set based on plan (monthly/yearly)
   - `subscriptionDaysRemaining` calculated

3. **Trial → Expired:**
   - Trial ends without purchase
   - `status: 'expired'`
   - User loses access

4. **Active → Cancelled:**
   - User cancels subscription
   - `status: 'cancelled'`
   - `cancelledAt` timestamp set
   - User still has access until `endDate`

5. **Active → Expired:**
   - Subscription `endDate` passes
   - `status: 'expired'`
   - User loses access

6. **Cancelled → Expired:**
   - Cancelled subscription `endDate` passes
   - `status: 'expired'`
   - User loses access

## Days Calculation Logic

### Trial Days Remaining:
```javascript
const trialDaysRemaining = trialEndDate 
  ? Math.max(0, Math.ceil((trialEndDate - now) / (1000 * 60 * 60 * 24)))
  : 0;
```

### Subscription Days Remaining:
```javascript
const subscriptionDaysRemaining = endDate 
  ? Math.max(0, Math.ceil((endDate - now) / (1000 * 60 * 60 * 24)))
  : 0;
```

### Appropriate Days Remaining:
- If in trial: `trialDaysRemaining`
- If active premium: `subscriptionDaysRemaining`
- If cancelled: `subscriptionDaysRemaining` (until endDate)

## Automatic Status Updates

The backend automatically updates subscription status when:
1. **Trial Expires:**
   - Checks `trialEndDate < now`
   - If `endDate > now`: Transition to `active`
   - If `endDate <= now`: Transition to `expired`

2. **Subscription Expires:**
   - Checks `endDate < now` and `status !== 'cancelled'`
   - Transition to `expired`

3. **Periodic Sync:**
   - App calls `/subscriptions/sync` every 5 minutes
   - Backend checks and updates status automatically
   - Returns `statusChanged` flag if update occurred

## Premium User Tracking

### Premium Active Users:
- `status: 'active'` (not trial, not expired, not cancelled)
- `isPremiumActive: true`
- Have paid subscription that is currently active

### Trial Users:
- `status: 'trial'`
- `isInTrial: true`
- In free trial period (3 days)

### Cancelled Users:
- `status: 'cancelled'`
- `isCancelled: true`
- Still have access until `endDate`
- `cancelledAt` timestamp recorded

### Expired Users:
- `status: 'expired'`
- `isExpired: true`
- No longer have access
- Need to resubscribe

## Testing

### Test Scenarios:

1. **New User Signup:**
   - Verify trial starts (3 days)
   - Check `trialDaysRemaining` decreases daily
   - Verify status is `trial`

2. **Purchase During Trial:**
   - Verify status transitions to `active`
   - Check `subscriptionDaysRemaining` is calculated
   - Verify `isPremiumActive: true`

3. **Trial Expires Without Purchase:**
   - Verify status transitions to `expired`
   - Check access is blocked
   - Verify `trialDaysRemaining: 0`

4. **Subscription Cancellation:**
   - Verify status is `cancelled`
   - Check user still has access until `endDate`
   - Verify `cancelledAt` is set
   - Check `daysRemaining` shows days until expiration

5. **Subscription Expiration:**
   - Verify status transitions to `expired`
   - Check access is blocked
   - Verify `subscriptionDaysRemaining: 0`

6. **Periodic Sync:**
   - Verify status updates automatically
   - Check `statusChanged` flag works
   - Verify days calculations update

## API Endpoints Summary

### GET `/api/subscriptions/status`
- Get current subscription status with days calculations
- Returns detailed status information
- Automatically updates expired subscriptions

### POST `/api/subscriptions/verify`
- Verify StoreKit transaction
- Update subscription status
- Calculate days remaining

### POST `/api/subscriptions/sync`
- Periodic sync endpoint
- Auto-update subscription status
- Returns status change flag

### POST `/api/subscriptions/cancel`
- Cancel subscription
- Set cancelled timestamp
- Return days remaining until expiration

## Benefits

1. **Accurate Days Calculations:**
   - Backend calculates days from actual dates
   - No timezone issues
   - Consistent across all devices

2. **Automatic Status Updates:**
   - Backend automatically updates expired subscriptions
   - No manual intervention needed
   - Real-time status tracking

3. **Premium User Tracking:**
   - Clear distinction between trial and premium users
   - Proper tracking of cancelled subscriptions
   - Accurate access control

4. **Smooth App Experience:**
   - Periodic sync keeps app status up to date
   - Background updates don't block UI
   - Accurate days remaining display

5. **Cancelled Subscription Handling:**
   - Users keep access until endDate
   - Proper tracking of cancellation date
   - Days remaining until expiration
