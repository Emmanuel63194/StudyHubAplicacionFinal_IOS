
import Foundation
import Combine

@MainActor
final class CuestionarioViewModel: ObservableObject {

    @Published private(set) var cuestionarios: [Cuestionario] = []
    @Published var titulo: String = ""
    @Published var preguntas: [PreguntaCuestionario] = []
    @Published var intentoCrear: Bool = false
    @Published private(set) var error: String?

    private let repository: CuestionarioRepository

    init(repository: CuestionarioRepository? = nil) {
        self.repository = repository ?? CuestionarioRepository()
        self.preguntas = [crearPreguntaVacia()]
        cargarCuestionarios()
    }

    func cargarCuestionarios() {
        do {
            cuestionarios = try repository.obtenerTodos()
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    func eliminarCuestionario(_ cuestionario: Cuestionario) {
        do {
            try repository.eliminar(cuestionario)
            cargarCuestionarios()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func actualizarTitulo(_ nuevoTitulo: String) {
        titulo = nuevoTitulo
    }

    func crearPreguntaVacia() -> PreguntaCuestionario {
        PreguntaCuestionario(
            texto: "",
            respuestas: Array(
                repeating: RespuestaCuestionario(
                    texto: "",
                    esCorrecta: false
                ),
                count: 3
            )
        )
    }

    func cargarCuestionarioParaEditar(_ cuestionario: Cuestionario) {
        titulo = cuestionario.titulo
        preguntas = cuestionario.preguntas
        intentoCrear = false
        error = nil
    }

    func agregarPregunta() {
        preguntas.append(crearPreguntaVacia())
    }

    func eliminarPregunta(indice: Int) {
        guard indice >= 1, indice < preguntas.count else {
            return
        }

        preguntas.remove(at: indice)
    }

    func actualizarTextoPregunta(
        indicePregunta: Int,
        texto: String
    ) {
        modificarPregunta(indicePregunta) { pregunta in
            var actualizada = pregunta
            actualizada.texto = texto
            return actualizada
        }
    }

    func actualizarTextoRespuesta(
        indicePregunta: Int,
        indiceRespuesta: Int,
        texto: String
    ) {
        modificarPregunta(indicePregunta) { pregunta in
            var actualizada = pregunta

            guard actualizada.respuestas.indices.contains(indiceRespuesta)
            else {
                return actualizada
            }

            actualizada.respuestas[indiceRespuesta].texto = texto
            return actualizada
        }
    }

    func marcarRespuestaCorrecta(
        indicePregunta: Int,
        indiceRespuesta: Int
    ) {
        modificarPregunta(indicePregunta) { pregunta in
            var actualizada = pregunta

            guard actualizada.respuestas.indices.contains(indiceRespuesta)
            else {
                return actualizada
            }

            for indice in actualizada.respuestas.indices {
                actualizada.respuestas[indice].esCorrecta =
                    indice == indiceRespuesta
            }

            return actualizada
        }
    }

    func eliminarRespuesta(
        indicePregunta: Int,
        indiceRespuesta: Int
    ) {
        modificarPregunta(indicePregunta) { pregunta in
            var actualizada = pregunta

            guard actualizada.respuestas.count == 3,
                  indiceRespuesta == 2 else {
                return actualizada
            }

            actualizada.respuestas.remove(at: indiceRespuesta)
            return actualizada
        }
    }

    private func modificarPregunta(
        _ indice: Int,
        transformacion: (PreguntaCuestionario) -> PreguntaCuestionario
    ) {
        guard preguntas.indices.contains(indice) else {
            return
        }

        preguntas[indice] = transformacion(preguntas[indice])
    }

    func tituloEsValido() -> Bool {
        !titulo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func mensajeErrorPregunta(
        _ pregunta: PreguntaCuestionario
    ) -> String? {
        let falta = pregunta.texto
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty

        let faltanRespuestas = pregunta.respuestas.filter {
            !$0.texto.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }.count < 2

        let faltaCorrecta = !pregunta.respuestas.contains { respuesta in
            respuesta.esCorrecta &&
            !respuesta.texto
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty
        }

        switch (falta, faltanRespuestas, faltaCorrecta) {
        case (true, true, true):
            return "(Falta la pregunta, 2 respuestas, opción correcta)"
        case (true, false, false):
            return "(Falta la pregunta)"
        case (false, true, false):
            return "(Faltan 2 respuestas)"
        case (false, false, true):
            return "(Falta la opción correcta)"
        case (true, true, false):
            return "(Falta la pregunta, 2 respuestas)"
        case (true, false, true):
            return "(Falta la pregunta, opción correcta)"
        case (false, true, true):
            return "(Faltan 2 respuestas, opción correcta)"
        default:
            return nil
        }
    }

    func preguntaEsValida(_ pregunta: PreguntaCuestionario) -> Bool {
        mensajeErrorPregunta(pregunta) == nil
    }

    func intentarCrear(
        onGuardado: (Int64) -> Void = { _ in }
    ) {
        intentoCrear = true
        guardarCuestionario(onGuardado: onGuardado)
    }

    func guardarCuestionario(
        onGuardado: (Int64) -> Void = { _ in }
    ) {
        // Si el título está vacío, no se guarda ni se genera el mensaje anterior.
        // La vista muestra "(Falta el nombre del cuestionario)" junto a Nombre:.
        guard tituloEsValido() else {
            return
        }

        guard !preguntas.isEmpty else {
            error = "El cuestionario debe tener al menos una pregunta."
            return
        }

        guard preguntas.allSatisfy({ preguntaEsValida($0) }) else {
            error = "Completa cada pregunta con al menos dos respuestas y una opción correcta."
            return
        }

        let preguntasLimpias = limpiarPreguntas(preguntas)

        let cuestionario = Cuestionario(
            titulo: titulo.trimmingCharacters(in: .whitespacesAndNewlines),
            preguntas: preguntasLimpias
        )

        do {
            let id = try repository.insertar(cuestionario)
            cargarCuestionarios()
            onGuardado(id)
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    func guardarCuestionarioGenerado(
        titulo: String,
        preguntas: [PreguntaCuestionario],
        onGuardado: (Int64) -> Void = { _ in }
    ) {
        let tituloLimpio = titulo.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !tituloLimpio.isEmpty, !preguntas.isEmpty else {
            return
        }

        guard preguntas.allSatisfy({ preguntaEsValida($0) }) else {
            return
        }

        let cuestionario = Cuestionario(
            titulo: tituloLimpio,
            preguntas: limpiarPreguntas(preguntas)
        )

        do {
            let id = try repository.insertar(cuestionario)
            cargarCuestionarios()
            onGuardado(id)
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    func editarCuestionario(
        _ cuestionario: Cuestionario,
        onGuardado: () -> Void = {}
    ) {
        intentoCrear = true

        // Si el título está vacío, no se edita ni se genera el mensaje anterior.
        guard tituloEsValido() else {
            return
        }

        guard !preguntas.isEmpty else {
            error = "El cuestionario debe tener al menos una pregunta."
            return
        }

        guard preguntas.allSatisfy({ preguntaEsValida($0) }) else {
            error = "Completa cada pregunta con al menos dos respuestas y una opción correcta."
            return
        }

        cuestionario.titulo = titulo.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        cuestionario.preguntas = limpiarPreguntas(preguntas)

        do {
            try repository.actualizar(cuestionario)
            cargarCuestionarios()
            error = nil
            onGuardado()
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func limpiarPreguntas(
        _ preguntas: [PreguntaCuestionario]
    ) -> [PreguntaCuestionario] {
        preguntas.map { pregunta in
            PreguntaCuestionario(
                texto: pregunta.texto.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
                respuestas: pregunta.respuestas
                    .filter {
                        !$0.texto.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty
                    }
                    .map { respuesta in
                        RespuestaCuestionario(
                            texto: respuesta.texto.trimmingCharacters(
                                in: .whitespacesAndNewlines
                            ),
                            esCorrecta: respuesta.esCorrecta
                        )
                    }
            )
        }
    }
}

