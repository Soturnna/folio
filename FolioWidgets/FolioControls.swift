import AppIntents
import SwiftUI
import WidgetKit

/// Controles do iOS 18: aparecem na Central de Controle e podem
/// substituir a lanterna e a câmera nos cantos da tela bloqueada.
@available(iOS 18.0, *)
struct NextPageControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.soturnna.folio.control.next") {
            ControlWidgetButton(action: NextPageIntent()) {
                Label("Avançar página", systemImage: "arrow.right")
            }
        }
        .displayName("Avançar página")
        .description("Avança uma página no Kindle.")
    }
}

@available(iOS 18.0, *)
struct PreviousPageControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.soturnna.folio.control.previous") {
            ControlWidgetButton(action: PreviousPageIntent()) {
                Label("Voltar página", systemImage: "arrow.left")
            }
        }
        .displayName("Voltar página")
        .description("Volta uma página no Kindle.")
    }
}
