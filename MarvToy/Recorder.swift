//
//  Recorder.swift
//  MarvToy
//
//  Created by Daniel Platt on 16/09/2023.
//

import SwiftUI
import AVFoundation
import Speech


class Recorder: ObservableObject {
    @Published var isRecording: Bool = false
    @Published var hasMicrophoneAccess: Bool = false
    @Published var alert: Alert?
    
    private var speechRecognizer = SFSpeechRecognizer()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private let audioSession = AVAudioSession.sharedInstance()
    var onRecognisedText: ((String) -> Void)?

    init() {
        // Configure the audio session
        audioSession.requestRecordPermission { (hasPermission) in
            self.hasMicrophoneAccess = hasPermission
     
            if !self.isSpeechRecognizerAvailable {
                  self.alert = Alert(title: Text("Speech Recognition Unavailable"),
                                     message: Text("Please try again later."),
                                     dismissButton: .default(Text("OK")))
              }
        }
    }
    
    var isSpeechRecognizerAvailable: Bool {
        return speechRecognizer?.isAvailable ?? false
    }
    
    func startRecording() {
        // Request microphone access
        if (!self.hasMicrophoneAccess) {
            print("Microphone access denied")
            return
        }

        do {
            try self.audioSession.setCategory(.playAndRecord, mode: .default, options: [
                .duckOthers,
                .allowBluetooth,
                .allowBluetoothA2DP,
            ])
            try self.audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            try self.audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
        } catch {
            print("Failed to set audio session category: \(error)")
        }
        
        // Reset the audio engine and the recognition task
        audioEngine.stop()
        recognitionTask?.cancel()
        self.recognitionTask = nil
        self.recognitionRequest = nil

        // Create and configure the recognition request
        self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = self.recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        recognitionRequest.shouldReportPartialResults = true

        // Install the tap on the audio engine's input node
        let recordingFormat = self.audioEngine.inputNode.outputFormat(forBus: 0)
        self.audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }

        // Start the audio engine
        do {
            try self.audioEngine.start()
        } catch {
            print("There was a problem starting the audio engine.")
        }

        // Start the recognition task
        self.recognitionTask = self.speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            var isFinal = false
            
            if let result = result {
                self.onRecognisedText?(result.bestTranscription.formattedString)
                isFinal = result.isFinal

//                if (self.recognizedText != "" && isFinal) {
//                    self.openAIManager.sendRequest(prompt: self.recognizedText, maxTokens: 50)
//                }
            }
            
            if error != nil || isFinal {
                self.stopRecording()
            }
        })

        // Change the UI state
        self.isRecording = true
    }

    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        do {
            try self.audioSession.setActive(false)
        } catch {
            print("There was a problem stopping the audio engine.")
        }
        self.recognitionRequest = nil
        self.recognitionTask = nil
        self.isRecording = false

//        if (self.recognizedText != "") {
//            self.openAIManager.sendRequest(prompt: self.recognizedText, maxTokens: 50)
//        }
    }
}
