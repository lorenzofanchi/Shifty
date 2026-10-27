//
//  PrefManager.swift
//  Shifty
//
//  Created by Nate Thompson on 5/6/17.
//
//

import Cocoa

enum Keys {
    /// Replaced by quickToggle; read once, to carry the old setting over.
    static let isStatusToggleEnabled = "isStatusToggleEnabled"
    static let quickToggle = "quickToggle"
    static let isAutoLaunchEnabled = "isAutoLaunchEnabled"
    static let isDarkModeSyncEnabled = "isDarkModeSyncEnabled"
    static let isWebsiteControlEnabled = "isWebsiteControlEnabled"
    static let trueToneControl = "trueToneControl"
    static let currentAppDisableRules = "disabledApps"
    static let runningAppDisableRules = "disabledRunningApps"
    static let browserRules = "browserRules"
    static let transitionPeriod = "transitionPeriod"

    static let toggleNightShiftShortcut = "toggleNightShiftShortcut"
    static let incrementColorTempShortcut = "incrementColorTempShortcut"
    static let decrementColorTempShortcut = "decrementColorTempShortcut"
    static let disableAppShortcut = "disableAppShortcut"
    static let disableDomainShortcut = "disableDomainShortcut"
    static let disableSubdomainShortcut = "disableSubdomainShortcut"
    static let disableHourShortcut = "disableHourShortcut"
    static let disableCustomShortcut = "disableCustomShortcut"
    static let toggleTrueToneShortcut = "toggleTrueToneShortcut"
    static let toggleDarkModeShortcut = "toggleDarkModeShortcut"
    
    static let lastInstalledShiftyVersion = "lastInstalledShiftyVersion"
    static let hasSetupWindowShown = "hasSetupWindowShown"
}


class PrefManager {
    static let shared = PrefManager()

    private init() {
        registerFactoryDefaults()
    }

    private var userDefaults: UserDefaults {
        return UserDefaults.standard
    }
        
    private func registerFactoryDefaults() {
        let factoryDefaults = [
            Keys.isAutoLaunchEnabled: NSNumber(value: false),
            Keys.quickToggle: userDefaults.bool(forKey: Keys.isStatusToggleEnabled)
                ? QuickToggle.left.rawValue
                : QuickToggle.off.rawValue,
            Keys.isDarkModeSyncEnabled: NSNumber(value: false),
            Keys.isWebsiteControlEnabled: NSNumber(value: false),
            Keys.trueToneControl: NSNumber(value: false),
            Keys.transitionPeriod: NSNumber(value: -1),
            Keys.hasSetupWindowShown: NSNumber(value: false)
            ] as [String : Any]

        userDefaults.register(defaults: factoryDefaults)
    }
}


/// Which click on the menu bar icon turns Night Shift on or off. The other
/// click opens the menu; with .off, both do.
enum QuickToggle: String, CaseIterable {
    case off, left, right
}
