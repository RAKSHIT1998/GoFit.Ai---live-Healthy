# Privacy Policy Setup Guide

## ✅ Privacy Policy Has Been Created

Your privacy policy is now available at:
- **Local:** `backend/public/privacy.html`
- **Live URL:** `https://gofit-ai-live-healthy-1.onrender.com/privacy`

## 📝 The Privacy Policy Includes:

✅ **AI Data Usage Section** (Google Gemini AI)
- What data is sent (photos, timestamps, meal type)
- What data is NOT sent (no PII, location, health records)
- How AI processes data
- User consent requirements
- Privacy protections
- Links to Google's privacy policies
- User rights (opt-out, delete, disable)

✅ **Medical Citations**
- References to scientific sources
- Links to Mifflin-St Jeor equation, WHO, USDA, etc.
- Medical disclaimer

✅ **Standard Privacy Sections**
- Information we collect
- How we use information
- Data storage and security
- Data sharing policies
- HealthKit integration
- User rights (access, correction, deletion, export)
- Children's privacy
- Subscription/payment data
- Contact information

## 🚀 To Deploy:

The privacy policy will automatically be available once you deploy to Render:

1. **Commit your changes:**
```bash
cd "/Users/rakshitbargotra/Documents/GoFit.Ai - live Healthy"
git add backend/public/privacy.html backend/server.js
git commit -m "Add comprehensive privacy policy with AI data disclosure"
git push
```

2. **Render will automatically redeploy** (if auto-deploy is enabled)
   - Or manually deploy in Render dashboard

3. **Verify it's live:**
   - Visit: https://gofit-ai-live-healthy-1.onrender.com/privacy
   - Should see the full privacy policy page

## 🔗 Where the Privacy Policy is Linked:

✅ **In the iOS app:**
- Settings → Privacy & Data → "Privacy Policy" (opens in browser)
- AI Consent screen → "View Full Privacy Policy" button
- File: `Features/Authentication/ProfileView.swift` (line ~785)

✅ **In App Store Connect:**
- Add this URL to your app's privacy policy field
- URL: `https://gofit-ai-live-healthy-1.onrender.com/privacy`

## 📱 Testing:

**Test in app:**
1. Open GoFit.Ai
2. Go to Settings/Profile tab
3. Tap "Privacy Policy" under Privacy & Data section
4. Should open the privacy policy in Safari

**Test in browser:**
1. Open: https://gofit-ai-live-healthy-1.onrender.com/privacy
2. Verify all sections are visible
3. Test that all external links work (Google, PubMed, WHO, etc.)

## ✏️ To Update Privacy Policy:

Simply edit: `backend/public/privacy.html`

The file is plain HTML, so you can:
- Update text directly
- Add new sections
- Change links
- Modify styling in the `<style>` section

After editing, commit and push to deploy changes.

## 📋 App Store Connect Instructions:

When submitting to App Store:

1. **App Privacy** section:
   - Add privacy policy URL: `https://gofit-ai-live-healthy-1.onrender.com/privacy`

2. **Data Types to Declare:**
   - ✅ Health & Fitness (nutrition, workouts)
   - ✅ Photos (optional, for meal scanner)
   - ✅ User ID (for account)
   - ✅ Email Address (for authentication)

3. **Third-Party Analytics/Advertising:**
   - Declare: Google Gemini AI (for food photo analysis)
   - Purpose: App Functionality
   - Data linked to user: No (photos not linked to identity)

4. **Review Notes:**
   - Include: "Privacy policy available at [URL]"
   - Include: "AI consent shown before any photo upload"

## ✅ Compliance Checklist:

- [x] Privacy policy created with AI data disclosure
- [x] Privacy policy accessible via URL
- [x] Privacy policy linked in app Settings
- [x] AI service clearly identified (Google Gemini)
- [x] Data disclosure complete (what is/isn't sent)
- [x] User consent flow implemented
- [x] Medical citations included
- [x] Contact information provided
- [x] Data retention policies stated
- [x] User rights explained

**Status:** ✅ Ready for deployment and App Store submission
