//
//  SettingsWindowController.swift
//  Shifty
//

import Cocoa
import SwiftUI

/// Hosts SettingsView in an ordinary window.
///
/// This was briefly an NSPanel with .nonactivatingPanel, to sidestep macOS
/// refusing to activate a menu bar app while another app is frontmost. It got
/// the window on screen and key, but left every first click being spent
/// bringing the app forward, which acceptsFirstMouse didn't cure either. The
/// app is now activated when the status item is clicked instead, so an ordinary
/// window is all that's needed here.
final class SettingsWindowController: NSWindowController {

    init() {
        let hostingController = NSHostingController(rootView: SettingsView())
        // A window takes its title from its content view controller. SwiftUI's
        // navigationTitle doesn't reach an AppKit window, so the view reports
        // the pane's name instead.
        hostingController.rootView = SettingsView { [weak hostingController] title in
            hostingController?.title = title
        }

        let window = NSWindow(contentViewController: hostingController)
        window.styleMask = [.titled, .closable, .miniaturizable, .fullSizeContentView]
        window.toolbarStyle = .unified
        window.isReleasedWhenClosed = false
        // The window is created once and reused, so without this it reopens on
        // whichever Space it was last closed on rather than the current one.
        // .managed has to be included: collectionBehavior replaces the whole
        // mask, and dropping it makes the window unmanaged, which puts it on
        // every Space at once.
        window.collectionBehavior = [.managed, .moveToActiveSpace]

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
