
import SwiftUI

struct CrearAsignaturaView: View {

    @ObservedObject var viewModel: AsignaturaViewModel

    var asignaturaAEditar: Asignatura?
    var onBack: () -> Void

    @State private var nombre: String
    @State private var salon: String
    @State private var bloques: [BloqueHorarioAsignatura]

    @State private var errorNombre = false
    @State private var horarioAbierto = false

    private let dias = [
        "Lunes", "Martes", "Miércoles", "Jueves",
        "Viernes", "Sábado", "Domingo"
    ]

    init(
        viewModel: AsignaturaViewModel,
        asignaturaAEditar: Asignatura? = nil,
        onBack: @escaping () -> Void = {}
    ) {
        self.viewModel = viewModel
        self.asignaturaAEditar = asignaturaAEditar
        self.onBack = onBack

        _nombre = State(
            initialValue: asignaturaAEditar?.nombre ?? ""
        )

        _salon = State(
            initialValue: asignaturaAEditar?.salon ?? ""
        )

        _bloques = State(
            initialValue: Self.textoABloques(
                asignaturaAEditar?.horario ?? ""
            )
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                barraSuperior

                campoTexto(
                    valor: $nombre,
                    placeholder: errorNombre
                        ? "Falta el nombre de la asignatura"
                        : "Añadir nombre",
                    icono: "asignatura_icono",
                    esError: errorNombre
                )
                .onChange(of: nombre) { _ in
                    errorNombre = false
                }

                campoTexto(
                    valor: $salon,
                    placeholder: "Agregar salón",
                    icono: "ubicacion_blanco_icono"
                )

                contenedorHorario
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(uiColor: .systemBackground))
    }

