import Foundation
import AuthenticationServices
import CryptoKit

@MainActor
final class AppleSignInService: NSObject {
    static let shared = AppleSignInService()
    
    private var currentNonce: String?
    private var completionHandler: ((Result<AppleSignInResult, Error>) -> Void)?
    
    private override init() {
        super.init()
    }
    
    // Start Sign in with Apple flow
    func signIn() async throws -> AppleSignInResult {
        return try await withCheckedThrowingContinuation { continuation in
            let nonce = randomNonceString()
            currentNonce = nonce
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(nonce)
            
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            
            completionHandler = { result in
                continuation.resume(with: result)
            }
            
            authorizationController.performRequests()
        }
    }
    
    // Generate random nonce for security
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    // SHA256 hash for nonce
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AppleSignInService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                completionHandler?(.failure(NSError(domain: "AppleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid state: A login callback was received, but no login request was sent."])))
                return
            }
            
            guard let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                completionHandler?(.failure(NSError(domain: "AppleSignIn", code: -2, userInfo: [NSLocalizedDescriptionKey: "Unable to fetch identity token"])))
                return
            }
            
            // Extract user information
            var email: String?
            var fullName: String?
            
            if let emailValue = appleIDCredential.email {
                email = emailValue
            }
            
            if let fullNameValue = appleIDCredential.fullName {
                let formatter = PersonNameComponentsFormatter()
                fullName = formatter.string(from: fullNameValue)
            }
            
            let userIdentifier = appleIDCredential.user
            
            let result = AppleSignInResult(
                userIdentifier: userIdentifier,
                idToken: idTokenString,
                email: email,
                fullName: fullName,
                nonce: nonce
            )
            
            completionHandler?(.success(result))
            completionHandler = nil
            currentNonce = nil
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        #if DEBUG
        if let authError = error as? ASAuthorizationError {
            print("❌ Apple Sign In error: \(authError.localizedDescription)")
            print("   Error code: \(authError.code.rawValue)")
            print("   Error domain: \(authError.localizedDescription)")
        } else {
            print("❌ Apple Sign In error: \(error.localizedDescription)")
        }
        #endif
        
        // Provide more helpful error messages
        var userFriendlyError = error
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .unknown:
                userFriendlyError = NSError(domain: "AppleSignIn", code: authError.code.rawValue, userInfo: [NSLocalizedDescriptionKey: "Apple Sign In failed. Please ensure Sign in with Apple is enabled in your app settings."])
            case .canceled:
                userFriendlyError = NSError(domain: "AppleSignIn", code: authError.code.rawValue, userInfo: [NSLocalizedDescriptionKey: "Apple Sign In was canceled."])
            case .invalidResponse:
                userFriendlyError = NSError(domain: "AppleSignIn", code: authError.code.rawValue, userInfo: [NSLocalizedDescriptionKey: "Invalid response from Apple. Please try again."])
            case .notHandled:
                userFriendlyError = NSError(domain: "AppleSignIn", code: authError.code.rawValue, userInfo: [NSLocalizedDescriptionKey: "Apple Sign In could not be handled. Please check your app configuration."])
            case .failed:
                userFriendlyError = NSError(domain: "AppleSignIn", code: authError.code.rawValue, userInfo: [NSLocalizedDescriptionKey: "Apple Sign In failed. Please try again."])
            @unknown default:
                break
            }
        }
        
        completionHandler?(.failure(userFriendlyError))
        completionHandler = nil
        currentNonce = nil
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AppleSignInService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Get the key window more reliably
        if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
            return window
        }
        
        // Fallback: get any window from any scene
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window
        }
        
        // Last resort: get any available window (shouldn't happen in normal flow)
        #if DEBUG
        print("⚠️ Warning: No window found for Apple Sign In presentation. Using first available window.")
        #endif
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return windowScene?.windows.first ?? UIWindow()
    }
}

// MARK: - Result Model
struct AppleSignInResult {
    let userIdentifier: String
    let idToken: String
    let email: String?
    let fullName: String?
    let nonce: String
}

