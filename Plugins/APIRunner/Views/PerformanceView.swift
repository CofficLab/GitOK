//
//  PerformanceView.swift
//  GitOK
//
//  Created by Angel on 2024/12/13.
//

import SwiftUI

// Performance 视图
struct PerformanceView: View {
    let response: APIResponse?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TimelineView(response: response)

            GroupBox("Timing Breakdown") {
                VStack(alignment: .leading, spacing: 8) {
                    TimingRow(label: "DNS Lookup", value: response?.dnsLookupTime)
                    TimingRow(label: "TCP Connection", value: response?.tcpConnectionTime)
                    TimingRow(label: "TLS Handshake", value: response?.tlsHandshakeTime)
                    TimingRow(label: "Time to First Byte", value: response?.timeToFirstByte)
                    TimingRow(label: "Total Duration", value: response?.duration)
                }
                .padding()
            }
        }
    }
}
