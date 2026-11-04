import SwiftUI
import UserNotifications

private let colorTextoSecundarioEvento = Color(red: 152.0 / 255.0, green: 152.0 / 255.0, blue: 152.0 / 255.0)
private let colorRojoEvento = Color(red: 229.0 / 255.0, green: 23.0 / 255.0, blue: 63.0 / 255.0)
private let colorSuperficieNuevoEvento = Color(red: 39.0 / 255.0, green: 39.0 / 255.0, blue: 39.0 / 255.0)

struct NuevoEventoView: View {
    let eventoAEditar: Calendario?
    let onCerrar: () -> Void
    let onGuardar: (Calendario) -> Void

    @State private var titulo: String
    @State private var nota: String
    @State private var fechaSeleccionada: Date
    @State private var fechaEstablecida: Bool

    @State private var hora12: Int
    @State private var minuto: Int
    @State private var esPM: Bool
    @State private var horaEstablecida: Bool

    @State private var mostrarErrores = false
    @State private var mostrarSelectorFecha = false
    @State private var fechaTemporal = Date()

    @FocusState private var campoActivo: CampoEvento?

    private enum CampoEvento {
        case titulo
        case nota
    }

    init(
        eventoAEditar: Calendario? = nil,
        onCerrar: @escaping () -> Void,
        onGuardar: @escaping (Calendario) -> Void
    ) {
        self.eventoAEditar = eventoAEditar
        self.onCerrar = onCerrar
        self.onGuardar = onGuardar

        let fechaInicial: Date

        if let evento = eventoAEditar {
            fechaInicial = Date(timeIntervalSince1970: Double(evento.fecha) / 1000.0)
        } else {
            fechaInicial = Date()
        }

        let minutosGuardados = eventoAEditar?.hora ?? 0
        let hora24 = minutosGuardados / 60
        let horaInicial = hora24 % 12 == 0 ? 12 : hora24 % 12

        _titulo = State(initialValue: eventoAEditar?.titulo ?? "")
        _nota = State(initialValue: eventoAEditar?.nota ?? "")
        _fechaSeleccionada = State(initialValue: fechaInicial)
        _fechaEstablecida = State(initialValue: eventoAEditar != nil)
        _hora12 = State(initialValue: horaInicial)
        _minuto = State(initialValue: minutosGuardados % 60)
        _esPM = State(initialValue: hora24 >= 12)
        _horaEstablecida = State(initialValue: eventoAEditar != nil)
    }

