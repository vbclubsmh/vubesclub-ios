import SwiftUI

enum ClubHaptics {
    static let welcome = SensoryFeedback.impact(weight: .medium, intensity: 0.8)
    static let fieldFocus = SensoryFeedback.impact(weight: .medium, intensity: 0.75)
    static let selection = SensoryFeedback.impact(weight: .light, intensity: 0.8)
}
