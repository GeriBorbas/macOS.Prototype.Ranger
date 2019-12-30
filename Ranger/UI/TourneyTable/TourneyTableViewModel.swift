//
//  TourneyTableViewModel.swift
//  Ranger
//
//  Created by Geri Borbás on 2019. 12. 14..
//  Copyright © 2019. Geri Borbás. All rights reserved.
//

import Foundation
import SwiftUI


class TourneyTableViewModel: NSObject
    
{
    
    
    // MARK: - Services
    
    private lazy var pokerTracker: PokerTracker = PokerTracker()
    private lazy var sharkScope: SharkScope = SharkScope()
    
    
    // MARK: - Data
    
    /// Indicator of data change.
    private var changed: Bool = false
    
    /// Indicate data change.
    private func markAsChanged() { changed = true }
    
    /// Reset indicator of data change.
    private func markAsUnchanged() { changed = false }
        
    /// PokerTracker data from `live_tourney_table`. Can indicate change upon set.
    private var liveTourneyTables: [LiveTourneyTable] = []
    {
        didSet
        {
            if liveTourneyTables.elementsEqual(oldValue) == false
            { markAsChanged() }
        }
    }
    
    /// Selected table for this view. Can invoke `onChange()` upon set.
    private var selectedLiveTourneyTable: LiveTourneyTable?
    {
        didSet
        {
            // Look for changes.
            if selectedLiveTourneyTable != oldValue
            { try? processData() }
        }
    }
    
    /// Index of the currently selected table for this view (in `liveTourneyTables`).
    public var selectedLiveTourneyTableIndex: Int
    {
        get
        {
            // -1 if no tables selected.
            guard let selectedLiveTourneyTable = selectedLiveTourneyTable
            else { return -1 }
            return liveTourneyTables.firstIndex(of: selectedLiveTourneyTable)!
        }
        set
        {
            var _selectedLiveTourneyTable: LiveTourneyTable?
            
            // Select last table if index is greater than available tables (or `nil` if no tables at all).
            if liveTourneyTables.count < newValue
            { _selectedLiveTourneyTable = liveTourneyTables.last ?? nil }
            // Or just select table at index.
            else
            { _selectedLiveTourneyTable = liveTourneyTables[newValue] }
            
            // Set only if changed.
            if (selectedLiveTourneyTable != _selectedLiveTourneyTable)
            {
                selectedLiveTourneyTable = _selectedLiveTourneyTable
                onSelectedTableDidChange()
            }
        }
    }
    
    /// ViewModels for players seated at selected table (`selectedLiveTourneyTable`).
    private var playerViewModels: [PlayerViewModel] = []
    
    /// SharkScope `Data`
    private var playerStatisticsForPlayerNames: [String:Statistics] = [:]
    private var playerTableCountsForPlayerNames: [String:Int] = [:]
    
    
    // MARK: - Binds
    
    private var onChange: (() -> Void)?
    
    private func onSelectedTableDidChange()
    {
        // Update player list.
        markAsChanged()
        playerViewModels.removeAll()
        try? processData()
    }
    
    
    // MARK: - Lifecycle
    
