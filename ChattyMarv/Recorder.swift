//
//  Recorder.swift
//  ChattyMarv
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
    
    private var silenceTimer: Timer?
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

        print("Start recording")
        do {
            try self.audioSession.setCategory(.playAndRecord, mode: .default, options: [
                .duckOthers,
                .allowBluetooth,
                .allowBluetoothA2DP,
            ])
            try self.audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            if (UserDefaults.standard.bool(forKey: "USE_SPEAKER")) {
                try self.audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
            } else {
                try self.audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.none)
            }
        } catch {
            print("Failed to set audio session category: \(error)")
        }
        
        print("Start recording - reset")
        
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
        recognitionRequest.shouldReportPartialResults = false

        if speechRecognizer?.supportsOnDeviceRecognition == true {
            // Set requiresOnDeviceRecognition to true to enforce on-device recognition
            recognitionRequest.requiresOnDeviceRecognition = true
        } else {
            // Handle the case where on-device recognition is not supported
            print("On-device recognition not supported for the current language or device configuration.")
        }
        
        // Install the tap on the audio engine's input node
        print(" Install the tap on the audio engine's input node")

        let recordingFormat = self.audioEngine.inputNode.outputFormat(forBus: 0)
        self.audioEngine.inputNode.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
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
            if let result = result {
                self.silenceTimer?.invalidate()
                self.silenceTimer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(self.handleSilence), userInfo: nil, repeats: false)

                if result.isFinal {
                    self.onRecognisedText?(result.bestTranscription.formattedString)
                    print("Final recognition: \(result.bestTranscription.formattedString)")
                    self.stopRecording()
                }
            } else if let error = error {
                // Handle any errors here
                print("Error during recognition: \(error.localizedDescription)")
                self.stopRecording()
            }
        })

        // Change the UI state
        self.isRecording = true
        self.silenceTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(self.handleSilence), userInfo: nil, repeats: false)
    }

    @objc func handleSilence() {
        print("Silence detected. Stopping recording.")
        self.stopRecording()
    }
    
    func stopRecording() {
        print("Stop recording")
        self.silenceTimer?.invalidate()
        self.silenceTimer = nil

        if !self.isRecording {
            return
        }
        
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
    }
}