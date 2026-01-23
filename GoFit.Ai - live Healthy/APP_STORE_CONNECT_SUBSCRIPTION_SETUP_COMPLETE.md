# Complete App Store Connect Subscription Setup Guide

## ⚠️ IMPORTANT: Product IDs
Your app uses these **exact** product IDs (must match exactly in App Store Connect):
- **Monthly**: `com.gofitai.premium.monthlyy` - $1.99/month
- **Yearly**: `com.gofitai.premium.yearlyy` - $19.99/year

**Note**: The yearly ID has two 'y's at the end (`yearlyy`) - this is intentional based on your App Store Connect subscription group requirements.

---

## Step 1: Access App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Sign in with your Apple Developer account
3. Click **"My Apps"**
4. Select your app: **GoFit.AI** (or create a new app with bundle ID `com.rakshit.gofitai`)

---

## Step 2: Create Subscription Group

1. In your app's page, click **"Features"** in the left sidebar
2. Click **"In-App Purchases"**
3. Click **"Manage"** next to **"Subscription Groups"** (or click **"+"** if you don't have any)
4. Click **"+"** to create a new subscription group
5. Enter **Group Reference Name**: `GoFit.AI Premium`
6. Click **"Create"**

---

## Step 3: Create Monthly Subscription

### 3.1 Basic Information

1. In the **"In-App Purchases"** section, click the **"+"** button (top left)
2. Select **"Auto-Renewable Subscription"**
3. Fill in:
   - **Subscription Group**: Select `GoFit.AI Premium` (the group you just created)
   - **Reference Name**: `GoFit.AI Premium Monthly`
   - **Product ID**: `com.gofitai.premium.monthlyy` ⚠️ **MUST MATCH EXACTLY**
   - **Subscription Duration**: Select `1 Month`
4. Click **"Create"**

### 3.2 Subscription Display Name

1. Click on the subscription you just created
2. Under **"Subscription Display Name"**:
   - **Display Name**: `GoFit.AI Premium Monthly`
   - This is what users see in the App Store

### 3.3 Pricing and Availability

1. Scroll to **"Pricing and Availability"**
2. Click **"Add Subscription Price"**
3. Select your **Base Territory** (usually **United States**)
4. Set price: **$1.99 USD**
5. Click **"Next"**
6. Review prices for other territories (or use **"Use Price Schedule"** to auto-calculate)
7. Click **"Save"**

### 3.4 Subscription Information

1. Scroll to **"Subscription Information"**
2. **Description**: 
   ```
   Unlock all premium features including unlimited AI meal scans, personalized meal and workout plans, advanced health insights, and Apple Watch sync.
   ```
3. **Subscription Group Display Name**: `GoFit.AI Premium`
   - This appears in the App Store subscription management

### 3.5 Free Trial (Introductory Offer)

1. Scroll to **"Introductory Offers"**
2. Click **"+"** to add an offer
3. Select **"Free Trial"**
4. Set **Duration**: `3 Days`
5. **Eligibility**: 
   - Select **"All Users"** (or configure specific eligibility rules)
6. Click **"Create"**

### 3.6 Review Information

1. Scroll to **"Review Information"**
2. **Screenshot** (Required):
   - Take a screenshot of your app's paywall showing the monthly subscription
   - Minimum size: **640 x 920 pixels** (iPhone 6.7" display)
   - Upload the screenshot
3. **Review Notes** (Optional but recommended):
   ```
   This subscription provides access to premium features including:
   - Unlimited AI meal scanning
   - Personalized meal and workout recommendations
   - Advanced health insights and analytics
   - Apple Watch integration
   - Priority customer support
   
   Test Account: [Your sandbox test account email]
   Test Instructions: Sign in with sandbox account, navigate to paywall, purchase monthly subscription
   ```

### 3.7 Save and Submit

1. Review all information
2. Click **"Save"** (top right)
3. The subscription status should change to **"Ready to Submit"** or **"Waiting for Review"**

---

## Step 4: Create Yearly Subscription

Repeat the same steps as Step 3, but with these differences:

### 4.1 Basic Information

- **Subscription Group**: Select the **same group** (`GoFit.AI Premium`)
- **Reference Name**: `GoFit.AI Premium Yearly`
- **Product ID**: `com.gofitai.premium.yearlyy` ⚠️ **MUST MATCH EXACTLY** (note the double 'y')
- **Subscription Duration**: Select `1 Year`

### 4.2 Pricing

- Set price: **$19.99 USD**

### 4.3 Free Trial

- Set duration: **3 Days** (same as monthly)

### 4.4 Review Information

- Use a screenshot showing the yearly subscription option
- Update review notes to mention yearly subscription testing

---

## Step 5: Configure Subscription Group

1. Go back to **"In-App Purchases"** → **"Subscription Groups"**
2. Click on your group: `GoFit.AI Premium`
3. **Group Display Name**: `GoFit.AI Premium`
4. Ensure both subscriptions (monthly and yearly) are listed in this group
5. Click **"Save"**

---

## Step 6: App Store Metadata Requirements

### 6.1 App Description

1. Go to **"App Store"** tab in App Store Connect
2. Select your app version (or create a new version)
3. In **"Description"**, add at the bottom:
   ```
   Terms of Use: https://gofitai.org/terms-and-conditions
   Privacy Policy: https://gofitai.org/privacy-policy
   ```

### 6.2 Privacy Policy

1. Go to **"App Privacy"** section (in left sidebar)
2. Add **Privacy Policy URL**: `https://gofitai.org/privacy-policy`
3. Ensure the link is functional and accessible (test it in a browser)

### 6.3 Terms of Use (EULA)

1. Go to **"App Information"** tab
2. Scroll to **"EULA"** field
3. You can either:
   - Use **"Apple's Standard EULA"** (default)
   - Or add your custom Terms URL in the App Description (already done above)

---

## Step 7: Submit Subscriptions for Review

### 7.1 Pre-Submission Checklist

Before submitting, verify:

- [ ] Both subscriptions are created:
  - [ ] Monthly: `com.gofitai.premium.monthlyy` - $1.99
  - [ ] Yearly: `com.gofitai.premium.yearlyy` - $19.99
- [ ] Both are in the same Subscription Group (`GoFit.AI Premium`)
- [ ] Product IDs match **exactly** with your code
- [ ] Prices are set correctly ($1.99 monthly, $19.99 yearly)
- [ ] Free trial is configured (3 days for both)
- [ ] Subscription screenshots are uploaded
- [ ] Privacy Policy URL is added and functional
- [ ] Terms of Use link is in App Description
- [ ] Both subscriptions show **"Ready to Submit"** or **"Waiting for Review"** status

### 7.2 Submission Steps

1. Go to **"App Store"** tab
2. Create a new version or update existing version
3. In the **"In-App Purchases"** section, you should see both subscriptions
4. Ensure both are **"Ready to Submit"** status
5. Fill out all required **App Review Information**:
   - Contact information
   - Demo account (if required)
   - Notes for reviewer
6. Submit the app version for review
7. Subscriptions will be reviewed along with your app

---

## Step 8: Testing Subscriptions (Sandbox)

### 8.1 Create Sandbox Testers

1. In App Store Connect, go to **"Users and Access"** (top menu)
2. Click **"Sandbox Testers"** tab
3. Click **"+"** to add a new tester
4. Fill in:
   - **First Name**: Test
   - **Last Name**: User
   - **Email**: Use a unique email (not your real Apple ID)
   - **Password**: Create a password
   - **Country/Region**: Select your test region
5. Click **"Invite"**

### 8.2 Test on Device

1. **Sign out** of your real Apple ID on your test device:
   - Settings → [Your Name] → Media & Purchases → Sign Out
2. Launch your app
3. When prompted to sign in for purchases, use the **Sandbox Tester** account
4. Test purchases will be **free** in Sandbox mode
5. Subscriptions will have **accelerated renewal** (e.g., 3-day trial renews in 1 hour)

### 8.3 Testing Checklist

- [ ] Monthly subscription can be purchased
- [ ] Yearly subscription can be purchased
- [ ] Free trial activates correctly (3 days)
- [ ] Subscription status updates in app
- [ ] Subscription appears in device Settings → [Your Name] → Subscriptions
- [ ] Subscription can be cancelled
- [ ] Restore purchases works
- [ ] Subscription renews automatically (test with accelerated timing)

---

## Step 9: Common Issues and Solutions

### Issue: "Products not available" or "No products found"

**Causes:**
- Product IDs don't match exactly
- Subscriptions not approved/ready
- Wrong bundle identifier
- Network issues

**Solutions:**
1. Verify Product IDs match exactly:
   - Code: `com.gofitai.premium.monthlyy` and `com.gofitai.premium.yearlyy`
   - App Store Connect: Must be identical
2. Check subscription status in App Store Connect (should be "Ready to Submit" or "Approved")
3. Verify bundle identifier: `com.rakshit.gofitai`
4. Wait 24-48 hours after creating subscriptions (Apple needs time to propagate)
5. Test in Sandbox mode first

### Issue: "Subscription not found"

**Solutions:**
- Ensure both subscriptions are in the **same Subscription Group**
- Check that subscriptions are **approved** or **ready for review**
- Verify Product IDs have no typos (especially the double 'y' in yearly: `yearlyy`)

### Issue: App Review Rejection - Missing Subscription Info

**Solutions:**
- Ensure `PaywallView` displays:
  - Subscription title
  - Subscription length (month/year)
  - Price
  - Price per unit (for yearly: "$1.67/month")
  - Terms of Use link (working)
  - Privacy Policy link (working)
- Add Terms of Use to App Description
- Add Privacy Policy URL in App Privacy section
- Upload subscription screenshots

### Issue: Free Trial Not Working

**Solutions:**
- Ensure Introductory Offer is configured in App Store Connect (3 days)
- Verify user hasn't used trial before (Apple tracks this per Apple ID)
- Test with a fresh Sandbox Tester account
- Check that trial duration matches in code and App Store Connect

### Issue: "Invalid Product ID"

**Solutions:**
- Product IDs must:
  - Use reverse domain notation (e.g., `com.company.product`)
  - Contain only lowercase letters, numbers, dots, and hyphens
  - Not contain spaces or special characters
  - Match exactly between code and App Store Connect

---

## Step 10: After Approval

Once subscriptions are approved:

1. **Test with Real Purchases** (small amount):
   - Make a test purchase with a real account
   - Verify subscription activates correctly
   - Check subscription status updates

2. **Monitor in App Store Connect**:
   - Go to **"Sales and Trends"** to see subscription metrics
   - Monitor subscription renewal rates
   - Track subscription cancellations

3. **Server-Side Validation** (if implemented):
   - Verify receipts on your backend
   - Handle subscription status changes
   - Sync subscription status with your database

4. **Handle Expiration Gracefully**:
   - Show paywall when trial/subscription expires
   - Allow users to restore purchases
   - Provide clear messaging about subscription benefits

---

## Quick Reference

### Product IDs (MUST MATCH EXACTLY)
- **Monthly**: `com.gofitai.premium.monthlyy`
- **Yearly**: `com.gofitai.premium.yearlyy`

### Prices
- **Monthly**: $1.99 USD
- **Yearly**: $19.99 USD

### Free Trial
- **Duration**: 3 days
- **Applies to**: Both subscriptions

### Required Links
- **Privacy Policy**: `https://gofitai.org/privacy-policy`
- **Terms of Use**: `https://gofitai.org/terms-and-conditions`

### Bundle Identifier
- **App**: `com.rakshit.gofitai`

---

## Important Notes

⚠️ **Product IDs Must Match Exactly**
- Any mismatch between code and App Store Connect will cause products to not load
- Double-check the yearly ID has two 'y's: `yearlyy`

⚠️ **Subscription Group**
- Both subscriptions MUST be in the same Subscription Group
- Users can only have one active subscription from a group at a time
- Upgrading/downgrading is handled automatically by Apple

⚠️ **Timing**
- After creating subscriptions, wait 24-48 hours before testing
- Subscriptions must be approved before they work in production
- Sandbox testing works immediately after creation

⚠️ **Review Screenshots**
- Required for subscription review
- Must show the subscription option in your app
- Minimum size: 640 x 920 pixels

⚠️ **Pricing**
- Set prices in your base currency (USD)
- App Store Connect will auto-calculate prices for other territories
- You can manually adjust prices per territory if needed

---

## Support Resources

- [Apple In-App Purchase Guide](https://developer.apple.com/in-app-purchase/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Subscription Best Practices](https://developer.apple.com/app-store/subscriptions/)
- [StoreKit 2 Documentation](https://developer.apple.com/documentation/storekit)

---

## Troubleshooting Checklist

If subscriptions aren't working:

1. ✅ Product IDs match exactly (check for typos)
2. ✅ Bundle identifier is correct (`com.rakshit.gofitai`)
3. ✅ Subscriptions are in "Ready to Submit" or "Approved" status
4. ✅ Both subscriptions are in the same Subscription Group
5. ✅ Free trial is configured (3 days)
6. ✅ Privacy Policy URL is added and working
7. ✅ Terms of Use link is in App Description
8. ✅ Subscription screenshots are uploaded
9. ✅ Testing with Sandbox Tester account
10. ✅ Waited 24-48 hours after creating subscriptions

If all of the above are correct and subscriptions still don't work, contact Apple Developer Support.
