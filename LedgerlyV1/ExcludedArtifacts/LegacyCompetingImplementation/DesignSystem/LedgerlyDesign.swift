import SwiftUI

enum LedgerlyColor { static let paper = Color(red: 246/255, green: 241/255, blue: 233/255); static let navy = Color(red: 36/255, green: 61/255, blue: 75/255); static let sage = Color(red: 53/255, green: 105/255, blue: 88/255); static let clay = Color(red: 200/255, green: 117/255, blue: 90/255); static let danger = Color(red: 168/255, green: 70/255, blue: 61/255) }

struct EditorialTitle: ViewModifier { func body(content: Content) -> some View { content.font(.custom("Georgia", size: 30, relativeTo: .title)).fontWeight(.bold).foregroundStyle(LedgerlyColor.navy) } }
extension View { func editorialTitle() -> some View { modifier(EditorialTitle()) }; func ledgerCard() -> some View { padding(16).background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 16)).overlay(RoundedRectangle(cornerRadius: 16).stroke(.brown.opacity(0.15))) } }

struct PrimaryButton: View { let title: String; var destructive = false; let action: () -> Void
    var body: some View { Button(action: action) { Text(title).frame(maxWidth: .infinity, minHeight: 44) }.buttonStyle(.borderedProminent).tint(destructive ? LedgerlyColor.danger : LedgerlyColor.navy).accessibilityHint("Activates \(title)") }
}

func money(_ minor: Int64, currency: String) -> String { let f = NumberFormatter(); f.numberStyle = .currency; f.currencyCode = currency; return f.string(from: NSNumber(value: Double(minor) / 100)) ?? "\(minor)" }
