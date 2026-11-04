
import Foundation

@MainActor
final class CalificacionRepository {

    private let archivoURL: URL

    init() {
        let directorio = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]

        archivoURL = directorio.appendingPathComponent(
            "calificaciones.json"
        )
    }

    private func cargar() throws -> [Calificacion] {
        guard FileManager.default.fileExists(
            atPath: archivoURL.path
        ) else {
            return []
        }

        let datos = try Data(contentsOf: archivoURL)

        return try JSONDecoder().decode(
            [Calificacion].self,
            from: datos
        )
    }

    private func guardar(
        _ calificaciones: [Calificacion]
    ) throws {
        let datos = try JSONEncoder().encode(calificaciones)

        try datos.write(
            to: archivoURL,
            options: .atomic
        )
    }

    func agregar(_ calificacion: Calificacion) throws {
        var calificaciones = try cargar()

        let maximoID = calificaciones.map(\.id).max() ?? 0
        calificacion.id = max(maximoID, 0) + 1

        calificaciones.append(calificacion)

        try guardar(calificaciones)
    }

    func editar(_ calificacion: Calificacion) throws {
        var calificaciones = try cargar()

        guard let indice = calificaciones.firstIndex(
            where: { $0.id == calificacion.id }
        ) else {
            return
        }

        calificaciones[indice] = calificacion
        try guardar(calificaciones)
    }

    func eliminar(_ calificacion: Calificacion) throws {
        var calificaciones = try cargar()

        calificaciones.removeAll {
            $0.id == calificacion.id
        }

        try guardar(calificaciones)
    }

    func obtenerTodas() throws -> [Calificacion] {
        try cargar().sorted {
            $0.fecha > $1.fecha
        }
    }

    func obtenerPorAsignatura(
        _ asignaturaId: Int
    ) throws -> [Calificacion] {
        try cargar()
            .filter { $0.asignaturaId == asignaturaId }
            .sorted { $0.fecha > $1.fecha }
    }

    func obtenerPorId(_ id: Int) throws -> Calificacion? {
        try cargar().first {
            $0.id == id
        }
    }

    func obtenerPorcentajeUsado(
        _ asignaturaId: Int
    ) throws -> Int {
        try obtenerPorAsignatura(asignaturaId)
            .reduce(0) { total, calificacion in
                total + calificacion.porcentaje
            }
    }

    func eliminarPorAsignatura(
        _ asignaturaId: Int
    ) throws {
        var calificaciones = try cargar()

        calificaciones.removeAll {
            $0.asignaturaId == asignaturaId
        }

        try guardar(calificaciones)
    }
}

