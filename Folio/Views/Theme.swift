import SwiftUI

/// Identidade visual do Folio, em um só lugar.
enum Theme {
    /// Grafite quase preto (vem do catálogo, com variante de alto contraste).
    static let background = Color("FolioBackground")
    /// Texto escuro sobre o âmbar: contraste acima de 9:1.
    static let onAccent = Color(red: 0.10, green: 0.07, blue: 0.02)
    /// Superfícies de conteúdo: cinzas semânticos do sistema.
    static let surface = Color(.secondarySystemBackground)
    static let surfaceRaised = Color(.tertiarySystemBackground)
    static let success = Color.green
    static let warning = Color.orange
}

extension Font {
    /// Fonte serifada do sistema (New York), ligada ao Dynamic Type.
    static func folioSerif(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .serif, weight: weight)
    }
}

extension View {
    /// Liquid Glass para a camada de navegação (iOS 26+).
    /// Em versões anteriores, ou com "Reduzir transparência", usa material padrão.
    @ViewBuilder
    func folioGlass<S: Shape>(in shape: S) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.interactive(), in: shape)
        } else {
            self.background(.ultraThinMaterial, in: shape)
        }
        #else
        self.background(.ultraThinMaterial, in: shape)
        #endif
    }

    /// Botão de ação principal tingido (vidro proeminente no iOS 26+).
    @ViewBuilder
    func folioProminentButton() -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            self.buttonStyle(.glassProminent)
        } else {
            self.buttonStyle(.borderedProminent)
        }
        #else
        self.buttonStyle(.borderedProminent)
        #endif
    }
}

/// Estilo de "aperto": encolhe levemente o botão enquanto é pressionado.
/// Com "Reduzir movimento" ativo, troca a escala por uma leve transparência.
struct PressScaleStyle: ButtonStyle {
    var scale: CGFloat = 0.97
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? scale : 1)
            .opacity(configuration.isPressed && reduceMotion ? 0.8 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Brilho difuso de fundo (decorativo).
struct AmbientGlow: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.10))
                .frame(width: 380, height: 380)
                .blur(radius: 64)
                .offset(x: 140, y: -330)
            Circle()
                .fill(Color.indigo.opacity(0.07))
                .frame(width: 260, height: 260)
                .blur(radius: 70)
                .offset(x: -170, y: -200)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
