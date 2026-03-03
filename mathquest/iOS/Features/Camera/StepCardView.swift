import SwiftUI

struct StepCardView: View {
    let stepNumber: Int
    let content: String
    let isVisible: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 32, height: 32)

                Text("\(stepNumber)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.blue)
            }

            Text(content)
                .font(.body)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
    }
}

struct AnswerCardView: View {
    let answer: String
    let isVisible: Bool
    @State private var scale: CGFloat = 0.8

    var body: some View {
        VStack(spacing: 8) {
            Text("Answer")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(answer)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.green)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .opacity(isVisible ? 1 : 0)
        .onChange(of: isVisible) { _, visible in
            if visible {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    scale = 1.0
                }
            }
        }
    }
}

struct DifficultyBadge: View {
    let level: String

    private var color: Color {
        switch level.lowercased() {
        case "elementary":
            return .green
        case "middle_school":
            return .blue
        case "high_school":
            return .orange
        case "college":
            return .red
        default:
            return .gray
        }
    }

    private var displayText: String {
        switch level.lowercased() {
        case "elementary":
            return "Elementary"
        case "middle_school":
            return "Middle School"
        case "high_school":
            return "High School"
        case "college":
            return "College"
        default:
            return level.capitalized
        }
    }

    var body: some View {
        Text(displayText)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}

#Preview {
    VStack(spacing: 16) {
        AnswerCardView(answer: "42", isVisible: true)
        StepCardView(stepNumber: 1, content: "First, identify the numbers: 7 and 5", isVisible: true)
        StepCardView(stepNumber: 2, content: "Add them together: 7 + 5 = 12", isVisible: true)

        HStack {
            DifficultyBadge(level: "elementary")
            DifficultyBadge(level: "middle_school")
            DifficultyBadge(level: "high_school")
            DifficultyBadge(level: "college")
        }
    }
    .padding()
}
