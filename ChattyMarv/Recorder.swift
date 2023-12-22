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
    @Published var isPaused: Bool = false
    @Published var hasMicrophoneAccess: Bool = false
    @Published var alert: Alert?
        
    private var speechRecognizer = SFSpeechRecognizer()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private let audioSession = AVAudioSession.sharedInstance()

    private var silenceTimer: Timer?
    private var isSilenceTimerActive: Bool = false
    private var silenceDuration: TimeInterval = 0.0

    var onRecognisedText: ((String) -> Void)?
    var onRecognisedSilence: ((Int) -> Void)?
    var onRecognisedSound: (() -> Void)?

    init() {
        // Configure the audio session
        audioSession.requestRecordPermission { (hasPermission) in
            DispatchQueue.main.async {
                self.hasMicrophoneAccess = hasPermission
                
                if !self.isSpeechRecognizerAvailable {
                    self.alert = Alert(title: Text("Speech Recognition Unavailable"),
                                       message: Text("Please try again later."),
                                       dismissButton: .default(Text("OK")))
                }
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
        DispatchQueue.main.async {
            self.audioEngine.stop()
            self.recognitionTask?.cancel()
        
        // Change the UI state
        self.isRecording = true
        self.isPaused = false
        self.recognitionTask = nil
        self.recognitionRequest = nil
        
        // Create and configure the recognition request
        self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = self.recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = false
        
            if self.speechRecognizer?.supportsOnDeviceRecognition == true {
            // Set requiresOnDeviceRecognition to true to enforce on-device recognition
            recognitionRequest.requiresOnDeviceRecognition = true
        } else {
            // Handle the case where on-device recognition is not supported
            print("On-device recognition not supported for the current language or device configuration.")
        }
        
        // Install the tap on the audio engine's input node
        print("Install the tap on the audio engine's input node")
        
        let recordingFormat = self.audioEngine.inputNode.outputFormat(forBus: 0)
        self.audioEngine.inputNode.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            DispatchQueue.main.async {
                if (!self.isRecording || self.isPaused) {
                    return
                }

                self.recognitionRequest?.append(buffer)
                self.checkForSilence(buffer)
            }
        }
        
        // Start the audio engine
        do {
            try self.audioEngine.start()
        } catch {
            print("There was a problem starting the audio engine.")
        }
        
        self.resumeRecording()
        
        // Start the recognition task
        self.recognitionTask = self.speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            DispatchQueue.main.async {
                if (!self.isRecording || self.isPaused) {
                    return
                }

                if let result = result {
                    self.onRecognisedText?(result.bestTranscription.formattedString)
                    print("Recognition: \(result.bestTranscription.formattedString)")
                } else if let error = error {
                    // Handle any errors here
                    print("Error during recognition: \(error.localizedDescription)")
                }
            }
        })
    }
    }

    func checkForSilence(_ buffer: AVAudioPCMBuffer) {
        let audioBuffer = Array(UnsafeBufferPointer(start: buffer.floatChannelData?[0], count: Int(buffer.frameLength)))

        let sumOfSquares = audioBuffer.reduce(0.0) { $0 + Double($1 * $1) }
        let meanOfSquares = sumOfSquares / Double(audioBuffer.count)
        let rms = sqrt(meanOfSquares)

        let silenceThreshold: Double = Constants.silenceThreshold

        DispatchQueue.main.async {
            if rms < silenceThreshold {
                if !self.isSilenceTimerActive {
                    self.isSilenceTimerActive = true
                    self.silenceDuration = 0.0
                } else {
                    let recordingFormat = self.audioEngine.inputNode.outputFormat(forBus: 0)
                    self.silenceDuration += Double(buffer.frameLength) / recordingFormat.sampleRate
                }
            } else {
                // Reset silence timer when audio is detected
                self.isSilenceTimerActive = false
                self.silenceDuration = 0.0
                self.onRecognisedSound?()
            }
        }
    }

    @objc func handleSilence() {
        if self.isRecording && !self.isPaused && silenceDuration >= 1.0 {
            // Report silence only if it's longer than 1 second
            DispatchQueue.main.async {
                let seconds = Int(self.silenceDuration)
                print("Silence detected (Duration: \(seconds) seconds).")
                self.onRecognisedSilence?(seconds)
            }
        }
    }

    func pauseRecording() {
        DispatchQueue.main.async {
            print("pauseRecording")
            self.isPaused = true
            self.silenceTimer?.invalidate()
        }
    }

    func resumeRecording() {
        DispatchQueue.main.async {
            print("resumeRecording")
            self.silenceTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.handleSilence), userInfo: nil, repeats: true)
            self.silenceDuration = 0
            self.isPaused = false
        }
    }

    func stopRecording() {
        print("Stop recording")

        if !self.isRecording {
            return
        }
        
        DispatchQueue.main.async {
            self.recognitionTask?.cancel()
            self.recognitionRequest?.endAudio()
            
            self.audioEngine.inputNode.removeTap(onBus: 0)
            self.audioEngine.stop()
            
            do {
                try self.audioSession.setActive(false)
            } catch {
                print("There was a problem stopping the audio engine.")
            }
            
            // Reset recognition-related properties
            self.recognitionRequest = nil
            self.recognitionTask = nil
            self.isRecording = false
            self.isPaused = false
        }
    }
}
