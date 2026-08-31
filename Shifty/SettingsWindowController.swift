//
//  SettingsWindowController.swift
//  Shifty
//

import Cocoa

/// One tab of the settings window.
protocol SettingsPane: NSViewController {
    var paneLabel: String { get }
    var paneSymbolName: String { get }
}


/// Replaces MASPreferences, an unmaintained pod carried for three panes.
/// NSTabViewController in .toolbar style is the stock equivalent.
///
/// Owning the window also lets it be a non-activating panel, which can take
/// keyboard focus while the app stays inactive. That matters because macOS
/// refuses to activate a menu bar app while another app is frontmost: with the
/// old window, opening settings logged "app active: false, frontmost: Code"
/// however it was ordered, activated, or policy-flipped.
final class SettingsWindowController: NSWindowController {

    /// The panes, in the order given.
    let panes: [SettingsPane]

    init(panes: [SettingsPane], title: String) {
        self.panes = panes

        let tabViewController = NSTabViewController()
        tabViewController.tabStyle = .toolbar

        for pane in panes {
            let item = NSTabViewItem(viewController: pane)
            item.label = pane.paneLabel
            item.image = NSImage(systemSymbolName: pane.paneSymbolName,
                                 accessibilityDescription: pane.paneLabel)
            tabViewController.addTabViewItem(item)
        }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable, .nonactivatingPanel],
            backing: .buffered,
            defer: false)
        panel.contentViewController = tabViewController
        panel.title = title
        panel.toolbarStyle = .preference
        // Panels hide themselves on deactivate by default, which would make
        // settings vanish the moment focus went elsewhere.
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false

        super.init(window: panel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func showWindow(_ sender: Any?) {
        if let window = window, !window.isVisible {
            window.center()
        }
        super.showWindow(sender)
    }

    override func keyDown(with event: NSEvent) {
        // Cmd-W, since a menu bar app has no File menu to supply it.
        if event.keyCode == 13 && event.modifierFlags.contains(.command) {
            window?.close()
        } else {
            super.keyDown(with: event)
        }
    }
}
