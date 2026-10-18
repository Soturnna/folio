import SwiftUI

/// Modo leitura: tela preta inteira dividida em duas zonas de toque.
/// Avançar ocupa 65% da largura (a ação mais usada); Voltar, 35%.
/// Com "Inverter direção", as zonas trocam de lado.
struct ReadingModeView: View {
    @State private var kindle = KindleController.shared
    @AppStorage(SettingsKey.invert) private var invert = false
    @AppStorage(SettingsKey.haptics) private var haptics = true
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var flash: PageTurn?

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                if invert {
                    zone(.next, width: proxy.size.width * 0.65)
                    zone(.previous, width: proxy.size.width * 0.35)
                } else {
                    zone(.previous, width: proxy.size.width * 0.35)
                    zone(.next, width: proxy.size.width * 0.65)
                }
            }
        }
        .ignoresSafeArea()
        .background(Color.black)
        .overlay(alignment: .center) {
            VStack(spacing: 4) {
                Text("\(kindle.pagesThisSession)")
                    .font(.system(size: 120, weight: .light, design: .serif))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .foregroundStyle(Color(white: 0.20))
                Text("páginas")
                    .font(.folioSerif(.callout).italic())
                    .foregroundStyle(Color(white: 0.30))
            }
            .offset(y: -80)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
        .overlay(alignment: .top) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                        .folioGlass(in: Circle())
                }
                .accessibilityLabel("Sair do modo leitura")
                Spacer()
                Label("Kindle", systemImage: kindle.state == .offline ? "exclamationmark.triangle.fill" : "circle.fill")
                    .font(.caption)
                    .foregroundStyle(kindle.state == .offline ? AnyShapeStyle(Theme.warning) : AnyShapeStyle(.secondary))
                    .symbolRenderingMode(.monochrome)
                    .imageScale(.small)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .overlay(alignment: .bottom) {
            Text("Toque em qualquer lugar · tela escurecida para leitura noturna")
                .font(.caption)
                .foregroundStyle(Color(white: 0.45))
                .padding(.bottom, 24)
                .allowsHitTesting(false)
        }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .sensoryFeedback(.impact(weight: .light), trigger: kindle.successCount) { _, _ in haptics }
        .sensoryFeedback(.error, trigger: kindle.failureCount) { _, _ in haptics }
    }

    private func zone(_ direction: PageTurn, width: CGFloat) -> some View {
        Button {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.12)) { flash = direction }
            Task {
                await kindle.turn(direction)
                try? await Task.sleep(for: .milliseconds(180))
                withAnimation(.easeOut(duration: 0.25)) { flash = nil }
            }
        } label: {
            VStack(spacing: 10) {
                Spacer()
                Image(systemName: direction == .next ? "chevron.right" : "chevron.left")
                    .font(.title3)
                Text(direction == .next ? "Avançar" : "Voltar")
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .tracking(1.4)
            }
            .foregroundStyle(Color(white: 0.45))
            .padding(.bottom, 140)
            .frame(width: width)
            .frame(maxHeight: .infinity)
            .background(flash == direction ? Color(white: 0.07) : Color.black)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(direction == .next ? "Avançar página" : "Voltar página")
    }
}
