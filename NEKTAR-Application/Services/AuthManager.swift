import SwiftUI
import Foundation

class AuthManager: ObservableObject {
	@AppStorage("authToken") var authToken: String?
	@Published var isLoading: Bool = false
	@Published var errorMessage: String? = nil

	var isLoggedIn: Bool {
		authToken != nil
	}

	@MainActor
	func login(email: String, password: String) async {
		self.isLoading = true
		self.errorMessage = nil

		let loginURL = URL(string: "\(baseURLString)/auth/login")!
		let loginCredentials = LoginRequest(email: email, password: password)

		do {
			let response: LoginSuccessResponse = try await NetworkService.shared.request(
				url: loginURL,
				method: "POST",
				body: loginCredentials
			)
			self.authToken = response.access_token
		} catch let error as NetworkError {
			self.errorMessage = error.localizedDescription
			if case .unauthorized = error {
				self.authToken = nil
			}
		} catch {
			self.errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
		}
		self.isLoading = false
	}

	func logout() {
		self.authToken = nil
	}
}
