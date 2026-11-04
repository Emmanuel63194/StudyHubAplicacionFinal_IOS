
import SwiftUI

struct PantallaCuestionariosView: View {
    @ObservedObject var viewModel: CuestionarioViewModel

    var onMenuClick: () -> Void = {}
    var onAgregarClick: () -> Void = {}
    var onEditarClick: (Cuestionario) -> Void = { _ in }
    var onEliminarClick: (Cuestionario) -> Void = { _ in }
    var onCuestionarioClick: (Cuestionario) -> Void = { _ in }

    @State private var cuestionarioSeleccionadoParaEliminar: Cuestionario?
    @State private var mostrarConfirmacionEliminar = false
    @State private var mostrarCuestionarioRapido = false

    private let fondo = Color(red: 25 / 255, green: 25 / 255, blue: 25 / 255)
    private let filtros = ["Todos"]

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                barraSuperior

                if viewModel.cuestionarios.isEmpty {
                    estadoVacio
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .offset(x: 5, y: -35)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(viewModel.cuestionarios, id: \.id) { cuestionario in
                                tarjeta(cuestionario)
                            }
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 100)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            botonAgregar
                .padding(20)
                .padding(.bottom, 16)
        }
        .confirmationDialog(
            "¿Quieres eliminar este cuestionario?",
            isPresented: $mostrarConfirmacionEliminar,
            titleVisibility: .visible
        ) {
            Button("Eliminar", role: .destructive) {
                if let cuestionario = cuestionarioSeleccionadoParaEliminar {
                    onEliminarClick(cuestionario)
                }
                cuestionarioSeleccionadoParaEliminar = nil
            }

            Button("Cancelar", role: .cancel) {
                cuestionarioSeleccionadoParaEliminar = nil
            }
        } message: {
            Text("Eliminarás el cuestionario seleccionado.")
        }
        .sheet(isPresented: $mostrarCuestionarioRapido) {
            CuestionarioRapido(viewModel: viewModel) {
                mostrarCuestionarioRapido = false
            }
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

            Text("Cuestionarios")
                .font(.system(size: 25, weight: .semibold))
                .foregroundStyle(Color.primary)

            Spacer()

            Button {
                mostrarCuestionarioRapido = true
            } label: {
                Image("envio_rapido")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Crear cuestionario rápido")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 12)
    }

    private func tarjeta(_ cuestionario: Cuestionario) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 40, height: 40)

                Image("cuestionario_icono")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }

            Button {
                onCuestionarioClick(cuestionario)
            } label: {
                Text(cuestionario.titulo)
                    .font(.system(size: 20))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                onEditarClick(cuestionario)
            } label: {
                Image("editar_icono")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25, height: 25)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Editar cuestionario")

            Button {
                cuestionarioSeleccionadoParaEliminar = cuestionario
                mostrarConfirmacionEliminar = true
            } label: {
                Image("eliminar_icono")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25, height: 25)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Eliminar cuestionario")
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity)
        .frame(height: 67)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var estadoVacio: some View {
        VStack(spacing: 8) {
            Image("cuestionario_vacio")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 300)
                .frame(height: 210)

            Spacer()
                .frame(height: 12)

            Text("Sin cuestionarios")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Color.primary)
                .multilineTextAlignment(.center)

            Text("Los cuestionarios que añadas aparecerán aquí")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var botonAgregar: some View {
        Button(action: onAgregarClick) {
            Text("+")
                .font(.system(size: 30, weight: .regular))
                .foregroundStyle(Color.black)
                .frame(width: 56, height: 56)
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Agregar cuestionario")
    }
}
