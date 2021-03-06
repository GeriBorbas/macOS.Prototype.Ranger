//
//  Player.swift
//  Ranger
//
//  Created by Geri Borbás on 2019. 12. 23..
//  Copyright © 2019. Geri Borbás. All rights reserved.
//

import Foundation
import PokerTracker
import SharkScope


enum Model
{


    public struct Player
    {
        
        
        let name: String
        
        var pokerTracker: PokerTrackerData?
        var sharkScope: SharkScopeData
        
           
        struct PokerTrackerData: Equatable
        {
            
            
            let playerName: String
            
            var handPlayer: HandPlayer?
            var statistics: PokerTracker.DetailedStatistics?
            
            
            init(with playerName: String, handPlayer: HandPlayer? = nil)
            {
                self.playerName = playerName
                
                if let handPlayer = handPlayer
                { self.handPlayer = handPlayer }
            }
            
            public mutating func updateStatistics(for tourneyNumber: String? = nil)
            {
                self.statistics = try? PokerTracker.Service.fetch(
                    PokerTracker.DetailedStatisticsQuery(
                        playerNames: [playerName],
                        tourneyNumber: tourneyNumber
                )).first
            }
        }
        
        
        struct SharkScopeData: Equatable
        {
            
            
            let playerName: String
            
            var summary: PlayerSummary?
            var activeTournaments: ActiveTournaments?
            var tables: Int?
            var statistics: SharkScope.Statistics? { summary?.Response.PlayerResponse.PlayerView.Player.Statistics }
            
            
            init(with playerName: String)
            {
                self.playerName = playerName
            }
            
            public mutating func update(withSummary summary: PlayerSummary, activeTournaments: ActiveTournaments)
            {
                self.summary = summary
                self.activeTournaments = activeTournaments
                
                // Count only running (or late registration) tables.
                self.tables = activeTournaments.Response.PlayerResponse.PlayerView.Player.ActiveTournaments?.Tournament.reduce(0)
                {
                    count, eachTournament in
                    count + (eachTournament.state != "Registering" ? 1 : 0)
                } ?? 0

                // Logs.
                // if let activeTournaments = activeTournaments.Response.PlayerResponse.PlayerView.Player.ActiveTournaments
                // { print(activeTournaments) }
            }
        }
        
        
        init(name: String, handPlayer: HandPlayer? = nil)
        {
            self.name = name
            
            self.pokerTracker = PokerTrackerData(with: name, handPlayer: handPlayer)
            self.sharkScope = SharkScopeData(with: name)
        }
    }

    
}
    

extension Model.Player: Equatable
{
    
    
    /// PokerTracker `id_player` makes unique view models (used for manage collections).
    static func == (lhs: Model.Player, rhs: Model.Player) -> Bool
    { lhs.name == rhs.name }
}
    

extension Model.Player: Comparable
{
    
    
    static func < (lhs: Model.Player, rhs: Model.Player) -> Bool
    { lhs.name.lowercased() < rhs.name.lowercased() }
}


// MARK: - Description

extension Model.Player: CustomStringConvertible
{
    
    
    public var description: String
    {
        String(format:
            "\n%.0f\t%.0f\t%.0f\t%@",
            stack,
            (pokerTracker?.statistics?.VPIP.value ?? 0) * 100,
            (pokerTracker?.statistics?.aligned.PFR.value ?? 0) * 100,
            name
        )
    }
}


// MARK: - Column Data

extension Model.Player
{
    
    
    var textFieldDataForColumnIdentifiers: [String:TextFieldData]
    {
        let dictionary: [String:TextFieldData] =
        [
            "Seat" : TextFieldIntData(value: pokerTracker?.handPlayer?.seat),
            "Player" : TextFieldStringData(value: name),
            "Stack" : TextFieldDoubleData(value: pokerTracker?.handPlayer?.stack),
            "VPIP" : TextFieldDoubleData(value: pokerTracker?.statistics?.VPIP.value),
            "PFR" : TextFieldDoubleData(value: pokerTracker?.statistics?.aligned.PFR.value),
            "Hands" : TextFieldIntData(value: pokerTracker?.statistics?.cnt_hands),
            "Tables" : TextFieldIntData(value: sharkScope.tables),
            "ITM" : TextFieldFloatData(value: sharkScope.statistics?.ITM),
            "Early" : TextFieldFloatData(value: sharkScope.statistics?.FinshesEarly),
            "Late" : TextFieldFloatData(value: sharkScope.statistics?.FinshesLate),
            "Field Beaten" : TextFieldFloatData(value: sharkScope.statistics?.PercentFieldBeaten),
            "Finishes" : TextFieldDoubleData(value: sharkScope.statistics?.byPositionPercentage.trendLine.slope),
            "Count" : TextFieldFloatData(value: sharkScope.statistics?.Count),
            "Entrants" : TextFieldFloatData(value: sharkScope.statistics?.AvEntrants),
            "Stake" : TextFieldFloatData(value: sharkScope.statistics?.AvStake),
            "Years" : TextFieldFloatData(value: sharkScope.statistics?.YearsPlayed),
            "Losing" : TextFieldFloatData(value: sharkScope.statistics?.LosingDaysWithBreakEvenPercentage),
            "Winning" : TextFieldFloatData(value: sharkScope.statistics?.WinningDaysWithBreakEvenPercentage),
            "Profit" : TextFieldFloatData(value: sharkScope.statistics?.Profit),
            "ROI" : TextFieldFloatData(value: sharkScope.statistics?.AvROI),
            "Frequency" : TextFieldFloatData(value: sharkScope.statistics?.DaysBetweenPlays),
            "Games/Day" : TextFieldFloatData(value: sharkScope.statistics?.AvGamesPerDay),
            "Ability" : TextFieldFloatData(value: sharkScope.statistics?.Ability),
        ]
        return dictionary
    }
    
}


