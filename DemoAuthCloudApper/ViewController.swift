import AppAuth
import UIKit

class ViewController: UIViewController {

    // MARK: - UI Properties
    
    private let welcomeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = .darkGray
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var loginButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("Login", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        button.backgroundColor = .systemGreen
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.darkGray.cgColor
        button.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var logoutButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("Logout", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        button.backgroundColor = .systemRed
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.darkGray.cgColor
        button.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
        return button
    }()
    
    // --- Updated Token Buttons ---
    
    private lazy var showAccessTokenButton: UIButton = {
        let button = UIButton(type: .custom) // Changed to .custom
        button.setTitle("Access Token", for: .normal) // Shortened title
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold) // Slightly smaller font
        button.backgroundColor = .systemBlue // New color
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.darkGray.cgColor
        button.addTarget(self, action: #selector(showAccessTokenTapped), for: .touchUpInside)
        return button
    }()

    private lazy var showRefreshTokenButton: UIButton = {
        let button = UIButton(type: .custom) // Changed to .custom
        button.setTitle("Refresh Token", for: .normal) // Shortened title
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold) // Slightly smaller font
        button.backgroundColor = .systemOrange // New color
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.darkGray.cgColor
        button.addTarget(self, action: #selector(showRefreshTokenTapped), for: .touchUpInside)
        return button
    }()
    
    // This stack view will hold the new token buttons
    private lazy var tokenButtonsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical // Changed to vertical for better fit
        stack.spacing = 15 // Added spacing
        stack.alignment = .fill // Changed to fill
        stack.distribution = .fillEqually
        return stack
    }()

    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateUI()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .white

        // 1. Create a horizontal stack for the login/logout buttons
        let authButtonStack = UIStackView(arrangedSubviews: [loginButton, logoutButton])
        authButtonStack.axis = .horizontal
        authButtonStack.spacing = 20
        authButtonStack.alignment = .center
        authButtonStack.distribution = .fillEqually // Make buttons same size

        // 2. Add token buttons to their stack
        tokenButtonsStack.addArrangedSubview(showAccessTokenButton)
        tokenButtonsStack.addArrangedSubview(showRefreshTokenButton)
        
        // 3. Create a vertical stack for the label and all button stacks
        //    Order: Label, Token Buttons, Auth Buttons
        let mainStack = UIStackView(arrangedSubviews: [welcomeLabel, tokenButtonsStack, authButtonStack])
        mainStack.axis = .vertical
        mainStack.spacing = 30 // Adjusted spacing
        mainStack.alignment = .center
        
        // 4. Add the main stack to the view and set constraints
        view.addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            mainStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mainStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            // Constrain width of the main stack
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            // Ensure auth buttons fill the stack width
            authButtonStack.widthAnchor.constraint(equalTo: mainStack.widthAnchor),
            tokenButtonsStack.widthAnchor.constraint(equalTo: mainStack.widthAnchor)
        ])
    }
    
    /**
     * Updates the UI elements based on the current authentication state.
     */
    private func updateUI() {
        let isLoggedIn = AuthService.shared.isLoggedIn
        
        loginButton.isHidden = isLoggedIn
        logoutButton.isHidden = !isLoggedIn
        
        // --- Update ---
        // Also hide or show the token buttons stack based on login state
        tokenButtonsStack.isHidden = !isLoggedIn
        
        if isLoggedIn {
            welcomeLabel.text = "Welcome! You are logged in."
        } else {
            welcomeLabel.text = "Welcome to CloudApper"
        }
    }
    
    // MARK: - Button Actions

    @objc func loginTapped() {
        AuthService.shared.login(presentingVC: self) { [weak self] result in
            // IMPORTANT: Ensure all UI updates are on the main thread
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("✅ Login flow successful.")
                    self?.updateUI()
                case .failure(let error):
                    print("❌ Login flow failed: \(error.localizedDescription)")
                    self?.showErrorAlert(error: error)
                    self?.updateUI()
                }
            }
        }
    }
    
    @objc func logoutTapped() {
        AuthService.shared.logout(presentingVC: self) { [weak self] error in
            // IMPORTANT: Ensure all UI updates are on the main thread
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Logout flow failed: \(error.localizedDescription)")
                    self?.showErrorAlert(error: error)
                } else {
                    print("✅ Logout flow successful.")
                }
                // Always update UI after logout attempt
                self?.updateUI()
            }
        }
    }
    
    // --- New Button Actions ---
    
    @objc func showAccessTokenTapped() {
        let token = AuthService.shared.authState?.lastTokenResponse?.accessToken
        showTokenAlert(title: "Access Token", token: token)
    }
    
    @objc func showRefreshTokenTapped() {
        // Note: Refresh tokens are often nil for the "implicit" flow.
        // They are typically only returned in the "authorization code" or "hybrid" flows.
        let token = AuthService.shared.authState?.lastTokenResponse?.refreshToken
        showTokenAlert(title: "Refresh Token", token: token)
    }

    
    // MARK: - Helper
    
    private func showErrorAlert(error: Error) {
        // Don't show an alert if the user just canceled the flow
        let oidError = error as NSError
        if oidError.domain == OIDGeneralErrorDomain && oidError.code == OIDErrorCode.userCanceledAuthorizationFlow.rawValue {
            print("ℹ️ User canceled authorization flow.")
            return
        }
        
        let alert = UIAlertController(
            title: "Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }
    
    // --- New Helper Function ---
    
    /**
     * Presents an alert to display a token.
     * Includes a "Copy" button.
     */
    private func showTokenAlert(title: String, token: String?) {
        // Use a default message if the token is nil
        let message = token ?? "N/A (Not Available)"
        
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        
        // Add a "Copy" action only if the token exists
        if let tokenToCopy = token {
            alert.addAction(UIAlertAction(title: "Copy", style: .default, handler: { _ in
                UIPasteboard.general.string = tokenToCopy
            }))
        }
        
        // Add an "OK" action
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        
        self.present(alert, animated: true)
    }
}

