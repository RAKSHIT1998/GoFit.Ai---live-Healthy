# Complete StoreKit Setup Guide

## Current Status
- ✅ StoreKit framework linked
- ✅ PurchaseManager implemented
- ✅ Product IDs defined: `com.gofitai.premium.monthly` and `com.gofitai.premium.yearly`
- ⚠️ StoreKit configuration file exists but is empty
- ⚠️ App Store Connect products need to be created

## Option 1: App Store Connect Setup (Required for Production)

### Step 1: Create Subscription Products

1. **Log in to App Store Connect:**
   - Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
   - Select your app: **GoFit.Ai - live Healthy**

2. **Navigate to In-App Purchases:**
   - Click **"Features"** in the left sidebar
   - Click **"In-App Purchases"**
   - Click the **"+"** button to create a new subscription

3. **Create Monthly Subscription:**
   - **Type:** Auto-Renewable Subscription
   - **Product ID:** `com.gofitai.premium.monthly` (must match exactly)
   - **Subscription Group:** Create new group "Premium" (or use existing)
   - **Subscription Duration:** 1 month
   - **Price:** $1.99 (or your desired price)
   - **Display Name:** Monthly Premium
   - **Description:** Monthly premium subscription with access to all features including AI meal analysis, personalized workout plans, and health tracking.
   
   **Free Trial:**
   - Click **"Add Introductory Offer"**
   - **Type:** Free Trial
   - **Duration:** 3 days
   - **Price:** Free
   
   **Review Information:**
   - Add a screenshot (required for review)
   - Add review notes if needed
   
   Click **"Save"**

4. **Create Yearly Subscription:**
   - **Type:** Auto-Renewable Subscription
   - **Product ID:** `com.gofitai.premium.yearly` (must match exactly)
   - **Subscription Group:** Same group as monthly ("Premium")
   - **Subscription Duration:** 1 year
   - **Price:** $19.99 (or your desired price)
   - **Display Name:** Yearly Premium
   - **Description:** Yearly premium subscription with access to all features including AI meal analysis, personalized workout plans, and health tracking. Best value!
   
   **Free Trial:**
   - Click **"Add Introductory Offer"**
   - **Type:** Free Trial
   - **Duration:** 3 days
   - **Price:** Free
   
   **Review Information:**
   - Add a screenshot (required for review)
   - Add review notes if needed
   
   Click **"Save"**

5. **Submit for Review:**
   - Both subscriptions must be submitted for review
   - Go to each subscription → Click **"Submit for Review"**
   - Wait for Apple's approval (typically 24-48 hours)

### Step 2: Configure Subscription Group

1. **Set Subscription Group Order:**
   - In App Store Connect, go to **"Features" → "In-App Purchases"**
   - Click on your subscription group "Premium"
   - Set the order:
     - **1st:** Yearly Premium (best value)
     - **2nd:** Monthly Premium
   - This determines the order shown in your app

### Step 3: Testing with Sandbox Accounts

1. **Create Sandbox Test Accounts:**
   - Go to **"Users and Access" → "Sandbox Testers"**
   - Click **"+"** to add a test account
   - Use a real email (can be your own)
   - Create password
   - Save the account

2. **Test on Device:**
   - Sign out of App Store on your test device
   - Run your app
   - When prompted during purchase, use the sandbox account
   - Test purchase flow, cancellation, and restoration

## Option 2: StoreKit Configuration File (For Local Testing)

**Note:** The StoreKit file (`GoFit.storekit`) exists but is empty. You can populate it for local testing, but it's **optional** since you can test with App Store Connect sandbox accounts.

### If You Want to Use StoreKit File:

1. **In Xcode:**
   - Right-click on `GoFit.storekit` in the navigator
   - Select **"Open With External Editor"** (to avoid crashes)
   - Or create a new one through Xcode UI:
     - Right-click project folder
     - **New File** → **StoreKit Configuration File**
     - Name it `GoFit.storekit`

2. **Add Products Through Xcode UI:**
   - Double-click the StoreKit file (if it doesn't crash)
   - Click **"+"** button
   - Add subscriptions with:
     - Product IDs: `com.gofitai.premium.monthly` and `com.gofitai.premium.yearly`
     - Prices: $1.99 and $19.99
     - 3-day free trials

3. **Configure Scheme:**
   - Edit Scheme → Run → Options
   - Under "StoreKit Configuration", select `GoFit.storekit`

**Important:** If Xcode crashes when opening the StoreKit file, skip this option and use App Store Connect sandbox testing instead.

## Verification Checklist

### App Store Connect
- [ ] Monthly subscription created
- [ ] Yearly subscription created
- [ ] Both in same subscription group
- [ ] 3-day free trials configured
- [ ] Products submitted for review
- [ ] Products approved by Apple
- [ ] Sandbox test accounts created

### Code Verification
- [ ] Product IDs match exactly:
  - `com.gofitai.premium.monthly`
  - `com.gofitai.premium.yearly`
- [ ] PurchaseManager loads products correctly
- [ ] PaywallView displays products
- [ ] Purchase flow works
- [ ] Restore purchases works

### Testing
- [ ] Test purchase with sandbox account
- [ ] Test free trial activation
- [ ] Test subscription status updates
- [ ] Test restore purchases
- [ ] Test subscription expiration handling

## Current Product IDs in Code

**PurchaseManager.swift:**
```swift
let monthlyID = "com.gofitai.premium.monthly"
let yearlyID = "com.gofitai.premium.yearly"
```

**These must match exactly in App Store Connect!**

## Pricing Reference

- **Monthly:** $1.99/month
- **Yearly:** $19.99/year
- **Free Trial:** 3 days for both

## Troubleshooting

### "No products found" Error
- **Solution:** Products must be approved in App Store Connect
- **Alternative:** Use StoreKit file for local testing (if configured)

### Products Load but Purchase Fails
- **Solution:** Ensure you're using a sandbox test account
- **Check:** Sign out of App Store on device first

### Subscription Status Not Updating
- **Solution:** Wait a few seconds, status updates automatically
- **Check:** Backend subscription verification endpoint is working

## Next Steps

1. **Create products in App Store Connect** (required for production)
2. **Submit for review** and wait for approval
3. **Test with sandbox accounts** while waiting
4. **Verify products load** in your app
5. **Test purchase flow** end-to-end

The StoreKit file is optional - App Store Connect products are what matter for production!