// MARK: - Sorting

extension Model.Player
{
    
    
    func isInIncreasingOrder(to rhs: Model.Player, using sortDescriptors: [NSSortDescriptor]) -> Bool
    {
        // Shortcut.
        let lhs = self
        
        // Convert for (hardcoded but) swifty sort descriptors (named order descriptors).
        let orderDescriptorsForSortDescriptorKeys: [String:(ascending: (Model.Player, Model.Player) -> Bool, descending: (Model.Player, Model.Player) -> Bool)] =
        [
            "Seat" :
            (
                ascending: { lhs, rhs in lhs.pokerTracker?.handPlayer?.seat ?? 0 < rhs.pokerTracker?.handPlayer?.seat ?? 0 },
                descending: { lhs, rhs in lhs.pokerTracker?.handPlayer?.seat ?? 0 >= rhs.pokerTracker?.handPlayer?.seat ?? 0 }
            ),
            "Stack" :
            (
                ascending: { lhs, rhs in lhs.pokerTracker?.handPlayer?.stack ?? 0 < rhs.pokerTracker?.handPlayer?.stack ?? 0 },
                descending: { lhs, rhs in lhs.pokerTracker?.handPlayer?.stack ?? 0 >= rhs.pokerTracker?.handPlayer?.stack ?? 0 }
            ),
            "VPIP" :
            (
                ascending: { lhs, rhs in lhs.pokerTracker?.statistics?.VPIP.value ?? 0 < rhs.pokerTracker?.statistics?.VPIP.value ?? 0 },
                descending: { lhs, rhs in lhs.pokerTracker?.statistics?.VPIP.value ?? 0 >= rhs.pokerTracker?.statistics?.VPIP.value ?? 0 }
            ),
            "PFR" :
            (
                ascending: { lhs, rhs in lhs.pokerTracker?.statistics?.aligned.PFR.value ?? 0 < rhs.pokerTracker?.statistics?.aligned.PFR.value ?? 0 },
                descending: { lhs, rhs in lhs.pokerTracker?.statistics?.aligned.PFR.value ?? 0 >= rhs.pokerTracker?.statistics?.aligned.PFR.value ?? 0 }
            ),
            "Hands" :
            (
                ascending: { lhs, rhs in lhs.pokerTracker?.statistics?.cnt_hands ?? 0 < rhs.pokerTracker?.statistics?.cnt_hands ?? 0 },
                descending: { lhs, rhs in lhs.pokerTracker?.statistics?.cnt_hands ?? 0 >= rhs.pokerTracker?.statistics?.cnt_hands ?? 0 }
            ),
            "Tables" :
            (
                ascending: { lhs, rhs in lhs.sharkScope.tables ?? 0 < rhs.sharkScope.tables ?? 0 },
                descending: { lhs, rhs in lhs.sharkScope.tables ?? 0 >= rhs.sharkScope.tables ?? 0 }
            ),
            "ITM" :
            (
                ascending: { lhs, rhs in lhs.sharkScope.statistics?.ITM ?? 0 < rhs.sharkScope.statistics?.ITM ?? 0 },
                descending: { lhs, rhs in lhs.sharkScope.statistics?.ITM ?? 0 >= rhs.sharkScope.statistics?.ITM ?? 0 }
            ),
            "Early" :
            (
                ascending: { lhs, rhs in lhs.sharkScope.statistics?.FinshesEarly ?? 0 < rhs.sharkScope.statistics?.FinshesEarly ?? 0 },
                descending: { lhs, rhs in lhs.sharkScope.statistics?.FinshesEarly ?? 0 >= rhs.sharkScope.statistics?.FinshesEarly ?? 0 }
            ),
            "Late" :
            (
                ascending: { lhs, rhs in lhs.sharkScope.statistics?.FinshesLate ?? 0 < rhs.sharkScope.statistics?.FinshesLate ?? 0 },
                descending: { lhs, rhs in lhs.sharkScope.statistics?.FinshesLate ?? 0 >= rhs.sharkScope.statistics?.FinshesLate ?? 0 }
            ),
            "Field Beaten" :
            (
                ascending: { lhs, rhs in lhs.sharkScope.statistics?.PercentFieldBeaten ?? 0 < rhs.sharkScope.statistics?.PercentFieldBeaten ?? 0 },
                descending: { lhs, rhs in lhs.sharkScope.statistics?.PercentFieldBeaten ?? 0 >= rhs.sharkScope.statistics?.PercentFieldBeaten ?? 0 }
            ),
            "Finishes" :
            (
                ascending: { lhs, rhs in lhs.sharkScope.statistics?.byPositionPercentage.trendLine.slope ?? 0 < rhs.sharkScope.statistics?.byPositionPercentage.trendLine.slope ?? 0 },
                descending: { lhs, rhs in lhs.sharkScope.statistics?.byPositionPercentage.trendLine.slope ?? 0 >= rhs.sharkScope.statistics?.byPositionPercentage.trendLine.slope ?? 0 }
            ),
            "Count" :
            (
                ascending: { lhs, rhs in lhs.sharkScope.statistics?.Count ?? 0 < rhs.sharkScope.statistics?.Count ?? 0 },
                descending: { lhs, rhs in lhs.sharkScope.statistics?.Count ?? 0 >= rhs.sharkScope.statistics?.Count ?? 0 }
            ),
            "Entrants" :
            (
                ascending: { lhs, rhs in lhs.sharkScope.statistics?.AvEntrants ?? 0 < rhs.sharkScope.statistics?.AvEntrants ?? 0 },
                descending: { lhs, rhs in lhs.sharkScope.statistics?.AvEntrants ?? 0 >= rhs.sharkScope.statistics?.AvEntrants ?? 0 }
            ),
            "Stake" :
            (
                ascending: { lhs, rhs in lhs.sharkScope.statistics?.Stake ?? 0 < rhs.sharkScope.statistics?.Stake ?? 0 },
                descending: { lhs, rhs in lhs.sharkScope.statistics?.Stake ?? 0 >= rhs.sharkScope.statistics?.Stake ?? 0 }
            ),
            "Years" :
            (
                ascending: { lhs, rhs in lhs.sharkScope.statistics?.YearsPlayed ?? 0 < rhs.sharkScope.statistics?.YearsPlayed ?? 0 },
                descending: { lhs, rhs in lhs.sharkScope.statistics?.YearsPlayed ?? 0 >= rhs.sharkScope.statistics?.YearsPlayed ?? 0 }
            ),
            "Losing" :
            (
                ascending: { lhs, rhs in lhs.sharkScope.statistics?.LosingDaysWithBreakEvenPercentage ?? 0 < rhs.sharkScope.statistics?.LosingDaysWithBreakEvenPercentage ?? 0 },
                descending: { lhs, rhs in lhs.sharkScope.statistics?.LosingDaysWithBreakEvenPercentage ?? 0 >= rhs.sharkScope.statistics?.LosingDaysWithBreakEvenPercentage ?? 0 }
            ),
            "Winning" :
            (
                ascending: { lhs, rhs in lhs.sharkScope.statistics?.WinningDaysWithBreakEvenPercentage ?? 0 < rhs.sharkScope.statistics?.WinningDaysWithBreakEvenPercentage ?? 0 },
                descending: { lhs, rhs in lhs.sharkScope.statistics?.WinningDaysWithBreakEvenPercentage ?? 0 >= rhs.sharkScope.statistics?.WinningDaysWithBreakEvenPercentage ?? 0 }
            ),
            "Profit" :
            (
                ascending: { lhs, rhs in lhs.sharkScope.statistics?.Profit ?? 0 < rhs.sharkScope.statistics?.Profit ?? 0 },
                descending: { lhs, rhs in lhs.sharkScope.statistics?.Profit ?? 0 >= rhs.sharkScope.statistics?.Profit ?? 0 }
            ),
            "ROI" :
            (
                ascending: { lhs, rhs in lhs.sharkScope.statistics?.AvROI ?? 0 < rhs.sharkScope.statistics?.AvROI ?? 0 },
                descending: { lhs, rhs in lhs.sharkScope.statistics?.AvROI ?? 0 >= rhs.sharkScope.statistics?.AvROI ?? 0 }
            ),
            "Frequency" :
            (
                ascending: { lhs, rhs in lhs.sharkScope.statistics?.DaysBetweenPlays ?? 0 < rhs.sharkScope.statistics?.DaysBetweenPlays ?? 0 },
                descending: { lhs, rhs in lhs.sharkScope.statistics?.DaysBetweenPlays ?? 0 >= rhs.sharkScope.statistics?.DaysBetweenPlays ?? 0 }
            ),
            "Games/Day" :
            (
                ascending: { lhs, rhs in lhs.sharkScope.statistics?.AvGamesPerDay ?? 0 < rhs.sharkScope.statistics?.AvGamesPerDay ?? 0 },
                descending: { lhs, rhs in lhs.sharkScope.statistics?.AvGamesPerDay ?? 0 >= rhs.sharkScope.statistics?.AvGamesPerDay ?? 0 }
            ),
            "Ability" :
            (
                ascending: { lhs, rhs in lhs.sharkScope.statistics?.Ability ?? 0 < rhs.sharkScope.statistics?.Ability ?? 0 },
                descending: { lhs, rhs in lhs.sharkScope.statistics?.Ability ?? 0 >= rhs.sharkScope.statistics?.Ability ?? 0 }
            )
        ]
        
        // Use only the first sort descriptor (for now).
        guard let firstSortDescriptor = sortDescriptors.first
        else { return false }
        
        // Lookup corresponding order descriptor.
        guard let eachOrderDescriptor = orderDescriptorsForSortDescriptorKeys[firstSortDescriptor.key ?? ""]
        else { return false }
        
        // Select direction.
        let selectedOrderDescriptor = firstSortDescriptor.ascending ? eachOrderDescriptor.ascending : eachOrderDescriptor.descending
        
        // Determine order.
        return selectedOrderDescriptor(lhs, rhs)
    }
}


