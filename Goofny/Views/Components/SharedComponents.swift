import SwiftUI

// MARK: - Pet avatar (async image with placeholder)

struct PetAvatarView: View {
    let urlString: String?
    var size: CGFloat = 80
    var cornerRadius: CGFloat = 16

    var body: some View {
        AsyncImage(url: urlString.flatMap(URL.init(string:))) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            case .failure:
                placeholder
            case .empty:
                ZStack { Color(.systemGray6); ProgressView() }
            @unknown default:
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    private var placeholder: some View {
        ZStack {
            Color(.systemGray5)
            Image(systemName: "pawprint.fill")
                .font(.system(size: size * 0.35))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Title badge (King / Queen)

struct TitleBadge: View {
    let title: String

    var body: some View {
        Label(title, systemImage: "crown.fill")
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(title == "King" ? Color.yellow.opacity(0.25) : Color.pink.opacity(0.2))
            .foregroundStyle(title == "King" ? .orange : .pink)
            .clipShape(Capsule())
    }
}

// MARK: - Vote button

struct VoteButton: View {
    let votesCount: Int
    let hasVoted: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: hasVoted ? "heart.fill" : "heart")
                Text("\(votesCount)")
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            .font(.subheadline.bold())
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(hasVoted ? Color.pink.opacity(0.15) : Color(.systemGray6))
            .foregroundStyle(hasVoted ? .pink : .primary)
            .clipShape(Capsule())
        }
        .disabled(hasVoted)
        .sensoryFeedback(.success, trigger: hasVoted)
        .animation(.bouncy, value: votesCount)
    }
}

// MARK: - Rank chip

struct RankChip: View {
    let rank: Int

    var body: some View {
        Text("#\(rank)")
            .font(.caption.bold().monospacedDigit())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(background)
            .foregroundStyle(rank <= 3 ? .white : .secondary)
            .clipShape(Capsule())
    }

    private var background: Color {
        switch rank {
        case 1: .yellow
        case 2: Color(.systemGray)
        case 3: .brown
        default: Color(.systemGray6)
        }
    }
}

// MARK: - Empty state

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text(title).font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
}
