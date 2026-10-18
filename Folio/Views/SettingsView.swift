import SwiftUI

/// Ajustes: folha nativa com Form, para herdar o visual e a
/// acessibilidade do sistema (Liquid Glass, Dynamic Type, VoiceOver).
struct SettingsView: View {
    var onSearchAgain: () -> Void

    @State private var kindle = KindleController.shared
    @AppStorage(SettingsKey.volumeButtons) private var volumeButtons = true
    @AppStorage(SettingsKey.haptics) private var haptics = true
    @AppStorage(SettingsKey.invert) private var invert = false
    @AppStorage(SettingsKey.keepAwake) private var keepAwake = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Conexão") {
                    LabeledContent("Kindle", value: kindle.addressDescription)
                        .monospacedDigit()
                    Button("Procurar novamente", action: onSearchAgain)
                    Button("Zerar contador da sessão") { kindle.resetSession() }
                }

                Section("Controles") {
                    toggle("Botões de volume", "Vol + avança e Vol − volta, com o app aberto", $volumeButtons)
                    toggle("Vibração", "Confirmação tátil a cada página", $haptics)
                    toggle("Inverter direção", "Para mangás e leitura da direita para a esquerda", $invert)
                    toggle("Manter tela ligada", "O iPhone não bloqueia enquanto o Folio está aberto", $keepAwake)
                }

                Section {
                    LabeledContent {
                        Text("Siri · Ação").foregroundStyle(.secondary)
                    } label: {
                        Label("Avançar página", systemImage: "arrow.right")
                    }
                    LabeledContent {
                        Text("Siri · Ação").foregroundStyle(.secondary)
                    } label: {
                        Label("Voltar página", systemImage: "arrow.left")
                    }
                } header: {
                    Text("Atalhos")
                } footer: {
                    Text("Diga “Próxima página no Folio”. Para o Toque traseiro, vá em Ajustes do iPhone › Acessibilidade › Toque › Toque traseiro e escolha o atalho “Avançar página”.")
                }
            }
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Concluir", systemImage: "checkmark") { dismiss() }
                }
            }
        }
        .tint(.accentColor)
    }

    private func toggle(_ title: String, _ hint: String, _ value: Binding<Bool>) -> some View {
        Toggle(isOn: value) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(hint).font(.footnote).foregroundStyle(.secondary)
            }
        }
    }
}
