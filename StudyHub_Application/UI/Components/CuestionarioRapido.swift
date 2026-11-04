import SwiftUI
import Foundation

// MARK: - Configuración de OpenRouter

private enum OpenRouterConfig {
    static let apiURL = URL(
        string: "https://openrouter.ai/api/v1/chat/completions"
    )!

    static let model = "poolside/laguna-s-2.1:free"

    // Sustituye el marcador por una clave nueva y válida.
    // No compartas esta clave ni la subas a un repositorio público.
    static let apiKey = "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"
}

// MARK: - Resultado del cuestionario

private struct ResultadoCuestionarioGenerado {
    let titulo: String?
    let preguntas: [PreguntaCuestionario]?
    let mensaje: String
}

// MARK: - Modelos de OpenRouter

private struct OpenRouterRequest: Encodable {
    struct Message: Encodable {
        let role: String
        let content: String
    }

    let model: String
    let messages: [Message]
    let max_tokens: Int
}

private struct OpenRouterResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String?
            let reasoning: String?
            let refusal: String?
        }

        let message: Message?
        let finish_reason: String?
        let native_finish_reason: String?
    }

    struct APIError: Decodable {
        let message: String?
        let code: Int?
    }

    let choices: [Choice]?
    let error: APIError?
}

// MARK: - Modelos JSON del cuestionario

private struct CuestionarioJSON: Decodable {
    let titulo: String
    let preguntas: [PreguntaJSON]
}

private struct PreguntaJSON: Decodable {
    let pregunta: String
    let opciones: [String]
    let respuestaCorrecta: Int
}

// MARK: - Interfaz de cuestionario rápido

struct CuestionarioRapido: View {

    @ObservedObject var viewModel: CuestionarioViewModel

    var onCerrar: () -> Void = {}
    var onCuestionarioGuardado: () -> Void = {}

    @State private var contenido = ""
    @State private var cantidadPreguntas = ""
    @State private var mostrarErrorContenido = false
    @State private var mostrarErrorCantidad = false
    @State private var generando = false
    @State private var mensajeError: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {

                Text("Cuestionario instantáneo")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )

                VStack(alignment: .leading, spacing: 6) {

                    // MARK: - Contenido del tema

                    ZStack(alignment: .topLeading) {
                        if contenido.isEmpty {
                            Text(
                                mostrarErrorContenido
                                    ? "Falta contenido del tema"
                                    : "Digite el contenido del tema aquí"
                            )
                            .foregroundStyle(
                                mostrarErrorContenido
                                    ? Color.red
                                    : Color.gray
                            )
                            .padding(.horizontal, 5)
                            .padding(.vertical, 8)
                        }

                        TextEditor(text: $contenido)
                            .scrollContentBackground(.hidden)
                            .foregroundStyle(.white)
                            .disabled(generando)
                            .frame(minHeight: 145)
                            .padding(4)
                    }
                    .background(
                        Color(uiColor: .secondarySystemBackground)
                    )
                    .clipShape(
                        RoundedRectangle(cornerRadius: 10)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                mostrarErrorContenido
                                    ? Color.red
                                    : Color.clear,
                                lineWidth: 1
                            )
                    }
                    .onChange(of: contenido) { nuevoValor in
                        if !nuevoValor.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty {
                            mostrarErrorContenido = false
                        }
                    }

                    // MARK: - Cantidad de preguntas

