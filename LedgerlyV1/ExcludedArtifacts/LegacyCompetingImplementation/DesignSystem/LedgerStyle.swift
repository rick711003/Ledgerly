import SwiftUI

extension Color { static let ledgerPaper = Color(red: 0.965, green: 0.945, blue: 0.914); static let ledgerNavy = Color(red: 0.14, green: 0.24, blue: 0.29); static let ledgerSage = Color(red: 0.21, green: 0.41, blue: 0.35); static let ledgerClay = Color(red: 0.78, green: 0.46, blue: 0.35) }
struct PrimaryLedgerButton: ButtonStyle { func makeBody(configuration: Configuration) -> some View { configuration.label.fontWeight(.semibold).frame(maxWidth: .infinity, minHeight: 44).background(Color.ledgerNavy.opacity(configuration.isPressed ? 0.82 : 1)).foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 13)) } }
struct EditorialTitle: ViewModifier { func body(content: Content) -> some View { content.font(.system(.largeTitle, design: .serif, weight: .bold)).foregroundStyle(Color.ledgerNavy) } }
extension View { func editorialTitle() -> some View { modifier(EditorialTitle()) } }
