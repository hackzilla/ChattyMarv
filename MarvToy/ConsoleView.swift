//
//  ConsoleView.swift
//  MarvToy
//
//  Created by Daniel Platt on 16/09/2023.
//

import SwiftUI

struct ConsoleView: View {
    @Binding var consoleText: String

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer() // This will push the console to the bottom half
                
                VStack {
                    ScrollView {
                        Text(consoleText)
                            .padding()
                    }
                    .frame(width: geometry.size.width, alignment: .leading)
                    .background(Color.black.opacity(0.9))
                    .foregroundColor(.white)
                    .cornerRadius(15, corners: [.topLeft, .topRight])
                }
                .frame(width: geometry.size.width, height: geometry.size.height * 0.5)
            }
        }
    }
}

struct ConsoleView_Previews: PreviewProvider {
    @State static private var previewText = "Here you can place the program's input and output."

    static var previews: some View {
        ConsoleView(consoleText: $previewText)
    }
}


extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
