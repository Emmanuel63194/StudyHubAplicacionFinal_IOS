
import Foundation

@MainActor
final class CuestionarioRepository {

    private let archivoURL: URL

    init() {
        let directorio = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]

        archivoURL = directorio.appendingPathComponent(
            "cuestionarios.json"
        )
    }

    private func cargar() throws -> [Cuestionario] {
        guard FileManager.default.fileExists(
            atPath: archivoURL.path
        ) else {
            return []
        }

        let datos = try Data(contentsOf: archivoURL)
        return try JSONDecoder().decode(
            [Cuestionario].self,
            from: datos
        )
    }

    private func guardar(
        _ cuestionarios: [Cuestionario]
    ) throws {
        let datos = try JSONEncoder().encode(cuestionarios)

        try datos.write(
            to: archivoURL,
            options: .atomic
        )
    }

    func insertar(_ cuestionario: Cuestionario) throws -> Int64 {
        var cuestionarios = try cargar()

        let siguienteId = (cuestionarios.map(\.id).max() ?? 0) + 1
        cuestionario.id = siguienteId

        cuestionarios.append(cuestionario)
        try guardar(cuestionarios)

        return cuestionario.id
    }

    func actualizar(_ cuestionario: Cuestionario) throws {
        var cuestionarios = try cargar()

        guard let indice = cuestionarios.firstIndex(
            where: { $0.id == cuestionario.id }
        ) else {
            return
        }

        cuestionarios[indice] = cuestionario
        try guardar(cuestionarios)
    }

    func eliminar(_ cuestionario: Cuestionario) throws {
        var cuestionarios = try cargar()

        cuestionarios.removeAll {
            $0.id == cuestionario.id
        }

        try guardar(cuestionarios)
    }

    func obtenerTodos() throws -> [Cuestionario] {
        let cuestionarios = try cargar()

        return cuestionarios.sorted {
            $0.id > $1.id
        }
    }

    func obtenerPorId(
        _ cuestionarioId: Int64
    ) throws -> Cuestionario? {
        let cuestionarios = try cargar()

        return cuestionarios.first {
            $0.id == cuestionarioId
        }
    }
}

