import SwiftUI
import WidgetKit

/// Ponto de entrada da extensão: reúne a Live Activity e os controles.
@main
struct FolioWidgetsBundle: WidgetBundle {
    var body: some Widget {
        FolioLiveActivity()
        if #available(iOS 18.0, *) {
            NextPageControl()
            PreviousPageControl()
        }
    }
}
