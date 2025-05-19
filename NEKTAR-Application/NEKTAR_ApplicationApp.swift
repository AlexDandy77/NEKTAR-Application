import SwiftUI

@main
struct NEKTAR_ApplicationApp: App {
    @StateObject var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            if viewModel.isLoggedIn {
                PersonalCabinetView()
                    .environmentObject(viewModel)
            } else {
                LoginView()
                    .environmentObject(viewModel)
            }
        }
    }
}