    private var barraSuperior: some View {
        HStack {
            Button(action: onBack) {
                Image("regresar_icono")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 35, height: 35)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Regresar")

            Spacer()

            Button(action: guardar) {
                Text(asignaturaAEditar == nil ? "Agregar" : "Editar")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(width: 107, height: 36)
                    .background(Color.accentColor)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private func campoTexto(
        valor: Binding<String>,
        placeholder: String,
        icono: String,
        esError: Bool = false
    ) -> some View {
        HStack(spacing: 16) {
            Image(icono)
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)

            TextField(
                "",
                text: valor,
                prompt: Text(placeholder)
                    .foregroundColor(
                        esError ? Color.red : Color.secondary
                    )
            )
            .font(.system(size: 20))
            .textInputAutocapitalization(.sentences)
            .autocorrectionDisabled()
        }
        .padding(.horizontal, 16)
        .frame(height: 67)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var contenedorHorario: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut) {
                    horarioAbierto.toggle()
                }
            } label: {
                HStack(spacing: 16) {
                    Image("horario_blanco_icono")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)

                    Text("Establecer horario")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                        .rotationEffect(
                            .degrees(horarioAbierto ? 90 : 0)
                        )
                }
                .padding(.horizontal, 16)
                .frame(height: 67)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if horarioAbierto {
                VStack(spacing: 12) {
                    Divider()
                        .overlay(Color.white.opacity(0.35))

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ],
                        spacing: 8
                    ) {
                        ForEach(dias, id: \.self) { dia in
                            botonDia(dia)
                        }
                    }

                    Divider()
                        .overlay(Color.white.opacity(0.35))

                    ForEach($bloques) { $bloque in
                        VStack(spacing: 8) {
                            Text(bloque.dia)
                                .font(.system(size: 20))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)

                            filaHora(
                                titulo: "Inicio",
                                minutos: $bloque.inicio
                            )

                            filaHora(
                                titulo: "Final",
                                minutos: $bloque.fin
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .transition(
                    .opacity.combined(with: .move(edge: .top))
                )
            }
        }
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func botonDia(_ dia: String) -> some View {
        let seleccionado = bloques.contains { $0.dia == dia }

        return Button {
            alternarDia(dia)
        } label: {
            Text(dia)
                .font(.system(size: 15, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .foregroundStyle(seleccionado ? .black : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(
                    seleccionado ? Color.accentColor : Color.clear
                )
                .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(.plain)
    }

    private func filaHora(
        titulo: String,
        minutos: Binding<Int>
    ) -> some View {
        HStack(spacing: 5) {
            Text(titulo)
                .font(.system(size: 17))
                .foregroundStyle(.secondary)
                .frame(width: 62, alignment: .leading)

            selectorHora(
                texto: String(
                    format: "%02d",
                    hora12(minutos.wrappedValue)
                ),
                menos: {
                    minutos.wrappedValue = cambiarHora(
                        minutos.wrappedValue,
                        cambio: -1
                    )
                },
                mas: {
                    minutos.wrappedValue = cambiarHora(
                        minutos.wrappedValue,
                        cambio: 1
                    )
                }
            )

            Text("-")
                .foregroundStyle(.white)

            selectorHora(
                texto: String(
                    format: "%02d",
                    minutos.wrappedValue % 60
                ),
                menos: {
                    minutos.wrappedValue = cambiarMinuto(
                        minutos.wrappedValue,
                        cambio: -5
                    )
                },
                mas: {
                    minutos.wrappedValue = cambiarMinuto(
                        minutos.wrappedValue,
                        cambio: 5
                    )
                }
            )

            Text("-")
                .foregroundStyle(.white)

            selectorHora(
                texto: minutos.wrappedValue / 60 >= 12 ? "PM" : "AM",
                menos: {
                    minutos.wrappedValue = alternarAMPM(
                        minutos.wrappedValue
                    )
                },
                mas: {
                    minutos.wrappedValue = alternarAMPM(
                        minutos.wrappedValue
                    )
                }
            )
        }
    }

    private func selectorHora(
        texto: String,
        menos: @escaping () -> Void,
        mas: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 2) {
            Button(action: menos) {
                Text("−")
                    .fontWeight(.bold)
                    .frame(width: 22, height: 28)
            }

            Text(texto)
                .font(.system(size: 15))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)

            Button(action: mas) {
                Text("+")
                    .fontWeight(.bold)
                    .frame(width: 22, height: 28)
            }
        }
        .foregroundStyle(.black)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private func alternarDia(_ dia: String) {
        if bloques.contains(where: { $0.dia == dia }) {
            bloques.removeAll { $0.dia == dia }
        } else {
            bloques.append(
                BloqueHorarioAsignatura(
                    dia: dia,
                    inicio: 7 * 60,
                    fin: 9 * 60
                )
            )

            ordenarBloques()
        }
    }

    private func ordenarBloques() {
        bloques.sort {
            dias.firstIndex(of: $0.dia) ?? 0
                < dias.firstIndex(of: $1.dia) ?? 0
        }
    }

    private func guardar() {
        let nombreLimpio = nombre.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !nombreLimpio.isEmpty else {
            nombre = ""
            errorNombre = true
            return
        }

        let horario = bloques
            .map { "\($0.dia),\($0.inicio),\($0.fin)" }
            .joined(separator: ";")

        let guardadoCorrectamente: Bool

        if let asignatura = asignaturaAEditar {
            asignatura.nombre = nombreLimpio

            asignatura.salon = salon.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            asignatura.horario = horario

            guardadoCorrectamente = viewModel.editar(asignatura)
        } else {
            guardadoCorrectamente = viewModel.agregar(
                nombre: nombreLimpio,
                salon: salon.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
                horario: horario
            )
        }

        if guardadoCorrectamente {
            onBack()
        }
    }

    private func hora12(_ minutos: Int) -> Int {
        let hora = (minutos / 60) % 12
        return hora == 0 ? 12 : hora
    }

    private func cambiarHora(
        _ minutos: Int,
        cambio: Int
    ) -> Int {
        let hora24 = minutos / 60
        let esPM = hora24 >= 12
        let hora = (hora24 % 12 + cambio + 12) % 12

        return (hora + (esPM ? 12 : 0)) * 60 + minutos % 60
    }

    private func cambiarMinuto(
        _ minutos: Int,
        cambio: Int
    ) -> Int {
        let minuto = (minutos % 60 + cambio + 60) % 60
        return (minutos / 60) * 60 + minuto
    }

    private func alternarAMPM(_ minutos: Int) -> Int {
        (minutos + 12 * 60) % (24 * 60)
    }

    private static func textoABloques(
        _ texto: String
    ) -> [BloqueHorarioAsignatura] {
        guard !texto.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty else {
            return []
        }

        let dias = [
            "Lunes", "Martes", "Miércoles", "Jueves",
            "Viernes", "Sábado", "Domingo"
        ]

        return texto
            .split(separator: ";")
            .compactMap { parte in
                let datos = parte.split(
                    separator: ",",
                    omittingEmptySubsequences: false
                )

                guard datos.count == 3,
                      let dia = dias.first(where: {
                          normalizar($0) == normalizar(
                              String(datos[0]).trimmingCharacters(
                                  in: .whitespacesAndNewlines
                              )
                          )
                      }),
                      let inicio = Int(
                          datos[1].trimmingCharacters(
                              in: .whitespacesAndNewlines
                          )
                      ),
                      let fin = Int(
                          datos[2].trimmingCharacters(
                              in: .whitespacesAndNewlines
                          )
                      ) else {
                    return nil
                }

                return BloqueHorarioAsignatura(
                    dia: dia,
                    inicio: inicio,
                    fin: fin
                )
            }
            .sorted {
                dias.firstIndex(of: $0.dia) ?? 0
                    < dias.firstIndex(of: $1.dia) ?? 0
            }
    }

    private static func normalizar(_ texto: String) -> String {
        texto.folding(
            options: [.diacriticInsensitive, .caseInsensitive],
            locale: Locale(identifier: "es")
        )
    }
}

private struct BloqueHorarioAsignatura: Identifiable {

    var dia: String
    var inicio: Int
    var fin: Int

    var id: String { dia }
}

