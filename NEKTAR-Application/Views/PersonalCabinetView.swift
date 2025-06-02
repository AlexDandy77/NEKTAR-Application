import SwiftUI

struct PersonalCabinetView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var cabinetItems: [CabinetItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var itemForARVisualization: CabinetItem? = nil

    let cabinetItemsURL = URL(string: "\(baseURLString)/snippets")!

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    if isLoading {
                        ZStack {
                            LinearGradient(gradient: Gradient(colors: [Color.green.opacity(0.6), Color.teal.opacity(0.6)]),
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing)
                                .ignoresSafeArea()

                            ProgressView("Loading Cabinet...")
                                .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                                .foregroundColor(.white)
                                .padding()
                        }
                    } else if let errorMsg = errorMessage {
                        Text("Error: \(errorMsg)")
                            .foregroundColor(.red)
                            .padding()
                        Button("Retry") {
                            fetchCabinetItems()
                        }
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.orange)
                        .cornerRadius(10)
                    } else if cabinetItems.isEmpty {
                        ZStack{
                            LinearGradient(gradient: Gradient(colors: [Color.green.opacity(0.6), Color.teal.opacity(0.6)]),
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing)
                                .ignoresSafeArea()
                            VStack {
                                Image(systemName: "tray.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(Color.black.opacity(0.6))
                                    .padding(.bottom, 20)
                                Text("Your cabinet is empty.")
                                    .font(.title2)
                                    .foregroundColor(Color.black.opacity(0.8))
                                Text("Saved items will appear here.")
                                    .font(.subheadline)
                                    .foregroundColor(Color.black.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .padding()
                        }
                    } else {
                        List {
                            ForEach(cabinetItems) { item in
                                CabinetItemRow(item: item) {
                                    self.itemForARVisualization = item
                                }
                                .listRowBackground(Color.white.opacity(0.6))
                            }
                            .onDelete(perform: deleteCabinetItem)
                        }
                        .listStyle(InsetGroupedListStyle())
                        .refreshable {
                            fetchCabinetItems()
                        }
                    }
                }
                .navigationTitle("Personal Cabinet")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Menu {
                            Button(role: .destructive) {
                                authService.logout()
                            } label: {
                                Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                            }
                        } label: {
                            Image(systemName: "person.crop.circle.fill")
                                .foregroundColor(.white)
                                .imageScale(.large)
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                            .foregroundColor(.white)
                    }
                }
                .onAppear {
                    fetchCabinetItems()
                }
                .sheet(item: $itemForARVisualization) { item in
                    NavigationView {
                        ARNetworkVisualizationView(jsonDataString: item.jsonData)
                    }
                }
            }
            .toolbarBackground(Material.thin, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Fetch Cabinet Items (Actual Network Request)
    func fetchCabinetItems() {
        isLoading = true
        errorMessage = nil

        guard let token = authService.authToken else {
            errorMessage = "Authentication token not found. Please log in again."
            isLoading = false
            return
        }

        var request = URLRequest(url: cabinetItemsURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false

                if let error = error {
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                    self.cabinetItems = []
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    self.errorMessage = "Invalid response from server."
                    self.cabinetItems = []
                    return
                }

                if httpResponse.statusCode == 200 {
                    guard let data = data else {
                        self.errorMessage = "No data received from server."
                        self.cabinetItems = []
                        return
                    }
                    do {
                        let decodedItems = try JSONDecoder().decode([CabinetItem].self, from: data)
                        self.cabinetItems = decodedItems
                        self.errorMessage = nil
                    } catch {
                        print("Decoding error: \(error)")
                        self.errorMessage = "Failed to decode cabinet items: \(error.localizedDescription)"
                        self.cabinetItems = []
                    }
                } else if httpResponse.statusCode == 401 {
                    self.errorMessage = "Session expired. Please log in again."
                    authService.logout()
                    self.cabinetItems = []
                } else {
                    let responseBody = data.map { String(data: $0, encoding: .utf8) ?? "" } ?? "No response body."
                    self.errorMessage = "Server error \(httpResponse.statusCode): \(responseBody)"
                    self.cabinetItems = []
                }
            }
        }.resume()
    }

    // MARK: - Delete Cabinet Item
    func deleteCabinetItem(at offsets: IndexSet) {
        let itemsToDelete = offsets.map { cabinetItems[$0] }
        cabinetItems.remove(atOffsets: offsets)

        for item in itemsToDelete {
            deleteItemFromServer(item: item)
        }
    }

    private func deleteItemFromServer(item: CabinetItem) {
        guard let token = authService.authToken else {
            errorMessage = "Authentication token not found. Please log in again."
            return
        }

        guard let deleteURL = URL(string: "\(baseURLString)/snippets/\(item.id)") else {
            print("Invalid delete URL for item ID: \(item.id)")
            return
        }

        var request = URLRequest(url: deleteURL)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error deleting item \(item.id): \(error.localizedDescription)")
                    self.errorMessage = "Failed to delete '\(item.title)': \(error.localizedDescription)"
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    print("Invalid response for delete item \(item.id)")
                    self.errorMessage = "Failed to delete '\(item.title)': Invalid server response."
                    return
                }

                if httpResponse.statusCode == 200 || httpResponse.statusCode == 204 {
                    print("Successfully deleted item \(item.id)")
                } else {
                    let responseBody = data.map { String(data: $0, encoding: .utf8) ?? "" } ?? "No response body."
                    print("Server error deleting item \(item.id): \(httpResponse.statusCode) - \(responseBody)")
                    self.errorMessage = "Failed to delete '\(item.title)': Server responded with \(httpResponse.statusCode)."
                }
            }
        }.resume()
    }
}
