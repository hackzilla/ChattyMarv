import SwiftUI

struct iOSContentView: View {
    @ObservedObject private var recorder = Recorder()
    @ObservedObject private var speechManager = SpeechManager()
    @ObservedObject private var openAIRequest = OpenAIRequest()

    @State private var isConsoleVisible: Bool = false
    @State private var consoleText: String = "Session started \(formattedDate())\n\n"

    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.colorScheme) var colorScheme

    var onResponseReceived: ((String) -> Void)?
    var onRecognisedText: ((String) -> Void)?

    init() {
        self.recorder.onRecognisedText = { [self] text in
            DispatchQueue.main.async {
                self.consoleText += "User: \(text)\n"
            }
        }
        
        self.openAIRequest.onResponseReceived = { [self] text in
            DispatchQueue.main.async {
                self.consoleText += "Assistant: \(text)\n"
                speechManager.speakText(text: text)
            }
        }
    }

    func sendRequest(prompt: String, maxTokens: Int) {
        openAIRequest.sendRequest(prompt: prompt, maxTokens: maxTokens)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Main Content
                VStack {
                    if verticalSizeClass == .compact { // Landscape
                        HStack {
                            Image("bot")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: geometry.size.width * 0.5)
                            
                            VStack {
                                buttonView
                            }
                        }
                    } else { // Portrait
                        VStack {
                            Image("bot")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: geometry.size.width)

                            buttonView
                        }
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
     }
     
     var buttonView: some View {
         VStack(spacing: 10) {
             if !speechManager.isSpeaking {
                 Button(action: {
                     recorder.startRecording()
                 }) {
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
                 .disabled(!recorder.hasMicrophoneAccess || !recorder.isSpeechRecognizerAvailable)

             } else {
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
             }
         }
     }
 }

struct iOSContentView_Previews: PreviewProvider {
    static var previews: some View {
        iOSContentView()
    }
}

func formattedDate() -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: Date())
}