// MARK: - Shortcuts

extension Model.Player
{
    
    
    var isHero: Bool
    { pokerTracker?.handPlayer?.flg_hero ?? false }
    
    /// True if player has `pokerTracker.handPlayer` populated.
    var isPlaying: Bool
    { pokerTracker?.handPlayer != nil }
    
    var stack: Double
    { pokerTracker?.handPlayer?.stack ?? 0 }
    
    var statisticsSummary: String
    {
        String(format:
            """
            Early Finish: %.0f
            Late Finish: %.0f
            Field Beaten: %.0f
            Finishes: %.f
            Losing/Winning: %.f/%.f

            ITM: %.0f%%
            Count: %@

            ROI: %.f%%
            Profit: $%@
            """,
               sharkScope.statistics?.FinshesEarly ?? 0,
               sharkScope.statistics?.FinshesLate ?? 0,
               sharkScope.statistics?.PercentFieldBeaten ?? 0,
               ((sharkScope.statistics?.byPositionPercentage.trendLine.slope ?? 0) * -10000.0),
               (sharkScope.statistics?.LosingDaysWithBreakEvenPercentage ?? 0) * 100.0,
               (sharkScope.statistics?.WinningDaysWithBreakEvenPercentage ?? 0) * 100.0,
               
               sharkScope.statistics?.ITM ?? 0,
               (sharkScope.statistics?.Count ?? 0).formattedWithSeparator,
               
               sharkScope.statistics?.AvROI ?? 0,
               (sharkScope.statistics?.Profit ?? 0).formattedWithSeparator
        )
    }
    
