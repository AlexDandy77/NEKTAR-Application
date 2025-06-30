import SwiftUI

struct PersonalCabinetView: View {
	@EnvironmentObject var authService: AuthManager
	@StateObject private var cabinetManager: CabinetManager
	@State private var itemForARVisualization: CabinetItem? = nil

	@State private var hasAppearedAndLoaded = false

	init(authService: AuthManager) {
		_cabinetManager = StateObject(wrappedValue: CabinetManager(authService: authService))
	}

	var body: some View {
		NavigationView {
			ZStack {
				VStack {
					if cabinetManager.isLoading && !hasAppearedAndLoaded {
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
					} else if let errorMsg = cabinetManager.errorMessage {
						// Display error but allow retrying only if it's not a cancellation for a *subsequent* refresh
						Text("Error: \(errorMsg)")
							.foregroundColor(.red)
							.padding()
						
						// Provide a retry button only if it's a real error, not just a cancelled initial task
						Button("Retry") {
							Task { await cabinetManager.fetchCabinetItems() }
						}
						.padding()
						.foregroundColor(.white)
						.background(Color.orange)
						.cornerRadius(10)
					} else if cabinetManager.cabinetItems.isEmpty && !cabinetManager.isLoading { // Only show empty state if not loading AND no items
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
							ForEach(cabinetManager.cabinetItems) { item in
								CabinetItemRow(item: item) {
									self.itemForARVisualization = item
								}
								.listRowBackground(Color.white.opacity(0.6))
							}
							.onDelete(perform: { indexSet in
								Task {
									for index in indexSet {
										await cabinetManager.deleteCabinetItem(item: cabinetManager.cabinetItems[index])
									}
								}
							})
						}
						.listStyle(InsetGroupedListStyle())
						.refreshable {
							await cabinetManager.fetchCabinetItems()
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
				.task { // This task runs only once on first appearance
					guard !hasAppearedAndLoaded else { return } // Prevent re-fetching on subsequent appearances
					await cabinetManager.fetchCabinetItems()
					hasAppearedAndLoaded = true // Mark as loaded after first fetch attempt
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
}
