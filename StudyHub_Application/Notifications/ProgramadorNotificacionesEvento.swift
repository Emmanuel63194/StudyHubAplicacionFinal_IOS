import Foundation
import UserNotifications

final class ProgramadorNotificacionesEvento: NSObject, UNUserNotificationCenterDelegate {

    static let shared = ProgramadorNotificacionesEvento()

    static let eventoAbrirCalendario = Notification.Name(
        "StudyHubAbrirCalendarioDesdeNotificacion"
    )

    private let centro = UNUserNotificationCenter.current()
    private let prefijoIdentificador = "evento_calendario_"

    private override init() {
        super.init()
        centro.delegate = self
    }

    func solicitarPermiso() async throws -> Bool {
        try await centro.requestAuthorization(
            options: [.alert, .sound, .badge]
        )
    }

    func programar(
        eventoId: Int64,
        titulo: String,
        nota: String,
        fecha: Date
    ) async throws -> Bool {
        cancelar(eventoId: eventoId)

        guard fecha > Date() else {
            return false
        }

        let configuracion = await centro.notificationSettings()
        let autorizado: Bool

        switch configuracion.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            autorizado = true

        case .notDetermined:
            autorizado = try await solicitarPermiso()

        case .denied:
            autorizado = false

        @unknown default:
            autorizado = false
        }

        guard autorizado else {
            return false
        }

        let contenido = UNMutableNotificationContent()
        contenido.title = titulo
        contenido.body = nota.isEmpty
            ? "Tienes un evento programado."
            : nota
        contenido.sound = .default
        contenido.userInfo = [
            "evento_id": eventoId,
            "destino": "calendario"
        ]

        let componentes = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: fecha
        )

        let disparador = UNCalendarNotificationTrigger(
            dateMatching: componentes,
            repeats: false
        )

        let solicitud = UNNotificationRequest(
            identifier: identificador(eventoId),
            content: contenido,
            trigger: disparador
        )

        try await centro.add(solicitud)
        return true
    }

    func cancelar(eventoId: Int64) {
        let id = identificador(eventoId)

        centro.removePendingNotificationRequests(
            withIdentifiers: [id]
        )

        centro.removeDeliveredNotifications(
            withIdentifiers: [id]
        )
    }

    func cancelarTodas() {
        centro.removeAllPendingNotificationRequests()
        centro.removeAllDeliveredNotifications()
    }

    func recuperarNotificacionesPendientes() async {
        let pendientes = await centro.pendingNotificationRequests()

        print(
            "Notificaciones pendientes de StudyHub: \(pendientes.count)"
        )
    }

    private func identificador(_ eventoId: Int64) -> String {
        "\(prefijoIdentificador)\(eventoId)"
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
            @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let datos = response.notification.request.content.userInfo

        let eventoId: Int64?

        if let id = datos["evento_id"] as? Int64 {
            eventoId = id
        } else if let numero = datos["evento_id"] as? NSNumber {
            eventoId = numero.int64Value
        } else {
            eventoId = nil
        }

        if let eventoId {
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: Self.eventoAbrirCalendario,
                    object: nil,
                    userInfo: ["evento_id": eventoId]
                )
            }
        }

        completionHandler()
    }
}

