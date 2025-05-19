import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthenticationService

    var body: some View {
        // Conditional view based on login state
        if authService.isLoggedIn {
            PersonalCabinetView()
        } else {
            LoginView()
        }
    }
}
