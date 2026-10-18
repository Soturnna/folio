import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

/// Live Activity: o painel da tela bloqueada e da Dynamic Island.
/// Os botões usam `Button(intent:)`, que executa a ação sem abrir o app.
struct FolioLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FolioActivityAttributes.self) { context in
            LockScreenPanel(state: context.state)
                .activityBackgroundTint(Color.black.opacity(0.55))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        FolioMark(size: 26)
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Folio").font(.subheadline.weight(.bold))
                            ElapsedText(start: context.state.startedAt)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(context.state.pages)")
                            .font(.system(size: 34, weight: .light, design: .serif))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                        Text("pág.").font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 10) {
                        Button(intent: PreviousPageIntent()) {
                            Label("Voltar", systemImage: "arrow.left")
                                .font(.subheadline.weight(.bold))
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .background(Color(white: 0.17), in: Capsule())
                        }
                        .frame(maxWidth: .infinity)
                        Button(intent: NextPageIntent()) {
                            HStack(spacing: 8) {
                                Text("Avançar")
                                Image(systemName: "arrow.right")
                            }
                            .font(.headline.weight(.heavy))
                            .foregroundStyle(FolioPalette.onAmber)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(FolioPalette.amber, in: Capsule())
                        }
                        .layoutPriority(1)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 6)
                }
            } compactLeading: {
                Image(systemName: "book.closed.fill")
                    .foregroundStyle(FolioPalette.amber)
            } compactTrailing: {
                Text("\(context.state.pages)")
                    .font(.subheadline.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(FolioPalette.amber)
                    .contentTransition(.numericText())
            } minimal: {
                Text("\(context.state.pages)")
                    .font(.caption.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(FolioPalette.amber)
            }
            .keylineTint(FolioPalette.amber)
        }
    }
}

/// Painel da tela bloqueada (o mesmo do design "Tela bloqueada").
private struct LockScreenPanel: View {
    let state: FolioActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                FolioMark(size: 22)
                Text("Folio").font(.subheadline.weight(.bold))
                Spacer()
                HStack(spacing: 6) {
                    if state.online {
                        Circle().fill(FolioPalette.success).frame(width: 6, height: 6)
                    } else {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundStyle(FolioPalette.warning)
                    }
                    Text(state.online ? "Kindle · lendo há" : "Kindle sem resposta ·")
                    ElapsedText(start: state.startedAt)
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(state.pages)")
                        .font(.system(size: 44, weight: .light, design: .serif))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text("páginas nesta sessão")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Button(intent: PreviousPageIntent()) {
                    Image(systemName: "arrow.left")
                        .font(.title3.weight(.semibold))
                        .frame(width: 52, height: 52)
                        .background(Color.white.opacity(0.14), in: Circle())
                }
                .accessibilityLabel("Voltar página")
                Button(intent: NextPageIntent()) {
                    HStack(spacing: 8) {
                        Text("Avançar")
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(FolioPalette.onAmber)
                    .padding(.horizontal, 20)
                    .frame(height: 52)
                    .background(FolioPalette.amber, in: Capsule())
                }
                .accessibilityLabel("Avançar página")
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(.white)
        .padding(16)
    }
}

/// Tempo de leitura que avança sozinho (o sistema atualiza o texto).
private struct ElapsedText: View {
    let start: Date
    var body: some View {
        Text(start, style: .timer)
            .monospacedDigit()
    }
}

/// O símbolo do Folio (página com canto dobrado), gerado a partir do ícone.
struct FolioMark: View {
    var size: CGFloat
    var body: some View {
        Image("FolioMark")
            .resizable()
            .interpolation(.high)
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.23, style: .continuous))
            .accessibilityHidden(true)
    }
}
