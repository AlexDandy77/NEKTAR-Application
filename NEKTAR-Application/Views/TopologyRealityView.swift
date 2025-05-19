import SwiftUI
import RealityKit
import ARKit

struct TopologyRealityView: View {
    let reactFlowData: ReactFlowData
    @Environment(\.dismiss) var dismiss // To dismiss the sheet

    var body: some View {
        NavigationView {
            ARViewContainer(reactFlowData: reactFlowData)
                .ignoresSafeArea()
                .navigationTitle("Network Topology")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

// UIViewRepresentable to bridge ARView (UIKit) with SwiftUI
struct ARViewContainer: UIViewRepresentable {
    let reactFlowData: ReactFlowData

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        // Configuration for horizontal plane detection (for placing the topology)
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = .horizontal
        arView.session.run(config)

        // Create a horizontal plane anchor for content placement.
        // This makes the content appear on a detected flat surface.
        let anchor = AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: [0.3, 0.3]))
        arView.scene.addAnchor(anchor)

        // Add a simple light source to illuminate the scene
        let light = PointLight()
        light.light.intensity = 100000 // Adjust intensity as needed
        light.position = [0, 0.5, 0] // Position slightly above the scene content
        let lightEntity = AnchorEntity(world: [0, 0, 0])
        lightEntity.addChild(light)
        anchor.addChild(lightEntity)

        // Define simple materials (colors) for different device types
        let pcMaterial = SimpleMaterial(color: .blue, isMetallic: false)
        let laptopMaterial = SimpleMaterial(color: .green, isMetallic: false)
        let serverMaterial = SimpleMaterial(color: .red, isMetallic: false)
        let switchMaterial = SimpleMaterial(color: .orange, isMetallic: false)
        let routerMaterial = SimpleMaterial(color: .purple, isMetallic: false)
        let defaultMaterial = SimpleMaterial(color: .gray, isMetallic: false)
        let edgeMaterial = SimpleMaterial(color: UIColor(Color.black.opacity(0.7)), isMetallic: false)

        // Dictionary to store references to node entities by their ID,
        // so edges can connect them.
        var nodeEntities: [String: ModelEntity] = [:]
        for node in reactFlowData.nodes {
            // Scale down the React Flow coordinates (pixels) to a suitable size for RealityKit (meters)
            // React Flow's Y (vertical) becomes RealityKit's Z (depth) for a top-down view.
            let x = Float(node.position.x / 400.0)
            let y = Float(node.position.y / 400.0) // This is mapped to RealityKit's Z

            let mesh: MeshResource
            var material: RealityKit.Material

            // Choose mesh and material based on device type
            switch node.data.type {
            case "pc", "laptop", "server":
                mesh = .generateBox(size: 0.05, cornerRadius: 0.005) // Small box for end devices
                material = node.data.type == "pc" ? pcMaterial : (node.data.type == "laptop" ? laptopMaterial : serverMaterial)
            case "switch", "router":
                mesh = .generateBox(size: [0.08, 0.03, 0.05], cornerRadius: 0.005) // Flatter box for network devices
                material = node.data.type == "switch" ? switchMaterial : routerMaterial
            default:
                mesh = .generateSphere(radius: 0.04) // Fallback to sphere
                material = defaultMaterial
            }

            let modelEntity = ModelEntity(mesh: mesh, materials: [material])
            // Set position: x, y (height, kept low for flat view), z (depth)
            modelEntity.position = SIMD3<Float>(x, 0.02, y)

            // Add a text label above each node
            let textMesh = MeshResource.generateText(
                node.data.label,
                extrusionDepth: 0.001, // Very thin text
                font: .systemFont(ofSize: 0.02), // Small font size
                containerFrame: .zero,
                alignment: .center,
                lineBreakMode: .byWordWrapping
            )
            let textMaterial = SimpleMaterial(color: .white, isMetallic: false)
            let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])
            // Position text above the node, adjust Y offset for visibility
            textEntity.position = SIMD3<Float>(0, 0.05, 0)
            modelEntity.addChild(textEntity)

            // Add the node to the scene anchor
            anchor.addChild(modelEntity)
            // Store the entity to reference it later for edges
            nodeEntities[node.id] = modelEntity
        }

        // Create edges between nodes
        for edge in reactFlowData.edges {
            if let sourceEntity = nodeEntities[edge.source],
               let targetEntity = nodeEntities[edge.target] {

                let start = sourceEntity.position
                let end = targetEntity.position

                // Calculate midpoint for positioning the cylinder
                let midpoint = (start + end) / 2
                // Calculate distance for cylinder height
                let distance = simd_distance(start, end)
                // Calculate orientation to point the cylinder from source to target
                let orientation = simd_quatf(from: [0, 1, 0], to: normalize(end - start))

                // Create a thin cylinder for the edge
                let edgeMesh = MeshResource.generateCylinder(height: distance, radius: 0.002) // Very thin
                let edgeEntity = ModelEntity(mesh: edgeMesh, materials: [edgeMaterial])

                edgeEntity.transform.translation = midpoint
                // Rotate the cylinder to align with the connection axis (it's generated along Y-axis by default)
                edgeEntity.transform.rotation = orientation * simd_quatf(angle: .pi / 2, axis: [1, 0, 0])

                anchor.addChild(edgeEntity)
            }
        }

        return arView
    }

    // Update function is required but not used in this static scene
    func updateUIView(_ uiView: ARView, context: Context) {}
}
