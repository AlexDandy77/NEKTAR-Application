import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthenticationService // Access the auth service

    @State private var email = ""
    @State private var password = ""
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var isLoading = false

    let loginURL = URL(string: "\(baseURLString)/auth/login")!

    var body: some View {
        NavigationView {
            ZStack {
                // Background Gradient
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                VStack(spacing: 25) {
                    // App Icon (Placeholder)
                    Image(systemName: "lock.shield.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.white)
                        .padding(.bottom, 30)

                    Text("Welcome Back!")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    // Email Input
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
                                .foregroundColor(.black) // Ensures text is black in both themes
                                .accentColor(.black) // Ensures caret is black in both themes
                        }
                        
                    }
                    .padding(EdgeInsets(top: 8, leading: 15, bottom: 8, trailing: 15))
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)


                    // Password Input
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
                                .foregroundColor(.black) // Ensures text is black in both themes
                                .accentColor(.black) // Ensures caret is black in both themes
                        }
                        
                    }
                    .padding(EdgeInsets(top: 8, leading: 15, bottom: 8, trailing: 15))
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)


                    // Login Button
                    Button(action: loginUser) {
                        HStack {
                            if isLoading {
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
                        .background(isLoading ? Color.gray : Color.blue)
                        .cornerRadius(12)
                        .shadow(color: Color.blue.opacity(0.5), radius: 10, x: 0, y: 5)
                    }
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
                    .padding(.top, 10)

                    Spacer()
                }
                .padding(.horizontal, 30)
                .padding(.top, 50) // Adjust top padding
            }
            .navigationBarHidden(true) // Hide navigation bar for a cleaner look
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Login Status"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
        .accentColor(.white) // For back button if navigation bar was visible
    }

    func loginUser() {
        guard !email.isEmpty, !password.isEmpty else {
            alertMessage = "Email and password cannot be empty."
            showAlert = true
            return
        }

        isLoading = true
        let loginCredentials = LoginRequest(email: email, password: password)

        guard let encodedCredentials = try? JSONEncoder().encode(loginCredentials) else {
            self.handleLoginError(message: "An internal error occurred (encoding).")
            return
        }

        var request = URLRequest(url: loginURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = encodedCredentials

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    self.handleLoginError(message: "Network error: \(error.localizedDescription)")
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse, let data = data else {
                    self.handleLoginError(message: "Invalid response from server.")
                    return
                }

                if httpResponse.statusCode == 200 {
                    do {
                        let decodedResponse = try JSONDecoder().decode(LoginSuccessResponse.self, from: data)
                        // On successful login, update the authService
                        authService.login(token: decodedResponse.access_token)
                    } catch {
                        self.handleLoginError(message: "Successfully logged in, but failed to parse token.")
                    }
                } else if httpResponse.statusCode == 401 {
                    do {
                        let errorResponse = try JSONDecoder().decode(LoginErrorResponse.self, from: data)
                        self.handleLoginError(message: errorResponse.msg) // "Bad credentials"
                    } catch {
                        self.handleLoginError(message: "Bad credentials (unable to parse error details).")
                    }
                } else {
                    self.handleLoginError(message: "Login failed. Status code: \(httpResponse.statusCode)")
                }
            }
        }.resume()
    }

    private func handleLoginError(message: String) {
        print("Login Error: \(message)")
        alertMessage = message
        showAlert = true
        isLoading = false
    }
}
