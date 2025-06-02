import SwiftUI

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct LoginSuccessResponse: Codable {
    let access_token: String
}

struct LoginErrorResponse: Codable {
    let msg: String
}
