//
//  SetupPreviews.swift
//  Shifty
//

import Cocoa

// The wizard used to illustrate itself with screenshots: one of the menu bar,
// one of the menu, the latter in five languages. Both were captured in 2021 and
// both were wrong within one release of the menu changing. These build the same
// idea out of the app's own icon, its own menu switch and the system's colours,
// so there is nothing left to recapture.

/// Decorative: swallow clicks so nothing inside looks pressable.
class PreviewView: NSView {
    override func hitTest(_ point: NSPoint) -> NSView? { return nil }

    static func menuLabel(_ text: String, dim: Bool = false, semibold: Bool = false) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = semibold
            ? .systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)
            : .menuFont(ofSize: 0)
        label.textColor = dim ? .tertiaryLabelColor : .labelColor
        return label
    }

    /// A panel with a menu's proportions: same corner radius, same faint edge.
    static func menuPanel() -> NSView {
        let panel = NSView()
        panel.wantsLayer = true
        panel.layer?.cornerRadius = 8
        panel.layer?.cornerCurve = .continuous
        panel.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        panel.layer?.borderWidth = 1
        panel.layer?.borderColor = NSColor.separatorColor.cgColor
        panel.shadow = {
            let s = NSShadow()
            s.shadowColor = NSColor.black.withAlphaComponent(0.28)
            s.shadowBlurRadius = 10
            s.shadowOffset = NSSize(width: 0, height: -3)
            return s
        }()
        return panel
    }
}


/// The menu bar, with Shifty's real template icon in it. Page 1 says "look up
/// there", so it shows the bar and what drops out of it when you click.
class MenuBarPreview: PreviewView {
    override var intrinsicContentSize: NSSize { NSSize(width: 435, height: 152) }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard subviews.isEmpty else { return }

        let bar = NSView()
        bar.wantsLayer = true
        bar.layer?.cornerRadius = 6
        bar.layer?.backgroundColor = NSColor.tertiaryLabelColor.withAlphaComponent(0.16).cgColor

        // The real thing, tinted the way the menu bar tints it.
        let icon = NSImageView()
        icon.image = NSImage(named: "shiftyMenuIcon")
        icon.image?.isTemplate = true
        icon.contentTintColor = .labelColor
        icon.imageScaling = .scaleProportionallyDown

        // macOS draws a rounded highlight behind the status item whose menu is
        // open. This is that, so it's clear which icon the menu came from.
        let highlight = NSView()
        highlight.wantsLayer = true
        highlight.layer?.cornerRadius = 6
        highlight.layer?.cornerCurve = .continuous
        highlight.layer?.backgroundColor = NSColor.labelColor.withAlphaComponent(0.20).cgColor
        highlight.addSubview(icon)
        icon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 16),
            icon.heightAnchor.constraint(equalToConstant: 16),
            icon.centerXAnchor.constraint(equalTo: highlight.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: highlight.centerYAnchor),
            highlight.widthAnchor.constraint(equalToConstant: 30),
            highlight.heightAnchor.constraint(equalToConstant: 20),
        ])

        // The items a real menu bar has to the right of a new status item, so
        // Shifty sits where it actually would: leftmost of the group, because an
        // item added now goes to the left of the ones already there.
        func systemGlyph(_ symbol: String) -> NSImageView {
            let view = NSImageView()
            view.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
            view.contentTintColor = .labelColor
            view.imageScaling = .scaleProportionallyDown
            view.heightAnchor.constraint(equalToConstant: 15).isActive = true
            return view
        }
        let sound = systemGlyph("speaker.wave.2.fill")
        let wifi = systemGlyph("wifi")
        let controlCentre = systemGlyph("switch.2")
        let clock = PreviewView.menuLabel("Tue 1 Sep  9:41")
        clock.font = .systemFont(ofSize: 11.5)

        let cluster = NSStackView(views: [highlight, sound, wifi, controlCentre, clock])
        cluster.orientation = .horizontal
        cluster.alignment = .centerY
        cluster.spacing = 11

        // The menu that drops from it, using the switch the real menu draws.
        let toggle = MenuSwitch()
        toggle.isOn = true
        let switchRow = NSStackView(views: [
            PreviewView.menuLabel("Night Shift", semibold: true),
            NSView(),
            toggle,
        ])
        switchRow.orientation = .horizontal
        switchRow.alignment = .centerY

        let rows = NSStackView(views: [
            switchRow,
            PreviewView.menuLabel("Enabled until sunrise", dim: true),
        ])
        rows.orientation = .vertical
        rows.alignment = .leading
        rows.spacing = 3
        rows.edgeInsets = NSEdgeInsets(top: 8, left: 12, bottom: 10, right: 12)

        let panel = PreviewView.menuPanel()
        panel.addSubview(rows)
        rows.translatesAutoresizingMaskIntoConstraints = false

        for v in [bar, cluster, panel] { v.translatesAutoresizingMaskIntoConstraints = false }
        addSubview(bar)
        bar.addSubview(cluster)
        addSubview(panel)

        NSLayoutConstraint.activate([
            bar.topAnchor.constraint(equalTo: topAnchor),
            bar.leadingAnchor.constraint(equalTo: leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: trailingAnchor),
            bar.heightAnchor.constraint(equalToConstant: 24),

            cluster.trailingAnchor.constraint(equalTo: bar.trailingAnchor, constant: -12),
            cluster.centerYAnchor.constraint(equalTo: bar.centerYAnchor),

            // Hanging directly under the icon, which it can now that the system
            // items push Shifty far enough from the right edge for it to fit.
            panel.topAnchor.constraint(equalTo: bar.bottomAnchor, constant: 5),
            panel.leadingAnchor.constraint(equalTo: highlight.leadingAnchor),
            panel.widthAnchor.constraint(equalToConstant: 200),

            rows.topAnchor.constraint(equalTo: panel.topAnchor),
            rows.leadingAnchor.constraint(equalTo: panel.leadingAnchor),
            rows.trailingAnchor.constraint(equalTo: panel.trailingAnchor),
            rows.bottomAnchor.constraint(equalTo: panel.bottomAnchor),
        ])
    }
}


