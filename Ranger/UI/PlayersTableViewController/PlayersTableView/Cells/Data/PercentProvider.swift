//
//  Parameters.swift
//  Ranger
//
//  Created by Geri Borbás on 2020. 01. 03..
//  Copyright © 2020. Geri Borbás. All rights reserved.
//

import Cocoa


class PercentProvider: NSObject
{
    
    
    @objc dynamic var minimum: NSNumber = 0.0
    @objc dynamic var maximum: NSNumber = 0.0
    @objc dynamic var easing: String = "linear"
    @objc dynamic var offset: NSNumber = 0.0
    @objc dynamic var log: Bool = false
    
    
    func percent(value: Float) -> Float
    {
        // Only if adjustments any.
        if (
            minimum == 0.0 &&
            maximum == 0.0
            )
        { return value }
        
        // Calculate.
        let size = maximum.floatValue - minimum.floatValue
        let offsetValue = value - minimum.floatValue
        let percent = offsetValue / size
        let cappedPercent = max(min(percent, 1.0), 0.0)
        let easedPercent = cappedPercent.ease(name: easing)
        let offsetPercent = offset.floatValue + (1.0 - offset.floatValue) * easedPercent
        
        // Log.
        if (log)
        {
            print("value: \(value)")
            print("size: \(size)")
            print("offsetValue: \(offsetValue)")
            print("percent: \(percent)")
            print("cappedPercent: \(cappedPercent)")
            print("easedPercent: \(easedPercent)")
            print("offsetPercent: \(offsetPercent)")
        }
        
        return offsetPercent
    }
}
