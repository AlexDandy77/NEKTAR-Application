import SwiftUI

struct PersonalCabinetView: View {
    @State private var userData: UserData?

    var body: some View {
        VStack {
            if let user = userData {
                Text("Welcome, \(user.name)")
                Text("Email: \(user.email)")
            } else {
                ProgressView()
                    .onAppear(perform: loadUserData)
            }
        }
    }

    func loadUserData() {
        guard let token = UserDefaults.standard.string(forKey: "authToken"),
              let url = URL(string: "https://yourbackend.com/profile") else { return }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data,
               let user = try? JSONDecoder().decode(UserData.self, from: data) {
                DispatchQueue.main.async {
                    userData = user
                }
            }
        }.resume()
    }
}

struct UserData: Codable {
    let name: String
    let email: String
}
