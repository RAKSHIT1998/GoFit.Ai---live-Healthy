# Complete Subscription Setup Guide

This guide will walk you through setting up subscriptions in App Store Connect and ensuring everything works perfectly.

## 📋 Prerequisites

- Apple Developer Account (paid membership required)
- App Store Connect access
- Your app must be configured in App Store Connect
- Backend server running and accessible

---

## Step 1: Configure Products in App Store Connect

### 1.1 Access App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to **My Apps** → Select your app
3. Click on **Subscriptions** in the left sidebar
4. Click **+** to create a subscription group

### 1.2 Create Subscription Group

1. **Subscription Group Name**: "GoFit.Ai Premium"
2. Click **Create**

### 1.3 Create Monthly Subscription

1. Click **+** next to your subscription group
2. **Reference Name**: "Premium Monthly"
3. **Product ID**: `com.gofitai.premium.monthly` ⚠️ **Must match exactly**
4. **Subscription Duration**: 1 Month
5. Click **Create**

**Configure Monthly Subscription:**
- **Price**: Set your monthly price (e.g., $9.99/month)
- **Free Trial**: 
  - Enable "Free Trial"
  - Duration: 3 days
  - This matches your app's 3-day trial
- **Localizations**: Add descriptions in all supported languages
- **Review Information**: Add screenshots and description

### 1.4 Create Yearly Subscription

1. Click **+** next to your subscription group again
2. **Reference Name**: "Premium Yearly"
3. **Product ID**: `com.gofitai.premium.yearly` ⚠️ **Must match exactly**
4. **Subscription Duration**: 1 Year
5. Click **Create**

**Configure Yearly Subscription:**
- **Price**: Set your yearly price (e.g., $79.99/year - typically 2 months free vs monthly)
- **Free Trial**: 
  - Enable "Free Trial"
  - Duration: 3 days
- **Localizations**: Add descriptions in all supported languages
- **Review Information**: Add screenshots and description

### 1.5 Set Subscription Group Display Order

1. In your subscription group, set the display order:
   - Yearly (recommended) - First
   - Monthly - Second

---

## Step 2: Configure App for Subscriptions

### 2.1 Verify Product IDs in Code

Your app already has these product IDs configured:
- Monthly: `com.gofitai.premium.monthly`
- Yearly: `com.gofitai.premium.yearly`

**Location**: `GoFit.Ai - live Healthy/Features/Paywall/PurchaseManager.swift`

### 2.2 Verify Bundle ID

1. In Xcode, select your project
2. Go to **Signing & Capabilities**
3. Note your **Bundle Identifier** (e.g., `com.gofitai.app`)
4. Ensure it matches your App Store Connect app

---

## Step 3: Testing Subscriptions

### 3.1 Sandbox Testing Account

1. In App Store Connect, go to **Users and Access** → **Sandbox Testers**
2. Click **+** to create a test account
3. Use a **different email** than your Apple ID
4. Create multiple test accounts for different scenarios

### 3.2 Test on Device/Simulator

1. **Sign out** of your regular Apple ID on the test device
2. When prompted during purchase, use your **Sandbox Tester** account
3. Test the following scenarios:
   - ✅ New subscription purchase
   - ✅ Restore purchases
   - ✅ Subscription renewal
   - ✅ Cancel subscription
   - ✅ Trial period expiration

### 3.3 StoreKit Configuration File (Optional - for Xcode Testing)

For local testing without App Store Connect:

1. In Xcode: **File** → **New** → **File**
2. Select **StoreKit Configuration File**
3. Add your products:
   - `com.gofitai.premium.monthly` - Monthly subscription
   - `com.gofitai.premium.yearly` - Yearly subscription
4. Configure prices and trial periods
5. In scheme editor, set **StoreKit Configuration** to your file

---

## Step 4: Backend Verification Setup

### 4.1 Verify Backend Endpoints

Your backend already has these endpoints:
- `POST /api/subscriptions/verify` - Verifies purchase with backend
- `GET /api/subscriptions/status` - Gets subscription status

**Location**: `backend/routes/subscriptions.js`

### 4.2 Test Backend Integration

1. Make a test purchase in the app
2. Check backend logs to ensure verification is working
3. Verify user subscription status is saved in database

---

## Step 5: App Store Review Requirements

### 5.1 Subscription Terms

Add these to your app:
- Terms of Service link
- Privacy Policy link
- Subscription management instructions

**Already implemented in**: `PaywallView.swift`

### 5.2 Subscription Management

Users should be able to:
- ✅ View subscription status (in ProfileView)
- ✅ Restore purchases (in PaywallView)
- ✅ Manage subscription (link to Settings app)

