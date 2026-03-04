import SwiftUI

struct CoinBadgeView: View {
    let coins: Int
    /// Stile pill: sfondo a capsula, bordo, coin giallo, numero nero.
    var pillStyle: Bool = false

    var body: some View {
        let content = HStack(spacing: 6) {
            Image(systemName: "dollarsign.circle.fill")
                .foregroundStyle(.yellow)
            Text("\(coins)")
                .fontWeight(.semibold)
                .foregroundStyle(pillStyle ? .black : .primary)
        }
        .padding(.horizontal, pillStyle ? 14 : 0)
        .padding(.vertical, pillStyle ? 10 : 0)

        if pillStyle {
            content
                .background(Capsule().fill(Color.white))
                .overlay(Capsule().stroke(Color.black.opacity(0.15), lineWidth: 1))
        } else {
            content
        }
    }
}

#Preview {
    CoinBadgeView(coins: 42)
}
