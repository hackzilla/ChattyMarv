import SwiftUI
import AVFoundation

#if os(macOS)
class MacOSContentViewModel: NSObject, ObservableObject, NSSpeechRecognizerDelegate {
    @Published var textToSpeak = "Hello, World!"
    @Published var recognizedText = ""
    @Published var isListening = false
  
    @ObservedObject var openAi = OpenAIManager()

    private var speechSynthesizer = AVSpeechSynthesizer()
    private var speechRecognizer = NSSpeechRecognizer()
    
    override init() {
        super.init()
        self.speechRecognizer?.delegate = self
    }
    
    func speakText() {
        let utterance = AVSpeechUtterance(string: textToSpeak)
        speechSynthesizer.speak(utterance)
    }
    
    func startListening() {
        speechRecognizer?.startListening()
        isListening = true
    }
    
    func stopListening() {
        speechRecognizer?.stopListening()
        isListening = false
    }
    
    func speechRecognizer(_ sender: NSSpeechRecognizer, didRecognizeCommand command: String) {
        self.recognizedText = command
        self.openAi.sendRequest(prompt: command, maxTokens: 50)
    }
}

struct MacOSContentView: View {
    @ObservedObject var viewModel = MacOSContentViewModel()

    var body: some View {
        VStack {
            TextField("Text to speak", text: $viewModel.textToSpeak)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            TextField("Recognized text", text: $viewModel.recognizedText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            HStack {
                Button("Speak") {
                    viewModel.speakText()
                }
                Button(viewModel.isListening ? "Stop Listening" : "Start Listening") {
                    if viewModel.isListening {
                        self.viewModel.stopListening()
                    } else {
                        self.viewModel.startListening()
                    }
                }
            }
        }
        .padding()
    }
}
#endif
