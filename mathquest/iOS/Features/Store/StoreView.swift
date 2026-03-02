import SwiftUI

private let coinPackages: [(coins: Int, price: Double)] = [
    (25, 2.99),
    (60, 5),
    (200, 15),
    (500, 49.99),
]

struct StoreView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(coinPackages, id: \.coins) { p in
                        HStack {
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.yellow)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(p.coins) coins")
                                    .font(.headline)
                                Text(priceString(p.price))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Purchase") {
                                // TODO: in-app purchase
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Get more coins")
                        .font(.headline)
                }
            }
            .navigationTitle("Coin Shop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func priceString(_ price: Double) -> String {
        if price == Double(Int(price)) {
            return "€\(Int(price))"
        }
        return String(format: "€%.2f", price)
    }
}

#Preview {
    StoreView()
}
