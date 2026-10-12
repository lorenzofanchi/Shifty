//
//  SettingsView.swift
//  Shifty
//

import SwiftUI
import ServiceManagement
import AXSwift
import MASShortcut
import SwiftLog

/// The settings window's content: a sidebar of panes beside a grouped form,
/// laid out like System Settings.
struct SettingsView: View {
    private enum Pane: CaseIterable, Identifiable {
        case general, nightShift, shortcuts, about
        var id: Self { self }

        var title: String {
            switch self {
            case .general: NSLocalizedString("prefs.general", comment: "General")
            case .nightShift: "Night Shift"
            case .shortcuts: NSLocalizedString("prefs.shortcuts", comment: "Shortcuts")
            case .about: NSLocalizedString("prefs.about", comment: "About")
            }
        }

        var systemImage: String {
            switch self {
            case .general: "gearshape"
            case .nightShift: "moon"
            case .shortcuts: "command"
            case .about: "info.circle"
            }
        }
    }

    /// Called with the selected pane's name, for the window's title.
    var setTitle: (String) -> Void = { _ in }

    @State private var pane: Pane? = .general

    var body: some View {
        NavigationSplitView {
            List(Pane.allCases, selection: $pane) { pane in
                Label(pane.title, systemImage: pane.systemImage)
            }
            .navigationSplitViewColumnWidth(180)
            .toolbar(removing: .sidebarToggle)
        } detail: {
            Form {
                switch pane ?? .general {
                case .general: GeneralPane()
                case .nightShift: NightShiftPane()
                case .shortcuts: ShortcutsPane()
                case .about: AboutPane()
                }
            }
            .formStyle(.grouped)
        }
        .onChange(of: pane, initial: true) { setTitle((pane ?? .general).title) }
        .frame(width: 700, height: 500)
    }
}


/// A setting's title with a short explanation underneath.
private func label(_ title: LocalizedStringKey, caption: LocalizedStringKey) -> some View {
    VStack(alignment: .leading, spacing: 4) {
        Text(title)
        Text(caption)
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }
}

/// Writes through to `value`, then runs `action`. For settings whose switch has
/// a side effect, so it runs only when the person flips it, not whenever the
/// default changes underneath.
private func binding(_ value: Binding<Bool>, then action: @escaping (Bool) -> Void) -> Binding<Bool> {
    Binding(get: { value.wrappedValue },
            set: { value.wrappedValue = $0; action($0) })
}


private struct GeneralPane: View {
    @AppStorage(Keys.isAutoLaunchEnabled) private var autoLaunch = false
    @AppStorage(Keys.isStatusToggleEnabled) private var quickToggle = false
    @AppStorage(Keys.isWebsiteControlEnabled) private var websiteShifting = false
    @AppStorage(Keys.isDarkModeSyncEnabled) private var darkModeSync = false
    @AppStorage(Keys.trueToneControl) private var trueToneControl = false

    @State private var isAccessibilityTrusted = UIElement.isProcessTrusted()

    /// The appearance to put back when Scheduled Dark Mode is switched off.
    private static var defaultDarkModeState = SLSGetAppearanceThemeLegacy()

