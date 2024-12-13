//
//  ErrorView.swift
//  GitOK
//
//  Created by Angel on 2024/12/13.
//

import SwiftUI


struct ErrorView: View {
    let error: Error

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Text("Error")
                    .font(.headline)
                    .foregroundColor(.red)
                Text(error.localizedDescription)
                    .foregroundColor(.red)
                    .textSelection(.enabled)
            }
            .padding()
        }
    }
}
