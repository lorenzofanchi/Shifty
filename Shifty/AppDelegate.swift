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
        // First run, whether or not access happens to be granted already. The
        // old condition also required being untrusted, which made sense when
        // the wizard existed to collect that permission.
        let willShowSetupWindow = !userDefaults.bool(forKey: Keys.hasSetupWindowShown)
            || ProcessInfo.processInfo.environment["show_setup"] == "true"

        if userDefaults.bool(forKey: Keys.isWebsiteControlEnabled) && !UIElement.isProcessTrusted() {
            // No alert. Settings and the menu both show this state without
            // interrupting, and macOS won't show its own prompt twice anyway.
            logw("Accessibility permissions revoked while app was not running")
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
    
    
    func showSetupWindow() {
        let storyboard = NSStoryboard(name: "Setup", bundle: nil)
        setupWindowController = storyboard.instantiateInitialController() as? NSWindowController
        setupWindow = setupWindowController.window
        
        NSApplication.shared.activate(ignoringOtherApps: true)
        setupWindowController.showWindow(self)
        setupWindow.center()
        setupWindow.makeMain()
        
        UserDefaults.standard.set(true, forKey: Keys.hasSetupWindowShown)
    }
    
    func observeAccessibilityApiNotifications() {
        // Only ever sync upward. This notification fires for every app's
        // accessibility change, and can arrive before the system has updated
        // the answer for us, so reading false here is not evidence that the
        // person turned anything off: writing it back was what unticked the
        // checkbox a moment after access had in fact been granted.
        //
        // Access being revoked no longer switches the feature off either. The
        // preference records what the person asked for; whether it can work is
        // what the notice in Settings and the row in the menu are for.
        let syncIfTrusted = {
            if UIElement.isProcessTrusted() {
                UserDefaults.standard.set(true, forKey: Keys.isWebsiteControlEnabled)
            }
        }

        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.accessibility.api"),
            object: nil,
            queue: nil)
        { _ in
            logw("Accessibility permissions changed: \(UIElement.isProcessTrusted())")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: syncIfTrusted)
        }

        // Returning from System Settings is the dependable second chance, and
        // catches the case where the notification lost the race entirely.
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main)
        { _ in syncIfTrusted() }
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
