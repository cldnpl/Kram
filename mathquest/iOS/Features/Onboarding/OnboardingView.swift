import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    var onComplete: () -> Void

    var body: some View {
        Form {
            TextField(L10n.name, text: $viewModel.name)
            TextField(L10n.age, value: $viewModel.age, format: .number)
                .keyboardType(.numberPad)
            Picker(L10n.mathLevel, selection: $viewModel.mathLevel) {
                Text(L10n.levelBeginner).tag("beginner")
                Text(L10n.levelIntermediate).tag("intermediate")
                Text(L10n.levelAdvanced).tag("advanced")
            }
            .pickerStyle(.menu)
            Button(L10n.continue) {
                Task {
                    await viewModel.submit()
                    onComplete()
                }
            }
        }
        .navigationTitle(L10n.setupProfileTitle)
    }
}

#Preview {
    NavigationStack { OnboardingView(onComplete: {}) }
}
