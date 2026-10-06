//
//  CBBlueLightClient+Shifty.swift
//  CBBlueLightClient+Shifty
//
//  Created by Nate Thompson on 8/28/21.
//

import Foundation
import SwiftLog

extension CBBlueLightClient {
    static var shared = CBBlueLightClient()
    
    private var blueLightStatus: Status {
        var status: Status = Status()
        getBlueLightStatus(&status)
        return status
    }

    var blueLightReductionAmount: Float {
        get {
            var strength: Float = 0
            getStrength(&strength)
            return strength
        }
        set {
            setStrength(newValue, commit: true)
        }
    }
    
    func previewBlueLightReductionAmount(_ value: Float) {
        setStrength(value, commit: false)
    }

    var isNightShiftEnabled: Bool {
        blueLightStatus.enabled.boolValue
    }
    
    func setNightShiftEnabled(_ newValue: Bool) {
        // macOS fades Night Shift over 2s, and ignores a fade to the value it's
        // already heading for. So start our own fade first, at the chosen
        // period, and let macOS's then be the one that's ignored. -1 = leave it.
        let period = UserDefaults.standard.double(forKey: Keys.transitionPeriod)
        if period >= 0 {
            BrightnessSystemClient.shared?.setProperty([
                "BlueLightReductionFactorValue": newValue ? 1 : 0,
                "BlueLightReductionFactorFadePeriod": period,
            ] as NSDictionary, forKey: "BlueLightReductionFactor" as CFString)
            // ponytail: corebrightnessd handles the two requests on different
            // queues, and without a gap ours sometimes lands second. 50ms won
            // 16 of 16 toggles; poll the factor instead if it ever loses.
            usleep(50_000)
        }

        setEnabled(newValue)
        
        // Set to appropriate strength when in schedule transition by resetting schedule.
        // Not with our own fade: the reset drops to 0 and refades over 2s.
        if newValue && scheduledState && period < 0 {
            let savedSchedule = schedule
            schedule = .off
            schedule = savedSchedule
        }
    }

    static var supportsNightShift: Bool {
        get {
            CBBlueLightClient.supportsBlueLightReduction()
        }
    }

    var schedule: ScheduleType {
        get {
            switch blueLightStatus.mode {
            case 0:
                return .off
            case 1:
                return .solar
            case 2:
                return .custom(start: blueLightStatus.schedule.fromTime, end: blueLightStatus.schedule.toTime)
            default:
                assertionFailure("Unknown mode")
                return .off
            }
        }
        set {
            switch newValue {
            case .off:
                setMode(0)
            case .solar:
                setMode(1)
            case .custom(start: let start, end: let end):
                setMode(2)
                var schedule = Schedule(fromTime: start, toTime: end)
                setSchedule(&schedule)
            }
        }
    }
    
    var scheduledState: Bool {
        switch schedule {
        case .off:
            return false
        case .custom(start: let startTime, end: let endTime):
            let now = Time(Date())
            if endTime > startTime {
                //startTime and endTime are on the same day
                let scheduledState = now >= startTime && now < endTime
                logw("scheduled state: \(scheduledState)")
                return scheduledState
            } else {
                //endTime is on the day following startTime
                let scheduledState = now >= startTime || now < endTime
                logw("scheduled state: \(scheduledState)")
                return scheduledState
            }
        case .solar:
            guard let sunrise = BrightnessSystemClient.shared?.sunrise,
                let sunset = BrightnessSystemClient.shared?.sunset else {
                logw("Found nil for object BrightnessSystemClient. Returning false for scheduledState.")
                return false
            }
            let now = Date()
            logw("sunset: \(sunset)")
            logw("sunrise: \(sunrise)")
            
            // For some reason, BrightnessSystemClient.isDaylight doesn't track perfectly with sunrise and sunset
            // Should return true when not daylight
            let scheduledState : Bool
            let order = NSCalendar.current.compare(sunrise, to: sunset, toGranularity: .day)
            switch order {
                case .orderedSame, .orderedAscending:
                    scheduledState = now >= sunset || now <= sunrise
                case .orderedDescending:
                    scheduledState = now >= sunset && now <= sunrise
            }
            logw("scheduled state: \(scheduledState)")
            return scheduledState
        }
    }
    
    func setToSchedule() {
        if isNightShiftEnabled != scheduledState {
            setNightShiftEnabled(scheduledState)
        }
    }
}

enum ScheduleType: Equatable {
    case off
    case solar
    case custom(start: Time, end: Time)
    
    static func == (lhs: ScheduleType, rhs: ScheduleType) -> Bool {
        switch (lhs, rhs) {
        case (.off, .off), (.solar, .solar):
            return true
        case (let .custom(leftStart, leftEnd), let custom(rightStart, rightEnd)):
            return leftStart == rightStart && leftEnd == rightEnd
        default:
            return false
        }
    }
}
