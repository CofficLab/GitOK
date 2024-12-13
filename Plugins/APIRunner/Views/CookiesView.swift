//
//  CookiesView.swift
//  GitOK
//
//  Created by Angel on 2024/12/13.
//

import SwiftUI

// Cookies 视图
struct CookiesView: View {
    let cookies: [HTTPCookie]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(cookies, id: \.name) { cookie in
                VStack(alignment: .leading, spacing: 4) {
                    Text(cookie.name)
                        .font(.headline)
                    Text(cookie.value)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)

                    HStack {
                        Label(cookie.domain, systemImage: "globe")
                        Label(cookie.path, systemImage: "folder")
                        if cookie.isSecure {
                            Label("Secure", systemImage: "lock")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                Divider()
            }
        }
    }
}
