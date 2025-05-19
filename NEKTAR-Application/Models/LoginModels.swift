import SwiftUI

// Request body structure for login
struct LoginRequest: Codable {
    let email: String
    let password: String
}

// Success response structure for login
struct LoginSuccessResponse: Codable {
    let access_token: String
}

// Error response structure (matching your Flask's "msg")
struct LoginErrorResponse: Codable {
    let msg: String
}
