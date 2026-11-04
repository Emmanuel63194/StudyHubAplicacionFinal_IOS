
import SwiftUI

enum PantallaSeleccionada: Hashable {
    case resumen
    case calendario
    case asignaturas
    case calificaciones
    case cuestionarios
}

private struct OpcionMenu: Identifiable {
    let pantalla: PantallaSeleccionada
    let texto: String
    let nombreIcono: String

    var id: PantallaSeleccionada { pantalla }
}

struct PanelNavegacionLateral: View {
    let pantallaActual: PantallaSeleccionada
    let alSeleccionarOpcion: (PantallaSeleccionada) -> Void

    private let opciones: [OpcionMenu] = [
        OpcionMenu(
            pantalla: .resumen,
            texto: "Resumen",
            nombreIcono: "casa_home"
        ),
        OpcionMenu(
            pantalla: .calendario,
            texto: "Calendario",
            nombreIcono: "calendario_icono"
        ),
        OpcionMenu(
            pantalla: .asignaturas,
            texto: "Asignaturas",
            nombreIcono: "asignatura_icono"
        ),
        OpcionMenu(
            pantalla: .calificaciones,
            texto: "Calificaciones",
            nombreIcono: "calificacion_icono"
        ),
        OpcionMenu(
            pantalla: .cuestionarios,
            texto: "Cuestionarios",
            nombreIcono: "cuestionario_icono"
        )
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Agenda escolar")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Color.primary)
                .padding(.bottom, 16)

            Rectangle()
                .fill(Color.primary)
                .frame(height: 1)

            VStack(spacing: 4) {
                ForEach(opciones) { opcion in
                    elementoMenu(opcion)
                }
            }
            .padding(.top, 16)

            Spacer(minLength: 20)

            Image("logo_principal")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .offset(y: -30)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxHeight: .infinity)
        .frame(width: 310)
        .background(Color(uiColor: .systemBackground))
    }

    private func elementoMenu(_ opcion: OpcionMenu) -> some View {
        let seleccionado = opcion.pantalla == pantallaActual

        return Button {
            alSeleccionarOpcion(opcion.pantalla)
        } label: {
            HStack(spacing: 16) {
                Image(opcion.nombreIcono)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 26)

                Text(opcion.texto)
                    .font(.system(size: 20))
                    .foregroundStyle(Color.primary)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if seleccionado {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.accentColor.opacity(0.25))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}
