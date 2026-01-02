//
//  Item.swift
//  MoneyFlow
//
//  Created by Wing - on 2026/1/2.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
