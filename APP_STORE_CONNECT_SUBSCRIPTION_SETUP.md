# App Store Connect Subscription Setup Guide

## Overview
Your app uses two auto-renewable subscriptions:
- **Monthly**: `com.gofitai.premium.monthly` - $1.99/month
- **Yearly**: `com.gofitai.premium.yearly` - $19.99/year

## Step-by-Step Setup Instructions

### 1. Access App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Sign in with your Apple Developer account
3. Select your app: **GoFit.Ai - live Healthy**

### 2. Navigate to Subscriptions

1. In your app's page, click on **"Features"** in the left sidebar
2. Click on **"In-App Purchases"**
3. Click the **"+"** button (top left) to create a new in-app purchase
4. Select **"Auto-Renewable Subscription"**

### 3. Create Monthly Subscription

#### Basic Information
- **Subscription Group**: Create a new group called "GoFit.Ai Premium" (or use existing if you have one)
- **Reference Name**: `GoFit.Ai Premium Monthly`
- **Product ID**: `com.gofitai.premium.monthly` ⚠️ **MUST MATCH EXACTLY**
- **Subscription Duration**: `1 Month`

#### Subscription Display Name
- **Display Name**: `GoFit.Ai Premium Monthly`
- This appears in the App Store

#### Pricing and Availability
1. Click **"Add Subscription Price"**
2. Select your **Base Territory** (usually United States)
3. Set price: **$1.99 USD**
4. Click **"Next"** to set prices for other territories (or use "Use Price Schedule" to auto-calculate)
5. Click **"Save"**

#### Subscription Information
- **Description**: 
  ```
  Unlock all premium features including unlimited AI meal scans, personalized meal and workout plans, advanced insights, and Apple Watch sync.
  ```
- **Subscription Group Display Name**: `GoFit.Ai Premium` (appears in App Store)