/// Two of the menu's website rows, with the subdomain indented under the domain
/// exactly as the real menu indents it. Sized from the text it draws, so the
/// padding around it is the padding chosen here rather than whatever is left
/// over from a round number.
class WebsiteRulesPreview: PreviewView {
    private static let tick: CGFloat = 14      // column the checkmark sits in
    private static let tickGap: CGFloat = 4
    private static let indent: CGFloat = 18    // the real menu's indent level
    private static let leftInset: CGFloat = 12
    private static let rightPad: CGFloat = 14
    private static let topInset: CGFloat = 11
    private static let bottomInset: CGFloat = 11
    private static let rowGap: CGFloat = 8

    private static var rows: [(text: String, ticked: Bool, indent: CGFloat)] {[
        (NSLocalizedString("setup.rule_example_domain",
                           comment: "Disable for github.com"), true, 0),
        (NSLocalizedString("setup.rule_example_subdomain",
                           comment: "Disable for gist.github.com"), false, indent),
    ]}

    private static var font: NSFont { .menuFont(ofSize: 0) }

    override var intrinsicContentSize: NSSize {
        let widest = Self.rows
            .map { $0.indent + Self.tick + Self.tickGap
                   + ($0.text as NSString).size(withAttributes: [.font: Self.font]).width }
            .max() ?? 0
        let rowHeight = ceil(Self.font.boundingRectForFont.height)
        return NSSize(
            width: ceil(widest) + Self.leftInset + Self.rightPad,
            height: Self.topInset + rowHeight * 2 + Self.rowGap + Self.bottomInset)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard subviews.isEmpty else { return }

        func row(_ item: (text: String, ticked: Bool, indent: CGFloat)) -> NSView {
            let tick = PreviewView.menuLabel("✓")
            tick.textColor = item.ticked ? .controlAccentColor : .clear
            tick.alignment = .center
            tick.widthAnchor.constraint(equalToConstant: Self.tick).isActive = true

            let stack = NSStackView(views: [tick, PreviewView.menuLabel(item.text, dim: !item.ticked)])
            stack.orientation = .horizontal
            stack.alignment = .firstBaseline
            stack.spacing = Self.tickGap
            stack.edgeInsets = NSEdgeInsets(top: 0, left: item.indent, bottom: 0, right: 0)
            return stack
        }

        let rows = NSStackView(views: Self.rows.map(row))
        rows.orientation = .vertical
        rows.alignment = .leading
        rows.spacing = Self.rowGap
        rows.edgeInsets = NSEdgeInsets(top: Self.topInset, left: Self.leftInset,
                                       bottom: Self.bottomInset, right: 0)

        let panel = PreviewView.menuPanel()
        panel.addSubview(rows)
        rows.translatesAutoresizingMaskIntoConstraints = false
        panel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(panel)

        NSLayoutConstraint.activate([
            panel.topAnchor.constraint(equalTo: topAnchor),
            panel.bottomAnchor.constraint(equalTo: bottomAnchor),
            panel.leadingAnchor.constraint(equalTo: leadingAnchor),
            panel.trailingAnchor.constraint(equalTo: trailingAnchor),

            rows.topAnchor.constraint(equalTo: panel.topAnchor),
            rows.leadingAnchor.constraint(equalTo: panel.leadingAnchor),
            rows.bottomAnchor.constraint(equalTo: panel.bottomAnchor),
        ])
    }
}


/// The supported browsers, one row of icons. Each is taken from the
/// installed copy where there is one, so it's whatever that browser looks like
/// today, and falls back to the bundled asset otherwise.
class BrowserStrip: PreviewView {
    // Same order as the sentence above them.
    private static let browsers: [(name: String, bundleID: String, asset: String)] = [
        ("Safari",  "com.apple.Safari",             "safariIcon"),
        ("Chrome",  "com.google.Chrome",            "chromeIcon"),
        ("Brave",   "com.brave.Browser",            "braveIcon"),
        ("Edge",    "com.microsoft.edgemac",        "edgeIcon"),
        ("Opera",   "com.operasoftware.Opera",      "operaIcon"),
        ("Vivaldi", "com.vivaldi.Vivaldi",          "vivaldiIcon"),
    ]

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard subviews.isEmpty else { return }

        let icons = Self.browsers.map { browser -> NSImageView in
            let icon = NSImageView()
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: browser.bundleID) {
                icon.image = NSWorkspace.shared.icon(forFile: url.path)
            } else {
                icon.image = NSImage(named: browser.asset)
            }
            icon.imageScaling = .scaleProportionallyDown
            icon.widthAnchor.constraint(equalToConstant: 44).isActive = true
            icon.heightAnchor.constraint(equalToConstant: 44).isActive = true
            // The sentence above names every browser, so these carry no
            // information a screen reader needs to announce again.
            icon.setAccessibilityElement(false)
            return icon
        }

        let row = NSStackView(views: icons)
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 18
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)

        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor),
            row.bottomAnchor.constraint(equalTo: bottomAnchor),
            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }
}