**Already implemented**: All features are in place

---

## Step 6: Production Checklist

Before submitting to App Store:

### ✅ Product Configuration
- [ ] Both subscriptions created in App Store Connect
- [ ] Product IDs match exactly: `com.gofitai.premium.monthly` and `com.gofitai.premium.yearly`
- [ ] Prices set correctly
- [ ] 3-day free trial enabled on both
- [ ] Localizations added

### ✅ Testing
- [ ] Tested purchase flow on device
- [ ] Tested restore purchases
- [ ] Tested subscription renewal
- [ ] Tested trial expiration
- [ ] Backend verification working

### ✅ App Store Connect
- [ ] Subscription group created
- [ ] Products approved (if required)
- [ ] App metadata includes subscription info

### ✅ Code Verification
- [ ] Product IDs match App Store Connect
- [ ] Bundle ID matches App Store Connect
- [ ] Backend endpoints accessible
- [ ] Error handling in place

---

## Step 7: Pricing Strategy Recommendations

### Monthly Subscription
- **Recommended**: $9.99/month
- **Alternative**: $7.99/month or $12.99/month
- Consider your market and competitors

### Yearly Subscription
- **Recommended**: $79.99/year (save $40 vs monthly)
- **Alternative**: $69.99/year (save $30) or $89.99/year (save $30)
- Typically offer 2-3 months free vs monthly

### Free Trial
- **Current**: 3 days
- **Consider**: 7 days for better conversion
- Can be changed in App Store Connect

---

## Step 8: Monitoring & Analytics

### 8.1 App Store Connect Analytics

Monitor:
- Subscription conversion rate
- Trial-to-paid conversion
- Churn rate
- Revenue

### 8.2 Backend Analytics

Your backend already tracks:
- User subscriptions
- Subscription status
- Trial information

**Location**: `backend/routes/admin.js` - `/api/admin/metrics`

---

## Troubleshooting

### Products Not Loading

**Issue**: App shows "Products not available"

**Solutions**:
1. Verify product IDs match exactly (case-sensitive)
2. Ensure products are approved in App Store Connect
3. Check internet connection
4. Wait a few minutes after creating products (propagation delay)
5. Use Sandbox account for testing

### Purchase Not Completing

**Issue**: Purchase hangs or fails

**Solutions**:
1. Ensure you're signed out of regular Apple ID
2. Use Sandbox Tester account
3. Check backend is accessible
4. Verify network connectivity
5. Check Xcode console for errors

### Backend Verification Failing

**Issue**: Purchase succeeds but backend doesn't verify

**Solutions**:
1. Check backend logs
2. Verify `/api/subscriptions/verify` endpoint is accessible
3. Check authentication token is valid
4. Verify transaction data format

### Subscription Status Not Updating

**Issue**: App shows wrong subscription status

**Solutions**:
1. Call `purchases.checkSubscriptionStatus()` after purchase
2. Verify backend subscription status endpoint
3. Check user subscription in database
4. Force app restart

---

## Important Notes

### ⚠️ Product ID Format

Product IDs must:
- Start with your bundle ID prefix (e.g., `com.gofitai.`)
- Be lowercase
- Use dots (.) as separators
- Match exactly between code and App Store Connect

### ⚠️ Testing vs Production

- **Sandbox**: Use for testing, different from production
- **Production**: Real purchases, requires approved products
- Always test in Sandbox before production

### ⚠️ Subscription Changes

- Can change prices anytime
- Cannot change product IDs after creation
- Can modify trial periods
- Changes require app update if product IDs change

---

## Quick Start Checklist

1. ✅ Create subscription group in App Store Connect
2. ✅ Create monthly subscription (`com.gofitai.premium.monthly`)
3. ✅ Create yearly subscription (`com.gofitai.premium.yearly`)
4. ✅ Set prices and enable 3-day free trial
5. ✅ Create Sandbox Tester account
6. ✅ Test purchase flow on device
7. ✅ Verify backend integration
8. ✅ Submit app for review

---

## Support Resources

- [Apple StoreKit Documentation](https://developer.apple.com/documentation/storekit)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Subscription Best Practices](https://developer.apple.com/app-store/subscriptions/)

---

## Current Implementation Status

✅ **Completed**:
- StoreKit 2 integration
- Purchase flow
- Restore purchases
- Backend verification
- Subscription status checking
- Trial management
- Paywall UI
- Subscription status display

🎯 **Next Steps**:
1. Create products in App Store Connect
2. Test with Sandbox accounts
3. Submit for review

Your app is ready for subscriptions! Just configure the products in App Store Connect and test.
