
import Foundation
import Combine

@MainActor
final class CalificacionViewModel: ObservableObject {

    @Published private(set) var calificaciones: [Calificacion] = []
    @Published private(set) var error: String?

    private let repository: CalificacionRepository

    init(repository: CalificacionRepository? = nil) {
        self.repository = repository ?? CalificacionRepository()
        cargarCalificaciones()
    }

    func cargarCalificaciones() {
        do {
            calificaciones = try repository.obtenerTodas()
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    func agregar(
        asignaturaId: Int,
        nota: Double,
        porcentaje: Int,
        descripcion: String,
        fecha: Int64
    ) {
        let calificacion = Calificacion(
            asignaturaId: asignaturaId,
            nota: nota,
            porcentaje: porcentaje,
            descripcion: descripcion,
            fecha: fecha
        )

        do {
            try repository.agregar(calificacion)
            cargarCalificaciones()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func editar(_ calificacion: Calificacion) {
        do {
            try repository.editar(calificacion)
            cargarCalificaciones()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func eliminar(_ calificacion: Calificacion) {
        do {
            try repository.eliminar(calificacion)
            cargarCalificaciones()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func obtenerPorAsignatura(
        _ asignaturaId: Int
    ) -> [Calificacion] {
        do {
            return try repository.obtenerPorAsignatura(asignaturaId)
        } catch {
            self.error = error.localizedDescription
            return []
        }
    }

    func obtenerPorcentajeUsado(
        asignaturaId: Int
    ) -> Int {
        do {
            return try repository.obtenerPorcentajeUsado(asignaturaId)
        } catch {
            self.error = error.localizedDescription
            return 0
        }
    }
}

