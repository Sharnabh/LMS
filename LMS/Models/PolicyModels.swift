//
//  PolicyModels.swift
//  LMS
//
//  Created by Sharnabh on 31/03/25.
//

import Foundation

struct PolicyResponse: Decodable {
    let borrowing_limit: Int
    let return_period: Int
    let fine_amount: Int
    let lost_book_fine: Int
}
