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

struct NodeData: Codable, Identifiable {
    let id: String
    let data: NodeInfo
    let position: NodePosition
}

struct NodeInfo: Codable, Identifiable {
    let id: String
    let label: String
    let deviceType: String
    let coordinates: String?
    let interface: InterfaceData?
    let power_on: Bool?
    let src: String?

    enum CodingKeys: String, CodingKey {
        case label
        case deviceType = "type"
        case coordinates, interface, power_on, src
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.label = try container.decode(String.self, forKey: .label)
        self.deviceType = try container.decode(String.self, forKey: .deviceType)
        self.coordinates = try container.decodeIfPresent(String.self, forKey: .coordinates)
        self.interface = try container.decodeIfPresent(InterfaceData.self, forKey: .interface)
        self.power_on = try container.decodeIfPresent(Bool.self, forKey: .power_on)
        self.src = try container.decodeIfPresent(String.self, forKey: .src)
        self.id = UUID().uuidString // Generate a new ID if not present in JSON
    }
    
    // Explicit initializer for creating NodeInfo manually (e.g., for nodeInfoMap)
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

struct EdgeData: Codable, Identifiable {
    let id: String
    let source: String
    let target: String
}

// MARK: - AR Visualization View
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

// MARK: - ARView Container (UIViewRepresentable)
struct ARDisplayView: UIViewRepresentable {
    let topology: ReactFlowData
    @Binding var selectedNodeInfo: NodeInfo?
    @Binding var resetARTrigger: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self, selectedNodeInfo: $selectedNodeInfo, topology: topology)
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        context.coordinator.arView = arView
        arView.session.delegate = context.coordinator

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        arView.session.run(config)

        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.session = arView.session
        coachingOverlay.goal = .horizontalPlane
        arView.addSubview(coachingOverlay)
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        if resetARTrigger {
            context.coordinator.resetARSession()
            DispatchQueue.main.async {
                resetARTrigger = false
            }
        }
    }
    
    // This function creates a cylinder entity representing a line
    // Added safety checks for distance and thickness
    func createLineEntity(from startPoint: SIMD3<Float>, to endPoint: SIMD3<Float>, thickness: Float, material: SimpleMaterial) -> ModelEntity {
        let distance = simd_distance(startPoint, endPoint)

        // Safety check: ensure distance and thickness are positive and reasonable
        guard distance > 0.0001 else { // Use a small epsilon to account for floating point inaccuracies
            print("Warning: Line distance is too small or zero (\(distance)). Skipping line creation for points \(startPoint) to \(endPoint).")
            return ModelEntity() // Return an empty model to prevent crash, line won't be visible
        }
        
        guard thickness > 0 else {
            print("Warning: Line thickness is zero or negative (\(thickness)). Skipping line creation.")
            return ModelEntity() // Return an empty model
        }

        let cylinderMesh = MeshResource.generateCylinder(height: distance, radius: thickness * 1.5)
        let lineEntity = ModelEntity(mesh: cylinderMesh, materials: [material])
        lineEntity.position = (startPoint + endPoint) / 2
        
        // Calculate rotation to align cylinder between start and end points
        let direction = normalize(endPoint - startPoint)
        let upVector: SIMD3<Float> = [0, 1, 0] // Default cylinder axis is Y-up
        
        // Handle edge case where line is perfectly vertical
        if abs(abs(dot(direction, upVector)) - 1.0) < 0.001 {
            // Line is vertical (or very close to it)
            if direction.y < 0 {
                // Pointing down, rotate 180 degrees around X to flip
                lineEntity.transform.rotation = simd_quatf(angle: .pi, axis: [1, 0, 0])
            }
            // If direction.y > 0, no rotation needed (already aligned with upVector)
        } else {
            // Line is not vertical, calculate rotation axis and angle
            let rotationAxis = normalize(cross(upVector, direction))
            let rotationAngle = acos(dot(upVector, direction))
            lineEntity.transform.rotation = simd_quatf(angle: rotationAngle, axis: rotationAxis)
        }
        
        return lineEntity
    }

    // MARK: - Coordinator (UPDATED)
    class Coordinator: NSObject, ARSessionDelegate {
        var parent: ARDisplayView
        var arView: ARView?
        var networkTopology: ReactFlowData
        var nodeInfoMap: [String: NodeInfo] = [:]
        @Binding var selectedNodeInfo: NodeInfo?
        
        var placementAnchor: AnchorEntity?
        var contentPlaced: Bool = false

        init(_ parent: ARDisplayView, selectedNodeInfo: Binding<NodeInfo?>, topology: ReactFlowData) {
            self.parent = parent
            self._selectedNodeInfo = selectedNodeInfo
            self.networkTopology = topology
        }
        
        // MARK: - ARSessionDelegate (UPDATED)
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            // Only place content once a horizontal plane is detected
            guard !contentPlaced else { return }

            for anchor in anchors {
                if let planeAnchor = anchor as? ARPlaneAnchor, planeAnchor.alignment == .horizontal {
                    let newPlacementAnchor = AnchorEntity(anchor: planeAnchor)
                    arView?.scene.addAnchor(newPlacementAnchor)
                    self.placementAnchor = newPlacementAnchor
                    
                    // Bridge from synchronous delegate to an asynchronous context to place content
                    Task { @MainActor in // Ensure RealityKit operations are on the main actor
                        await self.placeNetworkContent()
                    }
                    
                    contentPlaced = true
                    break // Only use the first detected plane
                }
            }
        }
        
        // MARK: - Network Content Placement (UPDATED for async/await)
        @MainActor // Mark as MainActor to ensure RealityKit operations run on the main thread
        private func placeNetworkContent() async {
            guard let anchor = placementAnchor else { return }

            // Clear existing content to avoid duplicates on re-placement
            anchor.children.removeAll()
            nodeInfoMap.removeAll()

            let positionScaleFactor: Float = 0.0025 // Adjust as needed for AR scale
            let linkThickness: Float = 0.004 // Thickness of the connecting lines
            let xOffset: Float = -1.0
            //let yOffset: Float = -0.1
            let verticalOffset: Float = 0.05 // Vertical offset for nodes above the plane
            var nodeEntities: [String: Entity] = [:]

            await withTaskGroup(of: (id: String, model: ModelEntity?).self) { group in
                // Phase 1: Concurrently load all models
                for nodeData in networkTopology.nodes {
                    group.addTask {
                        let modelName = "\(nodeData.data.deviceType.lowercased()).usdz"
                        do {
                            // Use the new async initializer for ModelEntity
                            let model = try await ModelEntity(named: modelName)
                            return (nodeData.id, model)
                        } catch {
                            // If specific model fails, try loading the fallback model
                            do {
                                let fallbackModel = try await ModelEntity(named: "default.usdz")
                                return (nodeData.id, fallbackModel)
                            } catch {
                                print("Error: Failed to load model '\(modelName)' and fallback 'default.usdz'. \(error)")
                                return (nodeData.id, nil) // Return nil if both fail
                            }
                        }
                    }
                }
                
                // Phase 2: Collect and configure loaded models, add them to the scene
                for await result in group {
                    guard let loadedEntity = result.model else { continue }
                    
                    // Find the original nodeData for this result to get its position
                    guard let nodeData = networkTopology.nodes.first(where: { $0.id == result.id }) else { continue }
                    
                    // Configure the entity's position, scale, and name
                    let posX = Float(nodeData.position.x) * positionScaleFactor
                    let posZ = Float(nodeData.position.y) * positionScaleFactor
                    loadedEntity.position = [posX + xOffset, verticalOffset, posZ]
                    loadedEntity.scale = [0.1, 0.1, 0.1] // Adjust scale as needed for visual size
                    loadedEntity.name = nodeData.id // Set name for tap detection
                    
                    
                    // Generate collision shapes for tap detection
                    await loadedEntity.generateCollisionShapes(recursive: true)
                    
                    // Add the configured entity to the AR scene's anchor
                    anchor.addChild(loadedEntity)
                    nodeEntities[result.id] = loadedEntity // Store for line drawing
                    
                    // Populate nodeInfoMap for detail view
                    let nodeSpecificInfo = NodeInfo(id: nodeData.id, label: nodeData.data.label, deviceType: nodeData.data.deviceType, coordinates: nodeData.data.coordinates, interface: nodeData.data.interface, power_on: nodeData.data.power_on, src: nodeData.data.src)
                    self.nodeInfoMap[result.id] = nodeSpecificInfo
                }
            }
            
            // Phase 3: Draw connecting lines between placed nodes (runs after all models are loaded and placed)
            for linkData in networkTopology.edges {
                guard let sourceEntity = nodeEntities[linkData.source],
                      let targetEntity = nodeEntities[linkData.target] else {
                    print("Warning: Could not find source or target entity for edge \(linkData.id).")
                    continue
                }
                
                // The problematic line from your screenshot
                let lineMaterial = SimpleMaterial(color: .gray.withAlphaComponent(0.6), isMetallic: false)
                
                let lineEntity = parent.createLineEntity(from: sourceEntity.position, to: targetEntity.position, thickness: linkThickness, material: lineMaterial)
                
                // Only add the line if it's not an empty ModelEntity from the guard in createLineEntity
                if !lineEntity.children.isEmpty || lineEntity.components.has(ModelComponent.self) {
                    anchor.addChild(lineEntity)
                }
            }
        }
        
        func resetARSession() {
            guard let arView = arView else { return }
            
            // Clear all anchors from the scene
            arView.scene.anchors.removeAll()
            placementAnchor = nil
            contentPlaced = false
            nodeInfoMap.removeAll()

            // Re-run the AR session with reset options
            let config = ARWorldTrackingConfiguration()
            config.planeDetection = [.horizontal]
            arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        }

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView = arView else { return }
            let tapLocation = recognizer.location(in: arView)
            
            // Perform a hit test to find entities at the tap location
            if let tappedEntity = arView.entity(at: tapLocation) {
                var currentEntity: Entity? = tappedEntity
                // Traverse up the entity hierarchy to find the root entity with a name (node ID)
                while currentEntity != nil {
                    if let entityName = currentEntity?.name, let details = nodeInfoMap[entityName] {
                        self.selectedNodeInfo = details // Set the selected node to show details sheet
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
        .navigationBarHidden(true) // Hide the navigation bar for the sheet content
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
