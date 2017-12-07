//
//  Expense.swift
//  AwesomeAPI
//
//  Created by Nikolay Derkach on 12/7/17.
//  Copyright © 2017 Nikolay Derkach. All rights reserved.
//

import Foundation

struct Expense: Codable {
    let amount: Float
    let createdAt: Date
    let description: String
    let type: String

    enum CodingKeys: String, CodingKey {
        case amount
        case createdAt = "created_at"
        case description
        case type
    }
}
