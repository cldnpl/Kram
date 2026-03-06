import SwiftUI

struct CoinBadgeView: View {
    let coins: Int

    var body: some View {
        HStack(spacing: 4) {
            Image("coin", bundle: .main)
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .frame(width: 24, height: 24)
            Text("\(coins)")
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    CoinBadgeView(coins: 42)
}
