
import SwiftUI

private let colorTextoSecundario = Color(
    red: 152.0 / 255.0,
    green: 152.0 / 255.0,
    blue: 152.0 / 255.0
)

private let colorErrorCuestionario = Color(
    red: 1.0,
    green: 59.0 / 255.0,
    blue: 71.0 / 255.0
)

struct CrearCuestionarioView: View {
    @ObservedObject var viewModel: CuestionarioViewModel

    var onVolver: () -> Void
    var onCreado: () -> Void
    var cuestionarioAEditar: Cuestionario? = nil

    private let colorCampo = Color(
        red: 43.0 / 255.0,
        green: 43.0 / 255.0,
        blue: 43.0 / 255.0
    )

    var body: some View {
        VStack(spacing: 0) {
            barraSuperior

            ScrollView {
                VStack(spacing: 10) {
                    encabezadoConError(
                        titulo: "Nombre:",
                        error: viewModel.intentoCrear &&
                            viewModel.titulo.trimmingCharacters(
                                in: .whitespacesAndNewlines
                            ).isEmpty
                            ? "(Falta el nombre del cuestionario)"
                            : nil
                    )

                    campoTexto(
                        valor: Binding(
                            get: { viewModel.titulo },
                            set: {
                                viewModel.actualizarTitulo($0)
                            }
                        ),
                        placeholder: "Añadir nombre"
                    )

                    Spacer()
                        .frame(height: 2)

                    ForEach(
                        Array(viewModel.preguntas.enumerated()),
                        id: \.offset
                    ) { indice, pregunta in
                        bloquePregunta(
                            indice: indice,
                            pregunta: pregunta
                        )
                    }

                    Button {
                        viewModel.agregarPregunta()
                    } label: {
                        Text("+")
                            .font(
                                .system(
                                    size: 28,
                                    weight: .regular
                                )
                            )
                            .foregroundStyle(.black)
                            .frame(width: 49, height: 49)
                            .background(Color.accentColor)
                            .clipShape(
                                RoundedRectangle(cornerRadius: 12)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)

                    Spacer()
                        .frame(height: 24)

                    // Se conservan los demás mensajes de error.
                    if let error = viewModel.error,
                       !error.isEmpty {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundStyle(
                                colorErrorCuestionario
                            )
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )
                    }
                }
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.hidden)
        }
        .background(
            Color(
                red: 25.0 / 255.0,
                green: 25.0 / 255.0,
                blue: 25.0 / 255.0
            )
        )
        .task(id: cuestionarioAEditar?.id) {
            if let cuestionario = cuestionarioAEditar {
                viewModel.cargarCuestionarioParaEditar(
                    cuestionario
                )
            }
        }
    }

    // MARK: - Barra superior

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

