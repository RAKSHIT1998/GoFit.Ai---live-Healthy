//
//  Item.swift
//  GoFit.Ai - live Healthy
//
//  Created by Rakshit Bargotra on 12/12/25.
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