    func screenSeat(heroSittingAt heroSeat: Int) -> Int?
    {
        // Get seat from PokerTracker hand history.
        guard var tableSeat = pokerTracker?.handPlayer?.seat
        else { return nil }
        
        // Yet 9-MAX only.
        guard 1...9 ~= heroSeat else { return nil }
        guard 1...9 ~= tableSeat else { return nil }
        let preferredSeat = 5
        
        // Offset.
        let offset = preferredSeat - heroSeat // 5 - 4 = 1
        tableSeat += offset // 4 + 1 = 5
        
        // Clamp.
        tableSeat += 9 // put above zero
        tableSeat %= 9 // put below 9
        if tableSeat == 0 { tableSeat = 9 } // top up
        
        return tableSeat
    }
}


// MARK: - Cache

extension Model.Player.SharkScopeData
{
    
    
    var hasStatisticsCache: Bool
    { ApiRequestCache().hasCache(for: PlayerSummaryRequest(network: "PokerStars", player: playerName)) }
    
    var hasActiveTournamentsCache: Bool
    { ApiRequestCache().hasCache(for: ActiveTournamentsRequest(network: "PokerStars", player: playerName)) }
    
    var hasTournamentsCache: Bool
    { ApiRequestCache().hasCache(for: TournamentsRequest(network: "PokerStars", player: playerName)) }
}
