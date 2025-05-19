import SwiftUI

class AuthenticationService: ObservableObject {
    // @AppStorage will persist the token across app launches
    @AppStorage("authToken") var authToken: String?

    var isLoggedIn: Bool {
        authToken != nil
    }

    func login(token: String) {
        self.authToken = token
    }

    func logout() {
        self.authToken = nil
    }
}
