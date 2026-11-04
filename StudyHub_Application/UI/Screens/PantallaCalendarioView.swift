
import SwiftUI

private let nombresMesesCalendario = [
    "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
    "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"
]

private let diasSemanaCalendario = ["D", "L", "Ma", "Mi", "J", "V", "S"]

private let calendarioSistema = Calendar(identifier: .gregorian)

struct PantallaCalendarioView: View {
    @ObservedObject var viewModel: CalendarioViewModel

    var onMenuClick: () -> Void = {}

    @State private var mesVisible: Date = Date()
    @State private var fechaSeleccionada: Date = Calendar.current.startOfDay(for: Date())
    @State private var mostrarFormulario = false
    @State private var eventoEnEdicion: Calendario?
    @State private var eventoPorEliminar: Calendario?
    @State private var mostrarConfirmacionEliminar = false

    private let columnas = Array(
        repeating: GridItem(.flexible(), spacing: 0),
        count: 7
    )

    private var anioVisible: Int {
        Calendar.current.component(.year, from: mesVisible)
    }

    private var mesVisibleNumero: Int {
        Calendar.current.component(.month, from: mesVisible)
    }

    private var eventosDelDia: [Calendario] {
        viewModel.eventos
            .filter { mismoDia($0.fecha, que: fechaSeleccionada) }
            .sorted {
                if $0.hora == $1.hora {
                    return $0.titulo.localizedCaseInsensitiveCompare($1.titulo) == .orderedAscending
                }
                return $0.hora < $1.hora
            }
    }

    private var diasConEventos: Set<String> {
        Set(viewModel.eventos.map { claveFecha($0.fecha) })
    }

