
import Foundation
import Combine

@MainActor
final class AsignaturaViewModel: ObservableObject {

    @Published private(set) var asignaturas: [Asignatura] = []
    @Published private(set) var error: String?

    private let asignaturaRepository: AsignaturaRepository
    private let calificacionRepository: CalificacionRepository

    init(
        asignaturaRepository: AsignaturaRepository? = nil,
        calificacionRepository: CalificacionRepository? = nil
    ) {
        self.asignaturaRepository =
            asignaturaRepository ?? AsignaturaRepository()

        self.calificacionRepository =
            calificacionRepository ?? CalificacionRepository()

        cargarAsignaturas()
    }

    func cargarAsignaturas() {
        do {
            asignaturas = try asignaturaRepository.obtenerTodas()
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    @discardableResult
    func agregar(
        nombre: String,
        salon: String,
        horario: String = ""
    ) -> Bool {
        let asignatura = Asignatura(
            nombre: nombre,
            salon: salon,
            horario: horario
        )

        do {
            try asignaturaRepository.agregar(asignatura)
            cargarAsignaturas()

            guard error == nil else {
                return false
            }

            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    @discardableResult
    func editar(_ asignatura: Asignatura) -> Bool {
        do {
            try asignaturaRepository.editar(asignatura)
            cargarAsignaturas()

            guard error == nil else {
                return false
            }

            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func eliminar(_ asignatura: Asignatura) {
        do {
            try calificacionRepository.eliminarPorAsignatura(
                asignatura.id
            )

            try asignaturaRepository.eliminar(asignatura)

            cargarAsignaturas()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

