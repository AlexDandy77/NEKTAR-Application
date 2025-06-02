import SwiftUI
import RealityKit
import ARKit

// MARK: - Data Structures for JSON Parsing

struct NetworkTopologyContainer: Codable {
    let dsl: String
    let reactFlow: ReactFlowData

    enum CodingKeys: String, CodingKey {
        case dsl
        case reactFlow
    }
}

struct ReactFlowData: Codable {
    let edges: [EdgeData]
    let nodes: [NodeData]
}

struct NodeData: Codable, Identifiable { // Identifiable by its own 'id'
    let id: String
    let data: NodeInfo
    let position: NodePosition
}

// MARK: - NodeInfo: Corrected for JSON Decoding
struct NodeInfo: Codable, Identifiable {
    let id: String
    let label: String
    let deviceType: String
    let coordinates: String?
    let interface: InterfaceData?
    let power_on: Bool?
    let src: String?

    // CodingKeys to map JSON keys *within the "data" object* to struct properties.
    // 'id' is explicitly excluded here because it's not present in the 'data' JSON.
    enum CodingKeys: String, CodingKey {
        case label
        case deviceType = "type" // Maps "type" within JSON "data" to "deviceType"
        case coordinates, interface, power_on, src
    }

    // Custom initializer for Codable conformance. This is what JSONDecoder uses
    // when it encounters the 'data' object in your JSON.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.label = try container.decode(String.self, forKey: .label)
        self.deviceType = try container.decode(String.self, forKey: .deviceType)
        self.coordinates = try container.decodeIfPresent(String.self, forKey: .coordinates)
        self.interface = try container.decodeIfPresent(InterfaceData.self, forKey: .interface)
        self.power_on = try container.decodeIfPresent(Bool.self, forKey: .power_on)
        self.src = try container.decodeIfPresent(String.self, forKey: .src)
        
        // Provide a temporary ID for Identifiable conformance.
        // This 'id' will be overwritten with the actual NodeData.id when
        // NodeInfo instances are created for the nodeInfoMap.
        self.id = UUID().uuidString
    }
    
    // Convenience initializer to create NodeInfo with a specific ID (from NodeData.id).
    // This is used when populating the nodeInfoMap in the Coordinator.
    init(id: String, label: String, deviceType: String, coordinates: String?, interface: InterfaceData?, power_on: Bool?, src: String?) {
        self.id = id
        self.label = label
        self.deviceType = deviceType
        self.coordinates = coordinates
        self.interface = interface
        self.power_on = power_on
        self.src = src
    }
}

struct InterfaceData: Codable {
    let bandwidth: Int?
    let ip: String?
}

struct NodePosition: Codable {
    let x: Double
    let y: Double
}

struct EdgeData: Codable, Identifiable { // Identifiable by its own 'id'
    let id: String
    let source: String // Node ID
    let target: String // Node ID
}


// MARK: - AR Visualization View
struct ARNetworkVisualizationView: View {
    let jsonDataString: String
    @State private var networkTopology: NetworkTopologyContainer? = nil
    @State private var errorMessage: String? = nil
    @Environment(\.presentationMode) var presentationMode

    // State to hold the details of the tapped node for modal presentation
    @State private var selectedNodeInfo: NodeInfo? = nil
    
    // State to trigger AR session reset
    @State private var resetARTrigger: Bool = false

