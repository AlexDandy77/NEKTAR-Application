import SwiftUI

let baseURLString = "http://ec2-56-228-42-67.eu-north-1.compute.amazonaws.com/api"

@main
struct NektarApplication: App {
    @StateObject var authService = AuthenticationService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
        }
    }
}
