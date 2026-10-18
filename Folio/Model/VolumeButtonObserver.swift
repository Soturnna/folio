import AVFoundation
import MediaPlayer
import SwiftUI

/// Transforma os botões de volume em botões de virar página.
///
/// Como funciona: o iOS não avisa diretamente quando um botão de volume
/// é pressionado, mas avisa quando o volume MUDA. Observamos essa mudança
/// (KVO em `outputVolume`), decidimos se foi para cima ou para baixo e
/// devolvemos o volume ao valor de referência, para que os botões nunca
/// "travem" no máximo ou no mínimo.
/// Limitação do iOS: só funciona com o app aberto e a tela ligada.
@MainActor
final class VolumeButtonObserver: ObservableObject {
    var onUp: (() -> Void)?
    var onDown: (() -> Void)?

    private var observation: NSKeyValueObservation?
    private var baseline: Float = 0.5
    private var isResetting = false
    fileprivate weak var slider: UISlider?

    func start() {
        guard observation == nil else { return }
        let audio = AVAudioSession.sharedInstance()
        // .ambient + mixWithOthers: não interrompe música ou audiolivro tocando.
        try? audio.setCategory(.ambient, options: [.mixWithOthers])
        try? audio.setActive(true)

        baseline = audio.outputVolume
        if baseline > 0.9 || baseline < 0.1 {
            baseline = 0.5
            setVolume(baseline)
        }

        observation = audio.observe(\.outputVolume, options: [.new]) { [weak self] _, change in
            guard let value = change.newValue else { return }
            Task { @MainActor in self?.handle(value) }
        }
    }

    func stop() {
        observation?.invalidate()
        observation = nil
    }

    private func handle(_ value: Float) {
        if isResetting {
            isResetting = false
            return
        }
        guard abs(value - baseline) > 0.001 else { return }
        if value > baseline { onUp?() } else { onDown?() }
        setVolume(baseline)
    }

    private func setVolume(_ value: Float) {
        guard let slider else { return }
        isResetting = true
        // Pequeno atraso: o MPVolumeView ignora mudanças feitas no mesmo ciclo.
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(50))
            slider.value = value
        }
    }
}

/// Um MPVolumeView invisível. Mantê-lo na tela faz o iOS esconder o
/// indicador de volume do sistema e nos dá o controle (slider) para
/// restaurar o volume de referência.
struct HiddenVolumeView: UIViewRepresentable {
    let observer: VolumeButtonObserver

    func makeUIView(context: Context) -> MPVolumeView {
        let view = MPVolumeView(frame: CGRect(x: -200, y: -200, width: 10, height: 10))
        view.alpha = 0.01
        view.isUserInteractionEnabled = false
        Task { @MainActor in
            observer.slider = view.subviews.compactMap { $0 as? UISlider }.first
        }
        return view
    }

    func updateUIView(_ uiView: MPVolumeView, context: Context) {}
}
