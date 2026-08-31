//
//  SwitchView.swift
//  Shifty
//
//  Created by Nate Thompson on 11/11/21.
//

import Cocoa

/// A switch drawn from scratch, because NSSwitch can't be used in a menu:
/// its accent fill is only drawn while the containing window is key, and a
/// status item's menu window never is, so it renders grey however it is
/// configured. Its controlSize is also ignored (54x24 at regular, small and
/// mini alike), so it can't be made menu-sized either.
class MenuSwitch: NSControl {
    static let size = CGSize(width: 36, height: 20)

    var isOn: Bool = false {
        didSet {
            setAccessibilityValue(isOn)
            needsDisplay = true
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setAccessibilityRole(.checkBox)
        setAccessibilityValue(isOn)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: NSSize {
        return Self.size
    }

    override func draw(_ dirtyRect: NSRect) {
        let track = NSRect(origin: .zero, size: bounds.size)
        let radius = track.height / 2

        (isOn ? NSColor.controlAccentColor : NSColor.tertiaryLabelColor).setFill()
        NSBezierPath(roundedRect: track, xRadius: radius, yRadius: radius).fill()

        let inset: CGFloat = 2
        let diameter = track.height - inset * 2
        let knob = NSRect(
            x: isOn ? track.maxX - inset - diameter : track.minX + inset,
            y: track.minY + inset,
            width: diameter,
            height: diameter)

        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.25)
        shadow.shadowBlurRadius = 1.5
        shadow.shadowOffset = NSSize(width: 0, height: -0.5)
        shadow.set()
        NSColor.white.setFill()
        NSBezierPath(ovalIn: knob).fill()
        NSGraphicsContext.restoreGraphicsState()
    }

    // ponytail: snaps rather than slides. Add a layer animation if it bothers anyone.
    override func mouseDown(with event: NSEvent) {
        isOn.toggle()
        sendAction(action, to: target)
    }
}


class SwitchView: NSView {
    private var toggleSwitch = MenuSwitch()
    private var onSwitchToggle: (Bool) -> Void
    
    var switchState: Bool {
        didSet {
            toggleSwitch.isOn = switchState
        }
    }
    
    init(title: String, onSwitchToggle: @escaping (Bool) -> Void) {
        self.switchState = false
        self.onSwitchToggle = onSwitchToggle
        super.init(frame: .zero)
        
        let label = NSTextField()
        label.stringValue = title
        label.font = NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)
        label.isEditable = false
        label.isBezeled = false
        label.backgroundColor = .clear
        
        toggleSwitch.target = self
        toggleSwitch.action = #selector(switchToggled)
        toggleSwitch.setAccessibilityLabel(title)
        
        let stackView = NSStackView(views: [label, toggleSwitch])
        stackView.orientation = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .centerY
        
        self.addSubviewAndConstrainToEqualSize(
            stackView,
            withInsets: NSEdgeInsets(top: 3, left: 12, bottom: 3, right: 12))
        toggleSwitch.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func switchToggled() {
        onSwitchToggle(toggleSwitch.isOn)
    }
}


extension NSView {
    func addSubviewAndConstrainToEqualSize(
        _ subview: NSView,
        withInsets insets: NSEdgeInsets,
        includeLayoutMargins: Bool = false)
    {
        subview.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(subview)
        
        NSLayoutConstraint.activate([
            subview.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: insets.left),
            subview.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -insets.right),
            subview.topAnchor.constraint(equalTo: self.topAnchor, constant: insets.top),
            subview.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -insets.bottom),
        ])
    }
}
