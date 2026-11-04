
import Foundation

final class Asignatura: Codable, Identifiable {

    var id: Int
    var nombre: String
    var salon: String
    var horario: String

    init(
        id: Int = 0,
        nombre: String,
        salon: String = "",
        horario: String = ""
    ) {
        self.id = id
        self.nombre = nombre
        self.salon = salon
        self.horario = horario
    }
}
