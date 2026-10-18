import AVFoundation
import MediaPlayer
import UIKit

/// Controle por fones e mídia.
///
/// Ideia: o iOS só entrega os botões de mídia (⏮ ⏭ da tela bloqueada,
/// toque duplo dos AirPods, botão do fone Bluetooth) ao app que está
/// "tocando" algo. Então o Folio toca um áudio de SILÊNCIO em loop e
/// traduz "próxima faixa" em "próxima página".
/// Custo: interrompe outra música e gasta um pouco mais de bateria.
@MainActor
final class MediaRemoteController {
    static let shared = MediaRemoteController()

    private var player: AVAudioPlayer?
    private var targets: [Any] = []
    private(set) var isRunning = false

    func start() {
        guard !isRunning else { return }
        let audio = AVAudioSession.sharedInstance()
        do {
            // .playback SEM mixWithOthers: só assim o iOS nos considera
            // o app "tocando agora" e mostra os controles na tela bloqueada.
            try audio.setCategory(.playback, mode: .default, options: [])
            try audio.setActive(true)
            let player = try AVAudioPlayer(data: Self.silentWAV())
            player.numberOfLoops = -1
            player.volume = 0
            player.play()
            self.player = player
        } catch {
            return
        }
        isRunning = true
        registerCommands()
        refresh(pages: KindleController.shared.pagesThisSession)
    }

    func stop() {
        guard isRunning else { return }
        player?.stop()
        player = nil
        let center = MPRemoteCommandCenter.shared()
        for target in targets {
            center.nextTrackCommand.removeTarget(target)
            center.previousTrackCommand.removeTarget(target)
            center.togglePlayPauseCommand.removeTarget(target)
            center.playCommand.removeTarget(target)
            center.pauseCommand.removeTarget(target)
        }
        targets = []
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        isRunning = false
    }

    /// Atualiza o cartão "tocando agora" com a página atual.
    func refresh(pages: Int) {
        guard isRunning else { return }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: "Página \(pages)",
            MPMediaItemPropertyArtist: "Folio · Kindle",
            MPNowPlayingInfoPropertyPlaybackRate: 1.0,
            MPNowPlayingInfoPropertyIsLiveStream: true
        ]
        if let art = UIImage(named: "NowPlayingArt") {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: art.size) { _ in art }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func registerCommands() {
        let center = MPRemoteCommandCenter.shared()
        let invert = { SettingsDefaults.bool(SettingsKey.invert, default: false) }

        targets.append(center.nextTrackCommand.addTarget { _ in
            Task { @MainActor in await KindleController.shared.turn(invert() ? .previous : .next) }
            return .success
        })
        targets.append(center.previousTrackCommand.addTarget { _ in
            Task { @MainActor in await KindleController.shared.turn(invert() ? .next : .previous) }
            return .success
        })
        // Play/pausa não fazem nada, mas precisam responder para o
        // sistema manter o Folio como app de mídia ativo.
        for command in [center.togglePlayPauseCommand, center.playCommand, center.pauseCommand] {
            targets.append(command.addTarget { _ in .success })
        }
        center.nextTrackCommand.isEnabled = true
        center.previousTrackCommand.isEnabled = true
        center.skipForwardCommand.isEnabled = false
        center.skipBackwardCommand.isEnabled = false
        center.changePlaybackPositionCommand.isEnabled = false
    }

    /// Gera 1 segundo de silêncio em formato WAV (44 bytes de cabeçalho + zeros).
    private static func silentWAV() -> Data {
        let sampleRate: UInt32 = 8000
        let samples = Int(sampleRate)
        let dataSize = UInt32(samples * 2)
        var data = Data()
        func append<T: FixedWidthInteger>(_ value: T) {
            withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
        }
        data.append(contentsOf: Array("RIFF".utf8)); append(UInt32(36) + dataSize)
        data.append(contentsOf: Array("WAVE".utf8))
        data.append(contentsOf: Array("fmt ".utf8)); append(UInt32(16))
        append(UInt16(1)); append(UInt16(1))            // PCM, mono
        append(sampleRate); append(sampleRate * 2)      // taxa, bytes por segundo
        append(UInt16(2)); append(UInt16(16))           // alinhamento, bits
        data.append(contentsOf: Array("data".utf8)); append(dataSize)
        data.append(Data(count: Int(dataSize)))
        return data
    }
}
