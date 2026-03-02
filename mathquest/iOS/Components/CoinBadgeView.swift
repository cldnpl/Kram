import SwiftUI

struct CoinBadgeView: View {
    let coins: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "dollarsign.circle.fill")
                .foregroundStyle(.yellow)
            Text("\(coins)")
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    CoinBadgeView(coins: 42)
}
