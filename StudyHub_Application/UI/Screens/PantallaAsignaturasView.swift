
import SwiftUI

struct PantallaAsignaturasView: View {
    @ObservedObject var viewModel: AsignaturaViewModel

    var onMenuClick: () -> Void = {}
    var onAgregarClick: () -> Void = {}
    var onAsignaturaClick: (Asignatura) -> Void = { _ in }
    var onEditarClick: (Asignatura) -> Void = { _ in }

    @State private var asignaturaAEliminar: Asignatura?
    @State private var mostrarConfirmacionEliminar = false

    private let colorTextoSecundario = Color(
        red: 152.0 / 255.0,
        green: 152.0 / 255.0,
        blue: 152.0 / 255.0
    )

    var body: some View {
        VStack(spacing: 0) {
            barraSuperior

            if viewModel.asignaturas.isEmpty {
                estadoVacio
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .offset(x: 12, y: -25)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.asignaturas, id: \.id) { asignatura in
                            TarjetaAsignaturaView(
                                nombre: asignatura.nombre,
                                salon: asignatura.salon,
                                onClick: {
                                    onAsignaturaClick(asignatura)
                                },
                                onEditar: {
                                    onEditarClick(asignatura)
                                },
                                onEliminar: {
                                    asignaturaAEliminar = asignatura
                                    mostrarConfirmacionEliminar = true
                                }
                            )
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 56)
                }
                .scrollIndicators(.hidden)
            }

            HStack {
                Spacer()

                Button(action: onAgregarClick) {
                    Text("+")
                        .font(.system(size: 30, weight: .regular))
                        .foregroundStyle(Color.black)
                        .frame(width: 56, height: 56)
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .buttonStyle(.plain)
            }
            .offset(y: -40)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .background(Color(uiColor: .systemBackground))
        .preferredColorScheme(.dark)
        .confirmationDialog(
            "¿Quieres eliminarla?",
            isPresented: $mostrarConfirmacionEliminar,
            titleVisibility: .visible
        ) {
            Button("Eliminar", role: .destructive) {
                eliminarAsignatura()
            }

            Button("Cancelar", role: .cancel) {
                asignaturaAEliminar = nil
            }
        } message: {
            Text("Eliminarás la asignatura seleccionada")
        }
        .alert(
            "No se pudo eliminar la asignatura",
            isPresented: Binding(
                get: { viewModel.error != nil },
                set: { _ in }
            )
        ) {
            Button("Aceptar", role: .cancel) {}
        } message: {
            Text(viewModel.error ?? "Ocurrió un error inesperado.")
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
            .buttonStyle(.plain)
            .accessibilityLabel("Abrir menú")

            Text("Asignaturas")
                .font(.system(size: 25, weight: .bold))
                .foregroundStyle(Color.primary)

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var estadoVacio: some View {
        VStack(spacing: 0) {
            Image("buzon_vacio")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 300)
                .frame(height: 210)

            Spacer()
                .frame(height: 20)

            Text("Sin asignaturas")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color.primary)
                .multilineTextAlignment(.center)

            Spacer()
                .frame(height: 8)

            Text("Las asignaturas que añadas aparecerán aquí")
                .font(.system(size: 16))
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func eliminarAsignatura() {
        guard let asignatura = asignaturaAEliminar else {
            return
        }

        viewModel.eliminar(asignatura)
        asignaturaAEliminar = nil
    }
}

struct TarjetaAsignaturaView: View {
    let nombre: String
    let salon: String
    var onClick: () -> Void = {}
    var onEditar: () -> Void = {}
    var onEliminar: () -> Void = {}

    private var alturaTarjeta: CGFloat {
        salon.isEmpty ? 66 : 80
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Image("calificacion_negro_icono")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .frame(width: 30, height: 30)
                    .background(Color.accentColor)
                    .clipShape(Circle())

                Text(nombre)
                    .font(.system(size: 20))
                    .foregroundStyle(Color.accentColor)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: onEditar) {
                    Image("editar_icono")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Editar asignatura")

                Button(action: onEliminar) {
                    Image("eliminar_icono")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Eliminar asignatura")
            }

            if !salon.isEmpty {
                HStack(spacing: 6) {
                    Image("ubicacion_icono")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)

                    Text(salon)
                        .font(.system(size: 18))
                        .foregroundStyle(
                            Color(
                                red: 152.0 / 255.0,
                                green: 152.0 / 255.0,
                                blue: 152.0 / 255.0
                            )
                        )
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: alturaTarjeta)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .contentShape(Rectangle())
        .onTapGesture(perform: onClick)
    }
}
