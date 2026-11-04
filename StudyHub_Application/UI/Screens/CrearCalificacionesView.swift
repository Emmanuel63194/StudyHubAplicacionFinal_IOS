import SwiftUI

private let azulCalificacion = Color(
    red: 172.0 / 255.0,
    green: 198.0 / 255.0,
    blue: 1.0
)

struct CrearCalificacionesView: View {
    @ObservedObject var calificacionViewModel: CalificacionViewModel
    @ObservedObject var asignaturaViewModel: AsignaturaViewModel

    var onBack: () -> Void
    var onCrearAsignatura: () -> Void
    var calificacionAEditar: Calificacion?

    @State private var nota: String
    @State private var asignaturaId: Int?
    @State private var fecha: Date
    @State private var porcentaje: String
    @State private var descripcion: String

    @State private var mensajeNota = ""
    @State private var mensajePorcentaje = ""
    @State private var intentoGuardar = false
    @State private var selectorAsignaturaAbierto = false
    @State private var selectorFechaAbierto = false

    init(
        calificacionViewModel: CalificacionViewModel,
        asignaturaViewModel: AsignaturaViewModel,
        onBack: @escaping () -> Void = {},
        onCrearAsignatura: @escaping () -> Void = {},
        calificacionAEditar: Calificacion? = nil
    ) {
        self.calificacionViewModel = calificacionViewModel
        self.asignaturaViewModel = asignaturaViewModel
        self.onBack = onBack
        self.onCrearAsignatura = onCrearAsignatura
        self.calificacionAEditar = calificacionAEditar

        _nota = State(
            initialValue: calificacionAEditar.map {
                String($0.nota)
            } ?? ""
        )

        _asignaturaId = State(
            initialValue: calificacionAEditar?.asignaturaId
        )

        _fecha = State(
            initialValue: calificacionAEditar.map {
                Self.fechaDesdeMillis($0.fecha)
            } ?? Date()
        )

        _porcentaje = State(
            initialValue: calificacionAEditar.map {
                String($0.porcentaje)
            } ?? ""
        )

        _descripcion = State(
            initialValue: calificacionAEditar?.descripcion ?? ""
        )
    }

    private var asignaturas: [Asignatura] {
        asignaturaViewModel.asignaturas
    }

    private var calificaciones: [Calificacion] {
        calificacionViewModel.calificaciones
    }

    private var porcentajeUsado: Int {
        calificaciones
            .filter {
                $0.asignaturaId == asignaturaId &&
                $0.id != calificacionAEditar?.id
            }
            .reduce(0) { $0 + $1.porcentaje }
    }

    private var disponible: Int {
        max(0, 100 - porcentajeUsado)
    }

    private var errorNota: String {
        if !mensajeNota.isEmpty {
            return mensajeNota
        }

        if intentoGuardar && nota.isEmpty {
            return "Falta calificación"
        }

        return ""
    }

    private var errorPorcentaje: String {
        if !mensajePorcentaje.isEmpty {
            return mensajePorcentaje
        }

        if intentoGuardar && porcentaje.isEmpty {
            return "Falta porcentaje de calificación"
        }

        return ""
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                barraSuperior

                Spacer()
                    .frame(height: 5)

                campoEntrada(
                    valor: $nota,
                    placeholder: "Agregar calificación",
                    icono: "calificacion_icono",
                    tamanoTexto: 20,
                    error: errorNota,
                    tipo: .decimalPad
                )

                selectorAsignatura

                selectorFecha

                Text(
                    "Nota: El porcentaje de calificación va de 0 a 100%. Al agregar calificaciones, el porcentaje disponible disminuirá."
                )
                .font(.system(size: 13))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

                campoEntrada(
                    valor: $porcentaje,
                    placeholder: "Porcentaje de calificación (Disponible \(disponible)%)",
                    icono: "calculadora",
                    tamanoTexto: 14,
                    error: errorPorcentaje,
                    tipo: .numberPad
                )

                campoDescripcion

                if intentoGuardar &&
                    asignaturaId != nil &&
                    disponible <= 0 {
                    Text(
                        "No hay porcentaje disponible para agregar calificaciones"
                    )
                    .font(.system(size: 14))
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                }

                if let error = calificacionViewModel.error {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            .padding(16)
        }
        .background(Color(uiColor: .systemBackground))
        .onChange(of: nota) { nuevoValor in
            validarNota(nuevoValor)
        }
        .onChange(of: porcentaje) { nuevoValor in
            validarPorcentaje(nuevoValor)
        }
    }

