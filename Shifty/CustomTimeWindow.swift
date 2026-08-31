//
//  CustomTimeWindow.swift
//  Shifty
//
//  Created by Nate Thompson on 7/21/17.
//
//

import Cocoa

class OnlyIntValueFormatter: NumberFormatter, @unchecked Sendable {
    override func isPartialStringValid(_ partialString: String, newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>?, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        if partialString.isEmpty {
            return true
        }
        if partialString.count > 3 {
            return false
        }
        return Int(partialString) != nil
    }
}

class CustomTimeWindow: NSWindowController {

    var disableCustomTime: ((Int) -> Void)?
    var customTimeWindowIsOpen: ((Bool) -> Void)?
    let onlyIntValueFormatter = OnlyIntValueFormatter()

    override var windowNibName: NSNib.Name {
        return "CustomTimeWindow"
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        // Reused across openings, so it would otherwise reappear on whichever
        // Space it was last closed on. .managed must stay in the mask, or the
        // window becomes unmanaged and shows up on every Space.
        window?.collectionBehavior = [.managed, .moveToActiveSpace]

        // The title is already hidden, so the title bar is pure chrome. Let the
        // content fill the window and drop the bar and its separator hairline.
        window?.styleMask.insert(.fullSizeContentView)
        window?.titlebarAppearsTransparent = true
        window?.titlebarSeparatorStyle = .none
        // Nothing left to drag the window by otherwise.
        window?.isMovableByWindowBackground = true

        UserDefaults.standard.removeObject(forKey: "NSWindow Frame customTimeWindowFrame")
        let saveName = "customTimeWindow"

        // Take the height from the layout rather than the nib's contentRect. The
        // vertical chain is fully pinned, so any mismatch has to go somewhere:
        // too much and the inputs row stretches, too little and constraints
        // break. Width stays as designed, since the row has a flexible spacer.
        if let window = window, let content = window.contentView {
            content.layoutSubtreeIfNeeded()
            let fitting = content.fittingSize
            if fitting.height > 0 {
                window.setContentSize(NSSize(width: content.frame.width, height: fitting.height))
            }
        }

        // Restore the saved position but never the saved size: a frame saved
        // before a layout change would pin the window to the old dimensions.
        let nibSize = window?.frame.size

        if window?.setFrameUsingName(saveName) != true {
            window?.center()
        }

        if let window = window, let nibSize = nibSize {
            window.setFrame(NSRect(origin: window.frame.origin, size: nibSize), display: false)
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name("NSWindowWillCloseNotification"), object: nil, queue: nil) { _ in
            self.window?.saveFrame(usingName: saveName)
        }

        window?.level = .floating
        window?.titleVisibility = .hidden

        hoursTextField.formatter = onlyIntValueFormatter
        minutesTextField.formatter = onlyIntValueFormatter
    }

    @IBOutlet weak var hoursTextField: NSTextField!
    @IBOutlet weak var minutesTextField: NSTextField!

    @IBAction func cancelButtonClicked(_ sender: NSButton) {
        window?.close()
    }

    @IBAction func okButtonClicked(_ sender: NSButton) {
        let hours = hoursTextField.intValue
        let minutes = minutesTextField.intValue
        let timeIntervalInSeconds = hours * 3600 + minutes * 60
        disableCustomTime?(Int(timeIntervalInSeconds))

        window?.close()
    }
}
