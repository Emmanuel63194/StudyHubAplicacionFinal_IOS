
import Foundation
import Combine

@MainActor
final class CalendarioViewModel: ObservableObject {

    @Published private(set) var eventos: [Calendario] = []
    @Published private(set) var eventosCompletados: Set<Int64> = []
    @Published private(set) var error: String?

    private let repository: CalendarioRepository
    private let programadorNotificaciones =
        ProgramadorNotificacionesEvento.shared

    init(repository: CalendarioRepository? = nil) {
        self.repository = repository ?? CalendarioRepository()
        cargarEventos()
    }

    func cargarEventos() {
        do {
            eventos = try repository.obtenerTodos()
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    func alternarCompletado(eventoId: Int64) {
        if eventosCompletados.contains(eventoId) {
            eventosCompletados.remove(eventoId)
        } else {
            eventosCompletados.insert(eventoId)
        }
    }

    func guardarEvento(_ evento: Calendario) {
        do {
            let eventoId: Int64

            if evento.id == 0 {
                eventoId = try repository.insertar(evento)
            } else {
                try repository.actualizar(evento)
                eventoId = evento.id
            }

            cargarEventos()

            guard let eventoGuardado =
                try repository.obtenerPorId(eventoId) else {
                return
            }

            Task {
                await programarNotificacionParaEvento(eventoGuardado)
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func eliminarEvento(_ evento: Calendario) {
        do {
            try repository.eliminar(evento)

            programadorNotificaciones.cancelar(
                eventoId: evento.id
            )

            eventosCompletados.remove(evento.id)
            cargarEventos()
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func programarNotificacionParaEvento(
        _ evento: Calendario
    ) async {
        guard let fechaEvento = construirFechaEvento(
            fecha: evento.fecha,
            hora: evento.hora
        ) else {
            programadorNotificaciones.cancelar(
                eventoId: evento.id
            )
            return
        }

        do {
            let programada =
                try await programadorNotificaciones.programar(
                    eventoId: evento.id,
                    titulo: evento.titulo,
                    nota: evento.nota,
                    fecha: fechaEvento
                )

            if !programada {
                print(
                    "No se programó una notificación para el evento \(evento.id). Puede tener una fecha pasada o faltar permiso."
                )
            }
        } catch {
            self.error =
                "El evento se guardó, pero no se pudo programar su notificación: \(error.localizedDescription)"
        }
    }

    private func construirFechaEvento(
        fecha: Int64,
        hora: Int
    ) -> Date? {
        guard (0..<1440).contains(hora) else {
            return nil
        }

        let fechaGuardada = Date(
            timeIntervalSince1970: Double(fecha) / 1000.0
        )

        let calendario = Calendar.current

        guard let inicioDelDia = calendario.dateInterval(
            of: .day,
            for: fechaGuardada
        )?.start else {
            return nil
        }

        return calendario.date(
            byAdding: .minute,
            value: hora,
            to: inicioDelDia
        )
    }
}

