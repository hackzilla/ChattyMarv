//
//  ButtonView.swift
//  ChattyMarv
//
//  Created by Daniel Platt on 25/09/2023.
//

import SwiftUI
import SDWebImageSwiftUI

struct ButtonView: View {
    @ObservedObject var recorder: Recorder
    @ObservedObject var speechManager: SpeechManager
    @Binding var isUserSpeaking: Bool

    @Environment(\.colorScheme) var colorScheme


    var body: some View {
        VStack {
            Spacer()
            if (recorder.isRecording) {
                // potentially pass false, when paused
                VisualizerView(isUserSpeaking: self.$isUserSpeaking)
                    .frame(maxWidth: .infinity)
            }
            buttons()
            Spacer()
        }
    }

    func buttons () -> some View {
        if !recorder.isRecording {
            return AnyView(
                Button(action: {
                    recorder.startRecording()
                })
                {
                    Text("Start Listening")
                        .foregroundColor(colorScheme == .light ? Color.white : Color.black)
                        .padding()
                        .background(
                            (recorder.hasMicrophoneAccess && recorder.isSpeechRecognizerAvailable) ?
                            Color.primary :
                                Color.gray.opacity(0.6)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.2), lineWidth: 1)
                        )
                        .cornerRadius(10)
                }
                .contentShape(Rectangle())
                .disabled(!recorder.hasMicrophoneAccess || !recorder.isSpeechRecognizerAvailable
                )
            )
        } else {
            return AnyView(
                Button(action: {
                    recorder.stopRecording()
                }) {
                    Text("Stop Listening")
                        .foregroundColor(colorScheme == .light ? Color.white : Color.black)
                        .padding()
                        .background(Color.primary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.2), lineWidth: 1)
                        )
                        .cornerRadius(10)
                }
                .contentShape(Rectangle())
           )
        }
    }
}

struct ButtonView_Previews: PreviewProvider {
    static var previews: some View {
        ButtonView(recorder: previewIsRecording, speechManager: previewSpeechSpeaking, isUserSpeaking: .constant(true))
            .previewDisplayName("Recording - User Speaking")
        
        ButtonView(recorder: previewIsRecording, speechManager: previewSpeechNotSpeaking, isUserSpeaking: .constant(false))
            .previewDisplayName("Recording - User Not Speaking")
        
        ButtonView(recorder: previewIsNotRecording, speechManager: previewSpeechSpeaking, isUserSpeaking: .constant(false))
            .previewDisplayName("Not Recording - Speaking")
        
        ButtonView(recorder: previewIsNotRecording, speechManager: previewSpeechNotSpeaking, isUserSpeaking: .constant(false))
            .previewDisplayName("Not Recording - Not Speaking")
    }
    
    static var previewSpeechSpeaking: SpeechManager = {
        let manager = SpeechManager()
        manager.isSpeaking = true
        return manager
    }()
    
    static var previewSpeechNotSpeaking: SpeechManager = {
        let manager = SpeechManager()
        manager.isSpeaking = false
        return manager
    }()
    
    static var previewIsRecording: Recorder = {
        let manager = Recorder()
        manager.isRecording = true
        return manager
    }()
    
    static var previewIsNotRecording: Recorder = {
        let manager = Recorder()
        manager.isRecording = false
        return manager
    }()
}
