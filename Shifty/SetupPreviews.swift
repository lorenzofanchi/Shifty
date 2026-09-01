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
    override var intrinsicContentSize: NSSize { NSSize(width: 380, height: 150) }

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

            // hanging directly below the icon, as a status item menu does
            panel.topAnchor.constraint(equalTo: bar.bottomAnchor, constant: 5),
            panel.leadingAnchor.constraint(equalTo: icon.leadingAnchor, constant: -12),
            panel.widthAnchor.constraint(equalToConstant: 190),

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
    override var intrinsicContentSize: NSSize { NSSize(width: 330, height: 92) }

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
        rows.spacing = 6
        rows.edgeInsets = NSEdgeInsets(top: 10, left: 10, bottom: 12, right: 14)

        let panel = PreviewView.menuPanel()
        panel.addSubview(rows)
        rows.translatesAutoresizingMaskIntoConstraints = false
        panel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(panel)

        NSLayoutConstraint.activate([
            panel.centerXAnchor.constraint(equalTo: centerXAnchor),
            panel.topAnchor.constraint(equalTo: topAnchor),
            rows.topAnchor.constraint(equalTo: panel.topAnchor),
            rows.leadingAnchor.constraint(equalTo: panel.leadingAnchor),
            rows.trailingAnchor.constraint(equalTo: panel.trailingAnchor),
            rows.bottomAnchor.constraint(equalTo: panel.bottomAnchor),
        ])
    }
}
