import SwiftUI

struct RewardsView: View {
    var body: some View {
        List {
            Text(L10n.rewardsTitle)
        }
        .navigationTitle(L10n.rewardsNavTitle)
    }
}
