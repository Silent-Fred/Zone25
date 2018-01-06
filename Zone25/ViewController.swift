//
//  ViewController.swift
//  Zone25
//
//  Created by Michael Kühweg on 02.01.18.
//  Copyright © 2018 Michael Kühweg. All rights reserved.
//

import UIKit
import UserNotifications

class ViewController: UIViewController, UNUserNotificationCenterDelegate {

    @IBOutlet weak var pomodoro1: UIImageView!
    @IBOutlet weak var pomodoro2: UIImageView!
    @IBOutlet weak var pomodoro3: UIImageView!
    @IBOutlet weak var pomodoro4: UIImageView!

    @IBOutlet weak var button: UIButton!
    
    private let pomodori = PomodoroNotifications()
    private let refreshInterval = TimeInterval(1)
    private var refreshTimer = Timer()

    override func viewDidLoad() {
        super.viewDidLoad()
        UNUserNotificationCenter.current().delegate = self
        // Pending notifications on startup? Refresh screen accordingly.
        refresh()
        startRefreshTimer()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func buttonAction() {
        if pomodori.finished() {
            pomodori.scheduleNotifications()
        } else {
            pomodori.cancelNotifications()
        }
        refresh()
    }

    @objc public func refresh() {
        // localise these two terms???
        if pomodori.finished() {
            button.setTitle("Start", for: .normal)
        } else {
            button.setTitle("Stop", for: .normal)
        }
        let percentages = pomodori.pomodoriPassedByInPercent()
        pomodoro1.image = drawPomodori(placeholder: pomodoro1,
                                       percentageDone: percentages[0])
        pomodoro2.image = drawPomodori(placeholder: pomodoro2,
                                       percentageDone: percentages[1])
        pomodoro3.image = drawPomodori(placeholder: pomodoro3,
                                       percentageDone: percentages[2])
        pomodoro4.image = drawPomodori(placeholder: pomodoro4,
                                       percentageDone: percentages[3])
    }

    func startRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(
            timeInterval: refreshInterval,
            target: self,
            selector: (#selector(ViewController.refresh)),
            userInfo: nil,
            repeats: true)
        refreshTimer.tolerance = 1
    }

    func stopRefreshTimer() {
        refreshTimer.invalidate()
    }

    private func drawPomodori(placeholder: UIImageView,
                              percentageDone: Double) -> UIImage? {

        let bounds = boundingRectangle(placeholder: placeholder)

        let renderer = UIGraphicsImageRenderer(size: placeholder.frame.size)
        return renderer.image { context in
            if percentageDone < 100 {
                drawCircleIn(context: context, cgRect: bounds)
            }
            if percentageDone > 0 {
                drawArcIn(context: context,
                          cgRect: bounds,
                          percentageDone: percentageDone)
            }
        }
    }

    private func boundingRectangle(placeholder: UIImageView) -> CGRect {
        let x = CGFloat(2)
        let y = CGFloat(2)
        let width = CGFloat(placeholder.frame.width - 4)
        let height = CGFloat(placeholder.frame.height - 4)
        let squareExtent = min(width, height)
        return CGRect(x: x, y: y, width: squareExtent, height: squareExtent)
    }

    private func drawCircleIn(context: UIGraphicsImageRendererContext,
                              cgRect: CGRect) {
        let baseColour = self.view.tintColor
        let alpha = 0.25
        context.cgContext.setAlpha(CGFloat(alpha))
        context.cgContext.setFillColor((baseColour?.cgColor)!)
        context.cgContext.setStrokeColor((baseColour?.cgColor)!)
        context.cgContext.addEllipse(in: cgRect)
        context.cgContext.drawPath(using: .fillStroke)
    }

    private func drawArcIn(context: UIGraphicsImageRendererContext,
                           cgRect: CGRect,
                           percentageDone: Double) {
        let baseColour = self.view.tintColor
        let alpha = 1.0
        let angle = CGFloat(2.0) * CGFloat.pi * CGFloat(100 - percentageDone) / 100
        context.cgContext.setAlpha(CGFloat(alpha))
        context.cgContext.setFillColor((baseColour?.cgColor)!)
        context.cgContext.setStrokeColor((baseColour?.cgColor)!)
        let arcCenter = CGPoint(x: cgRect.midX, y: cgRect.midY)
        context.cgContext.move(to: arcCenter)
        context.cgContext.addArc(center: arcCenter,
                                 radius: min(cgRect.width, cgRect.height) / 2.0,
                                 startAngle: 0,
                                 endAngle: angle,
                                 clockwise: false)
        context.cgContext.fillPath()
    }

    //MARK: Delegates
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
        @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
}

