//
//  VisualizerView.swift
//  ChattyMarv
//
//  Created by Daniel Platt on 21/12/2023.
//

import SwiftUI
import SDWebImageSwiftUI

struct VisualizerView: View {
    @Binding public var isUserSpeaking: Bool

    @Environment(\.colorScheme) var colorScheme

    var imageName: String {
        switch (isUserSpeaking, colorScheme) {
            case (true, .dark):
                return "speaking_dark"
            case (true, .light):
                return "speaking_light"
            case (false, .dark):
                return "silence_dark"
            case (false, .light):
                return "silence_light"
            case (_, _):
                return "silence_light"
        }
    }

    var body: some View {
        if let url = Bundle.main.url(forResource: imageName, withExtension: "gif"),
           let data = try? Data(contentsOf: url) {
            return AnyView(
                AnimatedImage(data: data)
                    .frame(width: Constants.desiredWidth, height: Constants.desiredHeight)
                    .clipped()
            )
        } else {
            return AnyView(
                Text("Failed to load image.")
            )
        }
    }
}

#Preview {
    Group {
        // Speaking
        VisualizerView(isUserSpeaking: .constant(true))
            .previewDisplayName("Speaking")
        
        // Not Speaking
        VisualizerView(isUserSpeaking: .constant(false))
            .previewDisplayName("Silence")
    }
}
