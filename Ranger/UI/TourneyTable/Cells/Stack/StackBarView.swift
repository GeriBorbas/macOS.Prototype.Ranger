//
//  StackBarView.swift
//  Ranger
//
//  Created by Geri Borbás on 2020. 01. 08..
//  Copyright © 2020. Geri Borbás. All rights reserved.
//

import Cocoa



class StackBarView: NSView
{

    
    @IBOutlet weak var percentProvider: PercentProvider?
    @IBOutlet weak var colorRanges: ColorRanges?
    
    
    var stack: Float = 1500
    { didSet { self.setNeedsDisplay(self.bounds) } }
    var orbitCost: Float = 57
    { didSet { self.setNeedsDisplay(self.bounds) } }
    
    
    override func draw(_ dirtyRect: NSRect)
    {
        super.draw(dirtyRect)
        
        // Checks.
        guard let percentProvider = percentProvider
        else { return }
        
        // Draw chunks.
        var stackCursor: Float = 0.0
        let radius: CGFloat =  2.0
        let spacing: CGFloat = radius
        let stackIncrement = orbitCost * 5.0 // Draw 5M chunks
        while (true)
        {
            // Get bounds.
            let leftStack = stackCursor
            var rightStack = stackCursor + stackIncrement
            
            // Cap.
            if (rightStack > stack) { rightStack = stack }
            
            let leftPercent = percentProvider.percent(value: leftStack)
            let rightPercent = percentProvider.percent(value: rightStack)
                        
            let leftPosition = CGFloat(leftPercent) * self.bounds.width + spacing / 2.0
            let rightPosition = CGFloat(rightPercent) * self.bounds.width - spacing / 2.0
            var width = rightPosition - leftPosition
            
            // Cap.
            if (width < radius) { width = 0.0 }
            else if (width < radius * 2.0) { width = radius * 2.0 }
            
            // Measure.
            let chunkRect = CGRect(
                x: leftPosition,
                y: self.bounds.origin.y,
                width: width,
                height:  self.bounds.height
            )
            
            // Calculate color.
            let stackM = stack / orbitCost
            // let rightM = rightStack / orbitCost

            // Draw.
            let chunk = NSBezierPath(roundedRect: chunkRect, xRadius: 2.0, yRadius: 2.0)
            (colorRanges?.color(for: stackM) ?? NSColor.white).setFill()
            chunk.fill()
            
            // Step.
            stackCursor = rightStack
            
            // End.
            if (stackCursor >= stack)
            { break }
        }
    }
    
    override func layout()
    {
        super.layout()
    }
    
}
