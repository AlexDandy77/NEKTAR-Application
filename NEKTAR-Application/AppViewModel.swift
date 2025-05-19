import Foundation

class AppViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false

    init() {
        // Check if token exists at app start
        if let _ = UserDefaults.standard.string(forKey: "authToken") {
            isLoggedIn = true
        }
    }

    func logout() {
        UserDefaults.standard.removeObject(forKey: "authToken")
        isLoggedIn = false
    }

    func loginSucceeded(withToken token: String) {
        UserDefaults.standard.set(token, forKey: "authToken")
        isLoggedIn = true
    }
}