    var body: some View {
        Section {
            Toggle("Launch Shifty at login", isOn: binding($autoLaunch, then: setAutoLaunch))

            Toggle(isOn: binding($quickToggle) { on in
                (NSApp.delegate as? AppDelegate)?.setStatusToggle()
                logw("Quick Toggle set to \(on)")
            }) {
                label("Quick Toggle",
                      caption: "If enabled, click the Menu Bar icon to toggle Night Shift. Right click to open the menu.")
            }
        }

        Section {
            Toggle(isOn: binding($websiteShifting, then: setWebsiteShifting)) {
                label("Website Shifting",
                      caption: "If enabled, you can set Night Shift to automatically disable when you visit certain websites.")
            }

            // macOS only ever shows its own prompt once, so after a denial this
            // row is the only thing left saying the feature isn't working.
            if websiteShifting && !isAccessibilityTrusted {
                LabeledContent {
                    Button("Open Accessibility Settings…", action: openAccessibilitySettings)
                } label: {
                    Label {
                        Text("macOS needs to allow Shifty to read your browser’s address.")
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
        .onReceive(DistributedNotificationCenter.default().publisher(
            for: Notification.Name("com.apple.accessibility.api"))
        ) { _ in
            // The trust state lags the notification slightly.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isAccessibilityTrusted = UIElement.isProcessTrusted()
            }
        }

        Section {
            Toggle(isOn: binding($darkModeSync, then: setDarkModeSync)) {
                label("Scheduled Dark Mode",
                      caption: "If enabled, macOS Dark Mode will be automatically set based on the Night Shift schedule.")
            }

            if CBTrueToneClient.shared.state != .unsupported {
                Toggle(isOn: binding($trueToneControl, then: setTrueToneControl)) {
                    label("True Tone control",
                          caption: "If enabled, Night Shift rules for apps and websites will also affect True Tone.")
                }
            }
        }
    }

    private func setAutoLaunch(_ on: Bool) {
        let loginItem = SMAppService.loginItem(identifier: "io.natethompson.ShiftyHelper")
        do {
            if on {
                try loginItem.register()
            } else {
                try loginItem.unregister()
            }
            logw("Auto launch on login set to \(on)")
        } catch {
            logw("Error: could not set auto launch on login: \(error)")
        }
    }

    private func setWebsiteShifting(_ on: Bool) {
        logw("Website control preference clicked")
        if on {
            // Let macOS do the asking. Its alert is the only thing that adds
            // Shifty to the Accessibility list, which is what makes the switch
            // findable. It can't grant access, so the switch stays where the
            // person put it and the row below carries the "not yet" state.
            if !UIElement.isProcessTrusted(withPrompt: true) {
                logw("Accessibility not granted; system prompt shown")
            }
        } else {
            BrowserManager.shared.stopBrowserWatcher()
            logw("Website control disabled")
        }
        isAccessibilityTrusted = UIElement.isProcessTrusted()
    }

    private func openAccessibilitySettings() {
        // Prompt first: it re-adds Shifty to the list if it was removed, so the
        // row the person is about to look for is actually there.
        _ = UIElement.isProcessTrusted(withPrompt: true)
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }

    private func setDarkModeSync(_ on: Bool) {
        if on {
            Self.defaultDarkModeState = SLSGetAppearanceThemeLegacy()
            NightShiftManager.shared.updateDarkMode()
        } else {
            SLSSetAppearanceThemeLegacy(Self.defaultDarkModeState)
        }
        logw("Dark mode sync preference set to \(on)")
    }

    private func setTrueToneControl(_ on: Bool) {
        if on {
            if NightShiftManager.shared.isDisableRuleActive {
                CBTrueToneClient.shared.isTrueToneEnabled = false
            }
        } else {
            CBTrueToneClient.shared.isTrueToneEnabled = true
        }
        logw("True Tone control set to \(on)")
    }
}


/// Night Shift's schedule, kept current when it's changed elsewhere, such as in
/// System Settings. One shared instance, since NightShiftManager has no way to
/// stop listening.
private final class ScheduleObserver: ObservableObject {
    static let shared = ScheduleObserver()

    @Published var schedule = NightShiftManager.shared.schedule {
        didSet {
            if schedule != NightShiftManager.shared.schedule {
                NightShiftManager.shared.schedule = schedule
            }
        }
    }

    private init() {
        NightShiftManager.shared.onNightShiftChange { [weak self] in
            self?.schedule = NightShiftManager.shared.schedule
        }
    }
}


private struct NightShiftPane: View {
    private enum ScheduleKind { case off, custom, solar }

    @ObservedObject private var observer = ScheduleObserver.shared
    @AppStorage(Keys.transitionPeriod) private var transitionPeriod = -1.0

    /// Fade lengths in seconds. -1 leaves the fade to macOS, which takes 2s.
    private let transitions: [(title: LocalizedStringKey, period: Double)] = [
        ("Slow", 4), ("Normal", -1), ("Fast", 0.5), ("Very Fast", 0.1),
    ]

    private var kind: Binding<ScheduleKind> {
        Binding {
            switch observer.schedule {
            case .off: .off
            case .custom: .custom
            case .solar: .solar
            }
        } set: { kind in
            switch kind {
            case .off: observer.schedule = .off
            case .solar: observer.schedule = .solar
            case .custom:
                // The times macOS keeps from the last custom schedule.
                let saved = CBBlueLightClient.shared.blueLightStatus.schedule
                observer.schedule = .custom(start: saved.fromTime, end: saved.toTime)
            }
        }
    }

    private func time(isStart: Bool) -> Binding<Date> {
        Binding {
            guard case let .custom(start, end) = observer.schedule else { return Date() }
            return Date(isStart ? start : end)
        } set: { date in
            guard case let .custom(start, end) = observer.schedule else { return }
            observer.schedule = isStart
                ? .custom(start: Time(date), end: end)
                : .custom(start: start, end: Time(date))
        }
    }

    var body: some View {
        Section {
            Picker("Schedule", selection: kind) {
                Text("Off").tag(ScheduleKind.off)
                Text("Custom").tag(ScheduleKind.custom)
                Text("Sunset to Sunrise").tag(ScheduleKind.solar)
            }

            if case .custom = observer.schedule {
                DatePicker("From", selection: time(isStart: true), displayedComponents: .hourAndMinute)
                DatePicker("To", selection: time(isStart: false), displayedComponents: .hourAndMinute)
            }
        }

        Section {
            Picker(selection: $transitionPeriod) {
                ForEach(transitions, id: \.period) { transition in
                    Text(transition.title).tag(transition.period)
                }
            } label: {
                label("Transition",
                      caption: "How quickly Night Shift fades when Shifty turns it on or off.")
            }
        }
    }
}


private struct ShortcutsPane: View {
    private typealias Row = (title: LocalizedStringKey, key: String)

    private var groups: [[Row]] {
        var other: [Row] = [("Toggle Dark Mode", Keys.toggleDarkModeShortcut)]
        if CBTrueToneClient.shared.state != .unsupported {
            other.insert(("Toggle True Tone", Keys.toggleTrueToneShortcut), at: 0)
        }
        return [
            [("Toggle Night Shift", Keys.toggleNightShiftShortcut),
             ("Increase color temp", Keys.incrementColorTempShortcut),
             ("Decrease color temp", Keys.decrementColorTempShortcut)],
            [("Disable for current app", Keys.disableAppShortcut),
             ("Disable for domain", Keys.disableDomainShortcut),
             ("Disable for subdomain", Keys.disableSubdomainShortcut),
             ("Disable for an hour", Keys.disableHourShortcut),
             ("Disable for custom time", Keys.disableCustomShortcut)],
            other,
        ]
    }

    var body: some View {
        ForEach(groups.indices, id: \.self) { index in
            Section {
                ForEach(groups[index], id: \.key) { row in
                    LabeledContent(row.title) {
                        ShortcutRecorder(defaultsKey: row.key)
                            // It has no text baseline of its own, so the row
                            // would line its bottom edge up with the label's.
                            .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + 5 }
                    }
                }
            }
        }
    }
}

/// MASShortcut's recorder, which saves straight to the given default.
private struct ShortcutRecorder: NSViewRepresentable {
    let defaultsKey: String

    func makeNSView(context: Context) -> MASShortcutView {
        let view = MASShortcutView()
        view.associatedUserDefaultsKey = defaultsKey
        return view
    }

    func updateNSView(_ view: MASShortcutView, context: Context) {}

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: MASShortcutView, context: Context) -> CGSize? {
        CGSize(width: 160, height: 22)
    }
}


private struct AboutPane: View {
    private var name: String {
        Bundle.main.localizedInfoDictionary?["CFBundleDisplayName"] as? String ?? "Shifty"
    }

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    var body: some View {
        Section {
            VStack(spacing: 6) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 96, height: 96)
                Text(name)
                    .font(.title2.weight(.semibold))
                Text(version)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }

