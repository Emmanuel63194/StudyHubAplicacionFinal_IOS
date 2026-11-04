
import SwiftUI

struct EliminarRecurso: View {
    let onCancelar: () -> Void
    let onEliminar: () -> Void

    var titulo: String = "¿Quieres eliminarlo?"
    var descripcion: String = "Eliminarás el cuestionario seleccionado"

    var body: some View {
        VStack(spacing: 0) {
            Text(titulo)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            Spacer()
                .frame(height: 20)

            Text(descripcion)
                .font(.system(size: 18))
                .foregroundStyle(Color(red: 0.596, green: 0.596, blue: 0.596))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            Spacer()
                .frame(height: 25)

            HStack(spacing: 16) {
                botonModal(
                    texto: "Cancelar",
                    colorFondo: Color(uiColor: .secondarySystemBackground),
                    colorTexto: .white,
                    accion: onCancelar
                )

                botonModal(
                    texto: "Eliminar",
                    colorFondo: Color.accentColor,
                    colorTexto: .black,
                    accion: onEliminar
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
        .frame(maxWidth: 444)
        .frame(minHeight: 191)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .padding(.horizontal, 20)
    }

    private func botonModal(
        texto: String,
        colorFondo: Color,
        colorTexto: Color,
        accion: @escaping () -> Void
    ) -> some View {
        Button(action: accion) {
            Text(texto)
                .font(.system(size: 24, weight: texto == "Eliminar" ? .semibold : .regular))
                .foregroundStyle(colorTexto)
                .frame(maxWidth: .infinity)
                .frame(height: 49)
                .background(colorFondo)
                .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(.plain)
    }
}

