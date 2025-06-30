//
//  NetworkService.swift
//  Nektar
//
//  Created by Aliosa on 30.06.2025.
//

import Foundation

enum NetworkError: Error, LocalizedError {
	case invalidURL
	case noData
	case decodingFailed(Error)
	case serverError(statusCode: Int, message: String)
	case unauthorized
	case unknown(Error)

	var errorDescription: String? {
		switch self {
		case .invalidURL: return "The URL provided was invalid."
		case .noData: return "No data was received from the server."
		case .decodingFailed(let error): return "Failed to decode server response: \(error.localizedDescription)"
		case .serverError(let statusCode, let message): return "Server error \(statusCode): \(message)"
		case .unauthorized: return "Authentication failed or session expired. Please log in again."
		case .unknown(let error): return "An unexpected error occurred: \(error.localizedDescription)"
		}
	}
}

class NetworkService {
	static let shared = NetworkService()

	func request<T: Decodable>(
		url: URL,
		method: String,
		body: Encodable? = nil,
		authToken: String? = nil
	) async throws -> T {
		var request = URLRequest(url: url)
		request.httpMethod = method
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")

		if let token = authToken {
			request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
		}

		if let body = body {
			request.httpBody = try JSONEncoder().encode(body)
		}

		let (data, response) = try await URLSession.shared.data(for: request)

		guard let httpResponse = response as? HTTPURLResponse else {
			throw NetworkError.invalidURL
		}

		switch httpResponse.statusCode {
		case 200...299:
			do {
				return try JSONDecoder().decode(T.self, from: data)
			} catch {
				throw NetworkError.decodingFailed(error)
			}
		case 401:
			throw NetworkError.unauthorized
		case 400...499:
			let errorMessage = String(data: data, encoding: .utf8) ?? "Client error"
			throw NetworkError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
		case 500...599:
			let errorMessage = String(data: data, encoding: .utf8) ?? "Server error"
			throw NetworkError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
		default:
			let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown server response"
			throw NetworkError.unknown(NSError(domain: "Network", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
		}
	}
}
