//
//  RedirectToSettingsView.swift
//  MarvToy
//
//  Created by Daniel Platt on 17/09/2023.
//

import SwiftUI

struct RedirectToSettingsView: View {
    
    var body: some View {
        VStack(spacing: 20) {
            Text("API Key Missing!")
                .font(.headline)
            
            Text("Please go to the Settings app and enter the API Key.")
                .multilineTextAlignment(.center)
                .padding()
            
            Button(action: {
                // Direct the user to the settings app
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }) {
                Text("Open Settings")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}
