import WidgetKit
import SwiftUI

/// "Speak today's lift": the Fatcamp mark in the Smart Stack (turn the Digital
/// Crown from the watch face) and as a complication. Tapping it opens Fatcamp
/// straight to the mic.
struct ForgeEntry: TimelineEntry { let date: Date }

struct ForgeProvider: TimelineProvider {
    func placeholder(in context: Context) -> ForgeEntry { ForgeEntry(date: .now) }
    func getSnapshot(in context: Context, completion: @escaping (ForgeEntry) -> Void) { completion(ForgeEntry(date: .now)) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<ForgeEntry>) -> Void) {
        completion(Timeline(entries: [ForgeEntry(date: .now)], policy: .never))
    }
}

private let red = Color(red: 0.847, green: 0.220, blue: 0.169)   // #D8382B

struct ForgeWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: ForgeEntry

    var body: some View {
        content
            .widgetURL(URL(string: "fatcamp://speak"))
            .containerBackground(for: .widget) { Color.black }
    }

    @ViewBuilder private var content: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Image("Mark").resizable().scaledToFit().clipShape(Circle()).padding(3)
                    .widgetAccentable()
            }
        case .accessoryCorner:
            Image(systemName: "mic.fill").font(.system(size: 20, weight: .bold))
                .widgetLabel("Forge")
        case .accessoryInline:
            Label("Speak today's lift", systemImage: "mic.fill")
        default:   // .accessoryRectangular: the Smart Stack card
            HStack(spacing: 8) {
                Image("Mark").resizable().scaledToFit().frame(width: 40, height: 40).clipShape(Circle())
                    .widgetAccentable()
                VStack(alignment: .leading, spacing: 1) {
                    Text("FATCAMP").font(.system(size: 11, weight: .heavy)).tracking(0.6).foregroundStyle(red)
                        .widgetAccentable()
                    Text("Speak today's lift").font(.system(size: 15, weight: .heavy)).lineLimit(1).minimumScaleFactor(0.7)
                    HStack(spacing: 3) {
                        Image(systemName: "mic.fill").font(.system(size: 10, weight: .bold))
                        Text("Tap to forge").font(.system(size: 11, design: .monospaced))
                    }
                    .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

@main
struct FatcampWidgets: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "FatcampForge", provider: ForgeProvider()) { entry in
            ForgeWidgetView(entry: entry)
        }
        .configurationDisplayName("Forge a workout")
        .description("Tap, speak, train.")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular, .accessoryCorner, .accessoryInline])
    }
}
