//
//  OpenAIManager.swift
//  ChattyMarv
//
//  Created by Daniel Platt on 03/09/2023.
//

import Foundation
import AVFAudio
import UIKit

class SpeechManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published var isSpeaking: Bool = false

    var onFinishSpeaking: (() -> Void)?

    private let speechSynthesizer = AVSpeechSynthesizer()
    private let audioSession = AVAudioSession.sharedInstance()
    
    override init() {
        super.init();
    
        speechSynthesizer.delegate = self
    }
    
    func speakText(text: String) -> Void {
        print("Speak text: \(text)")

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: Constants.speechVoice)
        utterance.rate = Constants.speechRate
        utterance.volume = Constants.speechVolume
        
        do {
            try self.audioSession.setCategory(.playAndRecord, mode: .default, options: [
                .duckOthers,
                .allowBluetooth,
                .allowBluetoothA2DP
            ])
//            try self.audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            if (UserDefaults.standard.bool(forKey: "USE_SPEAKER")) {
                try self.audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
            } else {
                try self.audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.none)
            }

            self.speechSynthesizer.speak(utterance);
        } catch let error {
            print("OpenAIManager: Error setting up AVAudioSession: \(error.localizedDescription)")
        }
    }
    
    func stopSpeaking() {
        // Stops speech at the next word boundary, or immediately if you prefer.
        print("Stop speaking")
        if (self.isSpeaking) {
            self.speechSynthesizer.stopSpeaking(at: .word)
        }
    }

    func chooseSpeechVoices() -> [AVSpeechSynthesisVoice?] {
        // List all available voices in en-US language
        let voices = AVSpeechSynthesisVoice.speechVoices()
            .filter({$0.language == "en-US"})
        
        // split male/female voices
        let maleVoices = voices.filter({$0.gender == .male})
        let femaleVoices = voices.filter({$0.gender == .female})
        
        // pick voices
        let selectedMaleVoice = maleVoices.first(where: {$0.quality == .premium}) ?? maleVoices.first // premium is only available from iOS 16
        let selectedFemaleVoice = femaleVoices.first(where: {$0.quality == .enhanced}) ?? femaleVoices.first
        
        //
        if selectedMaleVoice == nil && selectedFemaleVoice == nil {
            showAlert(text: "Text to speech feature is not available on your device")
        } else if selectedMaleVoice == nil {
            showAlert(text: "Text to speech with Male voice is not available on your device")
        } else if selectedFemaleVoice == nil {
            showAlert(text: "Text to speech with Female voice is not available on your device")
        }
        
        return [selectedMaleVoice, selectedFemaleVoice]
    }
    
    private func showAlert(text: String)
    {
        print("Alert: \(text)")
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        // Speech started
        isSpeaking = true
        print("Start speaking")
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
        onFinishSpeaking?()
        print("Did finish speaking")

//        do {
//            try self.audioSession.setActive(false, options: .notifyOthersOnDeactivation)
//        } catch {
//            print("OpenAIManager: Error deactivating AVAudioSession: \(error.localizedDescription)")
//        }
    }
}
