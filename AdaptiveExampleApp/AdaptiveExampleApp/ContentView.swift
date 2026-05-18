//
//  ContentView.swift
//  AdaptiveExampleApp
//
//  Created by Mohamed Haloka on 18/05/2026.
//

import SwiftUI
import AdaptiveChat
import UIKit

struct ContentView: View {

    @State private var subject = "Math"
    @State private var topic   = "Fractions"

    private let teal = Color(red: 15/255, green: 118/255, blue: 110/255)

    var body: some View {
        VStack(spacing: 0) {

            // ── Header ──────────────────────────────────────
            VStack(spacing: 12) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 64))
                    .foregroundColor(teal)
                Text("AI Coach Chat")
                    .font(.largeTitle.bold())
                    .foregroundColor(teal)
                Text("Configure your session and launch the adaptive chat experience.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.top, 60)

            Spacer()

            // ── Fields ──────────────────────────────────────
            VStack(spacing: 20) {
                labeledField(label: "Subject", placeholder: "e.g. Math",      text: $subject)
                labeledField(label: "Topic",   placeholder: "e.g. Fractions", text: $topic)
            }
            .padding(.horizontal, 24)

            Spacer()

            // ── Launch button ────────────────────────────────
            Button(action: launchChat) {
                Label("Launch Chat", systemImage: "message.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(teal)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }

    // MARK: - Private

    @ViewBuilder
    private func labeledField(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
            TextField(placeholder, text: text)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
        }
    }

    private func launchChat() {
        let config = AdaptiveChatConfig(
            primaryColor:    UIColor(red: 15/255,  green: 118/255, blue: 110/255, alpha: 1),
            accentColor:     UIColor(red: 245/255, green: 158/255, blue: 11/255,  alpha: 1),
            backgroundColor: UIColor(red: 255/255, green: 251/255, blue: 245/255, alpha: 1),
            subject: subject.isEmpty ? "Math"      : subject,
            topic:   topic.isEmpty   ? "Fractions" : topic
        )
        guard
            let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
            let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else { return }
        AdaptiveChat.shared.presentChat(from: root, config: config)
    }
}

#Preview {
    ContentView()
}
