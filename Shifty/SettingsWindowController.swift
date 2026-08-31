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
/// This was briefly an NSPanel with .nonactivatingPanel, to sidestep macOS
/// refusing to activate a menu bar app while another app is frontmost. It got
/// the window on screen and key, but left every first click being spent
/// bringing the app forward, which acceptsFirstMouse didn't cure either. The
/// app is now activated when the status item is clicked instead, so an ordinary
/// window is all that's needed here.
final class SettingsWindowController: NSWindowController {

    /// The panes, in the order given.
    let panes: [SettingsPane]

    init(panes: [SettingsPane], title: String) {
        self.panes = panes

        // Pin every pane to the width of the widest one, so switching tabs only
        // ever changes the window's height. Reading .view here loads each pane's
        // xib, which is what makes fittingSize meaningful.
        let fittingSizes = panes.map { $0.view.fittingSize }
        let paneWidth = fittingSizes.map { $0.width }.max() ?? 0
        for (pane, size) in zip(panes, fittingSizes) {
            pane.preferredContentSize = NSSize(width: paneWidth, height: size.height)
        }

        let tabViewController = NSTabViewController()
        tabViewController.tabStyle = .toolbar

        for pane in panes {
            let item = NSTabViewItem(viewController: pane)
            item.label = pane.paneLabel
            item.image = NSImage(systemSymbolName: pane.paneSymbolName,
                                 accessibilityDescription: pane.paneLabel)
            tabViewController.addTabViewItem(item)
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false)
        window.contentViewController = tabViewController
        window.title = title
        window.toolbarStyle = .preference
        window.isReleasedWhenClosed = false

        super.init(window: window)
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
