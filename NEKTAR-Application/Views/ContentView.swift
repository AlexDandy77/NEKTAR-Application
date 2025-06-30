import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthManager

    var body: some View {
        if authService.isLoggedIn {
			PersonalCabinetView(authService: authService)
        } else {
            LoginView()
        }
    }
}
