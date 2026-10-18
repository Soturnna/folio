import SwiftUI

/// Tela para encontrar o Kindle: varredura automática + endereço manual.
struct ConnectView: View {
    @State private var kindle = KindleController.shared
    @State private var scanner = NetworkScanner()
    @State private var selected: DiscoveredKindle?
    @State private var manualAddress = ""
    @FocusState private var manualFocused: Bool

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            Circle()
                .fill(Color.accentColor.opacity(0.07))
                .frame(width: 400, height: 400)
                .blur(radius: 70)
                .offset(y: -120)
                .accessibilityHidden(true)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                            .frame(width: 44, height: 44)
                            .folioGlass(in: Circle())
                    }
                    .foregroundStyle(.primary)
                    .accessibilityLabel("Voltar")

                    VStack(alignment: .leading, spacing: 8) {
                        (Text("Encontre seu ") + Text("Kindle").italic())
                            .font(.folioSerif(.largeTitle))
                            .accessibilityAddTraits(.isHeader)
                        Text("Toque em “Passador Ligar” no Kindle e mantenha os dois aparelhos no mesmo Wi-Fi.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    RadarView(active: scanner.isScanning && !reduceMotion)
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)

                    results

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ou digite o endereço")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.leading, 4)
                        TextField("192.168.0.0:8080", text: $manualAddress)
                            .keyboardType(.numbersAndPunctuation)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($manualFocused)
                            .font(.body.monospacedDigit())
                            .padding(.horizontal, 16)
                            .frame(minHeight: 52)
                            .background(Theme.surface, in: .rect(cornerRadius: 16))
                            .onChange(of: manualAddress) { _, value in
                                if !value.isEmpty { selected = nil }
                            }
                            .accessibilityLabel("Endereço do Kindle")
                    }

                    Label {
                        Text("O iPhone vai pedir acesso à rede local. O Folio usa esse acesso apenas para enviar comandos ao seu Kindle. Nada sai da sua rede.")
                    } icon: {
                        Image(systemName: "lock")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .safeAreaInset(edge: .bottom) {
            Button(action: connect) {
                Text("Conectar")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .folioProminentButton()
            .controlSize(.large)
            .tint(.accentColor)
            .foregroundStyle(Theme.onAccent)
            .disabled(target == nil)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .onAppear { scanner.start(port: kindle.port) }
        .onDisappear { scanner.stop() }
        .onChange(of: scanner.found) { _, found in
            if selected == nil, manualAddress.isEmpty, let first = found.first { selected = first }
        }
    }

    @ViewBuilder
    private var results: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(scanner.isScanning ? "Procurando na rede…" : "Encontrado na rede")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if scanner.isScanning {
                    Text("\(Int(scanner.progress * 100))%")
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(.secondary)
                } else {
                    Button("Procurar de novo") { scanner.start(port: kindle.port) }
                        .font(.footnote.weight(.semibold))
                }
            }
            .padding(.horizontal, 4)

            if scanner.found.isEmpty {
                Text(emptyMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Theme.surface, in: .rect(cornerRadius: 20))
            } else {
                ForEach(scanner.found) { device in
                    Button {
                        selected = device
                        manualAddress = ""
                        manualFocused = false
                    } label: {
                        deviceRow(device)
                    }
                    .buttonStyle(PressScaleStyle(scale: 0.98))
                    .accessibilityAddTraits(selected == device ? .isSelected : [])
                }
            }
        }
    }

    private var emptyMessage: String {
        if scanner.localAddress == nil { return "Conecte o iPhone a uma rede Wi-Fi para procurar o Kindle." }
        return scanner.isScanning ? "Verificando os aparelhos da sua rede." : "Nenhum Kindle encontrado. Confira se o Passador está ligado ou digite o endereço abaixo."
    }

    private func deviceRow(_ device: DiscoveredKindle) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "book.closed")
                .font(.title3)
                .frame(width: 42, height: 42)
                .background(Theme.surfaceRaised, in: .rect(cornerRadius: 13))
            VStack(alignment: .leading, spacing: 2) {
                Text("Kindle").font(.headline)
                Text("\(device.host):\(device.port) · \(device.latencyMs) ms")
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if selected == device {
                Image(systemName: "checkmark")
                    .font(.headline)
                    .foregroundStyle(Theme.success)
                    .accessibilityHidden(true)
            }
        }
        .foregroundStyle(.primary)
        .padding(14)
        .background(Theme.surface, in: .rect(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(selected == device ? Theme.success.opacity(0.6) : .clear, lineWidth: 1.5))
    }

    /// Endereço escolhido: o digitado tem prioridade sobre o encontrado.
    private var target: (host: String, port: Int)? {
        let text = manualAddress.trimmingCharacters(in: .whitespaces)
        if !text.isEmpty {
            let parts = text.split(separator: ":")
            let host = String(parts[0])
            let port = parts.count > 1 ? Int(parts[1]) ?? SettingsDefaults.port : SettingsDefaults.port
            let octets = host.split(separator: ".")
            guard octets.count == 4, octets.allSatisfy({ Int($0).map { (0...255).contains($0) } ?? false }) else { return nil }
            return (host, port)
        }
        if let selected { return (selected.host, selected.port) }
        return nil
    }

    private func connect() {
        guard let target else { return }
        kindle.configure(host: target.host, port: target.port)
        dismiss()
    }
}

/// Animação de radar: anéis que pulsam enquanto a busca acontece.
private struct RadarView: View {
    var active: Bool
    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle().stroke(Color(white: 0.13)).frame(width: 220, height: 220)
            Circle().stroke(Color(white: 0.17)).frame(width: 158, height: 158)
            Circle()
                .stroke(Color.accentColor.opacity(0.55), lineWidth: 1.5)
                .frame(width: 100, height: 100)
                .scaleEffect(pulse ? 2.2 : 1)
                .opacity(pulse ? 0 : 1)
            Image(systemName: "book.closed")
                .font(.system(size: 34, weight: .light))
                .frame(width: 60, height: 80)
                .background(Theme.surface, in: .rect(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.primary.opacity(0.85), lineWidth: 1.5))
        }
        .onChange(of: active, initial: true) { _, isActive in
            if isActive {
                withAnimation(.easeOut(duration: 1.8).repeatForever(autoreverses: false)) { pulse = true }
            } else {
                withAnimation(.default) { pulse = false }
            }
        }
        .accessibilityHidden(true)
    }
}
