
import Foundation

final class Calendario: Codable, Identifiable {
    var id: Int64
    var titulo: String
    var fecha: Int64
    var hora: Int
    var nota: String

    init(
        id: Int64 = 0,
        titulo: String,
        fecha: Int64,
        hora: Int,
        nota: String
    ) {
        self.id = id
        self.titulo = titulo
        self.fecha = fecha
        self.hora = hora
        self.nota = nota
    }
}

