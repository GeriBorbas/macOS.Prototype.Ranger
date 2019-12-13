//
//  BasicPlayerStatistics.swift
//  Ranger
//
//  Created by Geri Borbás on 2019. 12. 09..
//  Copyright © 2019. Geri Borbás. All rights reserved.
//

import Foundation
import PostgresClientKit


class BasicPlayerStatistics: RowInitable
{
    
    
    let id_player: Int
    let id_site: Int
    let str_player_name: String
    let cnt_vpip: Int
    let cnt_hands: Int
    let cnt_walks: Int
    let cnt_pfr: Int
    let cnt_pfr_opp: Int
    
    let VPIP: Double
    let PFR: Double
    
    
    required init(row: Row) throws
    {
        id_player = try row.columns[0].int()
        id_site = try row.columns[1].int()
        str_player_name = try row.columns[2].string()
        cnt_vpip = try row.columns[3].int()
        cnt_hands = try row.columns[4].int()
        cnt_walks = try row.columns[5].int()
        cnt_pfr = try row.columns[6].int()
        cnt_pfr_opp = try row.columns[7].int()
        
        // Calculations.
        VPIP = Double(cnt_vpip) / Double(cnt_hands - cnt_walks)
        PFR = Double(cnt_pfr) / Double(cnt_pfr_opp)
    }
}


extension BasicPlayerStatistics: CustomStringConvertible
{
    var description: String
    {
        return "id_player: \(id_player), id_site: \(id_site), str_player_name: \(str_player_name), cnt_vpip: \(cnt_vpip), cnt_hands: \(cnt_hands), cnt_walks: \(cnt_walks), cnt_pfr: \(cnt_pfr), cnt_pfr_opp: \(cnt_pfr_opp) \n VPIP:\(String(format: "%.2f%%", VPIP * 100)), PFR:\(String(format: "%.2f%%", PFR * 100))"
    }
}
