
import Foundation

@MainActor
final class CalendarioRepository {

    private let archivoURL: URL

    init() {
        let directorio = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]

        archivoURL = directorio.appendingPathComponent(
            "eventos_calendario.json"
        )
    }

    private func cargar() throws -> [Calendario] {
        guard FileManager.default.fileExists(
            atPath: archivoURL.path
        ) else {
            return []
        }

        let datos = try Data(contentsOf: archivoURL)

        return try JSONDecoder().decode(
            [Calendario].self,
            from: datos
        )
    }

    private func guardar(_ eventos: [Calendario]) throws {
        let datos = try JSONEncoder().encode(eventos)

        try datos.write(
            to: archivoURL,
            options: .atomic
        )
    }

    func insertar(_ evento: Calendario) throws -> Int64 {
        var eventos = try cargar()

        let siguienteId = (eventos.map(\.id).max() ?? 0) + 1
        evento.id = siguienteId

        eventos.append(evento)
        try guardar(eventos)

        return evento.id
    }

    func actualizar(_ evento: Calendario) throws {
        var eventos = try cargar()

        guard let indice = eventos.firstIndex(
            where: { $0.id == evento.id }
        ) else {
            throw NSError(
                domain: "CalendarioRepository",
                code: 404,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "No se encontró el evento que se intenta actualizar."
                ]
            )
        }

        eventos[indice].titulo = evento.titulo
        eventos[indice].fecha = evento.fecha
        eventos[indice].hora = evento.hora
        eventos[indice].nota = evento.nota

        try guardar(eventos)
    }

    func eliminar(_ evento: Calendario) throws {
        var eventos = try cargar()

        eventos.removeAll {
            $0.id == evento.id
        }

        try guardar(eventos)
    }

    func obtenerTodos() throws -> [Calendario] {
        return try cargar().sorted {
            if $0.fecha != $1.fecha {
                return $0.fecha < $1.fecha
            }

            if $0.hora != $1.hora {
                return $0.hora < $1.hora
            }

            return $0.id < $1.id
        }
    }

    func obtenerPorId(_ eventoId: Int64) throws -> Calendario? {
        return try cargar().first {
            $0.id == eventoId
        }
    }

    func obtenerTodosUnaVez() throws -> [Calendario] {
        return try cargar()
    }
}

