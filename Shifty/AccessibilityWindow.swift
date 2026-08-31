//
//  AccessibilityWindow.swift
//  Shifty
//
//  Created by Nate Thompson on 1/1/18.
//

import Cocoa
import AXSwift

class AccessibilityWindow: NSWindowController {

    @IBOutlet weak var notNowButton: NSButton!
    @IBOutlet weak var openSysPrefsButton: NSButton!

    private var observers: [NSObjectProtocol] = []
    private var isTrusted = false

    override var windowNibName: NSNib.Name {
        get { return "AccessibilityWindow" }
    }
    
    override func windowDidLoad() {
        window?.center()
        
        notNowButton.title = NSLocalizedString("alert.not_now", comment: "Not now")
        updateForAccessibilityState()

        // Access is granted in System Settings, so watch for it rather than
        // leaving the user looking at a prompt that has already been satisfied.
        observers.append(DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.accessibility.api"),
            object: nil,
            queue: nil)
        { [weak self] _ in
            // The trust state lags the notification slightly.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self?.updateForAccessibilityState()
            }
        })

        // The distributed notification isn't always delivered while a modal run
        // loop is up, and returning from System Settings always reactivates us.
        observers.append(NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main)
        { [weak self] _ in
            self?.updateForAccessibilityState()
        })
    }

    deinit {
        observers.forEach {
            DistributedNotificationCenter.default().removeObserver($0)
            NotificationCenter.default.removeObserver($0)
        }
    }

    /// Once access is granted there is nothing left to open and nothing to decline,
    /// so the prompt collapses to a single Done button.
    private func updateForAccessibilityState() {
        isTrusted = UIElement.isProcessTrusted()

        notNowButton.isHidden = isTrusted
        openSysPrefsButton.title = isTrusted
            ? NSLocalizedString("alert.done", comment: "Done")
            : NSLocalizedString("alert.open_preferences", comment: "Open System Settings")
    }
    
    @IBAction func openSysPrefsClicked(_ sender: Any) {
        if !isTrusted {
            // Legacy URL, still the one that opens the Accessibility list.
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        }
        dismissWindow()
    }
    
    @IBAction func notNowClicked(_ sender: Any) {
        dismissWindow()
    }
    
    @IBAction func helpClicked(_ sender: Any) {
        NSWorkspace.shared.open(URL(string: "https://support.apple.com/guide/mac-help/allow-accessibility-apps-to-access-your-mac-mh43185")!)
        dismissWindow()
    }

    private func dismissWindow() {
        window?.close()
        NSApp.stopModal()
    }
}