    private var errorTitulo: Bool {
        mostrarErrores && titulo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var errorFecha: Bool {
        mostrarErrores && !fechaEstablecida
    }

    private var errorHora: Bool {
        mostrarErrores && !horaEstablecida
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                encabezado

                Spacer()
                    .frame(height: 16)

                CampoTextoEventoView(
                    texto: $titulo,
                    textoGuia: "Agregar titulo",
                    mensajeError: errorTitulo ? "Falta agregar titulo" : nil,
                    unaLinea: true
                )
                .focused($campoActivo, equals: .titulo)
                .padding(.horizontal, 8)
                .padding(.vertical, 12)

                LineaDivisoriaEventoView()

                selectorFecha

                if errorFecha {
                    MensajeErrorEventoView(
                        texto: "Falta el dia del evento",
                        tamano: 14
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 46)
                    .padding(.bottom, 8)
                }

                LineaDivisoriaEventoView()

                Group {
                    HStack(spacing: 12) {
                        Image("reloj_icono")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)

                        Text("Establecer hora del evento")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.primary)

                        Spacer(minLength: 0)
                    }
                    .padding(.leading, 4)
                    .padding(.top, 14)
                    .padding(.bottom, 8)

                    if errorHora {
                        MensajeErrorEventoView(
                            texto: "Falta la hora del evento",
                            tamano: 14
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 46)
                        .padding(.bottom, 8)
                    }

                    HStack(spacing: 6) {
                        SelectorValorEventoView(
                            texto: String(format: "%02d", hora12),
                            onMenos: { cambiarHora(-1) },
                            onMas: { cambiarHora(1) }
                        )

                        Text("-")
                            .foregroundStyle(Color.primary)

                        SelectorValorEventoView(
                            texto: String(format: "%02d", minuto),
                            onMenos: { cambiarMinuto(-1) },
                            onMas: { cambiarMinuto(1) }
                        )

                        Text("-")
                            .foregroundStyle(Color.primary)

                        SelectorValorEventoView(
                            texto: esPM ? "PM" : "AM",
                            onMenos: alternarAMPM,
                            onMas: alternarAMPM
                        )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)

                    LineaDivisoriaEventoView()

                    CampoTextoEventoView(
                        texto: $nota,
                        textoGuia: "Agregar nota",
                        unaLinea: false
                    )
                    .focused($campoActivo, equals: .nota)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(uiColor: .systemBackground))
        .scrollDismissesKeyboard(.interactively)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $mostrarSelectorFecha) {
            selectorFechaSheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .task {
            await solicitarPermisoNotificaciones()
        }
    }

    private var encabezado: some View {
        HStack {
            Button(action: onCerrar) {
                Image("cerrar_icono")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Cerrar")

            Spacer()

            Button(action: intentarGuardar) {
                Text(eventoAEditar == nil ? "Guardar" : "Editar")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(width: 107, height: 36)
                    .background(Color.accentColor)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }

    private var selectorFecha: some View {
        Button {
            campoActivo = nil
            fechaTemporal = fechaSeleccionada
            mostrarSelectorFecha = true
        } label: {
            HStack(spacing: 12) {
                Image("calendario_icono")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)

                Text(
                    fechaEstablecida
                    ? formatearFechaEvento(fechaSeleccionada)
                    : "Establecer dia del evento"
                )
                .font(.system(size: 20))
                .foregroundStyle(Color.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.primary)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var selectorFechaSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                DatePicker(
                    "Fecha del evento",
                    selection: $fechaTemporal,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top)
            .navigationTitle("Seleccionar fecha")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        mostrarSelectorFecha = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Aceptar") {
                        fechaSeleccionada = fechaTemporal
                        fechaEstablecida = true
                        mostrarSelectorFecha = false
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func cambiarHora(_ delta: Int) {
        hora12 = (hora12 - 1 + delta + 12) % 12 + 1
        horaEstablecida = true
    }

    private func cambiarMinuto(_ delta: Int) {
        minuto = (minuto + delta + 60) % 60
        horaEstablecida = true
    }

    private func alternarAMPM() {
        esPM.toggle()
        horaEstablecida = true
    }

    private func intentarGuardar() {
        mostrarErrores = true

        let tituloLimpio = titulo.trimmingCharacters(in: .whitespacesAndNewlines)
        let notaLimpia = nota.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !tituloLimpio.isEmpty,
              fechaEstablecida,
              horaEstablecida else {
            return
        }

        campoActivo = nil

        let calendario = Calendar.current
        let componentesFecha = calendario.dateComponents(
            [.year, .month, .day],
            from: fechaSeleccionada
        )

        guard let fechaAlInicioDelDia = calendario.date(
            from: componentesFecha
        ) else {
            return
        }

        let fechaMillis = Int64(
            fechaAlInicioDelDia.timeIntervalSince1970 * 1000
        )

        let hora24 = (hora12 % 12) + (esPM ? 12 : 0)
        let minutosDelDia = hora24 * 60 + minuto

        let evento: Calendario = Calendario(
            id: eventoAEditar?.id ?? Int64(0),
            titulo: tituloLimpio,
            fecha: fechaMillis,
            hora: minutosDelDia,
            nota: notaLimpia
        )

        onGuardar(evento)
        onCerrar()
    }

    private func formatearFechaEvento(_ fecha: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: fecha)
    }

    private func solicitarPermisoNotificaciones() async {
        let centro = UNUserNotificationCenter.current()
        let configuracion = await centro.notificationSettings()

        guard configuracion.authorizationStatus == .notDetermined else {
            return
        }

        do {
            _ = try await centro.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
        } catch {
            print("No se pudo solicitar el permiso de notificaciones: \(error.localizedDescription)")
        }
    }
}

private struct LineaDivisoriaEventoView: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.8))
            .frame(height: 1)
    }
}

private struct MensajeErrorEventoView: View {
    let texto: String
    let tamano: CGFloat

    var body: some View {
        Text(texto)
            .font(.system(size: tamano))
            .foregroundStyle(colorRojoEvento)
    }
}

private struct CampoTextoEventoView: View {
    @Binding var texto: String
    let textoGuia: String
    var mensajeError: String? = nil
    let unaLinea: Bool

    var body: some View {
        Group {
            if unaLinea {
                TextField(
                    "",
                    text: $texto,
                    prompt: Text(mensajeError ?? textoGuia)
                        .foregroundColor(
                            mensajeError == nil
                            ? colorTextoSecundarioEvento
                            : colorRojoEvento
                        )
                )
                .textInputAutocapitalization(.sentences)
                .submitLabel(.done)
            } else {
                ZStack(alignment: .topLeading) {
                    if texto.isEmpty {
                        Text(textoGuia)
                            .foregroundStyle(colorTextoSecundarioEvento)
                            .font(.system(size: 20))
                    }

                    TextEditor(text: $texto)
                        .font(.system(size: 20))
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 100)
                        .opacity(texto.isEmpty ? 0.85 : 1)
                }
            }
        }
        .font(.system(size: 20))
        .foregroundStyle(Color.primary)
        .tint(Color.accentColor)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SelectorValorEventoView: View {
    let texto: String
    let onMenos: () -> Void
    let onMas: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            boton(simbolo: "−", accion: onMenos)

            Text(texto)
                .font(.system(size: 18))
                .foregroundStyle(colorTextoSecundarioEvento)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)

            boton(simbolo: "+", accion: onMas)
        }
        .frame(width: 101, height: 30)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }

    private func boton(simbolo: String, accion: @escaping () -> Void) -> some View {
        Button(action: accion) {
            Text(simbolo)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.black)
                .frame(width: 30, height: 30)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

