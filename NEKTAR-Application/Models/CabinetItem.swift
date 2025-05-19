import SwiftUI

// Structure for items in the Personal Cabinet
struct CabinetItem: Identifiable, Codable {
    let id: UUID // For Identifiable
    let title: String
    let description: String
    let jsonData: String // To store the associated JSON as a string

    // Example initializer for mock data
    init(id: UUID = UUID(), title: String, description: String, jsonData: String) {
        self.id = id
        self.title = title
        self.description = description
        self.jsonData = jsonData
    }
}
