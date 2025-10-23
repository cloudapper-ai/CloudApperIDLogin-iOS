# OAuth2 Implementation With OpenID Library

This document explains, step-by-step, how the provided iOS implementation uses the AppAuth **(OpenID/OAuth2)** library to authenticate users, exchange authorization codes for tokens, store tokens securely, and log users out.

# Overview

This code explains how to implement `OAuth2 and OpenID` Connect authentication in an iOS application using the AppAuth library `(net.openid:AppAuth 2.0.0)`. Rather than focusing on the user interface, this guide walks through how AppAuth is configured, initialized, and integrated into your authentication flow.

# 1- What is AppAuth?
 
AppAuth for iOS is an open-source library maintained by the OpenID Foundation that provides standards-compliant support for OAuth 2.0 and OpenID Connect (OIDC). It handles complex flows such as:

1. Authorization Code Flow (with PKCE)
2. Token exchange and refresh
3. End session (logout)
4. Secure browser-based login using the safari
5. This library ensures that apps adhere to security best practices and do not handle sensitive credentials directly.

# 2 — Dependency Setup

AppAuth supports four options for dependency management.

CocoaPods

```
  pod 'AppAuth'

```
Swift Package Manager

```
dependencies: [
    .package(url: "https://github.com/openid/AppAuth-iOS.git", .upToNextMajor(from: "2.0.0"))
]

```

- This makes the AppAuth classes (AuthorizationService, AuthorizationRequest, AuthorizationResponse, EndSessionRequest, etc.) available in your project.
