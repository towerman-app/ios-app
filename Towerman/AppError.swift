//
//  AppError.swift
//  Towerman
//
//  Created by Noah Azzaria-Byrne on 2023-02-25.
//

import Foundation

struct AppError {
    let title: String
    let description: String
    let icon: String
    
    static func connection() -> AppError {
        return AppError(
            title: "Connection Error",
            description: "There was a problem with the connection. Please try again.",
            icon: "wifi.exclamationmark"
        )
    }
}