            Text(
                cuestionarioAEditar == nil
                    ? "Crear cuestionario"
                    : "Editar cuestionario"
            )
            .font(
                .system(size: 23, weight: .semibold)
            )
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.75)

            Spacer(minLength: 4)

            Button {
                guardarCuestionario()
            } label: {
                Text(
                    cuestionarioAEditar == nil
                        ? "Crear"
                        : "Editar"
                )
                .font(
                    .system(size: 15, weight: .semibold)
                )
                .foregroundStyle(.black)
                .frame(width: 95, height: 36)
                .background(Color.accentColor)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Encabezados

    private func encabezadoConError(
        titulo: String,
        error: String?,
        contenidoFinal: (() -> AnyView)? = nil
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(titulo)
                .font(.system(size: 20))
                .foregroundStyle(.white)

            if let error, !error.isEmpty {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundStyle(colorErrorCuestionario)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
            } else {
                Spacer(minLength: 0)
            }

            contenidoFinal?()
        }
        .padding(.horizontal, 4)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    // MARK: - Bloque de pregunta

    private func bloquePregunta(
        indice: Int,
        pregunta: PreguntaCuestionario
    ) -> some View {
        let mensajeError = viewModel.intentoCrear
            ? viewModel.mensajeErrorPregunta(pregunta)
            : nil

        return VStack(spacing: 10) {
            encabezadoConError(
                titulo: "Pregunta \(indice + 1)",
                error: mensajeError,
                contenidoFinal: indice > 0
                    ? {
                        AnyView(
                            botonIcono(
                                nombre: "eliminar_icono",
                                descripcion: "Eliminar pregunta"
                            ) {
                                viewModel.eliminarPregunta(
                                    indice: indice
                                )
                            }
                        )
                    }
                    : nil
            )

            campoTexto(
                valor: Binding(
                    get: {
                        guard viewModel.preguntas.indices.contains(
                            indice
                        ) else {
                            return ""
                        }

                        return viewModel.preguntas[indice].texto
                    },
                    set: {
                        viewModel.actualizarTextoPregunta(
                            indicePregunta: indice,
                            texto: $0
                        )
                    }
                ),
                placeholder: "Escribe la pregunta"
            )

            ForEach(
                Array(pregunta.respuestas.enumerated()),
                id: \.offset
            ) { indiceRespuesta, respuesta in
                campoTexto(
                    valor: Binding(
                        get: {
                            guard
                                viewModel.preguntas.indices.contains(
                                    indice
                                ),
                                viewModel.preguntas[indice]
                                    .respuestas.indices.contains(
                                        indiceRespuesta
                                    )
                            else {
                                return ""
                            }

                            return viewModel.preguntas[indice]
                                .respuestas[indiceRespuesta].texto
                        },
                        set: {
                            viewModel.actualizarTextoRespuesta(
                                indicePregunta: indice,
                                indiceRespuesta: indiceRespuesta,
                                texto: $0
                            )
                        }
                    ),
                    placeholder: "Escribe la respuesta"
                ) {
                    botonIcono(
                        nombre: respuesta.esCorrecta
                            ? "check_verde_icono"
                            : "check_icono",
                        descripcion: respuesta.esCorrecta
                            ? "Respuesta correcta"
                            : "Marcar como correcta",
                        conservarColor: respuesta.esCorrecta
                    ) {
                        viewModel.marcarRespuestaCorrecta(
                            indicePregunta: indice,
                            indiceRespuesta: indiceRespuesta
                        )
                    }

                    if pregunta.respuestas.count == 3 &&
                       indiceRespuesta == 2 {
                        botonIcono(
                            nombre: "eliminar_icono",
                            descripcion: "Eliminar respuesta"
                        ) {
                            viewModel.eliminarRespuesta(
                                indicePregunta: indice,
                                indiceRespuesta: indiceRespuesta
                            )
                        }
                    }
                }
            }
        }
        .padding(
            .bottom,
            indice < viewModel.preguntas.count - 1 ? 10 : 0
        )
    }

    // MARK: - Campo de texto

    private func campoTexto<ContenidoFinal: View>(
        valor: Binding<String>,
        placeholder: String,
        @ViewBuilder contenidoFinal: () -> ContenidoFinal = {
            EmptyView()
        }
    ) -> some View {
        HStack(spacing: 8) {
            ZStack(alignment: .leading) {
                if valor.wrappedValue.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 18))
                        .foregroundStyle(
                            colorTextoSecundario
                        )
                        .lineLimit(1)
                }

                TextField("", text: valor)
                    .font(.system(size: 18))
                    .foregroundStyle(.white)
                    .tint(.white)
                    .textInputAutocapitalization(.sentences)
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )

            contenidoFinal()
        }
        .frame(minHeight: 67)
        .padding(.horizontal, 16)
        .background(colorCampo)
        .clipShape(
            RoundedRectangle(cornerRadius: 16)
        )
    }

    // MARK: - Botones con iconos

    private func botonIcono(
        nombre: String,
        descripcion: String,
        conservarColor: Bool = false,
        accion: @escaping () -> Void
    ) -> some View {
        Button(action: accion) {
            Image(nombre)
                .resizable()
                .renderingMode(
                    conservarColor ? .original : .template
                )
                .scaledToFit()
                .frame(width: 30, height: 30)
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(descripcion)
    }

    // MARK: - Guardar cuestionario

    private func guardarCuestionario() {
        if let cuestionario = cuestionarioAEditar {
            viewModel.editarCuestionario(
                cuestionario,
                onGuardado: {
                    onCreado()
                }
            )
        } else {
            viewModel.intentarCrear(
                onGuardado: { _ in
                    onCreado()
                }
            )
        }
    }
}

