import SwiftUI
import WidgetKit

/// Both the Live Activity and the Lock Screen widget must be listed here, otherwise the system can
/// create an activity that the extension never renders.
@main
struct SpikeWidgetBundle: WidgetBundle {
    var body: some Widget {
        DayLiveActivity()
        BedtimeWidget()
    }
}
