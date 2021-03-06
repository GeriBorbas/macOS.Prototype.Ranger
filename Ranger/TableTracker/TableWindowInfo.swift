//
//  TableWindowInfo.swift
//  Ranger
//
//  Created by Geri Borbás on 2019. 12. 29..
//  Copyright © 2019. Geri Borbás. All rights reserved.
//

import Foundation
import SwiftUI


struct TableWindowInfo
{
    
    
    // Properties.
    var name: String
    var number: Int
    var index: Int
    var bounds: CGRect
    
    // UI.
    var UIKitBounds: CGRect
    {
        CGRect.init(
            x: self.bounds.minX,
            y: NSScreen.main!.frame.size.height - self.bounds.minY - self.bounds.size.height,
            width: self.bounds.size.width,
            height: self.bounds.size.height
        )
    }
    
    var isMainWindow: Bool
    { index == 1 }
        
    // Parse.
    var tableInfo: TableInfo?
    { TableInfo(name: name) }
}


extension TableWindowInfo
{
    
    
    /// Used to determine if any update delegation is needed in `TableTracker.tick()`.
    func isUpdated(comparedTo rhs: TableWindowInfo) -> Bool
    {
        // Shortcut.
        let lhs = self
        
        // Is updated if any of the following is different.
        guard lhs.name == rhs.name else { return true }
        guard lhs.number == rhs.number else { return true }
        guard lhs.index == rhs.index else { return true }
        guard lhs.bounds == rhs.bounds else { return true }
        
        return false
    }
}


extension TableWindowInfo: Equatable
{
    
    
    /// Equality is used for diffing in `TableTracker.tick()`.
    static func == (lhs: TableWindowInfo, rhs: TableWindowInfo) -> Bool
    {
        lhs.tableInfo?.tournamentNumber == rhs.tableInfo?.tournamentNumber
    }
}


extension TableWindowInfo: Hashable
{


    func hash(into hasher: inout Hasher)
    {
        hasher.combine(tableInfo?.tournamentNumber)
    }
}