    private var barraSuperior: some View {
        HStack {
            Button(action: onBack) {
                Image("regresar_icono")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Regresar")

            Spacer()

            Button(action: guardar) {
                Text(
                    calificacionAEditar == nil ? "Agregar" : "Editar"
                )
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.black)
                .frame(width: 107, height: 36)
                .background(azulCalificacion)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
    }

    private func campoEntrada(
        valor: Binding<String>,
        placeholder: String,
        icono: String,
        tamanoTexto: CGFloat,
        error: String,
        tipo: UIKeyboardType
    ) -> some View {
        HStack(spacing: 16) {
            Image(icono)
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)

            TextField(
                "",
                text: valor,
                prompt: Text(error.isEmpty ? placeholder : error)
                    .foregroundColor(
                        error.isEmpty ? Color.secondary : Color.red
                    )
            )
            .font(.system(size: tamanoTexto))
            .keyboardType(tipo)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .frame(height: 69)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var selectorAsignatura: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut) {
                    selectorAsignaturaAbierto.toggle()
                }
            } label: {
                HStack(spacing: 16) {
                    Image("asignatura_icono")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)

                    Text(
                        asignaturas.first {
                            $0.id == asignaturaId
                        }?.nombre ?? "Seleccionar una asignatura"
                    )
                    .font(.system(size: 17))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundStyle(.white)
                        .rotationEffect(
                            .degrees(
                                selectorAsignaturaAbierto ? 90 : 0
                            )
                        )
                }
                .padding(.horizontal, 16)
                .frame(height: 69)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if intentoGuardar && asignaturaId == nil {
                Text("Falta asignatura")
                    .font(.system(size: 14))
                    .foregroundStyle(.red)
                    .padding(.bottom, 8)
            }

            if selectorAsignaturaAbierto {
                Divider()
                    .overlay(Color.white.opacity(0.35))
                    .padding(.horizontal, 16)

                VStack(spacing: 6) {
                    if asignaturas.isEmpty {
                        Text("Sin asignaturas (agrega una asignatura)")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Button(action: onCrearAsignatura) {
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.black)
                                .frame(width: 49, height: 49)
                                .background(azulCalificacion)
                                .clipShape(
                                    RoundedRectangle(cornerRadius: 10)
                                )
                        }
                    } else {
                        ForEach(asignaturas, id: \.id) { asignatura in
                            Button {
                                asignaturaId = asignatura.id
                                selectorAsignaturaAbierto = false
                            } label: {
                                Text(asignatura.nombre)
                                    .font(.system(size: 17))
                                    .foregroundStyle(.black)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 32)
                                    .padding(.horizontal, 8)
                                    .background(
                                        asignatura.id == asignaturaId
                                            ? azulCalificacion
                                            : Color.white
                                    )
                                    .clipShape(
                                        RoundedRectangle(cornerRadius: 5)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var selectorFecha: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation {
                    selectorFechaAbierto.toggle()
                }
            } label: {
                HStack(spacing: 16) {
                    Image("calendario_blanco")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)

                    Text(fechaFormateada)
                        .font(.system(size: 17))
                        .foregroundStyle(.white)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundStyle(.white)
                        .rotationEffect(
                            .degrees(selectorFechaAbierto ? 90 : 0)
                        )
                }
                .padding(.horizontal, 16)
                .frame(height: 69)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if selectorFechaAbierto {
                DatePicker(
                    "Fecha de la calificación",
                    selection: $fecha,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(azulCalificacion)
                .padding()
                .environment(
                    \.locale,
                    Locale(identifier: "es_CO")
                )
            }
        }
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var fechaFormateada: String {
        fecha.formatted(
            .dateTime
                .locale(Locale(identifier: "es_CO"))
                .month(.wide)
                .day()
                .year()
        )
    }

    private var campoDescripcion: some View {
        ZStack(alignment: .topLeading) {
            if descripcion.isEmpty {
                Text(
                    intentoGuardar ? "Falta agregar nota" : "Agregar nota"
                )
                .font(.system(size: 20))
                .foregroundStyle(
                    intentoGuardar ? Color.red : Color.secondary
                )
                .padding(.top, 8)
                .padding(.leading, 5)
            }

            TextEditor(text: $descripcion)
                .font(.system(size: 20))
                .scrollContentBackground(.hidden)
                .frame(minHeight: 100)
                .opacity(descripcion.isEmpty ? 0.85 : 1)
        }
        .padding(12)
        .frame(minHeight: 116)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func validarNota(_ texto: String) {
        guard !texto.isEmpty else {
            mensajeNota = ""
            return
        }

        guard texto.range(
            of: #"^[0-9]*\.?[0-9]*$"#,
            options: .regularExpression
        ) != nil else {
            nota = ""
            mensajeNota = "Solo se admiten números"
            return
        }

        if let numero = Double(texto), numero > 5 {
            nota = ""
            mensajeNota = "La calificación va de 0 a 5"
        } else {
            mensajeNota = ""
        }
    }

    private func validarPorcentaje(_ texto: String) {
        guard !texto.isEmpty else {
            mensajePorcentaje = ""
            return
        }

        guard texto.range(
            of: #"^[0-9]*$"#,
            options: .regularExpression
        ) != nil else {
            porcentaje = ""
            mensajePorcentaje = "Solo se admiten números"
            return
        }

        if texto.count > 3 ||
            (Int(texto) ?? 0) > disponible {
            porcentaje = ""
            mensajePorcentaje = "Máximo \(disponible)%"
        } else {
            mensajePorcentaje = ""
        }
    }

    private func guardar() {
        intentoGuardar = true

        let descripcionLimpia = descripcion.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard let notaNumero = Double(nota),
              let porcentajeNumero = Int(porcentaje),
              let idAsignatura = asignaturaId else {
            return
        }

        guard !descripcionLimpia.isEmpty, disponible > 0 else {
            return
        }

        guard (0...5).contains(notaNumero) else {
            mensajeNota = "La calificación va de 0 a 5"
            return
        }

        guard porcentajeNumero >= 0,
              porcentajeNumero <= disponible else {
            mensajePorcentaje = "Máximo \(disponible)%"
            return
        }

        let fechaFinal = Self.millisDesdeFecha(fecha)

        if let existente = calificacionAEditar {
            existente.asignaturaId = idAsignatura
            existente.nota = notaNumero
            existente.porcentaje = porcentajeNumero
            existente.descripcion = descripcionLimpia
            existente.fecha = fechaFinal

            calificacionViewModel.editar(existente)
        } else {
            calificacionViewModel.agregar(
                asignaturaId: idAsignatura,
                nota: notaNumero,
                porcentaje: porcentajeNumero,
                descripcion: descripcionLimpia,
                fecha: fechaFinal
            )
        }

        onBack()
    }

    private static func millisDesdeFecha(_ fecha: Date) -> Int64 {
        let calendario = Calendar.current
        let fechaLocal = calendario.startOfDay(for: fecha)

        return Int64(fechaLocal.timeIntervalSince1970 * 1000)
    }

    private static func fechaDesdeMillis(_ millis: Int64) -> Date {
        Date(timeIntervalSince1970: Double(millis) / 1000)
    }
}
