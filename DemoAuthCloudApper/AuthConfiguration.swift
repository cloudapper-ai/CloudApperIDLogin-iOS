//
//  Untitled.swift
//  DemoAuthCloudApper
//
//  Created by Sanzid on 23/10/25.
//

struct AuthConfiguration {
    static let baseUrl = "https://dev-account.cloudapper.com/" // The base URL of the identity provider (authorization server).
    static let authUri = "connect/authorize" // The path to the authorization endpoint, appended to baseUrl.
    static let tokenUri = "connect/token" // The path to the token endpoint, used for exchanging codes for tokens.
    static let endSessionUri = "connect/endsession" // The path to the end session (logout) endpoint.
    static let scopes = ["openid", "email", "profile", "roles", "ko_webapi_v2", "offline_access", "marketplace_api"] // The list of permissions (scopes) the app is requesting.
    static let clientId = "ios-client" // The unique identifier for this client application.
    static let clientSecret = "" // The client secret (often empty for public clients like mobile apps).
    static let callbackUrl = "com.cloudapper.auth:/oauth2redirect" // The redirect URI the provider sends the authorization code to (must be registered).
    static let logoutCallbackUrl = "com.cloudapper.auth2:/logout" // The redirect URI the provider sends the user to after logging out.
    static let servicename = "cloudapper" // A service name, often used for storing credentials (e.g., in Keychain).
    static let responseType = "code id_token"
}
