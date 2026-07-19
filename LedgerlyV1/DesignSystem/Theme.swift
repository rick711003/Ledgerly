import SwiftUI

enum LedgerTheme {
    static let ivory = Color(red: 246/255, green: 241/255, blue: 233/255)
    static let navy = Color(red: 36/255, green: 61/255, blue: 75/255)
    static let terracotta = Color(red: 200/255, green: 117/255, blue: 90/255)
    static let sage = Color(red: 53/255, green: 105/255, blue: 88/255)
}
struct EditorialTitle: ViewModifier { func body(content: Content) -> some View { content.font(.custom("Georgia", size: 34, relativeTo: .largeTitle)).foregroundStyle(LedgerTheme.navy) } }
extension View { func editorialTitle() -> some View { modifier(EditorialTitle()) } }
struct PrimaryButton: ButtonStyle { func makeBody(configuration: Configuration) -> some View { configuration.label.font(.headline).frame(maxWidth: .infinity, minHeight: 48).background(LedgerTheme.navy.opacity(configuration.isPressed ? 0.75 : 1)).foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 14)) } }
