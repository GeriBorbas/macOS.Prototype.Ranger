//
//  ViewController.swift
//  Ranger
//
//  Created by Geri Borbás on 2019. 12. 02..
//  Copyright © 2019. Geri Borbás. All rights reserved.
//

import Cocoa
import CoreGraphics


class TourneyTableViewController: NSViewController, NSComboBoxDelegate
{

    
    // MARK: - UI
    
    @IBOutlet weak var tablesComboBox: NSComboBox!
    @IBOutlet weak var blindsLabel: NSTextField!
    @IBOutlet weak var stacksLabel: NSTextField!
    @IBOutlet weak var playersTableView: NSTableView!
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var sharkScopeStatusLabel: NSTextField!
    
    
    // MARK: - Model
    
    @IBOutlet weak var viewModel: TourneyTableViewModel!
    
    
    // MARK: - Lifecycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // Kick off PokerTracker updates.
        viewModel.start(onChange: layout)
        
        // Fetch SharkScope status at start.
        viewModel.fetchSharkScopeStatus
        {
            status in
            self.sharkScopeStatusLabel.stringValue = status
        }
    }
    
    func track(_ tableWindowInfo: TableWindowInfo)
    {
        // Setup for table info.
        self.view.window?.title = tableWindowInfo.name
    }
    
    func update(with tableWindowInfo: TableWindowInfo)
    {
        // Only if any.
        guard let window = self.view.window
        else { return }
        
        // Align.
        window.setFrame(
            NSRect(
                x: tableWindowInfo.UIKitBounds.origin.x,
                y: tableWindowInfo.UIKitBounds.origin.y - window.frame.size.height,
                width: tableWindowInfo.UIKitBounds.size.width,
                height: window.frame.size.height
            ),
            display: true
        )
         
        // Put above.
        window.order(NSWindow.OrderingMode.above, relativeTo: tableWindowInfo.number)
        
        // Disable drag.
        window.isMovable = false
    }
    
    func comboBoxSelectionDidChange(_ notification: Notification)
    {
        // Unwrap sender.
        guard let comboBox: NSComboBox = (notification.object as? NSComboBox)
        else { return }
        
        // Select model.
        viewModel.selectedLiveTourneyTableIndex = comboBox.indexOfSelectedItem
    }
    
    
    // MARK: - Layout
    
    func layout()
    {
        tablesComboBox.reloadData()
        tablesComboBox.selectItem(at: viewModel.selectedLiveTourneyTableIndex)
        
        let tableSummary = viewModel.tableSummary(for: viewModel.selectedLiveTourneyTableIndex, font: blindsLabel.font!)
        blindsLabel.attributedStringValue = tableSummary.blinds
        stacksLabel.attributedStringValue = tableSummary.stacks
        
        playersTableView.reloadData()
    }
}
