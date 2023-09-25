//
//  ButtonView.swift
//  MarvToy
//
//  Created by Daniel Platt on 25/09/2023.
//

import SwiftUI
import SDWebImageSwiftUI

struct ButtonView: View {
    @ObservedObject var recorder: Recorder
    @ObservedObject var speechManager: SpeechManager

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    buttons(for: geometry)
                    Spacer()
                }
                Spacer()
            }
        }
    }
    
    func buttons (for geometry: GeometryProxy) -> some View {
        if !speechManager.isSpeaking &&
            !recorder.isRecording {
            return AnyView(
                Button(action: {
                    recorder.startRecording()
                })
                {
                    Text("Ask Question")
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
                .disabled(!recorder.hasMicrophoneAccess ||
                          !recorder.isSpeechRecognizerAvailable
                )
            )
        } else if (recorder.isRecording) {
            if let url = Bundle.main.url(forResource: "load-142", withExtension: "gif"),
               let data = try? Data(contentsOf: url) {
                return AnyView(AnimatedImage(data: data)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
//                        .indicator(Indicator.progress)
                        .frame(width: geometry.size.width * 0.4)
                )
            } else {
                return AnyView(
                    Text("Failed to load image.")
                )
            }
        } else if (speechManager.isSpeaking) {
            return AnyView(
                Button(action: {
                    speechManager.stopSpeaking()
                }) {
                    Text("Stop speaking")
                        .foregroundColor(colorScheme == .light ? Color.white : Color.black)
                        .padding()
                        .background(
                            speechManager.isSpeaking ?
                            Color.secondary :
                                Color.gray.opacity(0.6)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.2), lineWidth: 1)
                        )
                        .cornerRadius(10)
                }
                .contentShape(Rectangle())
                .disabled(!speechManager.isSpeaking)
           )
        } else {
            return AnyView(EmptyView())
        }
    }
}

struct ButtonView_Previews: PreviewProvider {
    static var previews: some View {
        ButtonView(recorder: previewIsRecording, speechManager: previewSpeechNotSpeaking)
            .previewDisplayName("Recording - Not Speaking")
        
        ButtonView(recorder: previewIsNotRecording, speechManager: previewSpeechSpeaking)
            .previewDisplayName("Not Recording - Speaking")
        
        ButtonView(recorder: previewIsNotRecording, speechManager: previewSpeechNotSpeaking)
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
