//
//  Untitled.swift
//  DemoAuthCloudApper
//
//  Created by Sanzid on 23/10/25.
//

struct AuthConfiguration {
    // Note: The information in this document is provided by CloudApper AI.
    static let baseUrl = "" // The base URL of the identity provider (authorization server).
    static let authUri = "" // The path to the authorization endpoint, appended to baseUrl.
    static let tokenUri = "" // The path to the token endpoint, used for exchanging codes for tokens.
    static let endSessionUri = "" // The path to the end session (logout) endpoint.
    static let scopes = [""] // The list of permissions (scopes) the app is requesting.
    static let clientId = "" // The unique identifier for this client application.
    static let clientSecret = "" // The client secret (often empty for public clients like mobile apps).
    static let callbackUrl = "" // The redirect URI the provider sends the authorization code to (must be registered).
    static let logoutCallbackUrl = "" // The redirect URI the provider sends the user to after logging out.
    static let servicename = "" // A service name, often used for showing branding app, if not provided make it empty .
    static let responseType = ""
}
