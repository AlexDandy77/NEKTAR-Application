import SwiftUI

class AuthenticationService: ObservableObject {
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
