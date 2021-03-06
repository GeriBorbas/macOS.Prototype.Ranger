//
//  LiveTourneyPlayer.swift
//  Ranger
//
//  Created by Geri Borbás on 2019. 12. 09..
//  Copyright © 2019. Geri Borbás. All rights reserved.
//

import Foundation
import PostgresClientKit

    
public class LiveTourneyPlayer: Entry
{
    
    
    public let id_player: Int
    public let id_player_real: Int
    public let id_live_table: Int
    public let amt_ante: Double
    // amt_before
    public let amt_stack: Double
    // amt_won
    // amt_won_1
    // amt_won_2
    // amt_won_3
    // amt_won_4
    // amt_won_5
    // amt_won_6
    // amt_won_7
    // amt_won_8
    // amt_won_9
    
    
    public required init(row: Row) throws
    {
        id_player = try row.columns[0].int()
        id_player_real = try row.columns[1].int()
        id_live_table = try row.columns[2].int()
        amt_ante = try row.columns[3].double()
        amt_stack = try row.columns[5].double()
    }
}


extension LiveTourneyPlayer: Equatable
{
    
    
    public static func == (lhs: LiveTourneyPlayer, rhs: LiveTourneyPlayer) -> Bool
    {
        return (
            lhs.id_player == rhs.id_player &&
            lhs.id_live_table == rhs.id_live_table &&
            lhs.amt_stack == rhs.amt_stack
        )
    }
}


extension LiveTourneyPlayer: CustomStringConvertible
{
    
    
    public var description: String
    {
        return "id_player: \(id_player), id_player_real: \(id_player_real), id_live_table: \(id_live_table), amt_ante: \(amt_ante), amt_stack: \(amt_stack))"
    }
}