    public func start(onChange: (() -> Void)?)
    {
        // Retain.
        self.onChange = onChange
        
        // Schedule timer.
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true)
        { _ in self.tick() }
        
    }
    
    // MARK: - SharkScope
    
    func fetchSharkScopeStatus(completion: @escaping (_ status: String) -> Void)
    {
        // Ping to SharkScope.
        sharkScope.fetch(TimelineRequest(network: "PokerStars", player:"Borbas.Geri").withoutCache(),
                        completion:
        {
           (result: Result<Timeline, RequestError>) in
           switch result
           {
               case .success(let lastActivity):
                   completion("\(lastActivity.Response.UserInfo.RemainingSearches) search remaining (logged in as \(lastActivity.Response.UserInfo.Username)).")
                   break
               
               case .failure(let error):
                   completion("SharkScope error: \(error)")
                   break
           }
        })
    }
    
    
    // MARK: - Process Data
    
    private func tick()
    {
        try? processData()
    }
    
    private func processData() throws
    {
        // Get current tables (may invoke `markAsChanged`).
        liveTourneyTables = try pokerTracker.fetch(LiveTourneyTableQuery())
        
        // Only if tables any.
        guard liveTourneyTables.count > 0
        else
        {
            invokeOnChangedIfNeeded()
            return
        }
        
        // Get current players (may invoke `markAsChanged`).
        let liveTourneyPlayers = try pokerTracker.fetch(LiveTourneyPlayerQuery())
                
        // Select first table by default if needed.
        if (selectedLiveTourneyTable == nil)
        { selectedLiveTourneyTable = liveTourneyTables.first! }
        
        // Filter current players at the selected table (with non-zero stack).
        let liveTourneyPlayersAtSelectedTable = liveTourneyPlayers.filter
        {
            (eachLiveTourneyPlayer: LiveTourneyPlayer) in
            (
                eachLiveTourneyPlayer.id_live_table == selectedLiveTourneyTableIndex + 1 &&
                eachLiveTourneyPlayer.amt_stack > 0
            )
        }
        
        // Collect `id_player` for current players.
        let currentPlayerIDs = liveTourneyPlayersAtSelectedTable
        .map{ eachPlayer in eachPlayer.id_player }

        // Colelct `id_player` for view model players.
        var viewModelPlayerIDs: [Int] = playerViewModels.map
        {
            eachPlayerViewModel in
            eachPlayerViewModel.pokerTracker.liveTourneyPlayer.id_player
        }

        // Collect removable players.
        var removablePlayerIDs: [Int] = []
        viewModelPlayerIDs.forEach
        {
            eachViewModelPlayerID in
            if (currentPlayerIDs.contains(eachViewModelPlayerID) == false)
            { removablePlayerIDs.append(eachViewModelPlayerID) }
        }
        
        // Remove removable players.
        removablePlayerIDs.forEach
        {
            eachRemovablePlayerID in
            if let indexOfRemovablePlayer = viewModelPlayerIDs.firstIndex(of: eachRemovablePlayerID)
            { viewModelPlayerIDs.remove(at: indexOfRemovablePlayer) }
        }

        // Create / Collect new players if needed.
        currentPlayerIDs.forEach
        {
            eachCurrentPlayerID in
            if (viewModelPlayerIDs.contains(eachCurrentPlayerID) == false)
            {
                let eachIndex = currentPlayerIDs.firstIndex(of: eachCurrentPlayerID)!
                playerViewModels.append(PlayerViewModel(with: liveTourneyPlayersAtSelectedTable[eachIndex]))
            }
        }
        
        // Look for changes.
        invokeOnChangedIfNeeded()
    }
    
    private func invokeOnChangedIfNeeded()
    {
        if (changed)
        {
            onChange?()
            markAsUnchanged()
        }
    }
    
    
    // MARK: - Table Summary Data
    
    public func tableSummary(for index: Int, font: NSFont) -> (blinds: NSAttributedString, stacks: NSAttributedString)
    {
        // Variables.
        var smallBlind:Double = 0
        var bigBlind:Double = 0
        var ante:Double = 0
        var players:Double = 0
        
        // Check data.
        if (liveTourneyTables.count == 0)
        {
            // Empty state.
            return (
                NSMutableAttributedString(string: "-"),
                NSMutableAttributedString(string: "-")
            )
        }
        
        // Fetch data from first live table.
        let selectedLiveTourneyTable = liveTourneyTables[index]
        smallBlind = selectedLiveTourneyTable.amt_sb
        bigBlind = selectedLiveTourneyTable.amt_bb
        ante = selectedLiveTourneyTable.amt_ante
        players = Double(selectedLiveTourneyTable.cnt_players)
        
        // Model.
        let M:Double = smallBlind + bigBlind + 9 * ante
        let M_5:Double = M * 5
        let M_10:Double = M * 10
        
        // View Model.
        let M_Rounded = String(format: "%.0f", ceil(M * 100) / 100)
        let M_5_Rounded = String(format: "%.0f", ceil(M_5 * 100) / 100)
        let M_10_Rounded = String(format: "%.0f", ceil(M_10 * 100) / 100)
        
        // Format.
        let lightAttribute: [NSAttributedString.Key: Any] = [
            .font : NSFont.systemFont(ofSize: font.pointSize, weight: NSFont.Weight.light),
            .foregroundColor : NSColor.systemGray
        ]
        
        let boldAttribute: [NSAttributedString.Key: Any]  = [
            .font : NSFont.systemFont(ofSize: font.pointSize, weight: NSFont.Weight.bold)
        ]
        
        let redAttribute: [NSAttributedString.Key: Any] = [
            .font : NSFont.systemFont(ofSize: font.pointSize, weight: NSFont.Weight.bold),
            .foregroundColor : NSColor.systemRed
        ]
        
        let orangeAttribute: [NSAttributedString.Key: Any] = [
            .font : NSFont.systemFont(ofSize: font.pointSize, weight: NSFont.Weight.bold),
            .foregroundColor : NSColor.systemOrange
            ]
        
        let yellowAttribute: [NSAttributedString.Key: Any] = [
            .font : NSFont.systemFont(ofSize: font.pointSize, weight: NSFont.Weight.bold),
            .foregroundColor : NSColor.systemYellow
            ]
        
        let levelString = NSMutableAttributedString(string: "")
            levelString.append(NSMutableAttributedString(string: String(format: "%.0f/%.0f", smallBlind, bigBlind), attributes:boldAttribute))
            levelString.append(NSMutableAttributedString(string: String(format: " Ante %.0f (%.0f players)", ante, players), attributes:lightAttribute))
        
        let stackString = NSMutableAttributedString(string: "")
        
            // M.
            stackString.append(NSMutableAttributedString(string: "1M ", attributes:lightAttribute))
            stackString.append(NSMutableAttributedString(string: String(format:"%@ ", M_Rounded), attributes:redAttribute))
            stackString.append(NSMutableAttributedString(string: String(format: "/ %.0f BB (%.0f hands)", M / bigBlind, players), attributes:lightAttribute))
            stackString.append(NSMutableAttributedString(string: "\n", attributes:lightAttribute))
        
            // 5M.
            stackString.append(NSMutableAttributedString(string: "5M ", attributes:lightAttribute))
            stackString.append(NSMutableAttributedString(string: String(format:"%@ ", M_5_Rounded), attributes:orangeAttribute))
            stackString.append(NSMutableAttributedString(string: String(format: "/ %.0f BB (%.0f hands)", M_5 / bigBlind, 5 * players), attributes:lightAttribute))
            stackString.append(NSMutableAttributedString(string: "\n", attributes:lightAttribute))
        
            // 10M.
            stackString.append(NSMutableAttributedString(string: "10M ", attributes:lightAttribute))
            stackString.append(NSMutableAttributedString(string: String(format:"%@ ", M_10_Rounded), attributes:yellowAttribute))
            stackString.append(NSMutableAttributedString(string: String(format: "/ %.0f BB (%.0f hands)", M_10 / bigBlind, 10 * players), attributes:lightAttribute))
        
        // Set.
        return (
            levelString,
            stackString
        )
    }
}


