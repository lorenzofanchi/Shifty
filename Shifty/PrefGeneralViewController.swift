//
//  GeneralPreferencesViewController.swift
//  Shifty
//
//  Created by Nate Thompson on 11/10/17.
//

import Cocoa
import ServiceManagement
import AXSwift
import SwiftLog


@objcMembers
class PrefGeneralViewController: NSViewController, SettingsPane {

    override var nibName: NSNib.Name {
        return "PrefGeneralViewController"
    }

    var paneLabel: String {
        return NSLocalizedString("prefs.general", comment: "General")
    }

    var paneSymbolName = "gearshape"





    @IBOutlet weak var autoLaunchButton: NSButton!
    @IBOutlet weak var quickToggleButton: NSButton!
    @IBOutlet weak var darkModeSyncButton: NSButton!
    @IBOutlet weak var websiteShiftingButton: NSButton!
    @IBOutlet weak var trueToneControlButton: NSButton!
    
    @IBOutlet weak var trueToneStackView: NSStackView!
    
    @IBOutlet weak var schedulePopup: NSPopUpButton!
    @IBOutlet weak var offMenuItem: NSMenuItem!
    @IBOutlet weak var customMenuItem: NSMenuItem!
    @IBOutlet weak var sunMenuItem: NSMenuItem!

    @IBOutlet weak var fromTimePicker: NSDatePicker!
    @IBOutlet weak var toTimePicker: NSDatePicker!
    @IBOutlet weak var fromLabel: NSTextField!
    @IBOutlet weak var toLabel: NSTextField!
    @IBOutlet weak var customTimeStackView: NSStackView!

    var appDelegate: AppDelegate!
    
    var defaultDarkModeState: Bool!

