import Foundation

struct CabinetItem: Identifiable, Codable {
    let id: Int
    let title: String
    let jsonData: String
    let createdAt: String

    init(id: Int, title: String, jsonData: String, createdAt: String) {
        self.id = id
        self.title = title
        self.jsonData = jsonData
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case jsonData = "content"
        case createdAt = "created_at"
    }
}
