import SwiftUI
import RealityKit
import ARKit

struct ARNetworkVisualizationView: View {
	let jsonDataString: String
	@State private var networkTopology: NetworkTopologyContainer? = nil
	@State private var errorMessage: String? = nil
	@Environment(\.presentationMode) var presentationMode

	@State private var selectedNodeInfo: NodeInfo? = nil
	@State private var resetARTrigger: Bool = false

	var body: some View {
		VStack {
			if let topology = networkTopology {
				ARDisplayView(topology: topology.reactFlow,
							  selectedNodeInfo: $selectedNodeInfo,
							  resetARTrigger: $resetARTrigger)
					.edgesIgnoringSafeArea(.all)
			} else if let errorMsg = errorMessage {
				VStack {
					Text("Error Parsing Network Data")
						.font(.headline).padding()
					ScrollView{ Text(errorMsg).font(.body).multilineTextAlignment(.center).padding() }
					Button("Dismiss") { presentationMode.wrappedValue.dismiss() }
						.padding()
				}
			} else {
				ProgressView("Loading and Parsing Network Data...")
					.onAppear { parseJsonData() }
			}
		}
		.navigationTitle("Network AR")
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			ToolbarItem(placement: .navigationBarTrailing) {
				HStack {
					Button("Reset AR") {
						resetARTrigger.toggle()
					}
					Button("Done") { presentationMode.wrappedValue.dismiss() }
				}
			}
		}
		.sheet(item: $selectedNodeInfo) { details in
			NavigationView {
				NodeDetailView(details: details)
			}
		}
	}

	private func parseJsonData() {
		guard let data = jsonDataString.data(using: .utf8) else {
			self.errorMessage = "Error: Could not convert JSON string to Data."
			return
		}
		do {
			let decoder = JSONDecoder()
			let decodedData = try decoder.decode(NetworkTopologyContainer.self, from: data)
			self.networkTopology = decodedData
		} catch {
			self.errorMessage = "Failed to decode network topology: \(error.localizedDescription)\n\nDebug Info: \(error)"
		}
	}
}