                    ZStack(alignment: .leading) {
                        if cantidadPreguntas.isEmpty {
                            Text(
                                mostrarErrorCantidad
                                    ? "Falta número de preguntas"
                                    : "Digite la cantidad de preguntas"
                            )
                            .foregroundStyle(
                                mostrarErrorCantidad
                                    ? Color.red
                                    : Color.gray
                            )
                            .padding(.horizontal, 5)
                        }

                        TextField("", text: $cantidadPreguntas)
                            .keyboardType(.numberPad)
                            .foregroundStyle(.white)
                            .padding(12)
                    }
                    .background(
                        Color(uiColor: .secondarySystemBackground)
                    )
                    .clipShape(
                        RoundedRectangle(cornerRadius: 10)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                mostrarErrorCantidad
                                    ? Color.red
                                    : Color.clear,
                                lineWidth: 1
                            )
                    }
                    .disabled(generando)
                    .onChange(of: cantidadPreguntas) { nuevoValor in
                        let filtrado = String(
                            nuevoValor.filter(\.isNumber)
                        )

                        if filtrado != nuevoValor {
                            cantidadPreguntas = filtrado
                        }

                        if !filtrado.isEmpty {
                            mostrarErrorCantidad = false
                        }
                    }
                }

                // MARK: - Error de generación

                if let mensaje = mensajeError {
                    ScrollView {
                        Text(mensaje)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )
                            .textSelection(.enabled)
                    }
                    .frame(maxHeight: 130)
                }

                if let errorViewModel = viewModel.error {
                    Text(errorViewModel)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )
                }

                // MARK: - Botón de generación

                if generando {
                    ProgressView("Generando cuestionario...")
                        .tint(
                            Color(
                                red: 0.67,
                                green: 0.78,
                                blue: 1.0
                            )
                        )
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                } else {
                    Button(action: generarCuestionario) {
                        Text("Generar")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .frame(width: 130, height: 42)
                            .background(
                                Color(
                                    red: 0.67,
                                    green: 0.78,
                                    blue: 1.0
                                )
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 0)
            }
            .padding(20)
            .background(Color(uiColor: .systemBackground))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        guard !generando else { return }
                        onCerrar()
                    }
                    .disabled(generando)
                }
            }
        }
        .preferredColorScheme(.dark)
        .interactiveDismissDisabled(generando)
        .frame(minWidth: 300, minHeight: 380)
    }

    // MARK: - Generar cuestionario

    private func generarCuestionario() {

        let tema = contenido.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let cantidad = Int(cantidadPreguntas)

        mostrarErrorContenido = tema.isEmpty
        mostrarErrorCantidad = cantidad == nil || cantidad! <= 0
        mensajeError = nil

        guard
            !mostrarErrorContenido,
            !mostrarErrorCantidad,
            let cantidad,
            cantidad > 0
        else {
            return
        }

        generando = true

        Task {
            let resultado = await generarCuestionarioOpenRouter(
                texto: tema,
                cantidadPreguntas: cantidad
            )

            await MainActor.run {
                guard
                    let titulo = resultado.titulo,
                    let preguntas = resultado.preguntas
                else {
                    mensajeError = resultado.mensaje
                    generando = false
                    return
                }

                viewModel.guardarCuestionarioGenerado(
                    titulo: titulo,
                    preguntas: preguntas
                ) { _ in
                    DispatchQueue.main.async {
                        onCuestionarioGuardado()
                    }
                }

                generando = false
            }
        }
    }
}


// MARK: - OpenRouter

