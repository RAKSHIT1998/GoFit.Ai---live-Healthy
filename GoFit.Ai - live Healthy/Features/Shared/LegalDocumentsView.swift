import SwiftUI

// MARK: - Privacy Policy View
struct PrivacyPolicyView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        Text("Privacy Policy")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Last Updated: March 5, 2026")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("GoFit.AI (\"we\", \"our\", or \"us\") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application GoFit.AI - Live Healthy (the \"App\").")
                    }
                    
                    sectionHeader("1. Information We Collect")
                    
                    sectionSubheader("1.1 Personal Information")
                    bulletList([
                        "Name and email address (when you create an account)",
                        "Profile information (age, gender, weight, height, fitness goals)",
                        "Health and fitness data (workouts, nutrition logs, daily activity)",
                        "Photos (only when you use meal scanning features, processed locally or via AI)"
                    ])
                    
                    sectionSubheader("1.2 Automatically Collected Information")
                    bulletList([
                        "Device information (model, operating system version)",
                        "App usage data and analytics",
                        "Apple HealthKit data (only with your explicit permission)"
                    ])
                    
                    sectionSubheader("1.3 HealthKit Data")
                    Text("We request access to Apple HealthKit data including steps, active energy, workouts, heart rate, and other fitness metrics. This data is used solely to provide personalized fitness recommendations and tracking within the App. We do not sell HealthKit data or use it for advertising purposes. HealthKit data is stored locally on your device and is not shared with third parties.")
                    
                    sectionHeader("2. How We Use Your Information")
                    bulletList([
                        "Provide, maintain, and improve our services",
                        "Personalize your fitness and nutrition recommendations",
                        "Process your AI-powered meal scans and workout suggestions",
                        "Manage your account and provide customer support",
                        "Send notifications related to your fitness goals (with your permission)",
                        "Analyze usage patterns to improve the App experience"
                    ])
                    
                    sectionHeader("3. AI Services and Data Processing")
                    Text("Our App uses artificial intelligence services (including Google Gemini) to provide meal analysis, workout recommendations, and personalized health insights. When you use these features:")
                    bulletList([
                        "Photos submitted for meal scanning are processed by AI services to identify food items and estimate nutritional content",
                        "Your fitness profile data may be used to generate personalized recommendations",
                        "AI-processed data is used solely to provide App functionality and is not used for advertising",
                        "You can review our AI Data Usage policy within the App settings"
                    ])
                    
                    sectionHeader("4. Data Sharing and Disclosure")
                    Text("We do not sell your personal information. We may share information in the following circumstances:")
                    bulletList([
                        "With service providers who assist in operating the App (e.g., cloud hosting, AI processing)",
                        "When required by law or to respond to legal processes",
                        "To protect the rights, property, or safety of our users",
                        "With your consent or at your direction"
                    ])
                    
                    sectionHeader("5. Data Storage and Security")
                    bulletList([
                        "Personal data is stored securely using industry-standard encryption",
                        "Health and fitness data is primarily stored locally on your device",
                        "We use secure HTTPS connections for all data transmission",
                        "We implement appropriate technical and organizational measures to protect your data"
                    ])
                    
                    sectionHeader("6. Your Rights and Choices")
                    bulletList([
                        "Access, update, or delete your personal information through the App settings",
                        "Revoke HealthKit permissions at any time through iOS Settings",
                        "Opt out of notifications through iOS Settings",
                        "Request data export or account deletion within the App",
                        "Withdraw consent for AI data processing at any time"
                    ])
                    
                    sectionHeader("7. Children's Privacy")
                    Text("The App is not intended for children under 13. We do not knowingly collect information from children under 13. If you believe we have collected information from a child under 13, please contact us so we can delete it.")
                    
                    sectionHeader("8. Subscriptions and Purchases")
                    Text("When you subscribe to GoFit.AI Premium, payment is processed by Apple through the App Store. We do not collect or store your payment information. Subscription management and billing inquiries should be directed to Apple.")
                    
                    sectionHeader("9. Changes to This Policy")
                    Text("We may update this Privacy Policy from time to time. We will notify you of any material changes by posting the updated policy in the App. Your continued use of the App after changes constitutes acceptance of the updated policy.")
                    
                    sectionHeader("10. Contact Us")
                    Text("If you have questions about this Privacy Policy or our data practices, please contact us at:")
                    Text("Email: support@gofitai.org")
                        .foregroundColor(.accentColor)
                    
                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .background(Color(uiColor: .systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.accentColor)
                }
            }
        }
    }
    
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.title3)
            .fontWeight(.semibold)
            .padding(.top, 8)
    }
    
    private func sectionSubheader(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .fontWeight(.medium)
    }
    
    private func bulletList(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(item)
                        .foregroundColor(.primary)
                }
            }
        }
    }
}

