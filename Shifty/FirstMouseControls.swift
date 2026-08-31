//
//  FirstMouseControls.swift
//  Shifty
//

import Cocoa
import MASShortcut

// The settings window is a non-activating panel, so it can be key while macOS
// still has another app frontmost. In that state the first click into the window
// is spent bringing the app forward and never reaches the control under the
// cursor. acceptsFirstMouse is the opt out, and it has to be answered by the
// view that gets hit, hence one subclass per control type used in the panes.

class FirstMouseButton: NSButton {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { return true }
}

class FirstMousePopUpButton: NSPopUpButton {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { return true }
}

class FirstMouseDatePicker: NSDatePicker {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { return true }
}

class FirstMouseShortcutView: MASShortcutView {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { return true }
}
