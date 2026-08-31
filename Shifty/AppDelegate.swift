//
//  AppDelegate.swift
//  Shifty
//
//  Created by Nate Thompson on 5/3/17.
//
//

import Cocoa
import ServiceManagement
import LetsMove
import AXSwift
import SwiftLog
import Intents

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let prefs = UserDefaults.standard
    @IBOutlet weak var statusMenu: NSMenu!
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    var statusItemClicked: (() -> Void)?

    lazy var settingsWindowController: SettingsWindowController = {
        return SettingsWindowController(
            panes: [
                PrefGeneralViewController(),
                PrefShortcutsViewController(),
                PrefAboutViewController()],
            title: NSLocalizedString("prefs.title", comment: "Settings"))
    }()

    var setupWindow: NSWindow!
    var setupWindowController: NSWindowController!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        #if !DEBUG
        PFMoveToApplicationsFolderIfNecessary()
        #endif
        
        UserDefaults.standard.register(defaults: ["NSApplicationCrashOnExceptions": true])
        
        let userDefaults = UserDefaults.standard
        
        
        let versionObject = Bundle.main.infoDictionary?["CFBundleShortVersionString"]
        userDefaults.set(versionObject as? String ?? "", forKey: Keys.lastInstalledShiftyVersion)
        
        

        logw("")
        logw("App launched")
        logw("macOS \(ProcessInfo().operatingSystemVersionString)")
        logw("Shifty Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")")

        verifySupportsNightShift()

        let launcherAppIdentifier = "io.natethompson.ShiftyHelper"

        let startedAtLogin = NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == launcherAppIdentifier
        }

        if startedAtLogin {
            DistributedNotificationCenter.default().post(name: .terminateApp, object: Bundle.main.bundleIdentifier!)
        }

        //The setup window covers accessibility itself, so don't stack an alert on top of it
        let willShowSetupWindow = (!userDefaults.bool(forKey: Keys.hasSetupWindowShown)
                                   && !UIElement.isProcessTrusted())
            || ProcessInfo.processInfo.environment["show_setup"] == "true"

        //Show alert if accessibility permissions have been revoked while app is not running
        if !willShowSetupWindow
            && userDefaults.bool(forKey: Keys.isWebsiteControlEnabled)
            && !UIElement.isProcessTrusted() {
            logw("Accessibility permissions revoked while app was not running")
            showAccessibilityDeniedAlert()
            userDefaults.set(false, forKey: Keys.isWebsiteControlEnabled)
        }
        
        observeAccessibilityApiNotifications()
        
        logw("Night Shift state: \(NightShiftManager.shared.isNightShiftEnabled)")
        logw("Schedule: \(NightShiftManager.shared.schedule)")
        logw("")

        updateMenuBarIcon()
        setStatusToggle()
        
        NightShiftManager.shared.onNightShiftChange {
            self.updateMenuBarIcon()
        }
        
        statusItem.behavior = .terminationOnRemoval
        statusItem.isVisible = true
        
        if willShowSetupWindow {
            showSetupWindow()
        }
    }
    
    
    
    //MARK: Called after application launch
    
    
    func verifySupportsNightShift() {
        if !NightShiftManager.supportsNightShift {
            logw("System does not support Night Shift")
            NSApplication.shared.activate(ignoringOtherApps: true)
            
            let alert: NSAlert = NSAlert()
            alert.messageText = NSLocalizedString("alert.hardware_message", comment: "Your Mac does not support Night Shift")
            alert.informativeText = NSLocalizedString("alert.hardware_informative", comment: "A newer Mac is required to use Shifty.")
            alert.alertStyle = NSAlert.Style.warning
            alert.addButton(withTitle: NSLocalizedString("general.ok", comment: "OK"))
            alert.runModal()
            
            NSApplication.shared.terminate(self)
        }
    }
    
    func showAccessibilityDeniedAlert() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        let alert: NSAlert = NSAlert()
        alert.messageText = NSLocalizedString("alert.accessibility_disabled_message", comment: "Accessibility permissions for Shifty have been disabled")
        alert.informativeText = NSLocalizedString("alert.accessibility_disabled_informative", comment: "Accessibility must be allowed to enable website shifting. Grant access to Shifty in Privacy & Security settings, located in System Settings.")
        alert.alertStyle = NSAlert.Style.warning
        alert.addButton(withTitle: NSLocalizedString("alert.open_preferences", comment: "Open System Settings"))
        alert.addButton(withTitle: NSLocalizedString("alert.not_now", comment: "Not now"))
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            logw("Open System Settings button clicked")
        } else {
            logw("Not now button clicked")
        }
    }
    
    func showSetupWindow() {
        let storyboard = NSStoryboard(name: "Setup", bundle: nil)
        setupWindowController = storyboard.instantiateInitialController() as? NSWindowController
        setupWindow = setupWindowController.window
        
        NSApplication.shared.activate(ignoringOtherApps: true)
        setupWindowController.showWindow(self)
        setupWindow.makeMain()
        
        UserDefaults.standard.set(true, forKey: Keys.hasSetupWindowShown)
    }
    
    func observeAccessibilityApiNotifications() {
        DistributedNotificationCenter.default().addObserver(forName: NSNotification.Name("com.apple.accessibility.api"), object: nil, queue: nil) { _ in
            logw("Accessibility permissions changed: \(UIElement.isProcessTrusted(withPrompt: false))")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                if UIElement.isProcessTrusted(withPrompt: false) {
                    UserDefaults.standard.set(true, forKey: Keys.isWebsiteControlEnabled)
                } else {
                    UserDefaults.standard.set(false, forKey: Keys.isWebsiteControlEnabled)
                }
            })
        }
    }
    
    
    
    //MARK: Status menu item

    func updateMenuBarIcon() {
        let icon = NightShiftManager.shared.isNightShiftEnabled
            ? #imageLiteral(resourceName: "shiftyMenuIcon")
            : #imageLiteral(resourceName: "sunOpenIcon")
        icon.isTemplate = true
        DispatchQueue.main.async {
            self.statusItem.button?.image = icon
        }
    }

    func setStatusToggle() {
        statusItem.menu = nil
        if let button = statusItem.button {
            button.action = #selector(statusBarButtonClicked)
            button.sendAction(on: [.leftMouseUp, .leftMouseDown, .rightMouseUp, .rightMouseDown])
        }
    }

    @objc func statusBarButtonClicked(sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if UserDefaults.standard.bool(forKey: Keys.isStatusToggleEnabled) {
            if event.type == .rightMouseDown
                || event.type == .rightMouseUp
                || event.modifierFlags.contains(.control)
            {
                statusItem.menu = statusMenu
                statusItem.button?.performClick(sender)
                statusItem.menu = nil
            } else if event.type == .leftMouseUp {
                statusItemClicked?()
            }
        } else {
            if event.type == .rightMouseUp
                || (event.type == .leftMouseUp
                    && event.modifierFlags.contains(.control))
            {
                statusItemClicked?()
            } else if event.type == .leftMouseDown
                && !event.modifierFlags.contains(.control)
            {
                statusItem.menu = statusMenu
                statusItem.button?.performClick(sender)
                statusItem.menu = nil
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        logw("App terminated")
    }
    
    
    func application(_ application: NSApplication, handlerFor intent: INIntent) -> Any? {
        if intent is GetNightShiftStateIntent {
            return GetNightShiftStateIntentHandler()
        }
        if intent is SetNightShiftStateIntent {
            return SetNightShiftStateIntentHandler()
        }
        if intent is GetColorTemperatureIntent {
            return GetColorTemperatureIntentHandler()
        }
        if intent is SetColorTemperatureIntent {
            return SetColorTemperatureIntentHandler()
        }
        if intent is SetDisableTimerIntent {
            return SetDisableTimerIntentHandler()
        }
        if intent is GetTrueToneStateIntent {
            return GetTrueToneStateIntentHandler()
        }
        if intent is SetTrueToneStateIntent {
            return SetTrueToneStateIntentHandler()
        }
        return nil
    }
}
