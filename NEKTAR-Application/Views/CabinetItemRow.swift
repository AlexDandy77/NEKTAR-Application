import SwiftUI

struct CabinetItemRow: View {
    let item: CabinetItem
    let onShowJson: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(item.title)
                    .font(.headline)
                    .foregroundColor(Color.black.opacity(0.85))
                Text("Created: \(item.createdAt)")
                    .font(.subheadline)
                    .foregroundColor(Color.black.opacity(0.7))
                    .lineLimit(1)
            }
            Spacer()
            Button {
                onShowJson()
            } label: {
                Image(systemName: "arkit")
                    .foregroundColor(.blue.opacity(0.8))
                    .imageScale(.large)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 10)
    }
}
