import AppIntents
import SwiftUI
import WidgetKit

/// Lock Screen widget (accessoryRectangular): ticking countdown to 23:00 and a button that starts a
/// Live Activity through StartDayIntent (LiveActivityIntent → runs in the app process) — question 4.
struct BedtimeEntry: TimelineEntry {
    let date: Date
    let target: Date
}

struct BedtimeProvider: TimelineProvider {
    func placeholder(in context: Context) -> BedtimeEntry {
        let now = Date()
        return BedtimeEntry(date: now, target: SpikeTime.nextBedtime(from: now))
    }

    func getSnapshot(in context: Context, completion: @escaping (BedtimeEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BedtimeEntry>) -> Void) {
        let now = Date()
        let target = SpikeTime.nextBedtime(from: now)
        let entry = BedtimeEntry(date: now, target: target)
        // Reload a minute after 23:00 so the widget switches to the next day's target.
        completion(Timeline(entries: [entry], policy: .after(target.addingTimeInterval(60))))
    }
}

struct BedtimeWidgetView: View {
    let entry: BedtimeEntry

    var body: some View {
        HStack(spacing: 4) {
            VStack(alignment: .leading, spacing: 0) {
                Text(verbatim: "До 23:00 · spike")
                    .font(.caption2)
                Text(timerInterval: entry.date...max(entry.target, entry.date.addingTimeInterval(1)), countsDown: true)
                    .font(Font.system(size: 22, weight: .semibold).monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            Spacer(minLength: 2)
            Button(intent: StartDayIntent(source: "виджет")) {
                Image(systemName: "play.fill")
            }
        }
        .containerBackground(Color.clear, for: .widget)
    }
}

struct BedtimeWidget: Widget {
    let kind: String = "BedtimeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BedtimeProvider()) { entry in
            BedtimeWidgetView(entry: entry)
        }
        .configurationDisplayName("До отбоя (spike)")
        .description("Отсчёт до 23:00 и кнопка запуска Live Activity")
        .supportedFamilies([.accessoryRectangular])
    }
}
