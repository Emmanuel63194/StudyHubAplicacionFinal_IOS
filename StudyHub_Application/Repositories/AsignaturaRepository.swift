
import Foundation

@MainActor
final class AsignaturaRepository {

    private let archivoURL: URL

    init() {
        let directorio = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]

        archivoURL = directorio.appendingPathComponent(
            "asignaturas.json"
        )
    }

    private func cargarArchivo() throws -> [Asignatura] {
        guard FileManager.default.fileExists(
            atPath: archivoURL.path
        ) else {
            return []
        }

        let datos = try Data(contentsOf: archivoURL)

        return try JSONDecoder().decode(
            [Asignatura].self,
            from: datos
        )
    }

    private func guardar(
        _ asignaturas: [Asignatura]
    ) throws {
        let datos = try JSONEncoder().encode(asignaturas)

        try datos.write(
            to: archivoURL,
            options: .atomic
        )
    }

    /// Devuelve las asignaturas y repara identificadores duplicados.
    func obtenerTodas() throws -> [Asignatura] {
        var asignaturas = try cargarArchivo()
        var identificadores = Set<Int>()
        var siguienteID = max(
            asignaturas.map(\.id).max() ?? 0,
            0
        ) + 1

        var huboCambios = false

        for asignatura in asignaturas {
            if identificadores.contains(asignatura.id) {
                while identificadores.contains(siguienteID) {
                    siguienteID += 1
                }

                asignatura.id = siguienteID
                identificadores.insert(siguienteID)
                siguienteID += 1
                huboCambios = true
            } else {
                identificadores.insert(asignatura.id)
            }
        }

        if huboCambios {
            try guardar(asignaturas)
        }

        return asignaturas
    }

    /// Agrega una asignatura con un ID único.
    func agregar(_ asignatura: Asignatura) throws {
        var asignaturas = try obtenerTodas()

        let maximoID = asignaturas.map(\.id).max() ?? 0
        let nuevoID = max(maximoID, 0) + 1

        asignatura.id = nuevoID
        asignaturas.append(asignatura)

        try guardar(asignaturas)
    }

    func editar(_ asignatura: Asignatura) throws {
        var asignaturas = try obtenerTodas()

        guard let indice = asignaturas.firstIndex(
            where: { $0.id == asignatura.id }
        ) else {
            throw NSError(
                domain: "AsignaturaRepository",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "No se encontró la asignatura que deseas editar."
                ]
            )
        }

        asignaturas[indice] = asignatura
        try guardar(asignaturas)
    }

    func eliminar(_ asignatura: Asignatura) throws {
        var asignaturas = try obtenerTodas()

        let cantidadAnterior = asignaturas.count

        asignaturas.removeAll {
            $0.id == asignatura.id
        }

        guard asignaturas.count < cantidadAnterior else {
            throw NSError(
                domain: "AsignaturaRepository",
                code: 2,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "No se encontró la asignatura que deseas eliminar."
                ]
            )
        }

        try guardar(asignaturas)
    }
}
