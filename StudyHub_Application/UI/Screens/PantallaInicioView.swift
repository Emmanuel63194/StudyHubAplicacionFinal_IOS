
import SwiftUI

struct PantallaInicioView: View {

    @ObservedObject var viewModel: CalendarioViewModel
    var onMenuClick: () -> Void = {}

    @State private var mostrarDetalle = false
    @State private var eventoDetalle: Calendario?

    private var eventosHoy: [Calendario] {
        eventosParaFecha(Date())
    }

    private var eventosManana: [Calendario] {
        let manana = Calendar.current.date(
            byAdding: .day,
            value: 1,
            to: Date()
        ) ?? Date()

        return eventosParaFecha(manana)
    }

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    barraSuperior

                    Spacer()
                        .frame(height: 24)

                    seccionEventos(
                        titulo: "Hoy",
                        eventos: eventosHoy
                    )

                    Spacer()
                        .frame(height: 28)

                    seccionEventos(
                        titulo: "Mañana",
                        eventos: eventosManana
                    )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }

            if mostrarDetalle, let evento = eventoDetalle {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        cerrarDetalle()
                    }
                    .transition(.opacity)
                    .zIndex(1)

                VStack {
                    Spacer()

                    ResumenEmergente(
                        evento: evento,
                        onCerrar: cerrarDetalle
                    )
                    .transition(
                        .move(edge: .bottom)
                            .combined(with: .opacity)
                    )
                }
                .ignoresSafeArea(edges: .bottom)
                .zIndex(2)
            }
        }
        .animation(
            .easeInOut(duration: 0.3),
            value: mostrarDetalle
        )
        .preferredColorScheme(.dark)
    }

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

            Text("Resumen")
                .font(.system(size: 25, weight: .semibold))
                .foregroundColor(Color.primary)

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func seccionEventos(
        titulo: String,
        eventos: [Calendario]
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(titulo)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color.primary)

            if eventos.isEmpty {
                TarjetaResumen()
            } else {
                TarjetaResumen {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(eventos, id: \.id) { evento in
                            filaEvento(evento)

                            if evento.id != eventos.last?.id {
                                Divider()
                                    .overlay(
                                        Color.white.opacity(0.12)
                                    )
                            }
                        }
                    }
                }
            }
        }
    }

    private func filaEvento(
        _ evento: Calendario
    ) -> some View {
        let completado = viewModel.eventosCompletados
            .contains(evento.id)

        return HStack(alignment: .top, spacing: 14) {
            Button {
                viewModel.alternarCompletado(
                    eventoId: evento.id
                )
            } label: {
                ZStack {
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 2)
                        .frame(width: 30, height: 30)

                    if completado {
                        Image("check_icono")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 25, height: 25)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                completado
                    ? "Marcar como pendiente"
                    : "Marcar como completado"
            )

            Button {
                eventoDetalle = evento
                mostrarDetalle = true
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    Text(evento.titulo)
                        .font(.system(size: 20))
                        .foregroundColor(Color.primary)
                        .lineLimit(1)
                        .strikethrough(completado)

                    if !evento.nota.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty {
                        Text(evento.nota)
                            .font(.system(size: 17))
                            .foregroundColor(Color.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if completado {
                Button {
                    viewModel.eliminarEvento(evento)
                } label: {
                    Image("eliminar_icono")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Eliminar evento")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func eventosParaFecha(
        _ fecha: Date
    ) -> [Calendario] {
        let calendar = Calendar.current

        return viewModel.eventos
            .filter { evento in
                let fechaEvento = Date(
                    timeIntervalSince1970:
                        Double(evento.fecha) / 1000
                )

                return calendar.isDate(
                    fechaEvento,
                    inSameDayAs: fecha
                )
            }
            .sorted { primero, segundo in
                if primero.hora != segundo.hora {
                    return primero.hora < segundo.hora
                }

                return primero.id < segundo.id
            }
    }

    private func cerrarDetalle() {
        withAnimation(.easeInOut(duration: 0.3)) {
            mostrarDetalle = false
        }
    }
}