// MARK: - TableView Data

extension TourneyTableViewModel: NSTableViewDataSource
{
    
    
    func numberOfRows(in tableView: NSTableView) -> Int
    { return playerViewModels.count }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?
    {
        // Checks.
        guard let column = tableColumn else { return nil }
        guard playerViewModels.count > row else { return nil }
        
        // Data.
        let playerViewModel = playerViewModels[row]
        let liveTourneyPlayer = playerViewModel.pokerTracker.liveTourneyPlayer
        let player = playerViewModel.pokerTracker.player
        let statistics = playerViewModel.pokerTracker.statistics
        
        // Display data.
        let playerName = player?.player_name ?? ""
        let stack = liveTourneyPlayer.amt_stack
        
        // PokerTracker.
        var VPIP = "-"
        var PFR = "-"
        if let statistics = statistics
        {
            VPIP = String(format: "%.0f", statistics.VPIP * 100)
            PFR = String(format: "%.0f", statistics.PFR * 100)
        }
        
        var tables = "-"
        var count: Float?
        var profit: Float?
        var ROI = "-"
        var early = "-"
        var late = "-"
        var years: Float?
        var freq: Float?
        
        // Table count.
        if let tableCount = playerTableCountsForPlayerNames[playerName]
        { tables = String(tableCount) }
        
        // SharkScope.
        if let statistics = playerStatisticsForPlayerNames[playerName]
        {
            count = statistics.Count
            profit = statistics.isAuthorized(statistic: "Profit") ? statistics.Profit : nil
            ROI = statistics.isAuthorized(statistic: "AvROI") ? String(format: "%.1f%%", statistics.AvROI) : "-"
            early = String(format: "%.1f%%", statistics.FinshesEarly)
            late = String(format: "%.1f%%", statistics.FinshesLate)
            years = statistics.YearsPlayed
            freq = statistics.DaysBetweenPlays
        }
        
        let cellDecoratorsForTitles: [String:((NSTextField?) -> Void)] =
        [
            "Player" : { $0?.stringValue = playerName },
            "Stack" : { $0?.doubleValue = stack },
            "VPIP" : { $0?.stringValue = VPIP },
            "PFR" : { $0?.stringValue = PFR },
            "Tables" : { $0?.stringValue = tables },
            "Count" : { if let count = count { $0?.floatValue = count } },
            "Profit" : { if let profit = profit { $0?.floatValue = profit } },
            "ROI" : { $0?.stringValue = ROI },
            "Early" : { $0?.stringValue = early },
            "Late" : { $0?.stringValue = late },
            "Years" : { if let years = years { $0?.floatValue = years } },
            "Freq." : { if let freq = freq { $0?.floatValue = freq } }
        ]
        
        // Create cell view.
        guard let cellView = tableView.makeView(withIdentifier: (column.identifier), owner: self) as? NSTableCellView else { return nil }
        
        // Apply decorator.
        cellDecoratorsForTitles[column.title]!(cellView.textField)
        
        return cellView
    }
}