// MARK: - Terms of Use (EULA) View
struct TermsOfUseView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        Text("Terms of Use")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Last Updated: March 5, 2026")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Please read these Terms of Use (\"Terms\") carefully before using the GoFit.AI - Live Healthy mobile application (the \"App\") operated by GoFit.AI (\"we\", \"our\", or \"us\"). By downloading, installing, or using the App, you agree to be bound by these Terms.")
                    }
                    
                    sectionHeader("1. Acceptance of Terms")
                    Text("By accessing or using the App, you agree to these Terms and our Privacy Policy. If you do not agree to these Terms, do not use the App.")
                    
                    sectionHeader("2. Description of Service")
                    Text("GoFit.AI is a health and fitness application that provides:")
                    bulletList([
                        "AI-powered meal scanning and nutritional analysis",
                        "Personalized workout recommendations",
                        "Fitness and health tracking",
                        "Integration with Apple HealthKit",
                        "Premium subscription features"
                    ])
                    
                    sectionHeader("3. Account Registration")
                    bulletList([
                        "You must create an account to use certain features of the App",
                        "You are responsible for maintaining the confidentiality of your account credentials",
                        "You agree to provide accurate and complete information",
                        "You must be at least 13 years old to create an account"
                    ])
                    
                    sectionHeader("4. Subscriptions and Payments")
                    
                    sectionSubheader("4.1 Premium Subscription")
                    Text("GoFit.AI offers auto-renewable subscription plans that provide access to premium features:")
                    bulletList([
                        "Monthly Plan: Billed monthly at the current listed price",
                        "Yearly Plan: Billed annually at the current listed price",
                        "A 3-day free trial is available for new subscribers"
                    ])
                    
                    sectionSubheader("4.2 Billing")
                    bulletList([
                        "Payment is charged to your Apple ID account upon confirmation of purchase",
                        "Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current period",
                        "Your account will be charged for renewal within 24 hours prior to the end of the current period",
                        "The renewal price will be the same as the original subscription price unless we notify you of a price change"
                    ])
                    
                    sectionSubheader("4.3 Free Trial")
                    Text("If offered, the free trial period lasts 3 days. If you do not cancel before the trial ends, your subscription will automatically begin and you will be charged. You can cancel during the trial at no cost.")
                    
                    sectionSubheader("4.4 Cancellation")
                    Text("You can cancel your subscription at any time through your Apple ID Settings. Cancellation takes effect at the end of the current billing period. No refunds are provided for partial periods. To manage or cancel subscriptions, go to Settings > [Your Name] > Subscriptions on your device.")
                    
                    sectionHeader("5. Health Disclaimer")
                    Text("IMPORTANT: The App is designed for general fitness and wellness purposes only.")
                        .fontWeight(.semibold)
                    bulletList([
                        "The App does not provide medical advice, diagnosis, or treatment",
                        "AI-generated meal analyses and workout recommendations are estimates and should not replace professional medical or nutritional advice",
                        "Consult your physician before starting any new exercise or diet program",
                        "If you have a medical condition, consult your healthcare provider before using the App",
                        "We are not responsible for any health outcomes resulting from use of the App"
                    ])
                    
                    sectionHeader("6. User Conduct")
                    Text("You agree not to:")
                    bulletList([
                        "Use the App for any unlawful purpose",
                        "Attempt to reverse engineer or modify the App",
                        "Interfere with the App's functionality or security",
                        "Share your account with others or create multiple accounts",
                        "Upload harmful, offensive, or inappropriate content"
                    ])
                    
                    sectionHeader("7. Intellectual Property")
                    Text("All content, features, and functionality of the App (including but not limited to design, text, graphics, logos, and software) are owned by GoFit.AI and are protected by copyright, trademark, and other intellectual property laws.")
                    
                    sectionHeader("8. Limitation of Liability")
                    Text("To the maximum extent permitted by applicable law, GoFit.AI shall not be liable for any indirect, incidental, special, consequential, or punitive damages, or any loss of profits or revenues, whether incurred directly or indirectly, or any loss of data, use, goodwill, or other intangible losses resulting from your use of the App.")
                    
                    sectionHeader("9. Disclaimer of Warranties")
                    Text("The App is provided \"as is\" and \"as available\" without warranties of any kind, either express or implied, including but not limited to implied warranties of merchantability, fitness for a particular purpose, and non-infringement.")
                    
                    sectionHeader("10. Modifications to Terms")
                    Text("We reserve the right to modify these Terms at any time. We will provide notice of material changes through the App. Your continued use after such modifications constitutes acceptance of the updated Terms.")
                    
                    sectionHeader("11. Termination")
                    Text("We may terminate or suspend your account and access to the App at our sole discretion, without notice, for conduct that we believe violates these Terms or is harmful to other users, us, or third parties.")
                    
                    sectionHeader("12. Governing Law")
                    Text("These Terms shall be governed by and construed in accordance with applicable laws, without regard to conflict of law provisions.")
                    
                    sectionHeader("13. Contact Us")
                    Text("If you have questions about these Terms, please contact us at:")
                    Text("Email: support@gofitai.org")
                        .foregroundColor(.accentColor)
                    
                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .background(Color(uiColor: .systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.accentColor)
                }
            }
        }
    }
    
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.title3)
            .fontWeight(.semibold)
            .padding(.top, 8)
    }
    
    private func sectionSubheader(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .fontWeight(.medium)
    }
    
    private func bulletList(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(item)
                        .foregroundColor(.primary)
                }
            }
        }
    }
}

// MARK: - Previews
#Preview("Privacy Policy") {
    PrivacyPolicyView()
}

#Preview("Terms of Use") {
    TermsOfUseView()
}
