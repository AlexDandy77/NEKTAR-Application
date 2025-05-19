import SwiftUI

let baseURLString = "http://127.0.0.1:5000"

@main
struct NektarApplication: App {
    @StateObject var authService = AuthenticationService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService) // Provide authService to the environment
        }
    }
}
