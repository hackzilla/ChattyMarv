//
//  Constants.swift
//  ChattyMarv
//
//  Created by Daniel Platt on 22/12/2023.
//

import SwiftUI

struct Constants {
    // Speech
    static let speechVoice =  "en-GB"
    static let speechRate: Float = 0.52
    static let speechVolume: Float = 1.0
    
    // OpenAI
    static let maxTokens = 50
    
    // Visualiser
    static let desiredWidth: CGFloat = 300
    static let desiredHeight: CGFloat = 150
    
    // Voice
    static let silenceThreshold: Double = 0.01
    static let requestAfterSeconds = 2
}