        Section {
            LabeledContent("Website") {
                Link("github.com/lorenzofanchi/Shifty", destination: URL(string: "https://github.com/lorenzofanchi/Shifty")!)
            }
            LabeledContent("Donate") {
                Link("Ko-fi", destination: URL(string: "https://ko-fi.com/fruitfuldevelopment")!)
            }
        }

        Section {
            LabeledContent("Website") {
                Link("shifty.natethompson.io", destination: URL(string: "https://shifty.natethompson.io")!)
            }
            LabeledContent("Translate") {
                Link("Crowdin", destination: URL(string: "https://shifty.natethompson.io/translate")!)
            }
        } header: {
            Text("Based on Shifty by Nate Thompson")
        } footer: {
            // GPL v3 section 5: keep the original notice, mark the changes and
            // their date, and show both where the app shows its legal notices.
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Group {
                        Text(verbatim: "© 2017-2021 Nate Thompson")
                        Text(verbatim: "Modifications © 2026 Fruitful Development")
                    }
                    .foregroundStyle(.secondary)
                    Link("GNU General Public License v3", destination: URL(string: "https://www.gnu.org/licenses/gpl-3.0.html")!)
                }
                .font(.subheadline)
                Spacer()
                Button("Credits…") {
                    guard let url = Bundle.main.url(forResource: "credits", withExtension: "rtfd") else { return }
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
}
