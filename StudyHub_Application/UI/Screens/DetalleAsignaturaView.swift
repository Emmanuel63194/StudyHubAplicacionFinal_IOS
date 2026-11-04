
import SwiftUI

private let colorTextoSecundarioDetalle = Color(
    red: 152.0 / 255.0,
    green: 152.0 / 255.0,
    blue: 152.0 / 255.0
)

private struct BloqueHorarioDetalle: Identifiable {
    let id: Int
    let dia: String
    let inicio: String
    let fin: String
}

struct DetalleAsignaturaView: View {

    let asignatura: Asignatura?

    @ObservedObject var calificacionViewModel: CalificacionViewModel

    var onBack: () -> Void = {}

    @State private var mostrarAyuda = false

    private let colorTarjeta = Color(
        red: 43.0 / 255.0,
        green: 43.0 / 255.0,
        blue: 43.0 / 255.0
    )

    private var calificacionesAsignatura: [Calificacion] {
        guard let asignatura else { return [] }

        return calificacionViewModel.calificaciones.filter {
            $0.asignaturaId == asignatura.id
        }
    }

    private var calificacionesRecientes: [Calificacion] {
        let calendario = Calendar.current
        let inicioHoy = calendario.startOfDay(for: Date())

        guard let inicioHaceCincoDias = calendario.date(
            byAdding: .day,
            value: -5,
            to: inicioHoy
        ),
        let inicioManana = calendario.date(
            byAdding: .day,
            value: 1,
            to: inicioHoy
        ) else {
            return []
        }

        return calificacionesAsignatura
            .filter {
                let fecha = Date(
                    timeIntervalSince1970: Double($0.fecha) / 1000
                )

                return fecha >= inicioHaceCincoDias &&
                    fecha < inicioManana
            }
            .sorted { $0.fecha > $1.fecha }
    }

    private var porcentajeTotal: Int {
        calificacionesAsignatura.reduce(0) {
            $0 + $1.porcentaje
        }
    }

    private var promedio: Double? {
        guard porcentajeTotal > 0 else { return nil }

        let sumaPonderada = calificacionesAsignatura.reduce(0.0) {
            $0 + $1.nota * Double($1.porcentaje)
        }

        return sumaPonderada / Double(porcentajeTotal)
    }

