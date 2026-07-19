import SwiftUI

enum LedgerlyStyle { static let paper = Color(red: 0.965, green: 0.945, blue: 0.914); static let navy = Color(red: 0.14, green: 0.24, blue: 0.29); static let sage = Color(red: 0.21, green: 0.41, blue: 0.35); static let clay = Color(red: 0.78, green: 0.46, blue: 0.35); static let danger = Color(red: 0.66, green: 0.275, blue: 0.24) }
struct EditorialTitle: ViewModifier { func body(content: Content) -> some View { content.font(.custom("Georgia", size: 29, relativeTo: .title)).fontWeight(.bold).foregroundStyle(LedgerlyStyle.navy) } }
extension View { func editorialTitle() -> some View { modifier(EditorialTitle()) }; func ledgerCard() -> some View { padding(16).background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 18)).overlay(RoundedRectangle(cornerRadius: 18).stroke(.brown.opacity(0.16))) } }
struct PrimaryButton: ButtonStyle { func makeBody(configuration: Configuration) -> some View { configuration.label.frame(maxWidth: .infinity, minHeight: 48).background(LedgerlyStyle.navy.opacity(configuration.isPressed ? 0.82 : 1), in: RoundedRectangle(cornerRadius: 14)).foregroundStyle(.white).scaleEffect(configuration.isPressed ? 0.98 : 1) } }
