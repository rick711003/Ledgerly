import SwiftUI

enum LedgerTheme {
    static let ivory = Color(red: 246 / 255, green: 241 / 255, blue: 233 / 255)
    static let paper = Color(red: 255 / 255, green: 252 / 255, blue: 246 / 255)
    static let navy = Color(red: 36 / 255, green: 61 / 255, blue: 75 / 255)
    static let ink = Color(red: 28 / 255, green: 42 / 255, blue: 48 / 255)
    static let terracotta = Color(red: 200 / 255, green: 117 / 255, blue: 90 / 255)
    static let sage = Color(red: 53 / 255, green: 105 / 255, blue: 88 / 255)
    static let olive = Color(red: 116 / 255, green: 112 / 255, blue: 77 / 255)
    static let hairline = navy.opacity(0.10)
    static let cardShadow = navy.opacity(0.10)
}

struct LedgerBackground: View {
    var showsArtwork = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [LedgerTheme.paper, LedgerTheme.ivory],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            if showsArtwork {
                Image("Ledgerly-Journal-Background-v1")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.18)
                    .blendMode(.multiply)
            }

            Circle()
                .fill(LedgerTheme.terracotta.opacity(0.08))
                .frame(width: 280, height: 280)
                .blur(radius: 28)
                .offset(x: 150, y: -300)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

struct EditorialTitle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 34, weight: .bold, design: .serif))
            .tracking(-0.6)
            .foregroundStyle(LedgerTheme.navy)
    }
}

struct LedgerCard: ViewModifier {
    var padding: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(LedgerTheme.paper.opacity(0.96))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(LedgerTheme.hairline, lineWidth: 1)
            }
            .shadow(color: LedgerTheme.cardShadow, radius: 18, y: 8)
    }
}

extension View {
    func editorialTitle() -> some View {
        modifier(EditorialTitle())
    }

    func ledgerCard(padding: CGFloat = 18) -> some View {
        modifier(LedgerCard(padding: padding))
    }
}

struct PrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(
                LinearGradient(
                    colors: [LedgerTheme.navy, LedgerTheme.navy.opacity(0.88)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: LedgerTheme.navy.opacity(configuration.isPressed ? 0.08 : 0.22), radius: 12, y: 6)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct LedgerIcon: View {
    let systemName: String
    var color = LedgerTheme.terracotta

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: 36, height: 36)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
    }
}

struct LedgerSectionTitle: View {
    let title: String
    var detail: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(LedgerTheme.ink)

            if let detail {
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
