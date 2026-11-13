import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

/// Lock Screen presentation + Dynamic Island (compact / minimal / expanded).
/// Only self-updating views are used: Text(timerInterval:) and ProgressView(timerInterval:).
/// Phrase A/B switches on `context.isStale` (set by the system at staleDate) — question 2.
struct DayLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DayAttributes.self) { context in
            LockScreenDayView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.85))
                .activitySystemActionForegroundColor(Color.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    SpikeDayRing(range: context.state.timerRange)
                        .frame(width: 40, height: 40)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(verbatim: context.isStale ? "B" : "A")
                        .font(.headline)
                        .foregroundStyle(context.isStale ? Color.orange : Color.green)
                }
                DynamicIslandExpandedRegion(.center) {
                    SpikeTimerText(range: context.state.timerRange, variant: context.attributes.fontVariant, size: 30)
                        .foregroundStyle(Color.white)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedBottomView(context: context)
                }
            } compactLeading: {
                SpikeDayRing(range: context.state.timerRange)
                    .frame(width: 22, height: 22)
            } compactTrailing: {
                Text(timerInterval: context.state.timerRange, countsDown: true)
                    .font(Font.system(size: 14, weight: .semibold).monospacedDigit())
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 64)
            } minimal: {
                SpikeDayRing(range: context.state.timerRange)
                    .frame(width: 22, height: 22)
            }
            .keylineTint(Color.orange)
        }
    }
}

struct LockScreenDayView: View {
    let context: ActivityViewContext<DayAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Text(verbatim: "\(context.state.segmentName) · \(context.attributes.label) · \(context.attributes.fontVariant)")
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.75))
                    .lineLimit(1)
                Spacer(minLength: 4)
                Text(verbatim: context.isStale ? "B · stale" : "A")
                    .font(.caption.bold())
                    .foregroundStyle(context.isStale ? Color.orange : Color.green)
            }
            HStack(alignment: .center, spacing: 8) {
                SpikeTimerText(range: context.state.timerRange, variant: context.attributes.fontVariant, size: 36)
                    .foregroundStyle(Color.white)
                Spacer(minLength: 4)
                Button(intent: SwapPhraseIntent(activityID: context.activityID)) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
                .tint(Color.orange)
            }
            ProgressView(timerInterval: context.state.timerRange, countsDown: true) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
            .tint(Color.orange)
            Text(verbatim: context.isStale ? context.state.stalePhrase : context.state.phrase)
                .font(.subheadline)
                .foregroundStyle(Color.white)
                .lineLimit(2)
        }
        .padding(12)
    }
}

struct ExpandedBottomView: View {
    let context: ActivityViewContext<DayAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ProgressView(timerInterval: context.state.timerRange, countsDown: true) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
            .tint(Color.orange)
            HStack(alignment: .center, spacing: 8) {
                Text(verbatim: context.isStale ? context.state.stalePhrase : context.state.phrase)
                    .font(.caption)
                    .lineLimit(2)
                Spacer(minLength: 4)
                Button(intent: SwapPhraseIntent(activityID: context.activityID)) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
                .tint(Color.orange)
            }
        }
    }
}

/// Self-ticking countdown in the bundled 7-segment font or in the system font (question 6).
struct SpikeTimerText: View {
    let range: ClosedRange<Date>
    let variant: String
    let size: CGFloat

    var body: some View {
        Text(timerInterval: range, countsDown: true)
            .font(SpikeFont.timer(variant: variant, size: size))
            .multilineTextAlignment(.leading)
            .lineLimit(1)
    }
}

/// "Кольцо остатка дня": system circular progress driven by the timer interval.
struct SpikeDayRing: View {
    let range: ClosedRange<Date>

    var body: some View {
        ProgressView(timerInterval: range, countsDown: true) {
            EmptyView()
        } currentValueLabel: {
            EmptyView()
        }
        .progressViewStyle(.circular)
        .tint(Color.orange)
    }
}
