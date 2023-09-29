//
//  APIKeyCheckView.swift
//  ChattyMarv
//
//  Created by Daniel Platt on 17/09/2023.
//

import SwiftUI
import Combine

class APIKeyViewModel: ObservableObject {
    @Published var apiKey: String? = UserDefaults.standard.string(forKey: "API_KEY")
    private var cancellable: AnyCancellable?

    init() {
        cancellable = UserDefaults.standard.publisher(for: \.API_KEY)
            .sink(receiveValue: { [weak self] newValue in
                self?.apiKey = newValue
//                print("ApiKey: \(newValue ?? "empty")")
            })
    }
}

struct APIKeyCheckView: View {
    @ObservedObject private var viewModel = APIKeyViewModel()
    
    var body: some View {
        Group {
            if viewModel.apiKey?.isEmpty ?? true {
                RedirectToSettingsView()
            } else {
            #if os(macOS)
                MacContentView()
            #else
                iOSContentView()
            #endif
            }
        }
    }
  
}

extension UserDefaults {
    @objc dynamic var API_KEY: String? {
        return string(forKey: "API_KEY")
    }
}