    var body: some View {
        VStack {
            if let topology = networkTopology {
                ARDisplayView(topology: topology.reactFlow,
                              selectedNodeInfo: $selectedNodeInfo,
                              resetARTrigger: $resetARTrigger) // Pass the binding
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
                        resetARTrigger.toggle() // Toggle to trigger AR reset
                    }
                    Button("Done") { presentationMode.wrappedValue.dismiss() }
                }
            }
        }
        .sheet(item: $selectedNodeInfo) { details in // 'item' requires NodeInfo to be Identifiable
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

// MARK: - ARView Container (UIViewRepresentable)
struct ARDisplayView: UIViewRepresentable {
    let topology: ReactFlowData
    @Binding var selectedNodeInfo: NodeInfo?
    @Binding var resetARTrigger: Bool // Binding to trigger AR reset

    func makeCoordinator() -> Coordinator {
        Coordinator(self, selectedNodeInfo: $selectedNodeInfo, topology: topology)
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        context.coordinator.arView = arView

        // Set the ARSessionDelegate
        arView.session.delegate = context.coordinator

        // Configure AR session for plane detection
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal] // Detect horizontal planes
        arView.session.run(config)

        // Add coaching overlay for user guidance
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.session = arView.session
        coachingOverlay.goal = .horizontalPlane // Guide user to find a horizontal plane
        arView.addSubview(coachingOverlay)
        
        // Add a tap gesture recognizer for node interaction
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        // Observe changes to resetARTrigger to reset the AR session
        if resetARTrigger {
            context.coordinator.resetARSession()
            // Reset the trigger immediately after handling it
            DispatchQueue.main.async {
                resetARTrigger = false
            }
        }
        // Topology is static once loaded, so no complex updates needed here.
    }
    
    // Helper function to create a line entity (moved here for better organization)
    func createLineEntity(from startPoint: SIMD3<Float>, to endPoint: SIMD3<Float>, thickness: Float, material: SimpleMaterial) -> ModelEntity {
        let distance = simd_distance(startPoint, endPoint)
        let cylinderMesh = MeshResource.generateCylinder(height: distance, radius: thickness / 2)
        let lineEntity = ModelEntity(mesh: cylinderMesh, materials: [material])
        lineEntity.position = (startPoint + endPoint) / 2
        let direction = normalize(endPoint - startPoint)
        let upVector: SIMD3<Float> = [0, 1, 0]
        if abs(abs(dot(direction, upVector)) - 1.0) < 0.001 {
            if direction.y < 0 { lineEntity.transform.rotation = simd_quatf(angle: .pi, axis: [1, 0, 0]) }
        } else {
            let rotationAxis = normalize(cross(upVector, direction))
            let rotationAngle = acos(dot(upVector, direction))
            lineEntity.transform.rotation = simd_quatf(angle: rotationAngle, axis: rotationAxis)
        }
        return lineEntity
    }

    class Coordinator: NSObject, ARSessionDelegate {
        var parent: ARDisplayView
        var arView: ARView?
        var networkTopology: ReactFlowData // Store topology here for access in delegate methods
        var nodeInfoMap: [String: NodeInfo] = [:]
        @Binding var selectedNodeInfo: NodeInfo?
        
        // Anchor for placing the entire network visualization
        var placementAnchor: AnchorEntity?
        var contentPlaced: Bool = false // Flag to ensure content is placed only once per session/plane

        init(_ parent: ARDisplayView, selectedNodeInfo: Binding<NodeInfo?>, topology: ReactFlowData) {
            self.parent = parent
            self._selectedNodeInfo = selectedNodeInfo
            self.networkTopology = topology
        }
        
        // MARK: - ARSessionDelegate
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            // Check if a horizontal plane anchor was added and content hasn't been placed yet
            guard !contentPlaced else { return }

            for anchor in anchors {
                if let planeAnchor = anchor as? ARPlaneAnchor, planeAnchor.alignment == .horizontal {
                    // Create an AnchorEntity at the detected plane's transform
                    let newPlacementAnchor = AnchorEntity(anchor: planeAnchor)
                    arView?.scene.addAnchor(newPlacementAnchor)
                    self.placementAnchor = newPlacementAnchor
                    
                    // Place the network content on this detected plane
                    placeNetworkContent()
                    contentPlaced = true // Set flag to true after placement
                    break // Only place content on the first detected horizontal plane
                }
            }
        }
        
        // MARK: - Network Content Placement
        private func placeNetworkContent() {
            guard let arView = arView, let anchor = placementAnchor else { return }

            // Clear any existing network models before placing new ones
            anchor.children.removeAll()
            nodeInfoMap.removeAll()

            let nodeBaseSize: Float = 0.05
            let positionScaleFactor: Float = 0.0025 // Adjusted for potentially better initial scaling
            let linkThickness: Float = 0.004
            let verticalOffset: Float = 0.05 // Slightly lower offset if on a desk

            var nodeEntities: [String: Entity] = [:]

            for nodeData in networkTopology.nodes {
                let deviceClassType = nodeData.data.deviceType.lowercased()
                var nodeEntity: ModelEntity

                switch deviceClassType {
                    case "pc":
                        nodeEntity = ModelEntity(mesh: .generateSphere(radius: nodeBaseSize / 2), materials: [SimpleMaterial(color: .systemBlue, isMetallic: false)])
                    case "laptop":
                        nodeEntity = ModelEntity(mesh: .generateSphere(radius: nodeBaseSize / 2 * 0.9), materials: [SimpleMaterial(color: .systemGreen, isMetallic: false)])
                    case "server":
                        nodeEntity = ModelEntity(mesh: .generateBox(size: nodeBaseSize), materials: [SimpleMaterial(color: .systemOrange, isMetallic: false)])
                    case "switch":
                        nodeEntity = ModelEntity(mesh: .generateBox(width: nodeBaseSize * 1.5, height: nodeBaseSize * 0.5, depth: nodeBaseSize * 0.8), materials: [SimpleMaterial(color: .systemPurple, isMetallic: false)])
                    case "router":
                        nodeEntity = ModelEntity(mesh: .generateCylinder(height: nodeBaseSize * 0.7, radius: nodeBaseSize * 0.4), materials: [SimpleMaterial(color: .systemRed, isMetallic: false)])
                    default:
                        nodeEntity = ModelEntity(mesh: .generateSphere(radius: nodeBaseSize / 2 * 0.7), materials: [SimpleMaterial(color: .systemGray, isMetallic: false)])
                }
                
                // Position relative to the detected plane anchor
                let posX = Float(nodeData.position.x) * positionScaleFactor
                let posZ = Float(nodeData.position.y) * positionScaleFactor
                nodeEntity.position = [posX, verticalOffset, posZ] // Y is vertical offset from the plane
                
                nodeEntity.name = nodeData.id
                nodeEntity.generateCollisionShapes(recursive: true) // Enable tap detection

                anchor.addChild(nodeEntity)
                nodeEntities[nodeData.id] = nodeEntity
                
                // Construct NodeInfo for the map, including the 'id' from NodeData for Identifiable conformance
                let nodeSpecificInfo = NodeInfo(id: nodeData.id, // Use NodeData.id for Identifiable
                                                label: nodeData.data.label,
                                                deviceType: nodeData.data.deviceType,
                                                coordinates: nodeData.data.coordinates,
                                                interface: nodeData.data.interface,
                                                power_on: nodeData.data.power_on,
                                                src: nodeData.data.src)
                nodeInfoMap[nodeData.id] = nodeSpecificInfo
            }

            for linkData in networkTopology.edges {
                guard let sourceEntity = nodeEntities[linkData.source],
                      let targetEntity = nodeEntities[linkData.target] else {
                    continue
                }
                let lineMaterial = SimpleMaterial(color: .gray.withAlphaComponent(0.6), isMetallic: false)
                // Positions are already relative to the anchor, so no need for relativeTo: anchor again
                let lineEntity = parent.createLineEntity(from: sourceEntity.position,
                                                         to: targetEntity.position,
                                                         thickness: linkThickness,
                                                         material: lineMaterial)
                anchor.addChild(lineEntity)
            }
        }
        
        // MARK: - AR Session Reset
        func resetARSession() {
            guard let arView = arView else { return }
            
            // Remove all existing anchors and content
            arView.scene.anchors.removeAll()
            placementAnchor = nil
            contentPlaced = false
            nodeInfoMap.removeAll() // Clear map as content is removed

            // Re-run the AR session with plane detection
            let config = ARWorldTrackingConfiguration()
            config.planeDetection = [.horizontal]
            arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        }

        // MARK: - Tap Gesture Handling
        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView = arView else { return }
            let tapLocation = recognizer.location(in: arView)
            
            // Perform a raycast to find entities at the tap location
            if let tappedEntity = arView.entity(at: tapLocation) {
                var currentEntity: Entity? = tappedEntity
                // Traverse up the hierarchy to find the main node entity
                while currentEntity != nil {
                    if let entityName = currentEntity?.name, let details = nodeInfoMap[entityName] {
                        self.selectedNodeInfo = details
                        return
                    }
                    currentEntity = currentEntity?.parent
                }
            }
        }
    }
}

// MARK: - NodeDetailView (for the sheet)
struct NodeDetailView: View {
    let details: NodeInfo
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Node Details")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 5)

            detailRow(label: "Label:", value: details.label)
            detailRow(label: "Device Type:", value: details.deviceType)
            
            if let coords = details.coordinates {
                detailRow(label: "Coordinates:", value: coords)
            }
            
            if let interface = details.interface {
                Text("Interface:")
                    .font(.headline)
                    .padding(.top, 5)
                detailRow(label: "  Bandwidth:", value: interface.bandwidth != nil ? "\(interface.bandwidth!) Mbps" : "N/A")
                detailRow(label: "  IP Address:", value: interface.ip ?? "N/A")
            }
            
            if let powerOn = details.power_on {
                detailRow(label: "Power On:", value: powerOn ? "Yes" : "No")
            }
            
            if let src = details.src {
                detailRow(label: "Source:", value: src)
            }
            
            Spacer()
            
            Button("Done") {
                presentationMode.wrappedValue.dismiss()
            }
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
        .navigationBarHidden(true) // Hide the default navigation bar for the sheet
    }
    
    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.gray)
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}
