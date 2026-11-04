
import Foundation

final class Calificacion: Codable, Identifiable {
    var id: Int
    var asignaturaId: Int
    var nota: Double
    var porcentaje: Int
    var descripcion: String
    var fecha: Int64

    init(
        id: Int = 0,
        asignaturaId: Int,
        nota: Double,
        porcentaje: Int,
        descripcion: String,
        fecha: Int64
    ) {
        self.id = id
        self.asignaturaId = asignaturaId
        self.nota = nota
        self.porcentaje = porcentaje
        self.descripcion = descripcion
        self.fecha = fecha
    }
}

