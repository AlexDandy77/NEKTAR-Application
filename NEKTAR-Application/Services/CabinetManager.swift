//
//  CabinetManage.swift
//  Nektar
//
//  Created by Aliosa on 30.06.2025.
//

import SwiftUI
import Foundation

class CabinetManager: ObservableObject {
	@Published var cabinetItems: [CabinetItem] = []
	@Published var isLoading: Bool = false
	@Published var errorMessage: String? = nil

	private let cabinetItemsURL = URL(string: "\(baseURLString)/snippets")!
	private var authService: AuthManager

	init(authService: AuthManager) {
			self.authService = authService
		}
	
	@MainActor
	func fetchCabinetItems() async {
		isLoading = true
		errorMessage = nil

		guard let token = authService.authToken else {
			errorMessage = "Authentication token not found. Please log in again."
			isLoading = false
			authService.logout()
			return
		}

		do {
			let items: [CabinetItem] = try await NetworkService.shared.request(
				url: cabinetItemsURL,
				method: "GET",
				authToken: token
			)
			self.cabinetItems = items
		} catch let error as NetworkError {
			self.errorMessage = error.localizedDescription
			self.cabinetItems = []
			if case .unauthorized = error {
				authService.logout()
			}
		} catch {
			self.errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
			self.cabinetItems = []
		}
		isLoading = false
	}

	@MainActor
	func deleteCabinetItem(item: CabinetItem) async {
		guard let token = authService.authToken else {
			errorMessage = "Authentication token not found. Please log in again."
			return
		}

		guard let deleteURL = URL(string: "\(baseURLString)/snippets/\(item.id)") else {
			errorMessage = "Invalid delete URL for item ID: \(item.id)"
			return
		}

		do {
			_ = try await NetworkService.shared.request(
				url: deleteURL,
				method: "DELETE",
				authToken: token
			) as String

			if let index = cabinetItems.firstIndex(where: { $0.id == item.id }) {
				cabinetItems.remove(at: index)
			}
		} catch let error as NetworkError {
			self.errorMessage = "Failed to delete '\(item.title)': \(error.localizedDescription)"
			if case .unauthorized = error {
				authService.logout()
			}
		} catch {
			self.errorMessage = "An unexpected error occurred during delete: \(error.localizedDescription)"
		}
	}
}
