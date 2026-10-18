import AppIntents
import SwiftUI

/// Tela principal: o controle remoto.
struct RemoteView: View {
    @State private var kindle = KindleController.shared
    @StateObject private var volume = VolumeButtonObserver()

    @AppStorage(SettingsKey.volumeButtons) private var volumeButtons = true
    @AppStorage(SettingsKey.haptics) private var haptics = true
    @AppStorage(SettingsKey.invert) private var invert = false
    @AppStorage(SettingsKey.keepAwake) private var keepAwake = true

    @State private var showSettings = false
    @State private var showConnect = false
    @State private var showReading = false

    @Environment(\.scenePhase) private var scenePhase
    @ScaledMetric(relativeTo: .largeTitle) private var counterSize: CGFloat = 84

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            AmbientGlow()

            VStack(alignment: .leading, spacing: 16) {
                topBar
                Text("Folio")
                    .font(.folioSerif(.largeTitle).italic())
                    .padding(.top, 4)
                    .accessibilityAddTraits(.isHeader)

                if kindle.state == .offline {
                    offlineBanner
                        .transition(.opacity)
                }

                stats
                nextButton
                secondaryButtons
                SiriTipView(intent: NextPageIntent())
                    .siriTipViewStyle(.dark)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 12)

            HiddenVolumeView(observer: volume)
                .frame(width: 1, height: 1)
                .accessibilityHidden(true)
        }
        .animation(.easeInOut(duration: 0.2), value: kindle.state)
        .sensoryFeedback(.impact(weight: .medium), trigger: kindle.successCount) { _, _ in haptics }
        .sensoryFeedback(.error, trigger: kindle.failureCount) { _, _ in haptics }
        .sheet(isPresented: $showSettings) {
            SettingsView(onSearchAgain: {
                showSettings = false
                showConnect = true
            })
            .presentationDetents([.large])
        }
        .fullScreenCover(isPresented: $showConnect) {
            ConnectView()
        }
        .fullScreenCover(isPresented: $showReading) {
            ReadingModeView()
        }
        .onAppear {
            configureVolume()
            applyKeepAwake()
            if kindle.host == nil {
                showConnect = true
            } else {
                Task { await kindle.ping() }
            }
        }
        .onChange(of: volumeButtons) { _, _ in configureVolume() }
        .onChange(of: invert) { _, _ in configureVolume() }
        .onChange(of: keepAwake) { _, _ in applyKeepAwake() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                configureVolume()
                applyKeepAwake()
                Task { await kindle.ping() }
            } else {
                volume.stop()
                UIApplication.shared.isIdleTimerDisabled = false
            }
        }
        .task {
            // Confere a conexão a cada 15 s enquanto a tela está aberta.
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(15))
                if scenePhase == .active, kindle.host != nil { await kindle.ping() }
            }
        }
    }

    // MARK: Partes da tela

    private var topBar: some View {
        HStack {
            Button { showConnect = true } label: { statusPill }
                .buttonStyle(PressScaleStyle(scale: 0.96))
                .accessibilityLabel("Conexão: \(statusTitle)")
                .accessibilityHint("Abre a tela para encontrar o Kindle")
            Spacer()
            Button { showSettings = true } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.body.weight(.medium))
                    .frame(width: 44, height: 44)
                    .folioGlass(in: Circle())
            }
            .buttonStyle(PressScaleStyle(scale: 0.92))
            .accessibilityLabel("Ajustes")
        }
        .foregroundStyle(.primary)
    }

    private var statusPill: some View {
        HStack(spacing: 10) {
            statusIcon
            Text(statusTitle).font(.subheadline.weight(.semibold))
            if let detail = statusDetail {
                Text(detail)
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 44)
        .folioGlass(in: Capsule())
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch kindle.state {
        case .online:
            Circle().fill(Theme.success).frame(width: 8, height: 8)
                .background(Circle().fill(Theme.success.opacity(0.2)).frame(width: 16, height: 16))
        case .offline:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.footnote).foregroundStyle(Theme.warning)
        case .checking:
            ProgressView().controlSize(.mini)
        case .notConfigured:
            Image(systemName: "wifi.exclamationmark").font(.footnote).foregroundStyle(.secondary)
        }
    }

    private var statusTitle: String {
        switch kindle.state {
        case .online: "Kindle"
        case .offline: "Sem resposta"
        case .checking: "Conectando"
        case .notConfigured: "Conectar Kindle"
        }
    }

    private var statusDetail: String? {
        switch kindle.state {
        case .online(let ms): "\(ms) ms"
        case .offline: "tocar p/ reconectar"
        default: nil
        }
    }

    private var offlineBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Theme.warning)
            VStack(alignment: .leading, spacing: 4) {
                Text("O Kindle não respondeu").font(.subheadline.weight(.semibold))
                Text("Confira se o Wi-Fi do Kindle está ligado e toque em “Passador Ligar” de novo.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Theme.warning.opacity(0.14), in: .rect(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Theme.warning.opacity(0.35)))
        .accessibilityElement(children: .combine)
    }

    private var stats: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Nesta sessão").font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
                Text("\(kindle.pagesThisSession)")
                    .font(.system(size: counterSize, weight: .light, design: .serif))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.snappy, value: kindle.pagesThisSession)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text("páginas viradas").font(.subheadline).foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Text("Tempo de leitura").font(.footnote).foregroundStyle(.secondary)
                TimelineView(.periodic(from: .now, by: 30)) { context in
                    Text(readingTime(at: context.date))
                        .font(.title3.weight(.semibold).monospacedDigit())
                }
                if let last = kindle.lastAction {
                    Label(last == .next ? "Avançou" : "Voltou", systemImage: "checkmark")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .labelStyle(.titleAndIcon)
                }
            }
            .padding(.bottom, 6)
            .accessibilityElement(children: .combine)
        }
    }

    private var nextButton: some View {
        Button {
            Task { await kindle.turn(.next) }
        } label: {
            VStack(alignment: .leading) {
                HStack {
                    Text("Próxima página")
                    Spacer()
                    if volumeButtons {
                        Label(invert ? "ou Vol −" : "ou Vol +", systemImage: "speaker.wave.2")
                    }
                }
                .font(.footnote.weight(.bold))
                .opacity(0.72)
                Spacer(minLength: 24)
                HStack(alignment: .bottom) {
                    Text("Avançar")
                        .font(.folioSerif(.largeTitle, weight: .medium))
                        .minimumScaleFactor(0.6)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 64, height: 64)
                        .background(Theme.onAccent, in: Circle())
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .foregroundStyle(Theme.onAccent)
            .background(Color.accentColor, in: .rect(cornerRadius: 34))
            .shadow(color: Color.accentColor.opacity(0.35), radius: 30, y: 16)
        }
        .buttonStyle(PressScaleStyle())
        .frame(minHeight: 220)
        .accessibilityLabel("Avançar página")
    }

    private var secondaryButtons: some View {
        HStack(spacing: 12) {
            Button {
                Task { await kindle.turn(.previous) }
            } label: {
                Label("Voltar", systemImage: "arrow.left")
                    .frame(maxWidth: .infinity, minHeight: 72)
                    .background(Theme.surface, in: .rect(cornerRadius: 24))
            }
            .accessibilityLabel("Voltar página")

            Button { showReading = true } label: {
                Label("Modo leitura", systemImage: "moon")
                    .frame(maxWidth: .infinity, minHeight: 72)
                    .background(Theme.surface, in: .rect(cornerRadius: 24))
            }
        }
        .font(.headline)
        .foregroundStyle(.primary)
        .buttonStyle(PressScaleStyle(scale: 0.95))
    }

    // MARK: Lógica

    private func readingTime(at date: Date) -> String {
        guard let start = kindle.sessionStart else { return "0 min" }
        let minutes = Int(date.timeIntervalSince(start) / 60)
        if minutes < 60 { return "\(minutes) min" }
        return "\(minutes / 60) h \(minutes % 60) min"
    }

    /// Liga ou desliga os botões de volume conforme o ajuste.
    /// Com "Inverter direção", Vol − avança (útil para mangás).
    private func configureVolume() {
        guard volumeButtons, scenePhase != .background else {
            volume.stop()
            return
        }
        volume.onUp = { Task { await kindle.turn(invert ? .previous : .next) } }
        volume.onDown = { Task { await kindle.turn(invert ? .next : .previous) } }
        volume.start()
    }

    private func applyKeepAwake() {
        UIApplication.shared.isIdleTimerDisabled = keepAwake
    }
}
