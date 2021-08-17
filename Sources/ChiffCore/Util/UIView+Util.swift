//
//  File.swift
//
//
//  Created by Dmitriy Starodubtsev on 13.08.2021.
//

import Foundation
import UIKit

extension UIView {
    public class func fromNib<T: UIView>() -> T {
        return Bundle(for: T.self).loadNibNamed(String(describing: T.self), owner: nil, options: nil)![0] as! T
    }

    public func shake(for duration: TimeInterval = 0.5, withTranslation translation: CGFloat = 10) {
        let propertyAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 0.3) {
            self.transform = CGAffineTransform(translationX: translation, y: 0)
        }

        propertyAnimator.addAnimations({
            self.transform = CGAffineTransform(translationX: 0, y: 0)
        }, delayFactor: 0.2)

        propertyAnimator.startAnimation()
    }

    public func startWiggle() {
        let duration: Double = 0.25
        let displacement: CGFloat = 1.0
        let degreesRotation: CGFloat = 2.0
        let negativeDisplacement = -1.0 * displacement
        let position = CAKeyframeAnimation(keyPath: "position")
        position.beginTime = 0.8
        position.duration = duration
        position.values = [
            NSValue(cgPoint: CGPoint(x: negativeDisplacement, y: negativeDisplacement)),
            NSValue(cgPoint: CGPoint(x: 0, y: 0)),
            NSValue(cgPoint: CGPoint(x: negativeDisplacement, y: 0)),
            NSValue(cgPoint: CGPoint(x: 0, y: negativeDisplacement)),
            NSValue(cgPoint: CGPoint(x: negativeDisplacement, y: negativeDisplacement))
        ]
        position.calculationMode = .linear
        position.isRemovedOnCompletion = false
        position.repeatCount = Float.greatestFiniteMagnitude
        position.beginTime = CFTimeInterval(Float(arc4random()).truncatingRemainder(dividingBy: Float(25)) / Float(100))
        position.isAdditive = true

        let transform = CAKeyframeAnimation(keyPath: "transform")
        transform.beginTime = 2.6
        transform.duration = duration
        transform.valueFunction = CAValueFunction(name: CAValueFunctionName.rotateZ)
        transform.values = [
            self.degreesToRadians(-1.0 * Double(degreesRotation)),
            self.degreesToRadians(Double(degreesRotation)),
            self.degreesToRadians(-1.0 * Double(degreesRotation))
        ]
        transform.calculationMode = .linear
        transform.isRemovedOnCompletion = false
        transform.repeatCount = Float.greatestFiniteMagnitude
        transform.isAdditive = true
        transform.beginTime = CFTimeInterval(Float(arc4random()).truncatingRemainder(dividingBy: Float(25)) / Float(100))

        self.layer.add(position, forKey: "bounce")
        self.layer.add(transform, forKey: "wiggle")
    }

    public func stopWiggle() {
        self.layer.removeAllAnimations()
        self.transform = .identity
    }

    public func degreesToRadians(_ number: Double) -> Double {
        return number * .pi / 180
    }
}
