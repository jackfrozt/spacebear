//
//  ViewController.swift
//  SpaceBear
//
//  Created by Jacky Li on 2017-04-20.
//  Copyright © 2017 Jacky Li. All rights reserved.
//

import UIKit

fileprivate enum Direction: CGFloat {
    case clockwise = 1
    case counterClockwise = -1
}

class ViewController: UIViewController, CAAnimationDelegate {
    
    // --- settings ---
   
    // the speed of the rotation
    private let secondsPerRevolution: Double = 16

    // the size of the globe, as a ratio to scene width or scene height, which ever is smaller.
    private let globeSize: CGFloat = 0.5
    
    // the distance between the astronaut and the globe, where 1 unit = height of the astronaut
    private let distanceInSpace: CGFloat = 0.8

    // true means the spinning animation has a gradual acceration before hitting target speed,
    // and gradual deceleration to a stop.
    private let isSmoothStartAndStop = true

    private let direction: Direction = .clockwise
    
    // --- end of settings ---
    
    
    private let rotateAstronautAnimationKey = "rotateAstronautAnimationKey"
    private let accelAnimationKey = "accelAnimationKey"
    private let decelAnimationKey = "decelAnimationKey"
    
    // animation ID used for identifying in animationDidStop callback
    private let animationIDKey = "animationIDKey"
    private let accelAnimationID = "accelAnimationID"
    private let decelAnimationID = "decelAnimationID"
    
    private var currentRotation: CGFloat = 0
    
    @IBOutlet weak var sceneView: UIView!
    @IBOutlet weak var astronaut: UIImageView!
    @IBOutlet weak var globe: UIImageView!
    @IBOutlet weak var globeWidth: NSLayoutConstraint!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateAstronautPositionOnLayout()
        disable(stopButton)
    }
    
    override func viewDidLayoutSubviews() {
        updateAstronautPositionOnLayout()
    }
    
    @IBAction func startPressed(_ sender: AnyObject) {
        disable(startButton)
        startSpin()
    }
    
    @IBAction func stopPressed(_ sender: AnyObject) {
        disable(stopButton)
        stopSpin()
    }
    
    private func updateAstronautPositionOnLayout() {
        // The astronaut view is placed at the center of the globe via autolayout.
        // The anchor point of the astronaut needs to be offset so that when a rotation is applied,
        // it flys around the glob.
        
        let astronautToGlobeSizeRatio = self.astronaut.bounds.size.width / globe.bounds.size.width

        // half of the height of the astronaut, plus however many times the height of the astronaut to get half a globe
        let globesEdge: CGFloat = 0.5 + ((1 / astronautToGlobeSizeRatio) / 2)
        let offset = globesEdge + distanceInSpace
        astronaut.layer.anchorPoint = CGPoint(x: 0.5 + offset, y: 0.5)
        
        // set the size of the globe
        // the globe's position is set via autolayout
        // the height of the globe depends on the dimension of the scene view.
        globeWidth.constant = min(sceneView.bounds.size.width, sceneView.bounds.size.height) * globeSize
    }
    
    private func startSpin() {
        if (isSmoothStartAndStop) {
            currentRotation = astronaut.layer.presentation()?.value(forKeyPath: "transform.rotation.z") as! CGFloat
            
            let accelAnim = CABasicAnimation(keyPath: "transform.rotation.z")
            accelAnim.setValue(accelAnimationID, forKey: animationIDKey)
            accelAnim.delegate = self
            accelAnim.fromValue = currentRotation
            accelAnim.toValue = currentRotation + (CGFloat.pi / 2 * direction.rawValue)
            astronaut.layer.setValue(accelAnim.toValue, forKeyPath: "transform.rotation.z")
            accelAnim.duration = secondsPerRevolution / 3.5
            accelAnim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
            astronaut.layer.add(accelAnim, forKey: accelAnimationKey)
            
        } else {
            spinAstronautFullSpeedFromCurrentLocation()
            enable(stopButton)
        }
    }
    
    private func stopSpin() {
        if (isSmoothStartAndStop) {
            currentRotation = astronaut.layer.presentation()?.value(forKeyPath: "transform.rotation.z") as! CGFloat
            astronaut.layer.removeAnimation(forKey: accelAnimationKey)
            astronaut.layer.removeAnimation(forKey: rotateAstronautAnimationKey)
            
            // decelerate
            let decelAnim = CABasicAnimation(keyPath: "transform.rotation.z")
            decelAnim.setValue(decelAnimationID, forKeyPath: animationIDKey)
            decelAnim.delegate = self
            decelAnim.fromValue = currentRotation
            decelAnim.toValue = currentRotation + (CGFloat.pi / 4 * direction.rawValue)
            astronaut.layer.setValue(decelAnim.toValue, forKeyPath: "transform.rotation.z")
            decelAnim.duration = secondsPerRevolution / 5
            decelAnim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
            astronaut.layer.add(decelAnim, forKey: decelAnimationKey)
            
        } else {
            currentRotation = astronaut.layer.presentation()?.value(forKeyPath: "transform.rotation.z") as! CGFloat
            astronaut.layer.removeAnimation(forKey: rotateAstronautAnimationKey)
            astronaut.layer.setValue(currentRotation, forKeyPath: "transform.rotation.z")
            
            enable(startButton)
        }
    }
    
    private func spinAstronautFullSpeedFromCurrentLocation() {
        guard astronaut.layer.animation(forKey: rotateAstronautAnimationKey) == nil else {
            return
        }
        
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = currentRotation
        animation.toValue = currentRotation + (CGFloat.pi * 2 * direction.rawValue)
        animation.repeatCount = .infinity
        animation.duration = secondsPerRevolution
        astronaut.layer.add(animation, forKey: rotateAstronautAnimationKey)
    }
    
    private func enable(_ button: UIButton) {
        button.isEnabled = true
        button.alpha = 1
    }
    
    private func disable(_ button: UIButton) {
        button.isEnabled = false
        button.alpha = 0.4
    }
    
    // CAAnimationDelegate
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if flag {
            if let id = anim.value(forKey: animationIDKey) as? String {
                switch id {
                case accelAnimationID:
                    currentRotation = self.astronaut.layer.value(forKeyPath: "transform.rotation.z") as! CGFloat
                    
                    // acceleration has finished
                    spinAstronautFullSpeedFromCurrentLocation()
                    
                    // allow stopping
                    enable(stopButton)
                    
                case decelAnimationID:
                    enable(startButton)
                    
                default:
                    break
                }
            }
        }
    }
    
    
}
