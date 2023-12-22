import SwiftUI

struct ContentView: View {
    @ObservedObject private var recorder = Recorder()
    @ObservedObject private var speechManager = SpeechManager()
    @ObservedObject private var openAIRequest = OpenAIRequest()

    @State private var isConsoleVisible: Bool = false
    @State private var consoleText: String = "Session started \(formattedDate())\n\n"
    @State private var text: String = ""
    @State private var isUserSpeaking = false

    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.colorScheme) var colorScheme

    var onResponseReceived: ((String) -> Void)?
    var onRecognisedText: ((String) -> Void)?
    var onRecognisedSilence: ((Int) -> Void)?
    var onRecognisedSound: (() -> Void)?

    @MainActor func addConsoleText(text: String) {
        consoleText.append("\(text)\n")
    }

    func sendRequest(prompt: String, maxTokens: Int) {
        openAIRequest.sendRequest(prompt: prompt, maxTokens: maxTokens)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Main Content
                VStack(spacing: 0) {
                    if verticalSizeClass == .compact { // Landscape
                        HStack {
                            Image("bot")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: geometry.size.width * 0.5)
                            
                            VStack {
                                ButtonView(recorder: recorder, speechManager: speechManager, isUserSpeaking: $isUserSpeaking)
                            }
                        }
                    } else { // Portrait
                       VStack {
                           Spacer()
                           Image("bot")
                               .resizable()
                               .aspectRatio(contentMode: .fit)
                               .frame(width: geometry.size.width)
                           Spacer()
                       }
                       .frame(height: geometry.size.height * 0.65)
                       
                       VStack {
                           Spacer()
                           ButtonView(recorder: recorder, speechManager: speechManager, isUserSpeaking: $isUserSpeaking)
                           Spacer()
                       }
                       .frame(height: geometry.size.height * 0.35)
                   }
                }
                .zIndex(0)
                
                // Console Toggle Button
                VStack {
                    Spacer()
                    Button("Toggle Console") {
                        withAnimation {
                            isConsoleVisible.toggle()
                        }
                    }
                    .padding(.bottom)
                }
                .frame(width: geometry.size.width)
                .zIndex(2)

                // Console View
                if isConsoleVisible {
                    ConsoleView(consoleText: $consoleText)
                        .transition(.move(edge: .bottom))
                        .zIndex(1)
                }
            }
            .edgesIgnoringSafeArea(.all)
        }
        .onAppear {
            self.recorder.onRecognisedText = { [self] text in
                DispatchQueue.main.async {
                    self.text += text
                }
            }
            
            self.openAIRequest.onResponseReceived = { [self] text in
                if (text == "") {
                    return
                }
                
                DispatchQueue.main.async {
                    print("handle: onResponseReceived")
                    
                    addConsoleText(text: "Assistant: \(text)")
                    speechManager.speakText(text: text)
                }
            }
            
            self.recorder.onRecognisedSilence = { [self] seconds in
                DispatchQueue.main.async {
                    self.isUserSpeaking = false

                    if seconds > Constants.requestAfterSeconds && self.text != "" {
                        self.recorder.pauseRecording()
                        addConsoleText(text: "User: \(self.text)")
                        sendRequest(prompt: self.text, maxTokens: Constants.maxTokens)
                        self.text = ""
                    }
                }
            }

            self.recorder.onRecognisedSound = {
                DispatchQueue.main.async {
                    // display something
                    self.isUserSpeaking = true
                }
            }

            self.speechManager.onFinishSpeaking = {
                DispatchQueue.main.async {
                    self.recorder.resumeRecording()
                    self.isUserSpeaking = true
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

func formattedDate() -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: Date())
}
