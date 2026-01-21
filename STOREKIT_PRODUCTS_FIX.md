# Fix: "No products found" StoreKit Error

## Problem
**Error:** "No products found. Make sure products are configured in App Store Connect or StoreKit configuration file."

This error occurs when StoreKit cannot find the subscription products. The products are defined in your code but need to be configured either:
1. **For local testing:** In the StoreKit configuration file
2. **For production:** In App Store Connect

## Solution

### Option 1: Use StoreKit Configuration File (For Local Testing)

Your StoreKit configuration file (`gofit ai.storekit`) already has the subscriptions configured, but you need to make sure Xcode is using it:

1. **Open your project in Xcode**

2. **Select the scheme:**
   - Click the scheme selector (next to the device selector at the top)
   - Click **"Edit Scheme..."**

3. **Configure StoreKit:**
   - In the left sidebar, select **"Run"**
   - Go to the **"Options"** tab
   - Under **"StoreKit Configuration"**, select:
     - **"gofit ai.storekit"** from the dropdown
   - Click **"Close"**

4. **Verify the StoreKit file:**
   - The file `GoFit.Ai - live Healthy/gofit ai.storekit` should exist
   - It should contain both subscriptions:
     - `com.gofitai.premium.monthly` (Monthly Premium - $9.99)
     - `com.gofitai.premium.yearly` (Yearly Premium - $79.99)
   - Both have 3-day free trials configured

5. **Clean and rebuild:**
   - **Product → Clean Build Folder** (`Cmd + Shift + K`)
   - **Product → Build** (`Cmd + B`)

6. **Run the app:**
   - The products should now load from the StoreKit configuration file

### Option 2: Configure in App Store Connect (For Production/TestFlight)

If you want to test with real App Store products (or for TestFlight/App Store submission):

1. **Log in to App Store Connect:**
   - Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
   - Select your app

2. **Create In-App Purchases:**
   - Go to **"Features" → "In-App Purchases"**
   - Click **"+"** to create a new subscription

3. **Create Monthly Subscription:**
   - **Type:** Auto-Renewable Subscription
   - **Product ID:** `com.gofitai.premium.monthly`
   - **Subscription Group:** Create new group "Premium" (or use existing)
   - **Duration:** 1 month
   - **Price:** Set to $1.99 (or your desired price)
   - **Free Trial:** 3 days
   - **Display Name:** Monthly Premium
   - **Description:** Monthly premium subscription with access to all features
   - **Review Information:** Add screenshot and description
   - **Save**

4. **Create Yearly Subscription:**
   - **Type:** Auto-Renewable Subscription
   - **Product ID:** `com.gofitai.premium.yearly`
   - **Subscription Group:** Same group as monthly ("Premium")
   - **Duration:** 1 year
   - **Price:** Set to $19.99 (or your desired price)
   - **Free Trial:** 3 days
   - **Display Name:** Yearly Premium
   - **Description:** Yearly premium subscription with access to all features. Best value!
   - **Review Information:** Add screenshot and description
   - **Save**

5. **Submit for Review:**
   - Both subscriptions need to be submitted for review
   - Go to each subscription → Click **"Submit for Review"**
   - Add required metadata (screenshots, descriptions)

6. **Wait for Approval:**
   - Apple typically reviews IAP products within 24-48 hours
   - Once approved, they'll be available for testing

7. **For Testing:**
   - Use **Sandbox Test Accounts** (created in App Store Connect → Users and Access → Sandbox Testers)
   - Sign out of App Store on your test device
   - When prompted during purchase, use the sandbox account

### Option 3: Use Both (Recommended)

**For Development:**
- Use StoreKit configuration file (Option 1) for quick local testing
- No need to wait for App Store Connect approval
- Products load instantly

**For Production:**
- Use App Store Connect (Option 2) for TestFlight and App Store
- Real products with real pricing
- Can test with sandbox accounts

## Verification

After configuring, verify products load:

1. **Run the app**
2. **Navigate to the paywall** (or wherever products are loaded)
3. **Check console logs:**
   - Should see: `✅ Loaded 2 products`
   - If you see: `⚠️ No products found`, the configuration isn't working

4. **Check Product IDs match:**
   - Code expects: `com.gofitai.premium.monthly` and `com.gofitai.premium.yearly`
   - StoreKit file has: `com.gofitai.premium.monthly` and `com.gofitai.premium.yearly` ✅
   - App Store Connect must match exactly

## Current Configuration

**Product IDs in Code:**
- Monthly: `com.gofitai.premium.monthly`
- Yearly: `com.gofitai.premium.yearly`

**StoreKit Configuration File:**
- ✅ Monthly Premium: `com.gofitai.premium.monthly` ($1.99/month, 3-day trial)
- ✅ Yearly Premium: `com.gofitai.premium.yearly` ($19.99/year, 3-day trial)

**Note:** The prices in the StoreKit file ($1.99/$19.99) match your App Store Connect pricing for testing.

## Troubleshooting

### Issue: Products still not loading after configuring StoreKit file

**Solution:**
1. Make sure the scheme is set to use the StoreKit file (Option 1, Step 3)
2. Clean build folder and rebuild
3. Restart Xcode
4. Check that the StoreKit file is in the project (not just in the file system)

### Issue: "Product ID already in use" in App Store Connect

**Solution:**
- Check if the product ID exists in another subscription group
- Check if it's used in another app
- Use a different product ID if needed (and update code)

### Issue: Products load in simulator but not on device

**Solution:**
- Device testing requires App Store Connect products (not just StoreKit file)
- Use sandbox test accounts
- Make sure products are approved in App Store Connect

### Issue: StoreKit file not showing in scheme options

**Solution:**
1. Make sure the `.storekit` file is added to the Xcode project
2. Check it's in the correct target
3. Try removing and re-adding the file to the project

## Quick Checklist

**For Local Testing (StoreKit File):**
- [ ] StoreKit file exists: `gofit ai.storekit`
- [ ] Scheme configured to use StoreKit file
- [ ] Products defined in subscriptionGroups
- [ ] Product IDs match code exactly
- [ ] Clean build and run

**For Production (App Store Connect):**
- [ ] Products created in App Store Connect
- [ ] Product IDs match code exactly
- [ ] Products submitted for review
- [ ] Products approved
- [ ] Sandbox test accounts created
- [ ] Testing with sandbox account

## Next Steps

1. **For immediate testing:** Use Option 1 (StoreKit file)
2. **For App Store submission:** Complete Option 2 (App Store Connect)
3. **Verify products load** in the app
4. **Test purchase flow** (with StoreKit file or sandbox account)

Once products are configured and loading, you should be able to:
- ✅ See products in the paywall
- ✅ Purchase subscriptions
- ✅ See subscription status
- ✅ Test free trials
