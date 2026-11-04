
import SwiftUI

private let filtrosCalificaciones = [
    "Hoy",
    "Ayer",
    "Última semana",
    "Último mes",
    "Todas"
]

private let azulPorcentajeCalificacion = Color(
    red: 172.0 / 255.0,
    green: 198.0 / 255.0,
    blue: 1.0
)

struct PantallaCalificacionesView: View {

    @ObservedObject var calificacionViewModel: CalificacionViewModel
    @ObservedObject var asignaturaViewModel: AsignaturaViewModel

    var onMenuClick: () -> Void = {}
    var onAgregarClick: () -> Void = {}
    var onEditarClick: (Calificacion) -> Void = { _ in }

    @State private var filtro = "Última semana"
    @State private var calificacionAEliminar: Calificacion?
    @State private var mostrarConfirmacionEliminar = false

    private var asignaturas: [Asignatura] {
        asignaturaViewModel.asignaturas
    }

    private var calificacionesVisibles: [Calificacion] {
        calificacionViewModel.calificaciones
            .filter { calificacion in
                cumpleFiltro(fechaMillis: calificacion.fecha)
                    && asignaturas.contains {
                        $0.id == calificacion.asignaturaId
                    }
            }
            .sorted { $0.fecha > $1.fecha }
    }

    private var hayCalificaciones: Bool {
        !calificacionesVisibles.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            barraSuperior

            Spacer()
                .frame(height: 16)

            if hayCalificaciones {
                listaCalificaciones
            } else {
                estadoVacio
            }

            filaFiltroYBoton
                .padding(.bottom, 8)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
        .preferredColorScheme(.dark)
        .alert(
            "¿Quieres eliminarla?",
            isPresented: $mostrarConfirmacionEliminar
        ) {
            Button("Cancelar", role: .cancel) {
                calificacionAEliminar = nil
            }

            Button("Eliminar", role: .destructive) {
                if let calificacion = calificacionAEliminar {
                    calificacionViewModel.eliminar(calificacion)
                }

                calificacionAEliminar = nil
            }
        } message: {
            Text("Eliminarás la calificación seleccionada.")
        }
        .onAppear {
            calificacionViewModel.cargarCalificaciones()
            asignaturaViewModel.cargarAsignaturas()
        }
    }

    // MARK: - Barra superior

    private var barraSuperior: some View {
        HStack(spacing: 16) {
            Button(action: onMenuClick) {
                Image("hamburguesa_icono")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Abrir menú")

            Text("Calificaciones")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.primary)

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Lista de calificaciones

    private var listaCalificaciones: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(asignaturasConCalificaciones, id: \.id) { asignatura in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(asignatura.nombre)
                            .font(.system(size: 20))
                            .foregroundStyle(.white)
                            .padding(.leading, 50)

                        ForEach(calificacionesDe(asignatura), id: \.id) { calificacion in
                            TarjetaCalificacionView(
                                calificacion: calificacion,
                                onEditar: {
                                    onEditarClick(calificacion)
                                },
                                onEliminar: {
                                    calificacionAEliminar = calificacion
                                    mostrarConfirmacionEliminar = true
                                }
                            )
                        }
                    }
                }
            }
            .padding(.bottom, 100)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var asignaturasConCalificaciones: [Asignatura] {
        asignaturas.filter { asignatura in
            calificacionesVisibles.contains {
                $0.asignaturaId == asignatura.id
            }
        }
    }

    private func calificacionesDe(_ asignatura: Asignatura) -> [Calificacion] {
        calificacionesVisibles
            .filter { $0.asignaturaId == asignatura.id }
            .sorted { $0.fecha > $1.fecha }
    }

    // MARK: - Estado vacío

    private var estadoVacio: some View {
        VStack(spacing: 20) {
            Spacer()

            Image("buzon_vacio")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 280)
                .frame(height: 210)

            Text("Sin calificaciones")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.primary)
                .multilineTextAlignment(.center)

            Text("Las calificaciones que añadas aparecerán aquí")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Filtro y botón agregar

