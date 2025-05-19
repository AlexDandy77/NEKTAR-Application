import SwiftUI

struct PersonalCabinetView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var cabinetItems: [CabinetItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showingTopologyForItem: CabinetItem? = nil

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
                                    // Action to show Topology View
                                    self.showingTopologyForItem = item // Set the item to show topology for
                                }
                                .listRowBackground(Color.white.opacity(0.6))
                            }
                        }
                        .listStyle(InsetGroupedListStyle())
                        .background(Color.clear)
                        .onAppear {
                             UITableView.appearance().backgroundColor = .clear
                             UITableViewCell.appearance().backgroundColor = .clear
                        }
                    }
                }
                .navigationTitle("Personal Cabinet")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
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
                // Present the TopologyRealityView as a sheet
                .sheet(item: $showingTopologyForItem) { item in
                    // Attempt to parse jsonData into ReactFlowData
                    if let data = item.jsonData.data(using: .utf8),
                       let reactFlowData = try? JSONDecoder().decode(ReactFlowData.self, from: data) {
                        TopologyRealityView(reactFlowData: reactFlowData)
                    } else {
                        // Fallback: If parsing fails, show the raw JSON
                        JsonDetailView(jsonData: item.jsonData)
                            .presentationDetents([.medium, .large]) // Adjust sheet size for JSON
                    }
                }
            }
            .toolbarBackground(Material.thin, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Fetch Cabinet Items (Mocked)
    func fetchCabinetItems() {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // This is your mock data. In a real scenario, you'd fetch this from your backend
            // and include authentication token in the request headers.
            let topologyJsonData = """
{
            "react_flow": {
                "edges": [
                    { "animated": true, "id": "e0", "source": "3", "target": "4", "type": "straight" },
                    { "animated": true, "id": "e1", "source": "1", "target": "4", "type": "straight" },
                    { "animated": true, "id": "e2", "source": "2", "target": "4", "type": "straight" },
                    { "animated": true, "id": "e3", "source": "4", "target": "9", "type": "straight" },
                    { "animated": true, "id": "e4", "source": "6", "target": "5", "type": "straight" },
                    { "animated": true, "id": "e5", "source": "8", "target": "5", "type": "straight" },
                    { "animated": true, "id": "e6", "source": "7", "target": "5", "type": "straight" },
                    { "animated": true, "id": "e7", "source": "5", "target": "9", "type": "straight" },
                    { "animated": true, "id": "e8", "source": "4", "target": "5", "type": "straight" }
                ],
                "nodes": [
                    { "data": { "coordinates": "168.5 288.0", "interface": { "bandwidth": 100, "ip": "192.168.1.10", "name": "FastEthernet0" }, "label": "PC0", "power_on": true, "src": "/images/pc.png", "type": "pc" }, "id": "1", "position": { "x": 168.5, "y": 288.0 }, "type": "custom" },
                    { "data": { "coordinates": "284.5 365.0", "interface": { "bandwidth": 100, "ip": "192.168.1.12", "name": "FastEthernet0" }, "label": "Laptop0", "power_on": true, "src": "/images/laptop.png", "type": "laptop" }, "id": "2", "position": { "x": 284.5, "y": 365.0 }, "type": "custom" },
                    { "data": { "coordinates": "175.0 166.0", "interface": { "bandwidth": 100, "ip": "192.168.1.11", "name": "FastEthernet0" }, "label": "Server0", "power_on": true, "src": "/images/server.png", "type": "server" }, "id": "3", "position": { "x": 175.0, "y": 166.0 }, "type": "custom" },
                    { "data": { "coordinates": "343.0 227.0", "interface": { "bandwidth": 100, "ip": "0.0.0.0", "name": "FastEthernet0" }, "label": "Switch0", "power_on": true, "src": "/images/switch.png", "type": "switch" }, "id": "4", "position": { "x": 343.0, "y": 227.0 }, "type": "custom" },
                    { "data": { "coordinates": "536.0 227.0", "interface": { "bandwidth": 100, "ip": "0.0.0.0", "name": "FastEthernet0" }, "label": "Switch1", "power_on": true, "src": "/images/switch.png", "type": "switch" }, "id": "5", "position": { "x": 536.0, "y": 227.0 }, "type": "custom" },
                    { "data": { "coordinates": "638.5 363.0", "interface": { "bandwidth": 100, "ip": "192.168.2.12", "name": "FastEthernet0" }, "label": "PC1", "power_on": true, "src": "/images/pc.png", "type": "pc" }, "id": "6", "position": { "x": 638.5, "y": 363.0 }, "type": "custom" },
                    { "data": { "coordinates": "739.5 169.0", "interface": { "bandwidth": 100, "ip": "192.168.2.10", "name": "FastEthernet0" }, "label": "Laptop1", "power_on": true, "src": "/images/laptop.png", "type": "laptop" }, "id": "7", "position": { "x": 739.5, "y": 169.0 }, "type": "custom" },
                    { "data": { "coordinates": "724.0 287.0", "interface": { "bandwidth": 100, "ip": "192.168.2.11", "name": "FastEthernet0" }, "label": "Server1", "power_on": true, "src": "/images/server.png", "type": "server" }, "id": "8", "position": { "x": 724.0, "y": 287.0 }, "type": "custom" },
                    { "data": { "coordinates": "449.5 314.0", "interface": { "bandwidth": 1000, "ip": "0.0.0.0", "name": "FastEthernet0" }, "label": "Router0", "power_on": true, "src": "/images/router.png", "type": "router" }, "id": "9", "position": { "x": 449.5, "y": 314.0 }, "type": "custom" }
                ]
            }
        }
"""

            self.cabinetItems = [
                CabinetItem(title: "Network Topology 1", description: "Complex office network diagram.", jsonData: topologyJsonData),
                CabinetItem(title: "Small Office Network", description: "Basic home office setup.", jsonData: #"{ "react_flow": { "edges": [ { "animated": true, "id": "e0", "source": "router-a", "target": "pc-a", "type": "straight" } ], "nodes": [ { "data": { "label": "Router-A", "type": "router" }, "id": "router-a", "position": { "x": 100.0, "y": 100.0 }, "type": "custom" }, { "data": { "label": "PC-A", "type": "pc" }, "id": "pc-a", "position": { "x": 200.0, "y": 200.0 }, "type": "custom" } ] } }"#)
            ]
            isLoading = false
        }
    }
}
