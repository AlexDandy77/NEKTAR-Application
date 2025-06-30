//
//  ARDataModels.swift
//  Nektar
//
//  Created by Aliosa on 30.06.2025.
//

import Foundation

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
		self.id = UUID().uuidString
	}
	
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
