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
    override var intrinsicContentSize: NSSize { NSSize(width: 435, height: 150) }

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

        // Shifty sits leftmost: a status item added now goes to the left of the
        // ones already there.
        let neighbours = (0..<2).map { _ -> NSView in
            let dot = NSView()
            dot.wantsLayer = true
            dot.layer?.cornerRadius = 4
            dot.layer?.backgroundColor = NSColor.labelColor.withAlphaComponent(0.28).cgColor
            dot.widthAnchor.constraint(equalToConstant: 8).isActive = true
            dot.heightAnchor.constraint(equalToConstant: 8).isActive = true
            return dot
        }
        let clock = PreviewView.menuLabel("9:41", dim: true)
        clock.font = .systemFont(ofSize: 11)

        let cluster = NSStackView(views: [icon] + neighbours + [clock])
        cluster.orientation = .horizontal
        cluster.alignment = .centerY
        cluster.spacing = 10
        icon.widthAnchor.constraint(equalToConstant: 15).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 15).isActive = true

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

            // A status item menu hangs from its icon, but shifts left to stay on
            // screen. Its right edge landing near the edge is what that looks
            // like, and it keeps the panel inside this view's bounds.
            panel.topAnchor.constraint(equalTo: bar.bottomAnchor, constant: 5),
            panel.trailingAnchor.constraint(equalTo: bar.trailingAnchor),
            panel.widthAnchor.constraint(equalToConstant: 200),

            rows.topAnchor.constraint(equalTo: panel.topAnchor),
            rows.leadingAnchor.constraint(equalTo: panel.leadingAnchor),
            rows.trailingAnchor.constraint(equalTo: panel.trailingAnchor),
            rows.bottomAnchor.constraint(equalTo: panel.bottomAnchor),
        ])
    }
}


/// Two of the menu's website rows, with the subdomain indented under the domain
/// exactly as the real menu indents it.
class WebsiteRulesPreview: PreviewView {
    override var intrinsicContentSize: NSSize { NSSize(width: 360, height: 178) }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard subviews.isEmpty else { return }

        func row(_ text: String, ticked: Bool, indent: CGFloat) -> NSView {
            let tick = PreviewView.menuLabel("✓")
            tick.textColor = ticked ? .controlAccentColor : .clear
            tick.alignment = .center
            tick.widthAnchor.constraint(equalToConstant: 14).isActive = true

            let stack = NSStackView(views: [tick, PreviewView.menuLabel(text, dim: !ticked)])
            stack.orientation = .horizontal
            stack.alignment = .firstBaseline
            stack.spacing = 4
            stack.edgeInsets = NSEdgeInsets(top: 0, left: indent, bottom: 0, right: 0)
            return stack
        }

        let rows = NSStackView(views: [
            row(NSLocalizedString("setup.rule_example_domain",
                                  comment: "Disable for github.com"), ticked: true, indent: 0),
            row(NSLocalizedString("setup.rule_example_subdomain",
                                  comment: "Disable for gist.github.com"), ticked: false, indent: 18),
        ])
        rows.orientation = .vertical
        rows.alignment = .leading
        rows.spacing = 8
        rows.edgeInsets = NSEdgeInsets(top: 14, left: 12, bottom: 16, right: 20)

        let panel = PreviewView.menuPanel()
        panel.addSubview(rows)
        rows.translatesAutoresizingMaskIntoConstraints = false
        panel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(panel)

        let browsers = BrowserStrip()
        browsers.translatesAutoresizingMaskIntoConstraints = false
        addSubview(browsers)

        NSLayoutConstraint.activate([
            panel.centerXAnchor.constraint(equalTo: centerXAnchor),
            panel.topAnchor.constraint(equalTo: topAnchor),
            rows.topAnchor.constraint(equalTo: panel.topAnchor),
            rows.leadingAnchor.constraint(equalTo: panel.leadingAnchor),
            rows.trailingAnchor.constraint(equalTo: panel.trailingAnchor),
            rows.bottomAnchor.constraint(equalTo: panel.bottomAnchor),

            browsers.topAnchor.constraint(equalTo: panel.bottomAnchor, constant: 26),
            browsers.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])
    }
}


/// The supported browsers, two rows of three. Each icon is taken from the
/// installed copy where there is one, so it's whatever that browser looks like
/// today, and falls back to the bundled asset otherwise.
class BrowserStrip: PreviewView {
    private static let browsers: [(name: String, bundleID: String, asset: String)] = [
        ("Safari",  "com.apple.Safari",             "safariIcon"),
        ("Chrome",  "com.google.Chrome",            "chromeIcon"),
        ("Edge",    "com.microsoft.edgemac",        "edgeIcon"),
        ("Brave",   "com.brave.Browser",            "braveIcon"),
        ("Opera",   "com.operasoftware.Opera",      "operaIcon"),
        ("Vivaldi", "com.vivaldi.Vivaldi",          "vivaldiIcon"),
    ]

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard subviews.isEmpty else { return }

        func cell(_ browser: (name: String, bundleID: String, asset: String)) -> NSView {
            let icon = NSImageView()
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: browser.bundleID) {
                icon.image = NSWorkspace.shared.icon(forFile: url.path)
            } else {
                icon.image = NSImage(named: browser.asset)
            }
            icon.imageScaling = .scaleProportionallyDown
            icon.widthAnchor.constraint(equalToConstant: 18).isActive = true
            icon.heightAnchor.constraint(equalToConstant: 18).isActive = true

            let label = PreviewView.menuLabel(browser.name, dim: true)
            label.font = .systemFont(ofSize: NSFont.smallSystemFontSize)

            let stack = NSStackView(views: [icon, label])
            stack.orientation = .horizontal
            stack.alignment = .centerY
            stack.spacing = 6
            stack.widthAnchor.constraint(equalToConstant: 96).isActive = true
            return stack
        }

        let rows = Self.browsers.chunked(3).map { group -> NSStackView in
            let row = NSStackView(views: group.map(cell))
            row.orientation = .horizontal
            row.alignment = .centerY
            row.spacing = 10
            row.distribution = .fillEqually
            return row
        }

        let grid = NSStackView(views: rows)
        grid.orientation = .vertical
        grid.alignment = .centerX
        grid.spacing = 10
        grid.translatesAutoresizingMaskIntoConstraints = false
        addSubview(grid)

        NSLayoutConstraint.activate([
            grid.topAnchor.constraint(equalTo: topAnchor),
            grid.bottomAnchor.constraint(equalTo: bottomAnchor),
            grid.leadingAnchor.constraint(equalTo: leadingAnchor),
            grid.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }
}


private extension Array {
    func chunked(_ size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map { Array(self[$0..<Swift.min($0 + size, count)]) }
    }
}
