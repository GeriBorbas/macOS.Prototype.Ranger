//
//  TourneyTableWindowController.swift
//  Ranger
//
//  Created by Geri Borbás on 2019. 12. 30..
//  Copyright © 2019. Geri Borbás. All rights reserved.
//

import Cocoa


class TourneyTableWindowController: NSWindowController
{
        
    
    // MARK: - Lifecycle
    
    static func instantiateAndShow(forTableWindowInfo tableWindowInfo: TableWindowInfo) -> TourneyTableWindowController
    {
        // Instantiate a new controller.
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let tourneyTableWindowController = storyboard.instantiateController(withIdentifier: "TourneyTableWindow") as! TourneyTableWindowController
            tourneyTableWindowController.showWindow(self)
        
        // Track table.
        let tourneyTableViewController = tourneyTableWindowController.contentViewController as! TourneyTableViewController
            tourneyTableViewController.track(tableWindowInfo)
        
        return tourneyTableWindowController
    }
    
    func update(with tableWindowInfo: TableWindowInfo)
    {
        let tourneyTableViewController = self.contentViewController as! TourneyTableViewController
            tourneyTableViewController.update(with: tableWindowInfo)
    }
}
