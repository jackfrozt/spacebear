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

class ViewController: UIViewController {
    
    // --- settings ---
   
    // the speed of the rotation
    private let secondsPerRevolution: Double = 2
    
    // the distance between the astronaut and the globe, where 1 unit = height of the astronaut
    private let distanceInSpace: CGFloat = 1.2

    // not implemented yet
    // true means the spinning animation has a gradual acceration before hitting target speed,
    // and gradual deceleration to a stop.
    private let isSmoothStartAndStop = false

    private let direction: Direction = .clockwise
    // end of settings
    
    private let rotateAstronautAnimationKey = "rotateAstronautAnimationKey"
    private var currentRotation: CGFloat = 0
    
    @IBOutlet weak var sceneView: UIView!
    @IBOutlet weak var astronaut: UIImageView!
    @IBOutlet weak var globe: UIImageView!
    @IBOutlet weak var globeWidth: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateAstronautPositionOnLayout()
    }
    
    override func viewDidLayoutSubviews() {
        updateAstronautPositionOnLayout()
    }
    
    @IBAction func startPressed(_ sender: AnyObject) {
        startSpin()
    }
    
    @IBAction func stopPressed(_ sender: AnyObject) {
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
        
        // the globe's position is set via autolayout
        // the height of the globe depends on the dimension of the scene view.
        
        globeWidth.constant = min(sceneView.bounds.size.width, sceneView.bounds.size.height) * 0.4
    }
    
    private func startSpin() {
        if (isSmoothStartAndStop) {
            // not implemented
        } else {
            if astronaut.layer.animation(forKey: rotateAstronautAnimationKey) == nil {
                let animation = CABasicAnimation(keyPath: "transform.rotation.z")
                animation.fromValue = currentRotation
                animation.toValue = currentRotation + (CGFloat.pi * 2 * direction.rawValue)
                animation.repeatCount = .infinity
                animation.duration = secondsPerRevolution
                astronaut.layer.add(animation, forKey: rotateAstronautAnimationKey)
            }
        }
    }
    
    private func stopSpin() {
        if (isSmoothStartAndStop) {
            // not implemented
        } else {
            currentRotation = astronaut.layer.presentation()?.value(forKeyPath: "transform.rotation.z") as! CGFloat
            astronaut.layer.removeAnimation(forKey: rotateAstronautAnimationKey)
            astronaut.layer.setValue(currentRotation, forKeyPath: "transform.rotation.z")
        }
    }
    
    // alternatively, these methods could be used to pause and unpause the animation
//    private func pauseAnimation(_ layer:CALayer){
//        let pausedTime = layer.convertTime(CACurrentMediaTime(), from: nil)
//        layer.speed = 0.0
//        layer.timeOffset = pausedTime
//    }
//    
//    private func resumeAnimation(_ layer:CALayer){
//        let pausedTime = layer.timeOffset
//        layer.speed = 1.0
//        layer.timeOffset = 0.0
//        layer.beginTime = 0.0
//        let timeSincePause = layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
//        layer.beginTime = timeSincePause
//    }

}
