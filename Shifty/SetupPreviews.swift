//
//  SetupPreviews.swift
//  Shifty
//

import Cocoa

// The setup wizard used to illustrate itself with screenshots: one of the menu
// bar, one of the menu with website rules, the latter in five languages. Both
// were captured in 2021 and both were wrong within one release of changing the
// menu. These draw the same idea from the same system colours as the rest of the
// window, so there is nothing left to recapture.

/// A menu bar with Shifty's icon sitting in it. Page 1 only needs to say
/// "look up there", so it shows the bar rather than the whole menu.
class MenuBarPreview: NSView {
    override var intrinsicContentSize: NSSize { NSSize(width: 300, height: 54) }
    override var allowsVibrancy: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        let bar = NSRect(x: 0, y: bounds.height - 26, width: bounds.width, height: 26)
        NSColor.tertiaryLabelColor.withAlphaComponent(0.22).setFill()
        NSBezierPath(roundedRect: bar, xRadius: 6, yRadius: 6).fill()

        // the sun, in the right hand cluster where status items live
        let d: CGFloat = 15
        let sun = NSRect(x: bar.maxX - 34 - d, y: bar.midY - d / 2, width: d, height: d)
        NSColor.labelColor.withAlphaComponent(0.75).setFill()
        NSBezierPath(ovalIn: sun).fill()
        NSColor.labelColor.withAlphaComponent(0.35).setFill()
        for neighbour in 0..<2 {
            let x = sun.minX - CGFloat(neighbour + 1) * 26
            NSBezierPath(ovalIn: NSRect(x: x, y: sun.minY + 2, width: d - 4, height: d - 4)).fill()
        }

        // a pointer up to it, so it reads as "that one"
        let tip = NSPoint(x: sun.midX, y: bar.minY - 6)
        let arrow = NSBezierPath()
        arrow.move(to: NSPoint(x: tip.x, y: tip.y))
        arrow.line(to: NSPoint(x: tip.x - 5, y: tip.y - 8))
        arrow.line(to: NSPoint(x: tip.x + 5, y: tip.y - 8))
        arrow.close()
        NSColor.controlAccentColor.setFill()
        arrow.fill()
    }
}


/// Two of the menu's website rows, one of them ticked. Page 2 needs to show
/// what a website rule looks like, not the whole menu.
class WebsiteRulesPreview: NSView {
    override var intrinsicContentSize: NSSize { NSSize(width: 340, height: 92) }
    override var allowsVibrancy: Bool { false }

    private let rows = [
        (NSLocalizedString("setup.rule_example_domain", comment: "Disable for github.com"), true),
        (NSLocalizedString("setup.rule_example_subdomain", comment: "Disable for gist.github.com"), false),
    ]

    override func draw(_ dirtyRect: NSRect) {
        NSColor.tertiaryLabelColor.withAlphaComponent(0.14).setFill()
        NSBezierPath(roundedRect: bounds, xRadius: 8, yRadius: 8).fill()

        let inset: CGFloat = 12
        let rowHeight: CGFloat = 26
        var y = bounds.height - inset - rowHeight

        for (title, isOn) in rows {
            let text = NSAttributedString(string: title, attributes: [
                .font: NSFont.menuFont(ofSize: 12),
                .foregroundColor: isOn ? NSColor.labelColor : NSColor.tertiaryLabelColor,
            ])
            text.draw(at: NSPoint(x: inset + 18, y: y + (rowHeight - text.size().height) / 2))

            if isOn {
                let tick = NSAttributedString(string: "✓", attributes: [
                    .font: NSFont.menuFont(ofSize: 12),
                    .foregroundColor: NSColor.controlAccentColor,
                ])
                tick.draw(at: NSPoint(x: inset, y: y + (rowHeight - tick.size().height) / 2))
            }
            y -= rowHeight + 4
        }
    }
}