    private var bloquesHorario: [BloqueHorarioDetalle] {
        guard let horario = asignatura?.horario,
              !horario.isEmpty else {
            return []
        }

        return horario
            .split(separator: ";")
            .enumerated()
            .compactMap { indice, elemento in
                let partes = elemento
                    .split(
                        separator: ",",
                        omittingEmptySubsequences: false
                    )
                    .map {
                        $0.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )
                    }

                guard partes.count >= 3 else {
                    return nil
                }

                return BloqueHorarioDetalle(
                    id: indice,
                    dia: partes[0],
                    inicio: partes[1],
                    fin: partes[2]
                )
            }
    }

    var body: some View {
        Group {
            if let asignatura {
                contenido(asignatura)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 42))
                        .foregroundColor(.gray)

                    Text("Asignatura no disponible")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)

                    Text("No se encontró la asignatura seleccionada.")
                        .font(.system(size: 16))
                        .foregroundColor(
                            colorTextoSecundarioDetalle
                        )
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(24)
                .background(
                    Color(
                        red: 25.0 / 255.0,
                        green: 25.0 / 255.0,
                        blue: 25.0 / 255.0
                    )
                )
            }
        }
        .preferredColorScheme(.dark)
        .alert(
            "¿Cómo funciona el promedio?",
            isPresented: $mostrarAyuda
        ) {
            Button("Entendido", role: .cancel) {}
        } message: {
            Text(
                """
                Es un promedio ponderado: cada nota vale según su porcentaje.

                Promedio = la suma de (nota × porcentaje), dividida entre la suma de los porcentajes.

                Ejemplo: 4.0 (40 %) y 3.0 (60 %).

                (4.0 × 40 + 3.0 × 60) ÷ 100 = 3.4

                Si aún no has registrado el 100 %, se calcula solo con los porcentajes que ya tienes.
                """
            )
        }
    }

    private func contenido(_ asignatura: Asignatura) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                encabezado(asignatura)

                if !asignatura.salon.isEmpty {
                    tarjeta(minHeight: 69) {
                        HStack(spacing: 12) {
                            Image("ubicacion_blanco_icono")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)

                            Text(asignatura.salon)
                                .font(.system(size: 20))
                                .foregroundStyle(.white)
                                .lineLimit(1)

                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity, minHeight: 36)
                    }
                }

                tarjeta(minHeight: 134) {
                    tituloTarjeta(
                        icono: "promedio_icono",
                        texto: "Promedio"
                    )

                    Spacer(minLength: 8)

                    Group {
                        if let promedio {
                            Text(String(format: "%.1f", promedio))
                                .font(.system(size: 32))
                                .foregroundStyle(.white)
                        } else {
                            Capsule()
                                .fill(.white)
                                .frame(width: 25, height: 4)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 66)
                }

                if !bloquesHorario.isEmpty {
                    tarjeta(minHeight: 120) {
                        tituloTarjeta(
                            icono: "horario_blanco_icono",
                            texto: "Horario semanal"
                        )

                        Spacer(minLength: 12)

                        tablaHorario
                    }
                }

                tarjeta(
                    minHeight: calificacionesRecientes.isEmpty
                        ? 160 : 120
                ) {
                    tituloTarjeta(
                        icono: "calificacion_icono",
                        texto: "Calificaciones recientes"
                    )

                    Spacer(minLength: 12)

                    if calificacionesRecientes.isEmpty {
                        Text("Sin calificaciones")
                            .font(.system(size: 16))
                            .foregroundStyle(
                                colorTextoSecundarioDetalle
                            )
                            .frame(
                                maxWidth: .infinity,
                                minHeight: 88
                            )
                            .multilineTextAlignment(.center)
                    } else {
                        ForEach(
                            Array(calificacionesRecientes.prefix(3)),
                            id: \.id
                        ) { calificacion in
                            filaCalificacion(calificacion)
                        }
                    }
                }

                Button {
                    mostrarAyuda = true
                } label: {
                    Text("¿Cómo funciona el promedio?")
                        .font(.system(size: 18))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )
                        .background(colorTarjeta)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 16)
                        )
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(16)
        }
        .background(
            Color(
                red: 25.0 / 255.0,
                green: 25.0 / 255.0,
                blue: 25.0 / 255.0
            )
        )
        .scrollIndicators(.hidden)
    }

    private func encabezado(
        _ asignatura: Asignatura
    ) -> some View {
        HStack(spacing: 16) {
            Button(action: onBack) {
                Image("regresar_icono")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Regresar")

            Text(asignatura.nombre)
                .font(.system(size: 23, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func tarjeta<Contenido: View>(
        minHeight: CGFloat = 0,
        @ViewBuilder contenido: () -> Contenido
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            contenido()
        }
        .padding(16)
        .frame(
            maxWidth: .infinity,
            minHeight: minHeight,
            alignment: .topLeading
        )
        .background(colorTarjeta)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func tituloTarjeta(
        icono: String,
        texto: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(icono)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)

            Text(texto)
                .font(.system(size: 20))
                .foregroundStyle(.white)

            Spacer(minLength: 0)
        }
    }

    // MARK: - Horario semanal

    private var tablaHorario: some View {
        VStack(spacing: 0) {
            ForEach(
                Array(bloquesHorario.enumerated()),
                id: \.element.id
            ) { indice, bloque in

                if indice > 0 {
                    Rectangle()
                        .fill(.white)
                        .frame(height: 1)
                }

                HStack(spacing: 0) {
                    Text(bloque.dia)
                        .frame(maxWidth: .infinity)
                        .padding(8)

                    Rectangle()
                        .fill(.white)
                        .frame(width: 1)

                    Text(
                        "\(formatearHora(bloque.inicio)) - \(formatearHora(bloque.fin))"
                    )
                    .frame(maxWidth: .infinity)
                    .padding(8)
                }
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            }
        }
        .overlay {
            Rectangle()
                .stroke(.white, lineWidth: 1)
        }
        .frame(maxWidth: 340)
        .frame(maxWidth: .infinity)
    }

    /// Convierte minutos desde la medianoche a una hora de 12 horas.
    /// Ejemplo: 420 -> 7:00 AM; 540 -> 9:00 AM.
    private func formatearHora(_ minutos: String) -> String {
        guard let valor = Int(minutos),
              (0..<(24 * 60)).contains(valor) else {
            return minutos
        }

        let hora24 = valor / 60
        let minuto = valor % 60

        let hora12 = hora24 % 12 == 0 ? 12 : hora24 % 12
        let periodo = hora24 < 12 ? "AM" : "PM"

        return String(
            format: "%d:%02d %@",
            hora12,
            minuto,
            periodo
        )
    }

    private func filaCalificacion(
        _ calificacion: Calificacion
    ) -> some View {
        HStack(spacing: 12) {
            Text(String(format: "%.1f", calificacion.nota))
                .font(.system(size: 20))
                .foregroundStyle(.white)
                .frame(width: 45, height: 45)
                .background(colorCirculo(calificacion.nota))
                .clipShape(Circle())

            Text(calificacion.descripcion)
                .font(.system(size: 17))
                .foregroundStyle(colorTextoSecundarioDetalle)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )

            Text(formatearFecha(calificacion.fecha))
                .font(.system(size: 14))
                .foregroundStyle(colorTextoSecundarioDetalle)
        }
        .padding(.vertical, 4)
    }

    private func colorCirculo(_ nota: Double) -> Color {
        switch nota {
        case ..<3.0:
            return Color(
                red: 1.0,
                green: 152.0 / 255.0,
                blue: 0
            )

        case ..<4.0:
            return Color(
                red: 1.0,
                green: 193.0 / 255.0,
                blue: 7.0 / 255.0
            )

        default:
            return Color(
                red: 76.0 / 255.0,
                green: 175.0 / 255.0,
                blue: 80.0 / 255.0
            )
        }
    }

    private func formatearFecha(_ milisegundos: Int64) -> String {
        let fecha = Date(
            timeIntervalSince1970: Double(milisegundos) / 1000
        )

        return fecha.formatted(
            .dateTime.day().month(.twoDigits)
        )
    }
}

