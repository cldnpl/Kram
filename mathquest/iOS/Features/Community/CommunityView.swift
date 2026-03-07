import SwiftUI

private let appPurple = Color(red: 0.4, green: 0.3, blue: 0.9)

struct CommunityView: View {
    @State private var placeholderText = ""

    private var homeGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: appPurple, location: 0),
                .init(color: Color(red: 0.85, green: 0.82, blue: 0.98), location: 0.25),
                .init(color: Color(red: 0.93, green: 0.91, blue: 0.99), location: 0.3),
                .init(color: Color(red: 0.97, green: 0.96, blue: 1.0), location: 0.4),
                .init(color: Color.white, location: 0.55)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var body: some View {
        ZStack {
            homeGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Text("Community")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 56)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        TextField("Placeholder", text: $placeholderText)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .foregroundStyle(.secondary)

                        CommunityCard(
                            title: "Global arena",
                            icon: "globe",
                            action: {}
                        )

                        CommunityCard(
                            title: "Challenge a friend",
                            icon: "person.2.wave.2.fill",
                            action: {}
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 24)
                }
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
        }
    }
}

private struct CommunityCard: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.body)
                    .fontWeight(.regular)
                    .foregroundStyle(.black)

                Spacer()

                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(appPurple)
            }
            .padding(16)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(appPurple, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CommunityView()
}
