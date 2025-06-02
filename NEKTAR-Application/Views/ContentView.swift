import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthenticationService

    var body: some View {
        if authService.isLoggedIn {
            PersonalCabinetView()
        } else {
            LoginView()
        }
    }
}
