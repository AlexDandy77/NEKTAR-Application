import SwiftUI

struct CabinetItemRow: View {
    let item: CabinetItem
    let onShowJson: () -> Void // Callback to show JSON

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(item.title)
                    .font(.headline)
                    .foregroundColor(Color.black.opacity(0.85))
                Text(item.description)
                    .font(.subheadline)
                    .foregroundColor(Color.black.opacity(0.7))
                    .lineLimit(2)
            }
            Spacer()
            Button {
                onShowJson()
            } label: {
                Image(systemName: "doc.text.magnifyingglass")
                    .foregroundColor(.blue.opacity(0.8)) // A distinct color for the button
                    .imageScale(.large)
            }
            .buttonStyle(PlainButtonStyle()) // Removes default button styling in list
        }
        .padding(.vertical, 10)
    }
}
