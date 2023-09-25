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
                                ButtonView(recorder: recorder, speechManager: speechManager)
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
                           ButtonView(recorder: recorder, speechManager: speechManager)
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
                    addConsoleText(text: "User: \(text)")
                    sendRequest(prompt: text, maxTokens: 50)
                }
            }
            
            self.openAIRequest.onResponseReceived = { [self] text in
                DispatchQueue.main.async {
                    addConsoleText(text: "Assistant: \(text)")
                    speechManager.speakText(text: text)
                }
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