    var body: some View {
        VStack(spacing: 0) {
            barraSuperior

            calendarioMensual
                .padding(.top, 12)

            VStack(spacing: 0) {
                if eventosDelDia.isEmpty {
                    estadoVacio
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    listaEventos
                }

                HStack {
                    Spacer()
                    Button {
                        eventoEnEdicion = nil
                        mostrarFormulario = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.black)
                            .frame(width: 56, height: 56)
                            .background(Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    .accessibilityLabel("Agregar evento")
                }
                .padding(.bottom, 12)
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(uiColor: .systemBackground))
        .preferredColorScheme(.dark)
        .sheet(isPresented: $mostrarFormulario) {
            formularioEvento
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .alert("¿Quieres eliminarlo?", isPresented: $mostrarConfirmacionEliminar) {
            Button("Cancelar", role: .cancel) {
                eventoPorEliminar = nil
            }

            Button("Eliminar", role: .destructive) {
                if let evento = eventoPorEliminar {
                    viewModel.eliminarEvento(evento)
                }
                eventoPorEliminar = nil
            }
        } message: {
            Text("Eliminarás el evento seleccionado.")
        }
        .onAppear {
            viewModel.cargarEventos()
        }
    }

    private var barraSuperior: some View {
        HStack(spacing: 16) {
            Button(action: onMenuClick) {
                Image("hamburguesa_icono")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 34, height: 34)
            }
            .accessibilityLabel("Abrir menú")

            Text("Calendario")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.primary)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    private var calendarioMensual: some View {
        VStack(spacing: 16) {
            HStack {
                Button {
                    cambiarMes(-1)
                } label: {
                    Image("flecha_icono")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 32)
                        .rotationEffect(.degrees(180))
                }
                .disabled(anioVisible == 2000 && mesVisibleNumero == 1)
                .accessibilityLabel("Mes anterior")

                Spacer()

                Text("\(nombresMesesCalendario[mesVisibleNumero - 1]) \(anioVisible)")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.primary)

                Spacer()

                Button {
                    cambiarMes(1)
                } label: {
                    Image("flecha_icono")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 32)
                }
                .disabled(anioVisible == 2200 && mesVisibleNumero == 12)
                .accessibilityLabel("Mes siguiente")
            }

            LazyVGrid(columns: columnas, spacing: 12) {
                ForEach(Array(diasSemanaCalendario.enumerated()), id: \.offset) { _, dia in
                    Text(dia)
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columnas, spacing: 12) {
                ForEach(Array(diasDelMes.enumerated()), id: \.offset) { _, dia in
                    if let dia {
                        celdaDia(dia)
                    } else {
                        Color.clear
                            .frame(height: 34)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var diasDelMes: [Int?] {
        guard let intervalo = Calendar.current.range(
            of: .day,
            in: .month,
            for: mesVisible
        ) else {
            return []
        }

        let componentes = Calendar.current.dateComponents(
            [.year, .month],
            from: mesVisible
        )

        guard let primerDia = Calendar.current.date(from: componentes) else {
            return []
        }

        // Calendar.weekday: domingo = 1, lunes = 2, ..., sábado = 7.
        let diaSemana = Calendar.current.component(.weekday, from: primerDia)
        let espaciosIniciales = diaSemana - 1

        var resultado = Array<Int?>(repeating: nil, count: espaciosIniciales)
        resultado.append(contentsOf: intervalo.map { Optional($0) })

        while resultado.count % 7 != 0 {
            resultado.append(nil)
        }

        return resultado
    }

    private func celdaDia(_ dia: Int) -> some View {
        let fechaDia = fechaEnMesVisible(dia)
        let seleccionada = Calendar.current.isDate(
            fechaDia,
            inSameDayAs: fechaSeleccionada
        )
        let tieneEvento = diasConEventos.contains(claveFecha(fechaDia))

        return Button {
            fechaSeleccionada = fechaDia
        } label: {
            VStack(spacing: 3) {
                Text("\(dia)")
                    .font(.system(size: 16))
                    .foregroundStyle(
                        seleccionada ? Color.white : Color.primary
                    )
                    .frame(width: 30, height: 30)
                    .background {
                        if seleccionada {
                            Circle().fill(Color.accentColor)
                        }
                    }

                Circle()
                    .fill(tieneEvento ? Color.red : Color.clear)
                    .frame(width: 5, height: 5)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 38)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            "\(dia) de \(nombresMesesCalendario[mesVisibleNumero - 1])"
        )
    }

    private var estadoVacio: some View {
        VStack(spacing: 12) {
            Image("calendario_color")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)

            Text("Sin eventos")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("No hay eventos para este día.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 28)
    }

    private var listaEventos: some View {
        ScrollView {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.secondary.opacity(0.35))
                    .frame(height: 1)
                    .padding(.top, 20)

                ForEach(eventosDelDia, id: \.id) { evento in
                    tarjetaEvento(evento)
                }
            }
            .padding(.bottom, 90)
        }
    }

    private func tarjetaEvento(_ evento: Calendario) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Text(formatearFechaHora(evento))
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer(minLength: 0)

                Button {
                    eventoEnEdicion = evento
                    mostrarFormulario = true
                } label: {
                    Image("editar_icono")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26, height: 26)
                }
                .accessibilityLabel("Editar evento")

                Button {
                    eventoPorEliminar = evento
                    mostrarConfirmacionEliminar = true
                } label: {
                    Image("eliminar_icono")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26, height: 26)
                }
                .accessibilityLabel("Eliminar evento")
            }
            .padding(.top, 12)

            Text(evento.titulo)
                .font(.system(size: 20))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 4)

            if !evento.nota.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(evento.nota)
                    .font(.system(size: 17))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 8)
            }

            Rectangle()
                .fill(Color.secondary.opacity(0.35))
                .frame(height: 1)
                .padding(.top, 6)
        }
    }

    private var formularioEvento: some View {
        FormularioEventoCalendario(
            eventoOriginal: eventoEnEdicion,
            onCerrar: {
                mostrarFormulario = false
                eventoEnEdicion = nil
            },
            onGuardar: { evento in
                viewModel.guardarEvento(evento)
                fechaSeleccionada = fechaDesdeMillis(evento.fecha)
                mesVisible = Calendar.current.date(
                    from: Calendar.current.dateComponents(
                        [.year, .month],
                        from: fechaSeleccionada
                    )
                ) ?? fechaSeleccionada
                mostrarFormulario = false
                eventoEnEdicion = nil
            }
        )
    }

    private func cambiarMes(_ cantidad: Int) {
        guard let nuevoMes = Calendar.current.date(
            byAdding: .month,
            value: cantidad,
            to: mesVisible
        ) else {
            return
        }

        let anio = Calendar.current.component(.year, from: nuevoMes)
        guard (2000...2200).contains(anio) else { return }

        mesVisible = nuevoMes

        if !Calendar.current.isDate(fechaSeleccionada, equalTo: nuevoMes, toGranularity: .month) {
            fechaSeleccionada = Calendar.current.date(
                from: Calendar.current.dateComponents([.year, .month], from: nuevoMes)
            ) ?? nuevoMes
        }
    }

    private func fechaEnMesVisible(_ dia: Int) -> Date {
        let componentes = DateComponents(
            year: anioVisible,
            month: mesVisibleNumero,
            day: dia
        )

        return Calendar.current.date(from: componentes) ?? mesVisible
    }

    private func claveFecha(_ millis: Int64) -> String {
        claveFecha(fechaDesdeMillis(millis))
    }

    private func claveFecha(_ fecha: Date) -> String {
        let componentes = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: fecha
        )

        return "\(componentes.year ?? 0)-\(componentes.month ?? 0)-\(componentes.day ?? 0)"
    }

    private func mismoDia(_ millis: Int64, que fecha: Date) -> Bool {
        Calendar.current.isDate(
            fechaDesdeMillis(millis),
            inSameDayAs: fecha
        )
    }

    private func fechaDesdeMillis(_ millis: Int64) -> Date {
        Date(timeIntervalSince1970: Double(millis) / 1000)
    }

    private func formatearFechaHora(_ evento: Calendario) -> String {
        let fecha = fechaDesdeMillis(evento.fecha)
        let formatoFecha = DateFormatter()
        formatoFecha.locale = Locale(identifier: "es_CO")
        formatoFecha.dateFormat = "dd/MM/yyyy"

        let hora = evento.hora / 60
        let minuto = evento.hora % 60

        return "\(formatoFecha.string(from: fecha)) · \(String(format: "%02d:%02d", hora, minuto))"
    }
}

