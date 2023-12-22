//
//  File.swift
//  ChattyMarv
//
//  Created by Daniel Platt on 03/09/2023.
//

import Foundation
import SwiftUI

struct RecordButton: View {
    @State private var isPressed: Bool = false

    var onChanged: () -> Void
    var onEnded: () -> Void
    var isDisabled: Bool
    
    var body: some View {
        let drag = DragGesture(minimumDistance: 0)
            .onChanged { _ in
                if !self.isPressed {
                    self.isPressed = true
                    self.onChanged()
                }
            }
            .onEnded { _ in
                self.isPressed = false
                self.onEnded()
            }

        return Text(isPressed ? "Release to Stop" : "Press and Hold to Talk")
            .padding()
            .background(isPressed ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .gesture(drag)
            .disabled(false)
    }
}
