import SwiftUI

struct PersonalCabinetView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var cabinetItems: [CabinetItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showingJsonForItem: CabinetItem? = nil // For modal

    let cabinetItemsURL = URL(string: "\(baseURLString)/api/cabinet")! // TODO Replace

    var body: some View {
        NavigationView {
            ZStack {
                // Background Gradient
                LinearGradient(gradient: Gradient(colors: [Color.green.opacity(0.6), Color.teal.opacity(0.6)]),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                VStack {
                    if isLoading {
                        ProgressView("Loading Cabinet...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                            .foregroundColor(.white)
                            .padding()
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
                            Text("Items you add will appear here.")
                                .font(.subheadline)
                                .foregroundColor(Color.black.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding()

                    } else {
                        List {
                            ForEach(cabinetItems) { item in
                                CabinetItemRow(item: item) {
                                    // Action to show JSON, could be a modal or navigation
                                    self.showingJsonForItem = item
                                }
                                .listRowBackground(Color.white.opacity(0.6)) // Make rows slightly transparent
                            }
                        }
                        .listStyle(InsetGroupedListStyle()) // A modern list style
                        .background(Color.clear) // Make list background clear to see gradient
                        .onAppear { // Ensure list rows are styled correctly on appear
                             UITableView.appearance().backgroundColor = .clear
                             UITableViewCell.appearance().backgroundColor = .clear
                        }
                    }
                }
                .navigationTitle("Personal Cabinet")
                .navigationBarTitleDisplayMode(.inline) // Or .large
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        // Example: User profile icon
                        Image(systemName: "person.crop.circle.fill")
                            .foregroundColor(.white)
                            .imageScale(.large)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            authService.logout()
                        } label: {
                            HStack {
                                Text("Logout")
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                            }
                            .foregroundColor(.white)
                        }
                    }
                }
                .onAppear {
                    fetchCabinetItems()
                }
                // Modal to display JSON
                .sheet(item: $showingJsonForItem) { item in
                    JsonDetailView(jsonData: item.jsonData)
                }
            }
            // Set navigation bar appearance for this view
            .toolbarBackground(Material.thin, for: .navigationBar) // Make nav bar transparent
            .toolbarBackground(.visible, for: .navigationBar) // Ensure it's visible
            .toolbarColorScheme(.dark, for: .navigationBar) // Ensure icons/text are white
        }
    }

    // MARK: - Fetch Cabinet Items (Mocked)
    func fetchCabinetItems() {
        isLoading = true
        errorMessage = nil

        // MOCK IMPLEMENTATION: Replace with actual network request
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { // Simulate network delay
            // In a real app, you'd use URLSession here with the authToken in headers
            // For example: request.setValue("Bearer \(authService.authToken ?? "")", forHTTPHeaderField: "Authorization")

            // Example of successful mock data
            self.cabinetItems = [
                CabinetItem(title: "Important Document", description: "Contains critical project details.", jsonData: #"{"projectId": "Alpha123", "status": "active", "dueDate": "2025-12-31"}"#),
                CabinetItem(title: "Vacation Photos", description: "Memories from the last trip.", jsonData: #"{"location": "Paris", "year": 2024, "album": ["eiffel_tower.jpg", "louvre.png"]}"#),
                CabinetItem(title: "Recipe Book", description: "Collection of favorite recipes.", jsonData: #"{"category": "Desserts", "recipes": [{"name": "Chocolate Cake", "prepTime": "30 mins"}]}"#)
            ]
            isLoading = false

            // Example of error handling (uncomment to test)
            // self.errorMessage = "Could not connect to the server."
            // self.cabinetItems = []
            // isLoading = false
        }
    }
}
