import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoggedIn = false

    var body: some View {
        VStack {
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            Button("Login") {
                login()
            }
            .padding()

            Text(errorMessage).foregroundColor(.red)
        }
        .padding()
        .fullScreenCover(isPresented: $isLoggedIn) {
            PersonalCabinetView()
        }
    }

    func login() {
        guard let url = URL(string: "http://127.0.0.0.1/login") else { return }
        let body: [String: String] = ["email": email, "password": password]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data,
               let tokenResponse = try? JSONDecoder().decode(TokenResponse.self, from: data) {
                UserDefaults.standard.set(tokenResponse.token, forKey: "authToken")
                DispatchQueue.main.async {
                    isLoggedIn = true
                }
            } else {
                DispatchQueue.main.async {
                    errorMessage = "Invalid credentials"
                }
            }
        }.resume()
    }
}

struct TokenResponse: Codable {
    let token: String
}
