//
//  NSMenu+Utilities.swift
//  Ranger
//
//  Created by Geri Borbás on 2020. 01. 06..
//  Copyright © 2020. Geri Borbás. All rights reserved.
//

import Foundation
import SwiftUI


extension NSMenu
{
    
    
    func with(items: [NSMenuItem]) -> NSMenu
    {
        items.forEach{self.addItem($0)}
        return self
    }
    
    func with(items: [String]) -> NSMenu
    {
        items.forEach{self.addItem(($0 == "-") ? NSMenuItem.separator() : NSMenuItem(title: $0, action: nil, keyEquivalent: ""))}
        return self
    }
}
