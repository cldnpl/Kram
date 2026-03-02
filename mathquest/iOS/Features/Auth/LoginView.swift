import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        VStack(spacing: 24) {
            Text("MathQuest")
                .font(.largeTitle)
                .fontWeight(.bold)
            Spacer()
            Button(action: { Task { await viewModel.signInWithGoogle() } }) {
                Label("Google Sign-In", systemImage: "person.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            Button(action: { Task { await viewModel.signInWithApple() } }) {
                Label("Apple Sign-In", systemImage: "apple.logo")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.bordered)
            Spacer()
        }
        .padding()
    }
}

#Preview {
    LoginView()
}
