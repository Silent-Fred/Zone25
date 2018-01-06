//
//  PomodoroNotifications.swift
//  Zone25
//
//  Created by Michael Kühweg on 02.01.18.
//  Copyright © 2018 Michael Kühweg. All rights reserved.
//

import UserNotifications

class PomodoroNotifications {

    static let durationPerPomodoro = 25 * 60 // 25 minutes in seconds
    static let durationPerShortBreak = 5 * 60 // 5 minutes
    static let durationPerLongBreak = 15 * 60 // 15 minutes

    static let numberOfPomodoriPerRun = 4

    private let schedulerIdentifierPrefix = "PomodoroNotification_"

    // TODO localization
    private let contentTitlePomodoro = "Focus"
    private let contentBodyPomodoro = "Focus on your task for \(durationPerPomodoro / 60) minutes"

    private let contentTitleShortBreak = "Short Break"
    private let contentBodyShortBreak = "Take a short break for \(durationPerShortBreak / 60) minutes"

    private let contentTitleLongBreak = "Short Break"
    private let contentBodyLongBreak = "Take a longer break for at least \(durationPerLongBreak / 60) minutes"

    private let keyForUserDefaults = "finishedLastPomodoroAt"

    public func scheduleNotifications() {
        // remove old notifcations if nobody else has done that explicitly
        cancelNotifications()
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { notificationSettings in
            if notificationSettings.authorizationStatus == .authorized {
                self.scheduleNotificationsWithCheckedAuthorization()
            }
        }
        // set the finish time now instead of asynchronously while scheduling
        // the pomodori - less hassle with view refreshes
        UserDefaults.standard.set(Date(timeIntervalSinceNow: finalBreakStartsAt()),
                                  forKey: keyForUserDefaults)
    }

    public func cancelNotifications() {
        UNUserNotificationCenter
            .current()
            .removeAllPendingNotificationRequests()
        // premature end is set
        UserDefaults.standard.set(Date(), forKey: keyForUserDefaults)
    }

    public func pomodoriPassedByInPercent() -> [Double] {
        var percentages = [Double](repeating: 0.0,
                                   count: PomodoroNotifications.numberOfPomodoriPerRun)
        for pomodoro in 1...PomodoroNotifications.numberOfPomodoriPerRun {
            percentages[pomodoro - 1] = pomodoroPassedByInPercent(pomodoroNumber: pomodoro)
        }
        return percentages
    }

    public func finished() -> Bool {
        return Date() >= timeWhenLastPomodoroFinished()
    }

    public func currentlyInBreak() -> Bool {
        let now = Date()
        if now >= timeWhenLastPomodoroFinished() {
            return true
        }
        let timeToFinish = timeWhenLastPomodoroFinished().timeIntervalSinceNow
        let phaseDuration = TimeInterval(PomodoroNotifications.durationPerPomodoro
            + PomodoroNotifications.durationPerShortBreak)
        let phases = timeToFinish / phaseDuration
        let remainderInPhase = (phases - trunc(phases)) * phaseDuration
        return Int(remainderInPhase) >= PomodoroNotifications.durationPerPomodoro
    }

    private func scheduleNotificationsWithCheckedAuthorization() {
        for pomodoro in 1..<PomodoroNotifications.numberOfPomodoriPerRun {
            // schedule break after this pomodoro
            let endOfPomodoro = TimeInterval(pomodoro * PomodoroNotifications.durationPerPomodoro
                + (pomodoro - 1) * PomodoroNotifications.durationPerShortBreak)
            let endOfBreak = TimeInterval(pomodoro * PomodoroNotifications.durationPerPomodoro
                + pomodoro * PomodoroNotifications.durationPerShortBreak)
            schedule(content: contentForShortBreak(),
                     withTimeInterval: endOfPomodoro)
            // schedule following pomodoro
            schedule(content: contentForPomodoro(),
                     withTimeInterval: endOfBreak)
        }
        // schedule long break at the end
        schedule(content: contentForLongBreak(), withTimeInterval: finalBreakStartsAt())
    }

    private func finalBreakStartsAt() -> TimeInterval {
        return TimeInterval(PomodoroNotifications.numberOfPomodoriPerRun
            * PomodoroNotifications.durationPerPomodoro
            + (PomodoroNotifications.numberOfPomodoriPerRun - 1)
            * PomodoroNotifications.durationPerShortBreak)
    }

    private func schedule(content: UNMutableNotificationContent,
                          withTimeInterval: TimeInterval) {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: withTimeInterval,
                                                        repeats: false)
        let identifier = schedulerIdentifierPrefix + UUID().uuidString
        let request = UNNotificationRequest(identifier: identifier,
                                            content: content,
                                            trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    private func pomodoroPassedByInPercent(pomodoroNumber: Int) -> Double {
        let startOfThisPomodoro = startOfPomodoro(pomodoroNumber: pomodoroNumber)
        let endOfThisPomodoro =
            startOfThisPomodoro.addingTimeInterval(
                TimeInterval(PomodoroNotifications.durationPerPomodoro))
        let now = Date()
        if now < startOfThisPomodoro { return 0.0 }
        if now >= endOfThisPomodoro { return 100.0 }
        let secondsIntoPomodoro = now.timeIntervalSince(startOfThisPomodoro)
        return Double(secondsIntoPomodoro) * 100.0
            / Double(PomodoroNotifications.durationPerPomodoro)
    }

    private func startOfPomodoro(pomodoroNumber: Int) -> Date {
        let howLongOverallExceptLongBreak = TimeInterval(
            PomodoroNotifications.numberOfPomodoriPerRun * PomodoroNotifications.durationPerPomodoro
                + (PomodoroNotifications.numberOfPomodoriPerRun - 1) * PomodoroNotifications.durationPerShortBreak)
        let start = Date(timeInterval: -howLongOverallExceptLongBreak,
                         since: timeWhenLastPomodoroFinished())
        let howLongBeforeThisPomodoro = TimeInterval(
            (pomodoroNumber - 1)
                * (PomodoroNotifications.durationPerPomodoro
                    + PomodoroNotifications.durationPerShortBreak))
        return start.addingTimeInterval(howLongBeforeThisPomodoro)
    }

    private func timeWhenLastPomodoroFinished() -> Date {
        return UserDefaults.standard.object(forKey: keyForUserDefaults)
            as? Date ?? Date().addingTimeInterval(TimeInterval(-1))
    }

    private func contentForPomodoro() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = contentTitlePomodoro
        content.body = contentBodyPomodoro
        content.sound = soundForPomodoro()
        return content
    }

    private func contentForShortBreak() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = contentTitleShortBreak
        content.body = contentBodyShortBreak
        content.sound = soundForShortBreak()
        return content
    }

    private func contentForLongBreak() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = contentTitleLongBreak
        content.body = contentBodyLongBreak
        content.sound = soundForLongBreak()
        return content
    }

    private func soundForPomodoro() -> UNNotificationSound {
        return UNNotificationSound(named: "work.aiff")
    }

    private func soundForShortBreak() -> UNNotificationSound {
        return UNNotificationSound(named: "break.aiff")
    }

    private func soundForLongBreak() -> UNNotificationSound {
        // same sound for now
        return UNNotificationSound(named: "break.aiff")
    }
}