private struct FormularioEventoCalendario: View {
    let eventoOriginal: Calendario?
    let onCerrar: () -> Void
    let onGuardar: (Calendario) -> Void

    @State private var titulo = ""
    @State private var nota = ""
    @State private var fecha = Date()
    @State private var hora = Date()
    @State private var mensajeError: String?

    private var esEdicion: Bool {
        eventoOriginal != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Información del evento") {
                    TextField("Título", text: $titulo)

                    DatePicker(
                        "Fecha",
                        selection: $fecha,
                        displayedComponents: [.date]
                    )

                    DatePicker(
                        "Hora",
                        selection: $hora,
                        displayedComponents: [.hourAndMinute]
                    )

                    TextField("Nota (opcional)", text: $nota, axis: .vertical)
                        .lineLimit(2...4)
                }

                if let mensajeError {
                    Section {
                        Text(mensajeError)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(esEdicion ? "Editar evento" : "Nuevo evento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar", action: onCerrar)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar", action: guardar)
                }
            }
            .onAppear(perform: cargarEvento)
        }
    }

    private func cargarEvento() {
        guard let evento = eventoOriginal else { return }

        titulo = evento.titulo
        nota = evento.nota
        fecha = Date(timeIntervalSince1970: Double(evento.fecha) / 1000)

        let minutos = evento.hora
        var componentes = Calendar.current.dateComponents([.year, .month, .day], from: fecha)
        componentes.hour = minutos / 60
        componentes.minute = minutos % 60
        hora = Calendar.current.date(from: componentes) ?? fecha
    }

    private func guardar() {
        let tituloLimpio = titulo.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !tituloLimpio.isEmpty else {
            mensajeError = "Escribe el título del evento."
            return
        }

        let calendario = Calendar.current
        let fechaNormalizada = calendario.startOfDay(for: fecha)
        let fechaMillis = Int64(fechaNormalizada.timeIntervalSince1970 * 1000)
        let componentesHora = calendario.dateComponents([.hour, .minute], from: hora)
        let minutos = (componentesHora.hour ?? 0) * 60 + (componentesHora.minute ?? 0)

        let evento = Calendario(
            id: eventoOriginal?.id ?? 0,
            titulo: tituloLimpio,
            fecha: fechaMillis,
            hora: minutos,
            nota: nota.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        onGuardar(evento)
    }
}
