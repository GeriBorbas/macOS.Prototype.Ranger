//
//  PlayersTableViewController.swift
//  Ranger
//
//  Created by Geri Borbás on 2020. 01. 17..
//  Copyright © 2020. Geri Borbás. All rights reserved.
//

import Foundation
import SwiftUI


protocol PlayersTableViewControllerDelegate
{
    
    
    func playersTableDidChange()
}


class PlayersTableViewController: NSViewController,

    PlayersTableViewModelDelegate,
    PlayersTableHeaderViewDelegate
{
    
    
    // MARK: - UI
    
    @IBOutlet weak var tableView: NSTableView!
    var delegate: PlayersTableViewControllerDelegate?
    
    
    // MARK: - Model
    
    @IBOutlet weak var viewModel: PlayersTableViewModel!
    
    
    // MARK: - Lifecycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // View model hook.
        viewModel.delegate = self
        
        // Double click.
        tableView.action = #selector(tableDidClick)
        tableView.doubleAction = #selector(tableDidDoubleClick)
    }
    
    
    // MARK: - Hooks
    
    public func update(with players: [Model.Player])
    { viewModel.update(with: players) }
    
    public func update(with tournamentInfo: TournamentInfo)
    { viewModel.update(with: tournamentInfo) }
    
    public func selectRow(at tableSeat: Int)
    {
        // Determine hero seat if any.
        guard
            let hero = viewModel.players.filter({ eachPlayer in eachPlayer.isHero }).first,
            let heroSeat = hero.pokerTracker?.handPlayer?.seat
        else { return }
        
        // Lookup player at given table seat.
        guard
            let player = viewModel.players.filter({ eachPlayer in eachPlayer.screenSeat(heroSittingAt: heroSeat) == tableSeat }).first,
            let row = viewModel.players.firstIndex(of: player)
        else { return }
        
        // Select.
        tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        
        // Retain selection.
        viewModel.selectedPlayer = player
    }
    
    
    // MARK: - Events
    
    @objc func tableDidClick()
    {
        // Skip header row double click.
        guard tableView.clickedRow > -1 else { return }
        guard viewModel.players.count > tableView.clickedRow else { return }
                
        // Select row.
        tableView.selectRowIndexes(IndexSet(integer: tableView.clickedRow), byExtendingSelection: false)
        
        // Retain selection.
        viewModel.selectedPlayer = viewModel.players[tableView.clickedRow]
    }
    
    @objc func tableDidDoubleClick()
    {
        // Skip header row double click.
        guard tableView.clickedRow > -1 else { return }
        
        // Fetch SharkScope (gonna push changes back).
        viewModel.fetchSharkScopeStatisticsForPlayer(inRow: tableView.clickedRow)
    }
    
    func tableHeaderContextMenu(for column: NSTableColumn) -> NSMenu?
    { return viewModel.tableHeaderContextMenu(for: column) }
    
    
    // MARK: - Layout
    
    func playersTableDidChange()
    {
        tableView.reloadData()
        delegate?.playersTableDidChange()
    }
}

// MARK: - Table View User Events

extension PlayersTableViewController: PlayersTableViewDelegate
{
    
    
    func fetchTournementsRequested(for playerName: String)
    { viewModel.fetchTournamentsForPlayer(withName: playerName) }
    
    func fetchLatestTournementsRequested(for playerName: String, amount: Int)
    { viewModel.fetchCompletedTournamentsForPlayer(withName: playerName, amount: amount) }
}


// MARK: - Table View Data

extension PlayersTableViewController: NSTableViewDataSource
{
    
    
    func numberOfRows(in tableView: NSTableView) -> Int
    { return viewModel.players.count }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?
    {
        // Checks.
        guard let column = tableColumn else { return nil }
        guard viewModel.players.count > row else { return nil }
        
        // Get data.
        let player = viewModel.players[row]
        
        // Create / Reuse cell view.
        guard let cellView = tableView.makeView(withIdentifier: (column.identifier), owner: self) as? PlayerCellView else { return nil }
        
        // Apply data.
        cellView.setup(with: player, in: tableColumn)
        
        // Select row if was selected before.
        if (viewModel.selectedPlayer == player)
        { tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false) }
        
        // Fade if no stack (yet hardcoded value).
        if
            let rowView = tableView.rowView(atRow: row, makeIfNecessary: false),
            player.isPlaying,
            player.stack <= 0
        { rowView.alphaValue = 0.4 }
        
        return cellView
    }
}


// MARK: - Table View Events

extension PlayersTableViewController: NSTableViewDelegate
{
    
    
    // Plug in custom row view.
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView?
    { return PlayersTableRowView() }
    
    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor])
    {
        // Sort view model using table sort descriptors.
        viewModel.sort(using: tableView.sortDescriptors)
        
        // Update table view.
        tableView.reloadData()
    }
}
