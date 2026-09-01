//
//  Setup.swift
//  
//
//  Created by Nate Thompson on 12/28/17.
//

import Cocoa
import AXSwift
import SwiftLog

class SetupWindowController: NSWindowController {
    override var storyboard: NSStoryboard {
        return NSStoryboard(name: "Setup", bundle: nil)
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.titleVisibility = .hidden
        window?.titlebarAppearsTransparent = true
        window?.isMovableByWindowBackground = true
    }
}








class SetupWindow: NSWindow {
    override func keyDown(with event: NSEvent) {
        super.keyDown(with: event)
        if event.keyCode == 13 && event.modifierFlags.contains(.command) {
            close()
        } else if event.keyCode == 46 && event.modifierFlags.contains(.command) {
            miniaturize(self)
        }
    }
}








class SetupView: NSView {
    @IBAction func closeButtonClicked(_ sender: Any) {
        window?.close()
    }
}
    
    
    
    
    
    

class WebsiteShiftingSetupViewController: NSViewController {
    @IBOutlet weak var websiteShiftingScreenshotView: NSImageView!

    /// Yes used to be a segue and nothing else: it moved to the accessibility
    /// page, and granting there was what switched the feature on, by way of the
    /// observer in AppDelegate. With that page gone, Yes has to do the work.
    @IBAction func enableWebsiteShifting(_ sender: Any) {
        UserDefaults.standard.set(true, forKey: Keys.isWebsiteControlEnabled)
        logw("Website Shifting enabled during setup")

        // Same ask as the checkbox in Settings: macOS prompts and lists Shifty,
        // and the notice there carries the state until access is granted.
        if !UIElement.isProcessTrusted(withPrompt: true) {
            logw("Accessibility not granted; system prompt shown")
        }
    }
    
    override func viewDidLoad() {
        var imageName: String
        
        if let language = Locale.current.language.languageCode?.identifier {
            imageName = "websiteShiftingScreenshot-\(language)"
            
            if let script = Locale.current.language.script?.identifier {
                imageName.append("-\(script)")
            }
        } else {
            imageName = "websiteShiftingScreenshot-en"
        }
        
        websiteShiftingScreenshotView.image = NSImage(named: imageName)
    }
}























class ContainerViewController: NSViewController {
    var sourceViewController: NSViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let setupStoryboard = NSStoryboard(name: "Setup", bundle: nil)
        sourceViewController = setupStoryboard.instantiateController(withIdentifier: "sourceViewController") as? NSViewController
        self.insertChild(sourceViewController, at: 0)
        self.view.addSubview(sourceViewController.view)
        self.view.frame = sourceViewController.view.frame
        
        self.view.topAnchor.constraint(equalTo: sourceViewController.view.topAnchor).isActive = true
    }
}


