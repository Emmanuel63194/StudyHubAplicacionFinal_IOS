
import SwiftUI

private struct EsquinasSuperioresRedondeadas: Shape {
    let radio: CGFloat

    func path(in rect: CGRect) -> Path {
        let radioSeguro = min(radio, min(rect.width / 2, rect.height))

        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radioSeguro))

        path.addQuadCurve(
            to: CGPoint(x: rect.minX + radioSeguro, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )

        path.addLine(to: CGPoint(x: rect.maxX - radioSeguro, y: rect.minY))

        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + radioSeguro),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )

        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()

        return path
    }
}

struct ResumenEmergente: View {
    let evento: Calendario
    let onCerrar: () -> Void

    private let colorTextoSecundario = Color(
        red: 0.596,
        green: 0.596,
        blue: 0.596
    )

    private let colorSuperficieResumen = Color(
        red: 39.0 / 255.0,
        green: 39.0 / 255.0,
        blue: 39.0 / 255.0
    )

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onCerrar) {
                    Image("cerrar_icono")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 38, height: 38)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Cerrar resumen")

                Spacer()

                Text(formatearFechaHoraEvento())
                    .font(.system(size: 16))
                    .foregroundStyle(colorTextoSecundario)
                    .multilineTextAlignment(.trailing)
            }
            .frame(maxWidth: .infinity)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(evento.titulo)
                        .font(.system(size: 20))
                        .foregroundStyle(Color.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if !evento.nota.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty {
                        Text(evento.nota)
                            .font(.system(size: 20))
                            .foregroundStyle(colorTextoSecundario)
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollIndicators(.visible)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity)
        .frame(maxHeight: UIScreen.main.bounds.height * 0.6)
        .background(colorSuperficieResumen)
        .clipShape(
            EsquinasSuperioresRedondeadas(radio: 16)
        )
    }

    private func formatearFechaHoraEvento() -> String {
        let fecha = Date(
            timeIntervalSince1970: TimeInterval(evento.fecha) / 1000
        )

        let calendario = Calendar.current

        let fechaFormateada = fecha.formatted(
            Date.FormatStyle()
                .weekday(.wide)
                .day()
                .month(.wide)
        )

        let minutosTotales = evento.hora
        let hora = minutosTotales / 60
        let minutos = minutosTotales % 60

        var componentes = DateComponents()
        componentes.calendar = calendario
        componentes.year = calendario.component(.year, from: fecha)
        componentes.month = calendario.component(.month, from: fecha)
        componentes.day = calendario.component(.day, from: fecha)
        componentes.hour = hora
        componentes.minute = minutos

        let fechaHora = calendario.date(from: componentes) ?? fecha

        return "\(fechaFormateada) · \(fechaHora.formatted(date: .omitted, time: .shortened))"
    }
}

