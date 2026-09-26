import SwiftUI

enum Theme {
    static let green = Color(red: 0.12, green: 0.48, blue: 0.30)
    static let orange = Color(red: 1.0, green: 0.48, blue: 0.16)
    static let card = Color(red: 0.075, green: 0.085, blue: 0.08)
    static let muted = Color.white.opacity(0.56)
}
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View { content.padding(16).background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous)) }
}
extension View { func fuelCard() -> some View { modifier(CardStyle()) } }
