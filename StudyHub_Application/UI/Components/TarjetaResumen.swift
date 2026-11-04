
import SwiftUI

struct TarjetaResumen<ContenidoEventos: View>: View {
    var contenidoEventos: ContenidoEventos?

    init(
        @ViewBuilder contenidoEventos: () -> ContenidoEventos? = { nil }
    ) {
        self.contenidoEventos = contenidoEventos()
    }

    private let colorFondo = Color(
        red: 48.0 / 255.0,
        green: 48.0 / 255.0,
        blue: 48.0 / 255.0
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                iconoLibreta

                Text("Eventos pendientes")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }

            Spacer()
                .frame(height: 16)

            if let contenidoEventos {
                contenidoEventos
            } else {
                Image("hombre_jardin")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)

                Spacer()
                    .frame(height: 12)

                Text("No hay trabajos o exámenes por realizar en el momento.")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(colorFondo)
        .clipShape(RoundedRectangle(cornerRadius: 25))
    }

    private var iconoLibreta: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 30, height: 30)

            Image("libreta_icono")
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 15)
        }
    }
}

extension TarjetaResumen where ContenidoEventos == EmptyView {
    init() {
        self.contenidoEventos = nil
    }
}
