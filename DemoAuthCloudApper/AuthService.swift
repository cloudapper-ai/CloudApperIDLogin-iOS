import AppAuth
import Foundation

class AuthService {
    // MARK: - Properties

    /// A shared singleton instance for global access
    static let shared = AuthService()

    /// The current authentication state, securely stored and loaded.
    private(set) var authState: OIDAuthState?

    /// The OIDC service configuration
    private let configuration: OIDServiceConfiguration?
    /// The key for saving the auth state to UserDefaults
    private let kAuthStateKey = "com.cloudapper.authState"

    /// Retains the authorization flow session to be resumed by the AppDelegate
    var currentAuthorizationFlow: OIDExternalUserAgentSession?

    /// A computed property to quickly check if the user is authorized.
    var isLoggedIn: Bool {
        return authState?.isAuthorized ?? false
    }

    // MARK: - Initialization

    private init() {
        guard let authURL = URL(string: AuthConfiguration.baseUrl + AuthConfiguration.authUri),
              let tokenURL = URL(string: AuthConfiguration.baseUrl + AuthConfiguration.tokenUri),
              let endSessionURL = URL(string: AuthConfiguration.baseUrl + AuthConfiguration.endSessionUri) else {
            // If URLs are bad, log a critical error. The app will not crash,
            // but login/logout will fail until this is fixed.
            print("❌ CRITICAL ERROR: Invalid AuthConfiguration URLs. AuthService could not be initialized.")
            configuration = nil
            loadState() // Load state anyway
            return // Exit init
        }
        // Build the configuration once
        configuration = OIDServiceConfiguration(
            authorizationEndpoint: authURL,
            tokenEndpoint: tokenURL,
            issuer: nil,
            registrationEndpoint: nil,
            endSessionEndpoint: endSessionURL
        )

        // Load any saved state from the last session
        loadState()
    }

    // MARK: - Public API

    /**
     * Starts the login flow.
     * - Parameters:
     * - presentingVC: The view controller to present the SFSafariViewController from.
     * - completion: A closure called with the result of the login attempt.
     */
    func login(presentingVC: UIViewController, completion: @escaping (Result<Void, Error>) -> Void) {
        // --- Authorization Request (Same as before) ---
        guard let configuration = configuration else {
            print("❌ CRITICAL ERROR: Invalid configuration. login could not be initialized.")
            return
        }
        let request = OIDAuthorizationRequest(
            configuration: configuration,
            clientId: AuthConfiguration.clientId,
            clientSecret: nil,
            scopes: AuthConfiguration.scopes,
            redirectURL: URL(string: AuthConfiguration.callbackUrl)!,
            responseType: AuthConfiguration.responseType,
            additionalParameters: ["servicename": AuthConfiguration.servicename]
        )

        let agent = OIDExternalUserAgentIOSSafariViewController(presentingViewController: presentingVC)

        print("🚀 Starting authorization request (Step 1)...")

        // --- Step 1: Present the Authorization Request ---
        currentAuthorizationFlow = OIDAuthorizationService.present(request, externalUserAgent: agent) { [weak self] response, error in

            guard let self = self else { return }

            if let response = response {
                print("✅ Authorization successful (Step 1). Received code.")
                if let idToken = response.idToken {
                    print("   ID Token: \(idToken)")
                }

                // --- Step 2: Manually Perform Token Exchange ---
                self.performTokenExchange(response: response, completion: completion)

            } else if let error = error {
                print("❌ Authorization error (Step 1): \(error.localizedDescription)")
                self.clearState()
                completion(.failure(error))
            }
        }
    }

    /**
     * Starts the logout flow.
     * - Parameters:
     * - presentingVC: The view controller to present the SFSafariViewController from.
     * - completion: A closure called with an optional error if logout fails.
     */
    func logout(presentingVC: UIViewController, completion: @escaping (Error?) -> Void) {
        guard let authState = authState else {
            print("ℹ️ Already logged out.")
            completion(nil)
            return
        }
        guard let configuration = configuration else {
            print("❌ CRITICAL ERROR: Invalid configuration. login could not be initialized.")
            return
        }
        // Ensure we have the necessary components for a logout request
        guard let idToken = authState.lastTokenResponse?.idToken,
              let _ = configuration.endSessionEndpoint,
              let postLogoutRedirectURL = URL(string: AuthConfiguration.logoutCallbackUrl) else {
            print("❌ Cannot construct logout request. Clearing local state only.")
            clearState()
            completion(nil)
            return
        }

        // --- Create End Session (Logout) Request ---
        let request = OIDEndSessionRequest(
            configuration: configuration,
            idTokenHint: idToken,
            postLogoutRedirectURL: postLogoutRedirectURL,
            additionalParameters: ["redirect_uri": AuthConfiguration.logoutCallbackUrl] // Add any server-specific params here
        )

        let agent = OIDExternalUserAgentIOSSafariViewController(presentingViewController: presentingVC)

        print("🚀 Starting logout request...")

        // --- Present the Logout Request ---
        currentAuthorizationFlow = OIDAuthorizationService.present(request, externalUserAgent: agent) { [weak self] _, error in
            // Always clear local state regardless of server response
            print("✅ Logout complete. Clearing local state.")
            self?.clearState()
            completion(error)
        }
    }

    // MARK: - Private Helpers

    /**
     * Performs the token exchange (Step 2 of the login flow).
     */
    private func performTokenExchange(response: OIDAuthorizationResponse, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let tokenExchangeRequest = response.tokenExchangeRequest() else {
            print("❌ Error creating token exchange request")
            let error = NSError(domain: "com.cloudapper.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create token request."])
            completion(.failure(error))
            return
        }

        print("🚀 Performing token exchange (Step 2)...")

        OIDAuthorizationService.perform(tokenExchangeRequest) { [weak self] tokenResponse, tokenError in

            guard let self = self else { return }

            if let tokenResponse = tokenResponse {
                // Success! Create and save the final authState
                let finalAuthState = OIDAuthState(authorizationResponse: response, tokenResponse: tokenResponse)
                self.setAuthState(finalAuthState)

                print("✅ Token exchange successful (Step 2).")
                print("   AccessToken: \(tokenResponse.accessToken ?? "nil")")
                completion(.success(()))

            } else if let tokenError = tokenError {
                // Token exchange failed - this is often a server-side config issue
                print("❌ Token exchange error (Step 2): \(tokenError.localizedDescription)")
                self.clearState()
                completion(.failure(tokenError))
            }
        }
    }

    // MARK: - Persistence

    private func setAuthState(_ authState: OIDAuthState?) {
        self.authState = authState
        saveState()
    }

    private func saveState() {
        guard let authState = authState else {
            clearState() // If authState is nil, clear any saved state
            return
        }

        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: authState, requiringSecureCoding: true)
            UserDefaults.standard.set(data, forKey: kAuthStateKey)
            print("💾 AuthState saved successfully.")
        } catch {
            print("❌ Failed to save authState: \(error)")
        }
    }

    private func loadState() {
        guard let data = UserDefaults.standard.data(forKey: kAuthStateKey) else {
            return
        }

        do {
            let authState = try NSKeyedUnarchiver.unarchivedObject(ofClass: OIDAuthState.self, from: data)
            self.authState = authState
            print("✅ AuthState loaded successfully.")
        } catch {
            print("❌ Failed to load authState: \(error)")
            // Clear corrupted data
            clearState()
        }
    }

    private func clearState() {
        UserDefaults.standard.removeObject(forKey: kAuthStateKey)
        authState = nil
        print("🗑️ AuthState cleared.")
    }
}