    override func viewDidLoad() {
        super.viewDidLoad()

        appDelegate = NSApplication.shared.delegate as? AppDelegate
        
        NightShiftManager.shared.onNightShiftChange {
            self.updateSchedule()
        }

        //Hide True Tone settings on unsupported computers
        trueToneStackView.isHidden = CBTrueToneClient.shared.state == .unsupported
        
        defaultDarkModeState = SLSGetAppearanceThemeLegacy()

        addTransitionRow()

        updateAccessibilityNotice()
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.accessibility.api"),
            object: nil,
            queue: .main)
        { [weak self] _ in
            // The trust state lags the notification slightly.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self?.updateAccessibilityNotice()
            }
        }

        //Fix layer-backing issues in 10.12 that cause window corners to not be rounded.
        if !ProcessInfo().isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 10, minorVersion: 13, patchVersion: 0)) {
            view.wantsLayer = false
        }
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        updateSchedule()
    }
    
    func updateSchedule() {
        switch NightShiftManager.shared.schedule {
        case .off:
            self.schedulePopup.select(self.offMenuItem)
            self.customTimeStackView.isHidden = true
        case .custom(start: let startTime, end: let endTime):
            self.schedulePopup.select(self.customMenuItem)
            let startDate = Date(startTime)
            let endDate = Date(endTime)
            
            self.fromTimePicker.dateValue = startDate
            self.toTimePicker.dateValue = endDate
            self.customTimeStackView.isHidden = false
        case .solar:
            self.schedulePopup.select(self.sunMenuItem)
            self.customTimeStackView.isHidden = true
        }
    }

    //MARK: IBActions

    @IBAction func setAutoLaunch(_ sender: NSButtonCell) {
        let loginItem = SMAppService.loginItem(identifier: "io.natethompson.ShiftyHelper")
        do {
            if sender.state == .on {
                try loginItem.register()
            } else {
                try loginItem.unregister()
            }
            logw("Auto launch on login set to \(sender.state.rawValue)")
        } catch {
            logw("Error: could not set auto launch on login: \(error)")
        }
    }

    @IBAction func quickToggle(_ sender: NSButtonCell) {
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        appDelegate.setStatusToggle()
        logw("Quick Toggle set to \(sender.state.rawValue)")
    }

    @IBAction func syncDarkMode(_ sender: NSButtonCell) {
        if sender.state == .on {
            defaultDarkModeState = SLSGetAppearanceThemeLegacy()
            NightShiftManager.shared.updateDarkMode()
        } else {
            SLSSetAppearanceThemeLegacy(defaultDarkModeState)
        }
        logw("Dark mode sync preference set to \(sender.state.rawValue)")
    }

    /// The "Needs access" chip beside the Website Shifting checkbox. Added to the
    /// pane rather than into the checkbox's stack view, so the row it sits on
    /// doesn't have to be rebuilt.
    private lazy var accessibilityChip: NSView = {
        let label = NSTextField(labelWithString:
            NSLocalizedString("prefs.needs_access", comment: "Needs access"))
        label.font = .systemFont(ofSize: 10, weight: .semibold)
        // Orange, not grey: this says the feature the person just switched on
        // isn't working yet, which is worth noticing.
        label.textColor = .systemOrange

        let chip = NSView()
        chip.wantsLayer = true
        chip.layer?.cornerRadius = 4
        chip.layer?.backgroundColor = NSColor.systemOrange.withAlphaComponent(0.16).cgColor
        chip.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        chip.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: chip.leadingAnchor, constant: 7),
            label.trailingAnchor.constraint(equalTo: chip.trailingAnchor, constant: -7),
            label.topAnchor.constraint(equalTo: chip.topAnchor, constant: 2),
            label.bottomAnchor.constraint(equalTo: chip.bottomAnchor, constant: -2),
        ])
        return chip
    }()

    /// Shown while Website Shifting is on but Accessibility hasn't been granted.
    /// macOS only ever shows its own prompt once, so after a denial this row is
    /// the only thing left saying the feature isn't actually working.
    private lazy var accessibilityNotice: NSStackView = {
        let label = NSTextField(labelWithString:
            NSLocalizedString("prefs.accessibility_needed",
                              comment: "macOS needs to allow Shifty to read your browser's address."))
        label.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        label.textColor = .secondaryLabelColor
        label.lineBreakMode = .byWordWrapping
        label.preferredMaxLayoutWidth = 300

        let button = NSButton(
            title: NSLocalizedString("prefs.open_accessibility", comment: "Open Accessibility Settings..."),
            target: self,
            action: #selector(openAccessibilitySettings))
        button.controlSize = .small
        button.bezelStyle = .rounded

        let stack = NSStackView(views: [label, button])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 4
        // Lines the notice up with the explanatory text above it rather than
        // with the checkbox. edgeInsets, because the enclosing stack view owns
        // the leading constraint and a second one would fight it.
        stack.edgeInsets = NSEdgeInsets(top: 2, left: 20, bottom: 0, right: 0)
        return stack
    }()

    func updateAccessibilityNotice() {
        let needed = UserDefaults.standard.bool(forKey: Keys.isWebsiteControlEnabled)
            && !UIElement.isProcessTrusted()

        guard let column = websiteShiftingButton.superview as? NSStackView else { return }

        if needed, accessibilityNotice.superview == nil {
            column.addView(accessibilityNotice, in: .bottom)

            view.addSubview(accessibilityChip)
            NSLayoutConstraint.activate([
                accessibilityChip.centerYAnchor.constraint(equalTo: websiteShiftingButton.centerYAnchor),
                accessibilityChip.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            ])
        } else if !needed, accessibilityNotice.superview != nil {
            column.removeView(accessibilityNotice)
            accessibilityChip.removeFromSuperview()
        }
    }

    @objc private func openAccessibilitySettings() {
        // Prompt first: it re-adds Shifty to the list if it was removed, so the
        // row the person is about to look for is actually there.
        _ = UIElement.isProcessTrusted(withPrompt: true)
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }

    @IBAction func setWebsiteControl(_ sender: NSButtonCell) {
        logw("Website control preference clicked")
        if sender.state == .on {
            // Let macOS do the asking. Its alert is the only thing that adds
            // Shifty to the Accessibility list, which is what makes the switch
            // findable. It can't grant access, so the checkbox stays where the
            // person put it and the notice below carries the "not yet" state.
            if !UIElement.isProcessTrusted(withPrompt: true) {
                logw("Accessibility not granted; system prompt shown")
            }
        } else {
            BrowserManager.shared.stopBrowserWatcher()
            logw("Website control disabled")
        }
        updateAccessibilityNotice()
    }
    
    @IBAction func setTrueToneControl(_ sender: NSButtonCell) {
        if sender.state == .on {
            if NightShiftManager.shared.isDisableRuleActive {
                CBTrueToneClient.shared.isTrueToneEnabled = false
            }
        } else {
            CBTrueToneClient.shared.isTrueToneEnabled = true
        }
        logw("True Tone control set to \(sender.state.rawValue)")
    }
    
    
    @IBAction func schedulePopup(_ sender: NSPopUpButton) {
        if schedulePopup.selectedItem == offMenuItem {
            NightShiftManager.shared.schedule = .off
            customTimeStackView.isHidden = true
        } else if schedulePopup.selectedItem == customMenuItem {
            scheduleTimePickers(self)
            customTimeStackView.isHidden = false
        } else if schedulePopup.selectedItem == sunMenuItem {
            NightShiftManager.shared.schedule = .solar
            customTimeStackView.isHidden = true
        }
    }

    /// Fade lengths in seconds for Slow, Normal, Fast and Very Fast. -1 leaves
    /// the fade to macOS.
    // ponytail: guessed by eye; tune these if a speed feels off.
    static let transitionPeriods: [Double] = [4, -1, 0.5, 0.1]

    /// The "Transition:" row under the schedule. Built here rather than in the
    /// xib, matched to the Schedule row so the two popups line up.
    private func addTransitionRow() {
        guard let scheduleRow = schedulePopup.superview as? NSStackView,
              let scheduleLabel = scheduleRow.arrangedSubviews.first,
              let column = scheduleRow.superview as? NSStackView else { return }

        let label = NSTextField(labelWithString:
            NSLocalizedString("prefs.transition", comment: "Transition:"))
        label.alignment = .right

        let popup = FirstMousePopUpButton()
        popup.addItems(withTitles: [
            NSLocalizedString("prefs.transition_slow", comment: "Slow"),
            NSLocalizedString("prefs.transition_normal", comment: "Normal"),
            NSLocalizedString("prefs.transition_fast", comment: "Fast"),
            NSLocalizedString("prefs.transition_very_fast", comment: "Very Fast"),
        ])
        let period = UserDefaults.standard.double(forKey: Keys.transitionPeriod)
        popup.selectItem(at: Self.transitionPeriods.firstIndex(of: period) ?? 1)
        popup.target = self
        popup.action = #selector(setTransitionSpeed(_:))

        // Both labels take the wider one's width; the popups take the rest.
        scheduleLabel.setContentHuggingPriority(.defaultLow + 1, for: .horizontal)
        label.setContentHuggingPriority(.defaultLow + 1, for: .horizontal)
        popup.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let row = NSStackView(views: [label, popup])
        column.addArrangedSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: scheduleRow.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: scheduleRow.trailingAnchor),
            label.widthAnchor.constraint(equalTo: scheduleLabel.widthAnchor),
        ])
    }

    @objc private func setTransitionSpeed(_ sender: NSPopUpButton) {
        let period = Self.transitionPeriods[sender.indexOfSelectedItem]
        UserDefaults.standard.set(period, forKey: Keys.transitionPeriod)
        logw("Transition period set to \(period)")
    }

    @IBAction func scheduleTimePickers(_ sender: Any) {
        let fromTime = Time(fromTimePicker.dateValue)
        let toTime = Time(toTimePicker.dateValue)
        NightShiftManager.shared.schedule = .custom(start: fromTime, end: toTime)
    }

}

