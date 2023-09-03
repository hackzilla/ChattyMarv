//
//  OpenAIManager.swift
//  MarvToy
//
//  Created by Daniel Platt on 03/09/2023.
//

import Foundation
import AVFAudio
import UIKit

class SpeechManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    var onResponseReceived: ((String) -> Void)?

    private let speechSynthesizer = AVSpeechSynthesizer()
    private let audioSession = AVAudioSession.sharedInstance()
    
    override init() {
        super.init();
    
        speechSynthesizer.delegate = self
    }
    
    func speakText(text: String) -> Void {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
        utterance.rate = 0.52
        utterance.volume = 1.0
        
        do {
            try self.audioSession.setCategory(.playAndRecord, mode: .default, options: [
                .duckOthers,
                .allowBluetooth,
                .allowBluetoothA2DP
            ])
            try self.audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            try self.audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
            
            self.speechSynthesizer.speak(utterance);
        } catch let error {
            print("OpenAIManager: Error setting up AVAudioSession: \(error.localizedDescription)")
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
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        do {
            try self.audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("OpenAIManager: Error deactivating AVAudioSession: \(error.localizedDescription)")
        }
    }
}