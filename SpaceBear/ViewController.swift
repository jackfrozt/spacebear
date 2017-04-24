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
    private let secondsPerRevolution: TimeInterval = 6
    
    // The spinning animation can have a gradual acceration before hitting target speed,
    // and gradual deceleration to a stop. During this time, jets fire, and controls are disabled.
    private let accelerationDuration: TimeInterval = 1.5
    private let decelerationDuration: TimeInterval = 1.8
    
    // the size of the globe image, as a ratio to view's width or scene's height, which ever is smaller.
    // the scene's height is from the top of the screen to the top of the buttons.
    private let globeSize: CGFloat = 0.5
    
    // the distance between the astronaut and the globe image, where 1 unit = height of the astronaut
    private let distanceInSpace: CGFloat = 0.6

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
    
    @IBOutlet weak var astronautGroupView: UIView!
    @IBOutlet weak var lowerJet: UIImageView!
    @IBOutlet weak var upperJetLeft: UIImageView!
    @IBOutlet weak var upperJetRight: UIImageView!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updatePositions()
        disable(stopButton)
        
        // set up the jets animations
        // the jets have an image in IB as placeholder, clear it to nil.
        lowerJet.image = nil
        upperJetLeft.image = nil
        upperJetRight.image = nil
        
        lowerJet.animationImages = [#imageLiteral(resourceName: "jets1"), #imageLiteral(resourceName: "jets2"), #imageLiteral(resourceName: "jets3"), #imageLiteral(resourceName: "jets4")]
        upperJetLeft.animationImages = [#imageLiteral(resourceName: "jets2"), #imageLiteral(resourceName: "jets3"), #imageLiteral(resourceName: "jets4"), #imageLiteral(resourceName: "jets1")]
        upperJetRight.animationImages = [#imageLiteral(resourceName: "jets4"), #imageLiteral(resourceName: "jets1"), #imageLiteral(resourceName: "jets2"), #imageLiteral(resourceName: "jets3")]
        
    }
    
    override func viewDidLayoutSubviews() {
        updatePositions()
    }
    
    @IBAction func startPressed(_ sender: AnyObject) {
        disable(startButton)
        startSpin()
    }
    
    @IBAction func stopPressed(_ sender: AnyObject) {
        disable(stopButton)
        stopSpin()
    }
    
    private func updatePositions() {
        // The astronaut view is placed at the center of the globe via autolayout.
        // The anchor point of the astronaut needs to be offset so that when a rotation is applied,
        // it flys around the glob.
        
        let astronautToGlobeSizeRatio = self.astronautGroupView.bounds.size.width / globe.bounds.size.width

        // half of the height of the astronaut, plus however many times the height of the astronaut to get half a globe
        let globesEdge: CGFloat = 0.5 + ((1 / astronautToGlobeSizeRatio) / 2)
        let offset = globesEdge + distanceInSpace
        astronautGroupView.layer.anchorPoint = CGPoint(x: 0.5 + offset, y: 0.5)
        
        // set the size of the globe
        // the globe's position is set via autolayout
        // the height of the globe depends on the dimension of the scene view.
        globeWidth.constant = min(sceneView.bounds.size.width, sceneView.bounds.size.height) * globeSize
    }
    
    private func startSpin() {
        if (accelerationDuration > 0) {
            /* 
             Acceleration is animated using CAAnimation with an ease-in.
             The continuous spin after acceleration is created in animationDidStop.
             
             The duration, speed and starting value are known,
             but the distance needed to get up to speed needs to be calculated.
             
             Let's start with the distance as if there were no acceleration.
             distance = time * speed
                      = (accelerationDuration * (2*Pi / secondsPerRevolution))
             
             kCAMediaTimingFunctionEaseIn is used for acceleration,
             and the velocity at the end of that animation needs to match the desired speed.
             The ease-in bezier curve has the control points (0.42,0.0) and (1.0,1.0).
             The slope at the end of that curve is 1.72414, which means
             it is 1.72414 times faster than it needs to be.
             To make the ease-in end in the desired speed, 
             the distance needs to be 1.72414 times shorter.
             */
            
            let accelDistance = CGFloat((accelerationDuration * (2 * Double.pi / secondsPerRevolution)) / 1.72414)
            
            currentRotation = astronautGroupView.layer.presentation()?.value(forKeyPath: "transform.rotation.z") as! CGFloat
            
            let accelAnim = CABasicAnimation(keyPath: "transform.rotation.z")
            accelAnim.setValue(accelAnimationID, forKey: animationIDKey)
            accelAnim.delegate = self
            accelAnim.fromValue = currentRotation
            accelAnim.toValue = currentRotation + (accelDistance * direction.rawValue)
            astronautGroupView.layer.setValue(accelAnim.toValue, forKeyPath: "transform.rotation.z")
            accelAnim.duration = accelerationDuration
            accelAnim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
            astronautGroupView.layer.add(accelAnim, forKey: accelAnimationKey)
            
            switch direction {
            case .clockwise:
                lowerJet.startAnimating()
            case .counterClockwise:
                upperJetLeft.startAnimating()
                upperJetRight.startAnimating()
            }
            
        } else {
            spinAstronautFullSpeedFromCurrentLocation()
            enable(stopButton)
        }
    }
    
    private func stopSpin() {
        if (decelerationDuration > 0) {
            currentRotation = astronautGroupView.layer.presentation()?.value(forKeyPath: "transform.rotation.z") as! CGFloat
            astronautGroupView.layer.removeAnimation(forKey: rotateAstronautAnimationKey)
            
            /*
             decelerate using kCAMediaTimingFunctionEaseOut
             which has an bezier curve with control points (0.0,0.0) and (0.58,1.0),
             similar to the acceleration animation.
             */
            
            let decelDistance = CGFloat((decelerationDuration * (2 * Double.pi / secondsPerRevolution)) / 1.72414)
            
            let decelAnim = CABasicAnimation(keyPath: "transform.rotation.z")
            decelAnim.setValue(decelAnimationID, forKeyPath: animationIDKey)
            decelAnim.delegate = self
            decelAnim.fromValue = currentRotation
            decelAnim.toValue = currentRotation + (decelDistance * direction.rawValue)
            astronautGroupView.layer.setValue(decelAnim.toValue, forKeyPath: "transform.rotation.z")
            decelAnim.duration = decelerationDuration
            decelAnim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
            astronautGroupView.layer.add(decelAnim, forKey: decelAnimationKey)
            
            switch direction {
            case .clockwise:
                upperJetLeft.startAnimating()
                upperJetRight.startAnimating()
            case .counterClockwise:
                lowerJet.startAnimating()
            }
            
        } else {
            currentRotation = astronautGroupView.layer.presentation()?.value(forKeyPath: "transform.rotation.z") as! CGFloat
            astronautGroupView.layer.removeAnimation(forKey: rotateAstronautAnimationKey)
            astronautGroupView.layer.setValue(currentRotation, forKeyPath: "transform.rotation.z")
            
            enable(startButton)
        }
    }
    
    private func spinAstronautFullSpeedFromCurrentLocation() {
        guard astronautGroupView.layer.animation(forKey: rotateAstronautAnimationKey) == nil else {
            return
        }
        
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = currentRotation
        animation.toValue = currentRotation + (CGFloat.pi * 2 * direction.rawValue)
        animation.repeatCount = .infinity
        animation.duration = secondsPerRevolution
        astronautGroupView.layer.add(animation, forKey: rotateAstronautAnimationKey)
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
                    currentRotation = self.astronautGroupView.layer.value(forKeyPath: "transform.rotation.z") as! CGFloat
                    
                    // acceleration has finished
                    
                    switch direction {
                    case .clockwise:
                        lowerJet.stopAnimating()
                    case .counterClockwise:
                        upperJetLeft.stopAnimating()
                        upperJetRight.stopAnimating()
                    }
                    
                    spinAstronautFullSpeedFromCurrentLocation()
                    
                    // allow stopping
                    enable(stopButton)
                    
                case decelAnimationID:
                    enable(startButton)
                    
                    switch direction {
                    case .clockwise:
                        upperJetLeft.stopAnimating()
                        upperJetRight.stopAnimating()
                    case .counterClockwise:
                        lowerJet.stopAnimating()
                    }
                default:
                    break
                }
            }
        }
    }
    
    
}