// MARK: - ComboBox Data

extension TourneyTableViewModel: NSComboBoxDataSource
{
    
    
    func numberOfItems(in comboBox: NSComboBox) -> Int
    { return liveTourneyTables.count }
    
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any?
    {
        let table = liveTourneyTables[index]
        return String(format: "Table %d - %.0f/%.0f Ante %.0f (%d players)",
                      table.id_live_table,
                      table.amt_sb,
                      table.amt_bb,
                      table.amt_ante,
                      table.cnt_players
        )
    }
}


// MARK: - TableView Events

extension TourneyTableViewModel: NSTableViewDelegate
{
    
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool
    {
        // Checks.
        guard playerViewModels.count > row else { return false }
        
        // Data.
        let playerViewModel = playerViewModels[row]
        let player = playerViewModel.pokerTracker.player
        
        // Only with data.
        guard let playerName = player?.player_name
            else { return true }
        
        // Copy name to clipboard.
        NSPasteboard.general.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
        NSPasteboard.general.setString(playerName, forType: NSPasteboard.PasteboardType.string)
        
        // Fetch summary.
        // let fetchPlayerName = "quAAsar"
        // let fetchPlayerName = "rybluk"
        // let fetchPlayerName = "perst777" // Blocked
        // let fetchPlayerName = "wASH1K"
        // let fetchPlayerName = "Taren Tano" // With space
        // let fetchPlayerName = "Brier Rose" // Full Tilt (Closed)
        // let fetchPlayerName = "NNiubility"
        // let fetchPlayerName = "dontumove" // One table
        let fetchPlayerName = playerName
        sharkScope.fetch(player: fetchPlayerName,
                         completion:
            {
                (result: Result<(playerSummary: PlayerSummary, activeTournaments: ActiveTournaments), RequestError>) in
                
                switch result
                {
                case .success(let responses):
                    
                    // Count only running (or late registration) tables.
                    let tables: Int = responses.activeTournaments.Response.PlayerResponse.PlayerView.Player.ActiveTournaments?.Tournament.reduce(0)
                    {
                        count, eachTournament in
                        count + (eachTournament.state != "Registering" ? 1 : 0)
                        } ?? 0
                    
                    // Logs.
                    print("\(responses.playerSummary.Response.PlayerResponse.PlayerView.Player.name) playing \(tables) tables.")
                    if let activeTournaments = responses.activeTournaments.Response.PlayerResponse.PlayerView.Player.ActiveTournaments
                    { print(activeTournaments) }
                    print(self.sharkScope.status)
                    
                    // Retain data.
                    self.playerStatisticsForPlayerNames[responses.playerSummary.Response.PlayerResponse.PlayerView.Player.name] = responses.playerSummary.Response.PlayerResponse.PlayerView.Player.Statistics
                    self.playerTableCountsForPlayerNames[responses.playerSummary.Response.PlayerResponse.PlayerView.Player.name] = tables
                    
                    // Update UI.
                    self.markAsChanged()
                    
                    break
                    
                case .failure(let error):
                    
                    print(error)
                    
                    // Update UI.
                    print(self.sharkScope.status)
                    
                    break
                }
        })
        
        return true
    }
}