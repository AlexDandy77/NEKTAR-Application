//
//  NodeDetailView.swift
//  Nektar
//
//  Created by Aliosa on 30.06.2025.
//

import SwiftUI

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
		.navigationBarHidden(true)
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
