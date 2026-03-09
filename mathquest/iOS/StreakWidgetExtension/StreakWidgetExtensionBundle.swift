import WidgetKit
import SwiftUI

@main
struct StreakWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        StreakWidgetExtension()
        StreakWidgetExtensionControl()
        StreakLiveActivity()
    }
}
