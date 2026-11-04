
import SwiftUI

private let colorRespuestaIncorrecta = Color.red
private let colorRespuestaCorrecta = Color(red: 22.0 / 255.0, green: 178.0 / 255.0, blue: 31.0 / 255.0)

struct RealizarCuestionarioView: View {
    let cuestionario: Cuestionario?
    let onVolver: () -> Void

    var respuestasIniciales: [Int: Int] = [:]

    @State private var seleccionadas: [Int: Int]

    init(
        cuestionario: Cuestionario?,
        onVolver: @escaping () -> Void,
        respuestasIniciales: [Int: Int] = [:]
    ) {
        self.cuestionario = cuestionario
        self.onVolver = onVolver
        self.respuestasIniciales = respuestasIniciales
        _seleccionadas = State(initialValue: respuestasIniciales)
    }

    private var preguntas: [PreguntaCuestionario] {
        cuestionario?.preguntas ?? []
    }

    private var total: Int {
        preguntas.count
    }

    private var respondidas: Int {
        seleccionadas.count
    }

    private var aciertos: Int {
        seleccionadas.reduce(into: 0) { resultado, seleccion in
            let indicePregunta = seleccion.key
            let indiceRespuesta = seleccion.value

            if preguntas.indices.contains(indicePregunta),
               preguntas[indicePregunta].respuestas.indices.contains(indiceRespuesta),
               preguntas[indicePregunta].respuestas[indiceRespuesta].esCorrecta {
                resultado += 1
            }
        }
    }

    private var terminado: Bool {
        total > 0 && respondidas >= total
    }

    var body: some View {
        VStack(spacing: 0) {
            barraSuperior

            if cuestionario == nil {
                estadoSinCuestionario
            } else if preguntas.isEmpty {
                estadoSinPreguntas
            } else {
                contenidoPreguntas
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
        .preferredColorScheme(.dark)
    }

    private var barraSuperior: some View {
        HStack(spacing: 16) {
            Button(action: onVolver) {
                Image("regresar_icono")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Volver")

            Text(cuestionario?.titulo ?? "Cuestionario")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var estadoSinCuestionario: some View {
        VStack(spacing: 20) {
            Text("No se encontró el cuestionario")
                .font(.system(size: 20))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            botonAccion(titulo: "Volver", accion: onVolver)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
    }

    private var estadoSinPreguntas: some View {
        VStack {
            Text("Este cuestionario no tiene preguntas")
                .font(.system(size: 20))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
    }

    private var contenidoPreguntas: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                Spacer()
                    .frame(height: 20)

                ForEach(preguntas.indices, id: \.self) { indice in
                    bloquePregunta(indice)

                    if indice < preguntas.count - 1 {
                        Spacer()
                            .frame(height: 40)
                    }
                }

                if terminado {
                    resultadoFinal
                        .padding(.top, 24)
                        .id("resultado-final")
                }

                Spacer()
                    .frame(height: 24)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    private func bloquePregunta(_ indice: Int) -> some View {
        let pregunta = preguntas[indice]
        let elegida = seleccionadas[indice]
        let yaRespondida = elegida != nil

        return VStack(alignment: .leading, spacing: 10) {
            Text("Pregunta \(indice + 1)")
                .font(.system(size: 20))
                .foregroundStyle(.white)
                .padding(.horizontal, 4)

            contenedorTexto(
                pregunta.texto,
                colorFondo: Color(uiColor: .secondarySystemBackground)
            )

            ForEach(pregunta.respuestas.indices, id: \.self) { indiceRespuesta in
                let respuesta = pregunta.respuestas[indiceRespuesta]
                let esElegida = elegida == indiceRespuesta

                let colorFondo: Color = {
                    guard esElegida else {
                        return Color(uiColor: .secondarySystemBackground)
                    }

                    return respuesta.esCorrecta
                        ? colorRespuestaCorrecta
                        : colorRespuestaIncorrecta
                }()

                let mostrarCheck: Bool = {
                    guard let elegida else { return false }

                    let seleccionIncorrecta =
                        !pregunta.respuestas[elegida].esCorrecta

                    return yaRespondida
                        && !esElegida
                        && respuesta.esCorrecta
                        && seleccionIncorrecta
                }()

                Button {
                    guard seleccionadas[indice] == nil else { return }
                    seleccionadas[indice] = indiceRespuesta
                } label: {
                    HStack(spacing: 8) {
                        Text(respuesta.texto)
                            .font(.system(size: 18))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if mostrarCheck {
                            Image("check_icono")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(colorFondo)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .contentShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .disabled(yaRespondida)
                .accessibilityLabel(
                    "Respuesta \(indiceRespuesta + 1): \(respuesta.texto)"
                )
            }
        }
    }

    private func contenedorTexto(
        _ texto: String,
        colorFondo: Color
    ) -> some View {
        Text(texto)
            .font(.system(size: 20))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(colorFondo)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var resultadoFinal: some View {
        VStack(spacing: 12) {
            Text("\(aciertos) / \(total) Respuestas correctas")
                .font(.system(size: 20))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            botonAccion(titulo: "Reiniciar") {
                seleccionadas.removeAll()
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func botonAccion(
        titulo: String,
        accion: @escaping () -> Void
    ) -> some View {
        Button(action: accion) {
            Text(titulo)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.black)
                .frame(width: 107, height: 36)
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}
