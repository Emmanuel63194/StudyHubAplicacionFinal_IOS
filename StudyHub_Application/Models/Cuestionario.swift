
import Foundation

struct RespuestaCuestionario: Codable {
    var texto: String
    var esCorrecta: Bool = false
}

struct PreguntaCuestionario: Codable {
    var texto: String
    var respuestas: [RespuestaCuestionario]
}

final class Cuestionario: Codable, Identifiable {
    var id: Int64
    var titulo: String
    var preguntasData: Data

    var preguntas: [PreguntaCuestionario] {
        get {
            (try? JSONDecoder().decode(
                [PreguntaCuestionario].self,
                from: preguntasData
            )) ?? []
        }
        set {
            preguntasData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    var cantidadPreguntas: Int {
        preguntas.count
    }

    init(
        id: Int64 = 0,
        titulo: String,
        preguntas: [PreguntaCuestionario] = []
    ) {
        self.id = id
        self.titulo = titulo
        self.preguntasData = (try? JSONEncoder().encode(preguntas)) ?? Data()
    }
}

