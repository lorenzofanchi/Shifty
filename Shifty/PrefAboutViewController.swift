//
//  PrefAboutViewController.swift
//  Shifty
//
//  Created by Nate Thompson on 11/10/17.
//

import Cocoa
import MASPreferences_Shifty

@objcMembers
class PrefAboutViewController: NSViewController, MASPreferencesViewController {

    override var nibName: NSNib.Name {
        get { return "PrefAboutViewController" }
    }

    var viewIdentifier: String = "PrefAboutViewController"

    var toolbarItemImage: NSImage? {
        return NSImage(systemSymbolName: "info.circle", accessibilityDescription: nil)
    }

    var toolbarItemLabel: String? {
        get {
            view.layoutSubtreeIfNeeded()
            return NSLocalizedString("prefs.about", comment: "About")
        }
    }

    var hasResizableWidth = false
    var hasResizableHeight = false

    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var versionLabel: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        //Fix layer-backing issues in 10.12 that cause window corners to not be rounded.
        if !ProcessInfo().isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 10, minorVersion: 13, patchVersion: 0)) {
            view.wantsLayer = false
        }

        let bundleDisplayName = Bundle.main.localizedInfoDictionary?["CFBundleDisplayName"]
        nameLabel.stringValue = bundleDisplayName as? String ?? ""

        let versionObject = Bundle.main.infoDictionary?["CFBundleShortVersionString"]
        versionLabel.stringValue = versionObject as? String ?? ""
    }

    @IBAction func visitWebsiteClicked(_ sender: NSButton) {
        guard let url = URL(string: "https://shifty.natethompson.io") else { return }
        NSWorkspace.shared.open(url)
    }

    @IBAction func submitFeedbackClicked(_ sender: NSButton) {
        guard let url = URL(string: "mailto:feedback@natethompson.io?subject=Shifty%20Feedback") else { return }
        NSWorkspace.shared.open(url)
    }
    
    @IBAction func twitterButtonClicked(_ sender: Any) {
        guard let url = URL(string: "https://natethompson.io/twitter") else { return }
        NSWorkspace.shared.open(url)
    }
    
    @IBAction func translateButtonClicked(_ sender: NSButton) {
        guard let url = URL(string: "https://shifty.natethompson.io/translate") else { return }
        NSWorkspace.shared.open(url)
    }

    @IBAction func donateButtonClicked(_ sender: NSButton) {
        guard let url = URL(string: "https://shifty.natethompson.io/donate") else { return }
        NSWorkspace.shared.open(url)
    }

    @IBAction func creditsButtonClicked(_ sender: Any) {
        guard let url = Bundle.main.url(forResource: "credits", withExtension: "rtfd") else { return }
        NSWorkspace.shared.open(url)
    }
}


class LinkButton: NSButton {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func resetCursorRects() {
        addCursorRect(self.bounds, cursor: .pointingHand)
    }
}
