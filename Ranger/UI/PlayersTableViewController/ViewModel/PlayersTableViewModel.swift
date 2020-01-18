//
//  PlayersTableViewModel.swift
//  Ranger
//
//  Created by Geri Borbás on 2019. 12. 14..
//  Copyright © 2019. Geri Borbás. All rights reserved.
//

import Foundation
import SwiftUI
import PokerTracker
import SharkScope


class PlayersTableViewModel: NSObject
{
 
    
    // MARK: - Services
    
    private var pokerTracker: PokerTracker.Service = PokerTracker.Service()
    private var sharkScope: SharkScope.Service = SharkScope.Service()
    
    
    // MARK: - Data
        
    public var players: [Model.Player] = []
    
    
    // MARK: - UI Data
    
    private var sortDescriptors: [NSSortDescriptor]?
    public var selectedPlayer: Model.Player?
    
    
    // MARK: - Binds
    
    /// By setting `stackPercentProvider.maximum`, stack bar sizes can be normalized.
    @IBOutlet weak var stackPercentProvider: PercentProvider!
    
    /// If `tournamenNumber` is set, only session statistics will be fetches for hero.
    var tournamentNumber: String?
    
    /// If `orbitCost` is set, M-ratio can be calculated for stacks.
    public var orbitCost: Float?
    
    public var sharkScopeStatus: String
    { sharkScope.status }
        
    private var onChange: (() -> Void)?
    
    
    // MARK: - Lifecycle
    
    public func update(with players: [Model.Player], onChange: (() -> Void)?)
    {
        // Retain callback.
        self.onChange = onChange
        
        try? update(with: players)
    }
    
    private func update(with players: [Model.Player]) throws
    {
        // Only if players any.
        guard players.first != nil
        else { return }
                
        // Mutable copy.
        var currentPlayers = players
        
        // Save SharkScope statistics if any.
        self.players.forEach
        {
            eachPlayer in
            if (currentPlayers.contains(eachPlayer))
            {
                let index = currentPlayers.firstIndex(of: eachPlayer)!
                currentPlayers[index].sharkScope = eachPlayer.sharkScope
            }
        }
        
        // Set new data.
        self.players = currentPlayers
        
        // Get latest PokerTracker statistics (get session stats for hero).
        for (eachIndex, eachPlayer) in self.players.enumerated()
        { self.players[eachIndex].pokerTracker?.updateStatistics(for: eachPlayer.isHero ? tournamentNumber : nil) }
        
        // Track stack extremes.
        stackPercentProvider.maximum = NSNumber(value: self.players.reduce(
            0.0,
            { max($0, $1.stack) })
        )
        
        // Sort view model using retained sort descriptors (if any).
        sort(using: self.sortDescriptors)
        
        // Invoke callback.
        onChange?()
    }
    
    func sort(using sortDescriptors: [NSSortDescriptor]?)
    {
        // Only if any (from table descriptors or from previously retained descriptors).
        guard let sortDescriptors = sortDescriptors
        else { return }
        
        // Retain.
        self.sortDescriptors = sortDescriptors
        
        // Sort in place.
        players = players.sorted
        {
            lhs, rhs -> Bool in
            lhs.isInIncreasingOrder(to: rhs, using: sortDescriptors)
        }
    }
}


// MARK: - Context Menu Events

extension PlayersTableViewModel
{
    
    
    func tableHeaderContextMenu(for column: NSTableColumn) -> NSMenu?
    {
        if (column.identifier.rawValue == "Stack")
        {
            return NSMenu(title: "Stack").with(items:
            [
                NSMenuItem(title: "linear", action: #selector(menuItemDidClick), keyEquivalent: "").with(target: self),
                NSMenuItem(title: "easeOut", action: #selector(menuItemDidClick), keyEquivalent: "").with( target: self)
            ])
        }
        
        return nil
    }
    
    @objc func menuItemDidClick(menuItem: NSMenuItem)
    {
        print("menuItemDidClick(\(menuItem.title))")
    }
}


// MARK: - SharkScope Events

extension PlayersTableViewModel
{
    
    public func fetchSharkScopeStatisticsForPlayer(inRow row: Int)
    {
        // Checks.
        guard players.count > row else { return }
        
        // Data.
        var player = players[row]

        // Fetch summary.
        sharkScope.fetch(player: player.name,
                         completion:
            {
                (result: Result<(playerSummary: PlayerSummary, activeTournaments: ActiveTournaments), SharkScope.Error>) in
                       
                switch result
                {
                    case .success(let responses):

                        // Retain.
                        player.sharkScope.update(withSummary: responses.playerSummary, activeTournaments: responses.activeTournaments)
                        
                        // Write.
                        self.players[row] = player
                        
                        // Invoke callback.
                        self.onChange?()

                        break

                    case .failure(let error):

                        // Fail silently for now.
                        print(error)

                    break
                }
           })
    }
    
    public func fetchCompletedTournamentsForPlayer(withName playerName: String)
    {
        // Lookup player.
        let firstPlayer = players.filter{ eachPlayer in eachPlayer.name == playerName }.first
        
        // Checks.
        guard let player = firstPlayer else { return }
        
        /// Data.
        sharkScope.fetch(CompletedTournamentsRequest(network: "PokerStars", player:player.name, amount: 80),
                         completion:
            {
                 (result: Result<CompletedTournaments, SharkScope.Error>)in
                       
                switch result
                {
                    case .success(let response):

                        print(response)
                        
                        // Retain.
                        // player.sharkScope.update(withSummary: responses.playerSummary, activeTournaments: responses.activeTournaments)
                        
                        // Invoke callback.
                        // self.onChange?()

                        break

                    case .failure(let error):

                        // Fail silently for now.
                        print(error)

                    break
                }
           })
    }
}