    private var filaFiltroYBoton: some View {
        HStack(alignment: .bottom, spacing: 12) {
            Menu {
                ForEach(filtrosCalificaciones, id: \.self) { opcion in
                    Button {
                        filtro = opcion
                    } label: {
                        if filtro == opcion {
                            Label(opcion, systemImage: "checkmark")
                        } else {
                            Text(opcion)
                        }
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    Image("calendario_blanco")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)

                    Text(filtro)
                        .font(.system(size: 17))
                        .foregroundStyle(Color.primary)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    Image("flecha_icono")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .rotationEffect(.degrees(90))
                }
                .padding(.horizontal, 16)
                .frame(height: 56)
                .frame(maxWidth: .infinity)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)

            Button(action: onAgregarClick) {
                Text("+")
                    .font(.system(size: 30, weight: .regular))
                    .foregroundStyle(.black)
                    .frame(width: 56, height: 56)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Agregar calificación")
        }
    }

    // MARK: - Filtros por fecha

    private func cumpleFiltro(fechaMillis: Int64) -> Bool {
        guard filtro != "Todas" else {
            return true
        }

        let fechaCalificacion = Date(
            timeIntervalSince1970: Double(fechaMillis) / 1000
        )

        let calendario = Calendar.current
        let hoy = calendario.startOfDay(for: Date())
        let fecha = calendario.startOfDay(for: fechaCalificacion)

        switch filtro {
        case "Hoy":
            return calendario.isDate(fecha, inSameDayAs: hoy)

        case "Ayer":
            guard let ayer = calendario.date(
                byAdding: .day,
                value: -1,
                to: hoy
            ) else {
                return false
            }

            return calendario.isDate(fecha, inSameDayAs: ayer)

        case "Última semana":
            guard let limite = calendario.date(
                byAdding: .day,
                value: -6,
                to: hoy
            ) else {
                return false
            }

            return fecha >= limite && fecha <= hoy

        case "Último mes":
            guard let limite = calendario.date(
                byAdding: .day,
                value: -29,
                to: hoy
            ) else {
                return false
            }

            return fecha >= limite && fecha <= hoy

        default:
            return true
        }
    }
}

// MARK: - Tarjeta individual

private struct TarjetaCalificacionView: View {

    let calificacion: Calificacion
    let onEditar: () -> Void
    let onEliminar: () -> Void

    var body: some View {
        VStack(spacing: 8) {

            // Fila superior: nota y descripción
            HStack(spacing: 12) {
                circuloNota

                Text(calificacion.descripcion)
                    .font(.system(size: 18))
                    .foregroundColor(Color.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Fila inferior: fecha e iconos centrados,
            // porcentaje alineado al extremo derecho
            ZStack {
                HStack(spacing: 10) {
                    Text(formatearFecha(calificacion.fecha))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)

                    Button(action: onEditar) {
                        Image("editar_icono")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("Editar calificación")

                    Button(action: onEliminar) {
                        Image("eliminar_icono")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("Eliminar calificación")
                }
                .frame(maxWidth: .infinity, alignment: .center)

                HStack {
                    Spacer()

                    Text("\(calificacion.porcentaje)%")
                        .font(.system(size: 20))
                        .foregroundColor(azulPorcentajeCalificacion)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .frame(height: 110)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Círculo de la nota

    private var circuloNota: some View {
        Text(formatearNota(calificacion.nota))
            .font(.system(size: 20))
            .foregroundColor(.white)
            .frame(width: 45, height: 45)
            .background(colorDeNota(calificacion.nota))
            .clipShape(Circle())
            .frame(width: 45, height: 45)
    }

    private func colorDeNota(_ nota: Double) -> Color {
        if nota < 3.0 {
            return Color(
                red: 229.0 / 255.0,
                green: 57.0 / 255.0,
                blue: 53.0 / 255.0
            )
        } else if nota < 4.0 {
            return Color(
                red: 212.0 / 255.0,
                green: 177.0 / 255.0,
                blue: 6.0 / 255.0
            )
        } else {
            return Color(
                red: 46.0 / 255.0,
                green: 158.0 / 255.0,
                blue: 46.0 / 255.0
            )
        }
    }

    private func formatearNota(_ nota: Double) -> String {
        String(format: "%g", nota)
    }

    private func formatearFecha(_ millis: Int64) -> String {
        let fecha = Date(
            timeIntervalSince1970: Double(millis) / 1000
        )

        let formato = DateFormatter()
        formato.locale = Locale(identifier: "es_CO")
        formato.timeZone = TimeZone.current
        formato.dateFormat = "MMMM d, yyyy"

        let texto = formato.string(from: fecha)
        return texto.prefix(1).uppercased() + texto.dropFirst()
    }
}

