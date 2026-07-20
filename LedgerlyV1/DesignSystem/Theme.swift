import SwiftUI

enum LedgerTheme {
  static let ivory = Color(red: 246 / 255, green: 243 / 255, blue: 237 / 255)
  static let paper = Color(red: 253 / 255, green: 251 / 255, blue: 247 / 255)
  static let navy = Color(red: 28 / 255, green: 51 / 255, blue: 61 / 255)
  static let ink = Color(red: 25 / 255, green: 38 / 255, blue: 43 / 255)
  static let terracotta = Color(red: 191 / 255, green: 101 / 255, blue: 72 / 255)
  static let sage = Color(red: 49 / 255, green: 101 / 255, blue: 82 / 255)
  static let olive = Color(red: 112 / 255, green: 105 / 255, blue: 69 / 255)
  static let mutedInk = ink.opacity(0.58)
  static let hairline = navy.opacity(0.085)
  static let cardShadow = navy.opacity(0.065)
}

/// Design-owned semantic type roles. Product views must use these tokens instead of
/// inventing point sizes so Dynamic Type and visual hierarchy stay consistent.
enum LedgerTypography {
  static let displayAmount = Font.system(.largeTitle, design: .serif, weight: .semibold)
  static let heroAmount = Font.system(.largeTitle, design: .serif, weight: .bold)
  static let editorialTitle = Font.system(.largeTitle, design: .serif, weight: .bold)
  static let screenTitle = Font.system(.title2, design: .serif, weight: .bold)
  static let sectionTitle = Font.title3.weight(.bold)
  static let body = Font.body
  static let bodyStrong = Font.body.weight(.semibold)
  static let action = Font.headline
  static let label = Font.subheadline.weight(.semibold)
  static let caption = Font.caption
  static let captionStrong = Font.caption.weight(.bold)
  static let footnote = Font.footnote
  static let icon = Font.subheadline.weight(.semibold)
}

struct LedgerBackground: View {
  var showsArtwork = false

  var body: some View {
    ZStack {
      LinearGradient(
        colors: [LedgerTheme.paper, LedgerTheme.ivory.opacity(0.94)],
        startPoint: .top,
        endPoint: .bottom
      )

      if showsArtwork {
        GeometryReader { proxy in
          Image("Ledgerly-Journal-Background-v1")
            .resizable()
            .scaledToFill()
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
            .opacity(0.08)
            .blendMode(.multiply)
        }
      }

      LinearGradient(
        colors: [LedgerTheme.terracotta.opacity(0.035), .clear],
        startPoint: .topTrailing,
        endPoint: .center
      )
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .clipped()
    .ignoresSafeArea()
    .accessibilityHidden(true)
  }
}

struct EditorialTitle: ViewModifier {
  func body(content: Content) -> some View {
    content
      .font(LedgerTypography.editorialTitle)
      .tracking(-0.6)
      .foregroundStyle(LedgerTheme.navy)
  }
}

struct LedgerCard: ViewModifier {
  var padding: CGFloat = 18

  func body(content: Content) -> some View {
    content
      .padding(padding)
      .background(LedgerTheme.paper)
      .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
          .stroke(LedgerTheme.hairline, lineWidth: 1)
      }
      .shadow(color: LedgerTheme.cardShadow, radius: 10, y: 4)
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
      .font(LedgerTypography.action)
      .frame(maxWidth: .infinity, minHeight: 50)
      .background(
        LinearGradient(
          colors: [LedgerTheme.navy, LedgerTheme.navy.opacity(0.88)],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
      .foregroundStyle(.white)
      .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
      .shadow(
        color: LedgerTheme.navy.opacity(configuration.isPressed ? 0.05 : 0.14), radius: 8, y: 4
      )
      .scaleEffect(configuration.isPressed ? 0.985 : 1)
      .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
  }
}

struct LedgerIcon: View {
  let systemName: String
  var color = LedgerTheme.terracotta

  var body: some View {
    Image(systemName: systemName)
      .font(LedgerTypography.icon)
      .foregroundStyle(color)
      .frame(width: 34, height: 34)
      .background(color.opacity(0.12))
      .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
  }
}

struct LedgerSectionTitle: View {
  let title: String
  var detail: String?

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title)
        .font(LedgerTypography.sectionTitle)
        .foregroundStyle(LedgerTheme.ink)

      if let detail {
        Text(detail)
          .font(LedgerTypography.body)
          .foregroundStyle(.secondary)
      }
    }
  }
}

struct LedgerScreenHeader: View {
  let title: String
  let detail: String
  var systemName: String

  var body: some View {
    HStack(alignment: .center, spacing: 14) {
      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(LedgerTypography.screenTitle)
          .foregroundStyle(LedgerTheme.ink)
        Text(detail)
          .font(LedgerTypography.footnote)
          .foregroundStyle(LedgerTheme.mutedInk)
          .fixedSize(horizontal: false, vertical: true)
      }

      Spacer(minLength: 12)

      Image(systemName: systemName)
        .font(.body.weight(.semibold))
        .foregroundStyle(LedgerTheme.navy)
        .frame(width: 42, height: 42)
        .background(LedgerTheme.navy.opacity(0.07))
        .clipShape(Circle())
    }
  }
}
