import Foundation

struct CabinetItem: Identifiable, Codable {
    let id: Int
    let title: String
    let jsonData: String
    let createdAt: String // Use camelCase for Swift properties

    init(id: Int, title: String, jsonData: String, createdAt: String) {
        self.id = id
        self.title = title
        self.jsonData = jsonData
        self.createdAt = createdAt
    }

    // CodingKeys to map backend JSON keys to Swift property names
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case jsonData = "content"
        case createdAt = "created_at"
    }
}
