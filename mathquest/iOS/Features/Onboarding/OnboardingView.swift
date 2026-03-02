import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    var onComplete: () -> Void

    var body: some View {
        Form {
            TextField("Name", text: $viewModel.name)
            TextField("Age", value: $viewModel.age, format: .number)
                .keyboardType(.numberPad)
            Picker("Math Level", selection: $viewModel.mathLevel) {
                Text("Beginner").tag("beginner")
                Text("Intermediate").tag("intermediate")
                Text("Advanced").tag("advanced")
            }
            .pickerStyle(.menu)
            Button("Continue") {
                Task {
                    await viewModel.submit()
                    onComplete()
                }
            }
        }
        .navigationTitle("Setup")
    }
}

#Preview {
    NavigationStack { OnboardingView(onComplete: {}) }
}
