import SwiftUI

enum LedgerTheme {
    static let paper = Color(red: 0.965, green: 0.945, blue: 0.914)
    static let card = Color(red: 1.0, green: 0.992, blue: 0.976)
    static let navy = Color(red: 0.141, green: 0.239, blue: 0.294)
    static let sage = Color(red: 0.208, green: 0.412, blue: 0.345)
    static let clay = Color(red: 0.784, green: 0.459, blue: 0.353)
    static let danger = Color(red: 0.659, green: 0.275, blue: 0.239)
}

struct EditorialTitle: ViewModifier { func body(content: Content) -> some View { content.font(.system(.largeTitle, design: .serif, weight: .bold)).foregroundStyle(LedgerTheme.navy) } }
extension View { func editorialTitle() -> some View { modifier(EditorialTitle()) } }

struct PrimaryButton: ButtonStyle {
    var destructive = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).frame(maxWidth: .infinity, minHeight: 44).foregroundStyle(.white)
            .background(destructive ? LedgerTheme.danger : LedgerTheme.navy).clipShape(RoundedRectangle(cornerRadius: 14))
            .opacity(configuration.isPressed ? 0.85 : 1).scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct Notice: View { let text: String; var error = false; var body: some View { Label(text, systemImage: error ? "exclamationmark.triangle.fill" : "checkmark.circle.fill").font(.subheadline).padding(12).frame(maxWidth: .infinity, alignment: .leading).background((error ? LedgerTheme.danger : LedgerTheme.sage).opacity(0.12)).clipShape(RoundedRectangle(cornerRadius: 12)).accessibilityAddTraits(.isStaticText) } }
