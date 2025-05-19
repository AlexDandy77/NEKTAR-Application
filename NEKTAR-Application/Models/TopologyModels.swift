import Foundation

// Top-level structure matching the "react_flow" key in your JSON
struct ReactFlowData: Codable {
    let edges: [ReactFlowEdge]
    let nodes: [ReactFlowNode]
}

// Structure for an individual edge in the topology
struct ReactFlowEdge: Codable, Identifiable {
    let animated: Bool
    let id: String
    let source: String // ID of the source node
    let target: String // ID of the target node
    let type: String   // e.g., "straight"
}

// Structure for an individual node (network device) in the topology
struct ReactFlowNode: Codable, Identifiable {
    let data: ReactFlowNodeData
    let id: String
    let position: ReactFlowNodePosition // Coordinates of the node
    let type: String                    // e.g., "custom" (likely refers to custom node type in React Flow)
}

// Data associated with a network device node
struct ReactFlowNodeData: Codable {
    let coordinates: String? // "168.5 288.0" - can be parsed if needed, but 'position' is more direct
    let `interface`: ReactNodeInterface? // Optional network interface details
    let label: String                    // Display name of the device (e.g., "PC0", "Router0")
    let power_on: Bool?
    let src: String?                     // Path to an image, e.g., "/images/pc.png"
    let type: String                     // Device type: "pc", "laptop", "switch", "router", "server"
}

// Structure for network interface details
struct ReactNodeInterface: Codable {
    let bandwidth: Int
    let ip: String
    let name: String
}

// Position coordinates for a node
struct ReactFlowNodePosition: Codable {
    let x: Double
    let y: Double
}