#### Review Information
- **Screenshot**: Upload a screenshot showing the subscription in your app (required for review)
  - Take a screenshot of your `PaywallView` showing the monthly subscription option
  - Minimum size: 640 x 920 pixels (iPhone 6.7" display)
- **Review Notes** (optional but recommended):
  ```
  This subscription provides access to premium features including:
  - Unlimited AI meal scanning
  - Personalized meal and workout recommendations
  - Advanced health insights
  - Apple Watch integration
  
  Test Account: [Your test account email]
  ```

#### Free Trial (Optional but Recommended)
1. Click **"Add Introductory Offer"**
2. Select **"Free Trial"**
3. Set duration: **3 Days** (matches your app's trial period)
4. Click **"Create"**

### 4. Create Yearly Subscription

Repeat the same steps as above, but with these differences:

#### Basic Information
- **Subscription Group**: Select the **same group** as monthly ("GoFit.Ai Premium")
- **Reference Name**: `GoFit.Ai Premium Yearly`
- **Product ID**: `com.gofitai.premium.yearly` ⚠️ **MUST MATCH EXACTLY**
- **Subscription Duration**: `1 Year`

#### Pricing and Availability
- Set price: **$19.99 USD**

#### Free Trial
- Set duration: **3 Days** (same as monthly)

### 5. Subscription Group Configuration

1. Go back to your **Subscription Group** ("GoFit.Ai Premium")
2. Set **Group Display Name**: `GoFit.Ai Premium`
3. Set **Group Localization**: Add localized names if supporting multiple languages

### 6. App Store Metadata Requirements

#### App Description
Add the following to your **App Description** in App Store Connect:

```
Terms of Use: https://gofitai.org/terms-and-conditions
Privacy Policy: https://gofitai.org/privacy-policy
```

#### Privacy Policy
1. Go to **App Privacy** section
2. Add Privacy Policy URL: `https://gofitai.org/privacy-policy`
3. Ensure the link is functional and accessible

#### Terms of Use (EULA)
You have two options:

**Option A: Use Standard Apple EULA**
- In App Description, add: "Terms of Use: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"

**Option B: Use Custom EULA**
- Go to **App Information** → **EULA** field
- Add your custom Terms of Use: `https://gofitai.org/terms-and-conditions`
- Also add it to App Description as shown above

### 7. Submit for Review

#### Before Submitting
1. ✅ Both subscription products are created
2. ✅ Product IDs match exactly: `com.gofitai.premium.monthly` and `com.gofitai.premium.yearly`
3. ✅ Prices are set correctly ($1.99 monthly, $19.99 yearly)
4. ✅ Subscription screenshots are uploaded
5. ✅ Privacy Policy URL is added
6. ✅ Terms of Use link is in App Description
7. ✅ Free trial is configured (3 days)

#### Submission Steps
1. Go to **App Store** tab in App Store Connect
2. Create a new version or update existing version
3. In the **In-App Purchases** section, you should see both subscriptions
4. Ensure both are **"Ready to Submit"** status
5. Fill out all required App Review Information
6. Submit for review

### 8. Testing Subscriptions

#### Sandbox Testing
1. Create a **Sandbox Tester** account in App Store Connect:
   - Go to **Users and Access** → **Sandbox Testers**
   - Click **"+"** to add a new tester
   - Use a unique email (not your real Apple ID)
2. Sign out of your real Apple ID on your test device
3. In your app, when prompted, sign in with the Sandbox Tester account
4. Test purchases will be free in Sandbox mode

#### Testing Checklist
- [ ] Monthly subscription can be purchased
- [ ] Yearly subscription can be purchased
- [ ] Free trial activates correctly (3 days)
- [ ] Subscription status updates correctly
- [ ] Subscription renews automatically (test with shorter duration)
- [ ] Subscription can be cancelled
- [ ] Restore purchases works

### 9. Common Issues and Solutions

#### Issue: "Products not available"
- **Solution**: Ensure Product IDs match exactly between code and App Store Connect
- Check that subscriptions are in "Ready to Submit" or "Approved" status

#### Issue: "Subscription not found"
- **Solution**: 
  - Verify Product IDs: `com.gofitai.premium.monthly` and `com.gofitai.premium.yearly`
  - Ensure subscriptions are in the same Subscription Group
  - Check that subscriptions are approved or ready for review

#### Issue: App Review Rejection - Missing Subscription Info
- **Solution**: 
  - Ensure all required information is displayed in `PaywallView`:
    - Subscription title
    - Subscription length
    - Price
    - Price per unit (for yearly)
    - Terms of Use link
    - Privacy Policy link
  - Add Terms of Use to App Description
  - Add Privacy Policy URL in App Privacy section

#### Issue: Free Trial Not Working
- **Solution**:
  - Ensure Introductory Offer is configured in App Store Connect
  - Check that trial duration matches (3 days)
  - Verify user hasn't used trial before (Apple tracks this)

### 10. Important Notes

⚠️ **Product IDs Must Match Exactly**
- Code: `com.gofitai.premium.monthly`
- App Store Connect: `com.gofitai.premium.monthly`
- Any mismatch will cause products to not load

⚠️ **Subscription Group**
- Both subscriptions MUST be in the same Subscription Group
- Users can only have one active subscription from a group at a time
- Upgrading/downgrading is handled automatically by Apple

⚠️ **Pricing**
- Set prices in your base currency (USD)
- App Store Connect will auto-calculate prices for other territories
- You can manually adjust prices per territory if needed

⚠️ **Review Screenshots**
- Required for subscription review
- Must show the subscription option in your app
- Minimum size: 640 x 920 pixels

### 11. After Approval

Once subscriptions are approved:
1. Test with real purchases (small amount)
2. Monitor subscription status in App Store Connect
3. Set up server-side receipt validation (if not already done)
4. Monitor subscription renewal rates
5. Handle subscription expiration gracefully in your app

## Quick Reference

### Product IDs
- Monthly: `com.gofitai.premium.monthly`
- Yearly: `com.gofitai.premium.yearly`

### Prices
- Monthly: $1.99 USD
- Yearly: $19.99 USD

### Free Trial
- Duration: 3 days
- Applies to both subscriptions

### Required Links
- Privacy Policy: `https://gofitai.org/privacy-policy`
- Terms of Use: `https://gofitai.org/terms-and-conditions`

## Support Resources

- [Apple In-App Purchase Guide](https://developer.apple.com/in-app-purchase/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Subscription Best Practices](https://developer.apple.com/app-store/subscriptions/)
