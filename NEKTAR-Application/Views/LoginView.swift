import SwiftUI

struct LoginView: View {
	@EnvironmentObject var authService: AuthManager

	@State private var email = ""
	@State private var password = ""
	@State private var showAlert = false

	var body: some View {
		NavigationView {
			ZStack {
				LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]),
							   startPoint: .topLeading,
							   endPoint: .bottomTrailing)
					.ignoresSafeArea()

				VStack(spacing: 25) {
					Image(systemName: "lock.shield.fill")
						.resizable()
						.scaledToFit()
						.frame(width: 100, height: 100)
						.foregroundColor(.white)
						.padding(.bottom, 30)

					Text("Welcome Back!")
						.font(.system(size: 32, weight: .bold, design: .rounded))
						.foregroundColor(.white)

					HStack {
						Image(systemName: "envelope.fill")
							.foregroundColor(.gray)
						ZStack(alignment: .leading) {
							if email.isEmpty {
								Text("Email")
									.foregroundColor(.gray)
									.padding(12)
							}
							TextField("", text: $email)
								.padding(12)
								.keyboardType(.emailAddress)
								.autocapitalization(.none)
								.textContentType(.emailAddress)
								.foregroundColor(.black)
								.accentColor(.black)
						}
					}
					.padding(EdgeInsets(top: 8, leading: 15, bottom: 8, trailing: 15))
					.background(Color.white.opacity(0.9))
					.cornerRadius(12)
					.shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)

					HStack {
						Image(systemName: "lock.fill")
							.foregroundColor(.gray)
						ZStack(alignment: .leading) {
							if password.isEmpty {
								Text("Password")
									.foregroundColor(.gray)
									.padding(12)
							}
							SecureField("", text: $password)
								.padding(12)
								.textContentType(.password)
								.foregroundColor(.black)
								.accentColor(.black)
						}
					}
					.padding(EdgeInsets(top: 8, leading: 15, bottom: 8, trailing: 15))
					.background(Color.white.opacity(0.9))
					.cornerRadius(12)
					.shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)

					Button(action: {
						Task {
							await authService.login(email: email, password: password)
						}
					}) {
						HStack {
							if authService.isLoading {
								ProgressView()
									.progressViewStyle(CircularProgressViewStyle(tint: .white))
									.padding(.trailing, 5)
								Text("Logging In...")
							} else {
								Image(systemName: "arrow.right.to.line.alt")
								Text("Login")
							}
						}
						.font(.headline)
						.frame(maxWidth: .infinity)
						.padding()
						.foregroundColor(.white)
						.background(authService.isLoading ? Color.gray : Color.blue)
						.cornerRadius(12)
						.shadow(color: Color.blue.opacity(0.5), radius: 10, x: 0, y: 5)
					}
					.disabled(authService.isLoading || email.isEmpty || password.isEmpty)
					.padding(.top, 10)

					Spacer()
				}
				.padding(.horizontal, 30)
				.padding(.top, 50)
			}
			.navigationBarHidden(true)
			.alert(isPresented: Binding(
				get: { authService.errorMessage != nil || showAlert },
				set: {
					if !$0 {
						authService.errorMessage = nil
						showAlert = false
					}
				}
			)) {
				Alert(
					title: Text("Login Status"),
					message: Text(authService.errorMessage ?? "Email and password cannot be empty."),
					dismissButton: .default(Text("OK"))
				)
			}
		}
		.accentColor(.white)
	}
}
