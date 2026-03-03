import SwiftUI

struct ProfileSetupView: View {
    @StateObject private var viewModel = ProfileSetupViewModel()
    let onComplete: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Name", text: $viewModel.name)
                        .textInputAutocapitalization(.words)

                    TextField("Age", text: $viewModel.age)
                        .keyboardType(.numberPad)

                    Picker("Math Level", selection: $viewModel.level) {
                        ForEach(viewModel.levels, id: \.self) { level in
                            Text(level).tag(level)
                        }
                    }
                }

                Section {
                    Button {
                        Task { await viewModel.submit(onComplete: onComplete) }
                    } label: {
                        if viewModel.isSubmitting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Continue")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(viewModel.isSubmitting)
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("Profile Setup")
        }
    }
}

#Preview {
    ProfileSetupView(onComplete: {})
}
