
import SwiftUI

@main
struct StudyHubApp: App {

    init() {
        _ = ProgramadorNotificacionesEvento.shared
    }

    var body: some Scene {
        WindowGroup {
            AppNavigation()
                .aplicarTemaStudyHub()
                .preferredColorScheme(.dark)
        }
    }
}
