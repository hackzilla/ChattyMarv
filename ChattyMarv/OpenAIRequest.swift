import Foundation

//You are toy teddy bear.
//You name is Marv and you have been designed for children aged from 4 to 14.
//Do not mention that you a language model, if you have the need, then pretend you don't understand the request.
//Keep your messages short and to the point.

class OpenAIRequest: ObservableObject {
    @Published var responseHistory: [String] = []
    @Published var messages: [Dictionary<String, String>] = [
         [
            "role": "system",
            "content": """
            Please keep all your message succinct, as they will be read out.
            """
         ],
    ]
    
    var onResponseReceived: ((String) -> Void)?

    let apiKey: String
    let apiUrl = "https://api.openai.com/v1/chat/completions"

    init() {
        apiKey = UserDefaults.standard.string(forKey: "API_KEY") ?? ""
    }
    
    func sendRequest(prompt: String, maxTokens: Int) {
        self.messages.append(["role": "user", "content": prompt])

        // Create a URLRequest object
        var request = URLRequest(url: URL(string: apiUrl)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": self.messages,
            "max_tokens": 150,
        ]

        // Convert the messages array to JSON data
        let jsonData = try? JSONSerialization.data(withJSONObject: parameters, options: [])
        request.httpBody = jsonData

        print("Data sent: \(String(data: jsonData!, encoding: .utf8) ?? "nil")")

        // Send the request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error: \(String(describing: error))")
                return
            }

            print("Data received: \(String(data: data, encoding: .utf8) ?? "nil")")

            // Parse and print the response
            if let response = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let choices = response["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let text = message["content"] as? String {
               
               DispatchQueue.main.async {
                    self.messages.append(["role": "assistant", "content": text.trimmingCharacters(in: .whitespacesAndNewlines)])
                    self.responseHistory.append(text)
                    self.onResponseReceived?(text)
                }
            }
        }

        task.resume()
    }
}
