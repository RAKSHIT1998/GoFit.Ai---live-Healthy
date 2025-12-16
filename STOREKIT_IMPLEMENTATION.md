# StoreKit & In-App Purchase Implementation

## Overview

The app uses **StoreKit 2** for managing in-app purchase subscriptions. This implementation provides a complete subscription system with free trials, receipt validation, and subscription status monitoring.

## Features

✅ **StoreKit 2 Integration**
- Modern async/await API
- Automatic transaction monitoring
- Subscription status tracking
- Receipt validation with backend

✅ **Subscription Plans**
- Monthly Premium: `com.gofitai.premium.monthly`
- Yearly Premium: `com.gofitai.premium.yearly`
- 3-day free trial support

✅ **Features**
- Real-time subscription status updates
- Automatic transaction handling
- Backend receipt verification
- Restore purchases functionality
- Subscription management UI

## Implementation Details

### PurchaseManager.swift

The `PurchaseManager` class handles all StoreKit operations:

**Key Features:**
- `@Published` properties for reactive UI updates
- Automatic transaction listener for background updates
- Subscription status monitoring (checks every minute)
- Backend receipt verification
- Product loading and caching

**Main Methods:**
- `loadProducts()` - Fetches available subscription products
- `purchase(productId:)` - Initiates purchase flow
- `restorePurchases()` - Restores previous purchases
- `updateSubscriptionStatus()` - Checks current subscription status

**Subscription Status:**
- `.unknown` - Initial state
- `.free` - No active subscription
- `.trial` - In free trial period
- `.active` - Active subscription
- `.expired` - Subscription expired
- `.cancelled` - Subscription cancelled

### PaywallView.swift

The paywall UI displays:
- Product information with real prices from App Store
- Free trial information
- Plan selection (Monthly/Yearly)
- Purchase button with loading states
- Error handling
- Restore purchases option

**Features:**
- Dynamic pricing from StoreKit
- Shows free trial availability
- Beautiful gradient UI with animations
- Loading states during purchase

### ProfileView.swift

The profile screen shows:
- Current subscription status
- Trial period information
- Expiration date
- Link to manage subscription in App Store
- Upgrade button for non-subscribers

## Setup Instructions

### 1. App Store Connect Configuration

1. Log in to [App Store Connect](https://appstoreconnect.apple.com)
2. Create your app (if not already created)
3. Go to **Features** → **In-App Purchases**
4. Create two **Auto-Renewable Subscriptions**:

   **Monthly Premium:**
   - Product ID: `com.gofitai.premium.monthly`
   - Subscription Group: Create new group "Premium"
   - Duration: 1 month
   - Price: Set your desired price
   - Free Trial: 3 days

   **Yearly Premium:**
   - Product ID: `com.gofitai.premium.yearly`
   - Subscription Group: Same group as monthly
   - Duration: 1 year
   - Price: Set your desired price
   - Free Trial: 3 days

5. Submit for review

### 2. Xcode Configuration

The StoreKit framework is already linked in the project. Verify:
- StoreKit.framework is in "Frameworks" folder
- Capabilities → In-App Purchase is enabled (if required)

### 3. Testing

**Sandbox Testing:**
1. Create sandbox test accounts in App Store Connect
2. Sign out of App Store on your test device
3. When prompted during purchase, use sandbox account
4. Test subscription flow, cancellation, and restoration

**Testing Checklist:**
- [ ] Products load correctly
- [ ] Purchase flow works
- [ ] Free trial activates
- [ ] Subscription status updates
- [ ] Restore purchases works
- [ ] Backend receipt validation works
- [ ] Subscription expiration handled

## Backend Integration

The app sends transaction data to the backend for verification:

**Endpoint: `POST /subscriptions/verify`**
```json
{
  "transactionData": "base64_encoded_jws",
  "productId": "com.gofitai.premium.monthly",
  "transactionId": 1234567890
}
```

**Endpoint: `GET /subscriptions/status`**
Returns current subscription status from backend.

## Code Structure

```
GoFit.Ai - live Healthy/
├── Features/
│   └── Paywall/
│       ├── PurchaseManager.swift    # StoreKit 2 implementation
│       └── PaywallView.swift        # Subscription UI
└── Features/
    └── Authentication/
        └── ProfileView.swift         # Subscription status display
```

## Usage Example

```swift
// In your view
@EnvironmentObject var purchases: PurchaseManager

// Check subscription status
if purchases.hasActiveSubscription {
    // Show premium features
}

// Purchase subscription
try await purchases.purchase(productId: "com.gofitai.premium.monthly")

// Restore purchases
try await purchases.restorePurchases()
```

## Important Notes

1. **Product IDs** must match exactly between App Store Connect and code
2. **Receipt Validation** should always be done server-side for security
3. **Transaction Monitoring** runs automatically in the background
4. **Subscription Status** is checked periodically (every minute)
5. **Free Trials** are handled automatically by StoreKit

## Troubleshooting

**Products not loading:**
- Verify product IDs match App Store Connect
- Check internet connection
- Ensure products are approved in App Store Connect

**Purchase fails:**
- Check sandbox account is signed in
- Verify backend receipt validation endpoint is working
- Check transaction logs in App Store Connect

**Subscription status not updating:**
- Wait for automatic status check (runs every minute)
- Call `purchases.updateSubscriptionStatus()` manually
- Check backend subscription status endpoint

## Security Best Practices

✅ Always validate receipts server-side
✅ Use JWT tokens for backend authentication
✅ Store subscription status in backend database
✅ Handle subscription expiration gracefully
✅ Monitor for fraudulent transactions

## Next Steps

1. Set up products in App Store Connect
2. Test with sandbox accounts
3. Implement backend receipt validation
4. Test subscription renewal flow
5. Submit for App Store review