private func generarCuestionarioOpenRouter(
    texto: String,
    cantidadPreguntas: Int
) async -> ResultadoCuestionarioGenerado {

    let apiKey = OpenRouterConfig.apiKey.trimmingCharacters(
        in: .whitespacesAndNewlines
    )

    guard !apiKey.isEmpty,
          apiKey != "TU_API_KEY_AQUI" else {
        return ResultadoCuestionarioGenerado(
            titulo: nil,
            preguntas: nil,
            mensaje: "Configura una API Key válida de OpenRouter antes de generar el cuestionario."
        )
    }

    let instrucciones = """
    A partir exclusivamente del texto de estudio proporcionado,
    genera un cuestionario.

    Primero genera un título breve y descriptivo relacionado
    directamente con el texto.

    Genera exactamente \(cantidadPreguntas) preguntas de selección
    múltiple.

    Cada pregunta debe tener exactamente 3 opciones y una única
    respuesta correcta.

    No inventes información que no aparezca o no pueda deducirse
    razonablemente del texto.

    Responde únicamente con un objeto JSON válido.
    No escribas explicaciones, Markdown ni bloques de código.
    No escribas texto antes ni después del JSON.

    Utiliza exactamente esta estructura:

    {
      "titulo": "Título del cuestionario",
      "preguntas": [
        {
          "pregunta": "Texto de la pregunta",
          "opciones": ["Opción A", "Opción B", "Opción C"],
          "respuestaCorrecta": 0
        }
      ]
    }

    respuestaCorrecta debe ser 0 para la primera opción,
    1 para la segunda y 2 para la tercera.

    TEXTO DE ESTUDIO:

    \(texto)
    """

    let solicitud = OpenRouterRequest(
        model: OpenRouterConfig.model,
        messages: [
            .init(
                role: "user",
                content: instrucciones
            )
        ],
        max_tokens: min(
            12000,
            max(2000, cantidadPreguntas * 400)
        )
    )

    do {
        var peticion = URLRequest(
            url: OpenRouterConfig.apiURL
        )

        peticion.httpMethod = "POST"
        peticion.timeoutInterval = 120

        peticion.setValue(
            "Bearer \(apiKey)",
            forHTTPHeaderField: "Authorization"
        )

        peticion.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        peticion.setValue(
            "application/json",
            forHTTPHeaderField: "Accept"
        )

        peticion.httpBody = try JSONEncoder().encode(solicitud)

        // MARK: Diagnóstico de la solicitud

        print("========== OPENROUTER: SOLICITUD ==========")
        print("URL:", peticion.url?.absoluteString ?? "Sin URL")
        print("Método:", peticion.httpMethod ?? "Sin método")
        print(
            "Authorization presente:",
            peticion.value(forHTTPHeaderField: "Authorization") != nil
        )
        print("Modelo:", OpenRouterConfig.model)
        print("Cantidad solicitada:", cantidadPreguntas)
        print("===========================================")

        // No imprimir la API key ni el encabezado Authorization.

        let (datos, respuesta) = try await URLSession.shared.data(
            for: peticion
        )

        guard let respuestaHTTP = respuesta as? HTTPURLResponse else {
            return ResultadoCuestionarioGenerado(
                titulo: nil,
                preguntas: nil,
                mensaje: "No se recibió una respuesta HTTP válida de OpenRouter."
            )
        }

        let respuestaTexto = String(
            data: datos,
            encoding: .utf8
        ) ?? ""

        // MARK: Diagnóstico de la respuesta

        print("========== OPENROUTER: RESPUESTA ==========")
        print("Código HTTP:", respuestaHTTP.statusCode)
        print("Respuesta completa:")
        print(respuestaTexto)
        print("===========================================")

        guard (200...299).contains(respuestaHTTP.statusCode) else {
            return ResultadoCuestionarioGenerado(
                titulo: nil,
                preguntas: nil,
                mensaje: """
                OpenRouter devolvió el error HTTP \(respuestaHTTP.statusCode).

                Detalle:
                \(respuestaTexto)
                """
            )
        }

        // Primero analizamos la respuesta como JSON genérico.
        // Así podemos detectar errores o campos ausentes sin depender
        // exclusivamente de la estructura Codable.

        guard let objeto = try JSONSerialization.jsonObject(
            with: datos
        ) as? [String: Any] else {
            return ResultadoCuestionarioGenerado(
                titulo: nil,
                preguntas: nil,
                mensaje: """
                OpenRouter respondió con HTTP \(respuestaHTTP.statusCode),
                pero el cuerpo recibido no es un objeto JSON válido.

                Revisa la consola de Xcode para ver la respuesta.
                """
            )
        }

        if let errorAPI = objeto["error"] as? [String: Any] {
            let detalle = errorAPI["message"] as? String
                ?? "OpenRouter no proporcionó detalles del error."

            return ResultadoCuestionarioGenerado(
                titulo: nil,
                preguntas: nil,
                mensaje: "OpenRouter informó un error: \(detalle)"
            )
        }

        guard let respuestaAPI = try? JSONDecoder().decode(
            OpenRouterResponse.self,
            from: datos
        ) else {
            return ResultadoCuestionarioGenerado(
                titulo: nil,
                preguntas: nil,
                mensaje: """
                No se pudo interpretar la estructura de la respuesta
                de OpenRouter.

                Código HTTP: \(respuestaHTTP.statusCode)

                Revisa la respuesta completa en la consola de Xcode.
                """
            )
        }

        guard let primeraOpcion = respuestaAPI.choices?.first else {
            return ResultadoCuestionarioGenerado(
                titulo: nil,
                preguntas: nil,
                mensaje: """
                OpenRouter respondió, pero no devolvió ninguna opción
                en el campo "choices".

                Revisa la respuesta completa en la consola de Xcode.
                """
            )
        }

        guard let mensaje = primeraOpcion.message else {
            return ResultadoCuestionarioGenerado(
                titulo: nil,
                preguntas: nil,
                mensaje: """
                OpenRouter devolvió una opción, pero no contiene
                el objeto "message".

                Revisa la respuesta completa en la consola de Xcode.
                """
            )
        }

        let contenidoGenerado = mensaje.content?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            ) ?? ""

        // MARK: Diagnóstico de contenido vacío

        guard !contenidoGenerado.isEmpty else {
            let motivo = primeraOpcion.finish_reason
                ?? "No especificado"

            let motivoProveedor = primeraOpcion.native_finish_reason
                ?? "No especificado"

            let tieneRazonamiento = !(mensaje.reasoning?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .isEmpty ?? true)

            let rechazo = mensaje.refusal?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                ) ?? ""

            print("========== CONTENIDO VACÍO ==========")
            print("finish_reason:", motivo)
            print("native_finish_reason:", motivoProveedor)
            print("¿Incluye reasoning?:", tieneRazonamiento)
            print("¿Incluye rechazo?:", !rechazo.isEmpty)
            print("=====================================")

            var detalle = """
            OpenRouter respondió, pero no devolvió contenido utilizable.

            Motivo de finalización: \(motivo)
            Motivo del proveedor: \(motivoProveedor)
            ¿Incluye razonamiento?: \(tieneRazonamiento)
            """

            if !rechazo.isEmpty {
                detalle += "\nMotivo de rechazo: \(rechazo)"
            }

            if tieneRazonamiento {
                detalle += """

                
                El modelo devolvió razonamiento, pero no el contenido
                del cuestionario. El razonamiento no se utilizará
                como sustituto del JSON.
                """
            }

            detalle += """

            
            Consulta la consola de Xcode para ver la respuesta
            completa de OpenRouter.
            """

            return ResultadoCuestionarioGenerado(
                titulo: nil,
                preguntas: nil,
                mensaje: detalle
            )
        }

        // MARK: Decodificar el cuestionario

        let datosJSON = Data(contenidoGenerado.utf8)

        let cuestionarioJSON: CuestionarioJSON

        do {
            cuestionarioJSON = try JSONDecoder().decode(
                CuestionarioJSON.self,
                from: datosJSON
            )
        } catch {
            print("========== JSON DEL CUESTIONARIO INVÁLIDO ==========")
            print("Error de decodificación:", error.localizedDescription)
            print("Contenido recibido:", contenidoGenerado)
            print("====================================================")

            return ResultadoCuestionarioGenerado(
                titulo: nil,
                preguntas: nil,
                mensaje: """
                OpenRouter devolvió contenido, pero no tiene el formato
                JSON esperado para el cuestionario.

                Error: \(error.localizedDescription)

                Revisa la consola de Xcode para consultar el contenido.
                """
            )
        }

        let titulo = cuestionarioJSON.titulo.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !titulo.isEmpty else {
            return ResultadoCuestionarioGenerado(
                titulo: nil,
                preguntas: nil,
                mensaje: "La IA no devolvió un título válido."
            )
        }

        guard cuestionarioJSON.preguntas.count == cantidadPreguntas else {
            return ResultadoCuestionarioGenerado(
                titulo: nil,
                preguntas: nil,
                mensaje: """
                La IA devolvió \(cuestionarioJSON.preguntas.count) preguntas,
                pero se solicitaron \(cantidadPreguntas).
                """
            )
        }

        var preguntas: [PreguntaCuestionario] = []

        for (indice, preguntaJSON) in
            cuestionarioJSON.preguntas.enumerated() {

            let textoPregunta = preguntaJSON.pregunta.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            guard
                !textoPregunta.isEmpty,
                preguntaJSON.opciones.count == 3,
                (0...2).contains(preguntaJSON.respuestaCorrecta)
            else {
                return ResultadoCuestionarioGenerado(
                    titulo: nil,
                    preguntas: nil,
                    mensaje: """
                    La pregunta \(indice + 1) no tiene una estructura válida.

                    Cada pregunta debe tener texto, exactamente 3 opciones
                    y una respuesta correcta entre 0 y 2.
                    """
                )
            }

            let opciones = preguntaJSON.opciones.map {
                $0.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            }

            guard opciones.allSatisfy({ !$0.isEmpty }) else {
                return ResultadoCuestionarioGenerado(
                    titulo: nil,
                    preguntas: nil,
                    mensaje: """
                    La pregunta \(indice + 1) contiene una opción vacía.
                    """
                )
            }

            let respuestas = opciones.enumerated().map {
                indiceOpcion, opcion in

                RespuestaCuestionario(
                    texto: opcion,
                    esCorrecta: indiceOpcion == preguntaJSON.respuestaCorrecta
                )
            }

            preguntas.append(
                PreguntaCuestionario(
                    texto: textoPregunta,
                    respuestas: respuestas
                )
            )
        }

        return ResultadoCuestionarioGenerado(
            titulo: titulo,
            preguntas: preguntas,
            mensaje: "Cuestionario generado correctamente."
        )

    } catch {
        print(
            "Error de conexión con OpenRouter:",
            error.localizedDescription
        )

        return ResultadoCuestionarioGenerado(
            titulo: nil,
            preguntas: nil,
            mensaje: """
            No se pudo completar la solicitud a OpenRouter.

            Error: \(error.localizedDescription)

            Comprueba la conexión a Internet y la configuración
            de OpenRouter.
            """
        )
    }
}

