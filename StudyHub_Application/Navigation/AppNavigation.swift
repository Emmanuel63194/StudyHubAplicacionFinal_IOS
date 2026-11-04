
import SwiftUI

@MainActor
private final class ModelosNavegacion {
    let asignaturas: AsignaturaViewModel
    let calendario: CalendarioViewModel
    let calificaciones: CalificacionViewModel
    let cuestionarios: CuestionarioViewModel

    init() {
        asignaturas = AsignaturaViewModel()
        calendario = CalendarioViewModel()
        calificaciones = CalificacionViewModel()
        cuestionarios = CuestionarioViewModel()
    }
}

private enum DestinoNavegacion {
    case resumen
    case calendario
    case asignaturas
    case calificaciones
    case cuestionarios
    case crearAsignatura
    case detalleAsignatura
    case crearCalificacion
    case crearCuestionario
    case realizarCuestionario

    var pantallaPrincipal: PantallaSeleccionada? {
        switch self {
        case .resumen:
            return .resumen

        case .calendario:
            return .calendario

        case .asignaturas, .crearAsignatura, .detalleAsignatura:
            return .asignaturas

        case .calificaciones, .crearCalificacion:
            return .calificaciones

        case .cuestionarios, .crearCuestionario, .realizarCuestionario:
            return .cuestionarios
        }
    }
}

@MainActor
struct AppNavigation: View {
    @State private var modelos: ModelosNavegacion?
    @State private var historial: [DestinoNavegacion] = [.resumen]
    @State private var mostrarMenu = false

    @State private var asignaturaSeleccionada: Asignatura?
    @State private var calificacionSeleccionada: Calificacion?
    @State private var cuestionarioSeleccionado: Cuestionario?

    private var destinoActual: DestinoNavegacion {
        historial.last ?? .resumen
    }

    private var pantallaSeleccionada: PantallaSeleccionada {
        destinoActual.pantallaPrincipal ?? .resumen
    }

    var body: some View {
        ZStack(alignment: .leading) {
            Group {
                if let modelos {
                    contenidoPrincipal(modelos)
                } else {
                    ProgressView("Cargando StudyHub...")
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity
                        )
                        .background(Color(uiColor: .systemBackground))
                }
            }

            if mostrarMenu {
                Color.black
                    .opacity(0.5)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        cerrarMenu()
                    }
                    .zIndex(1)

                if modelos != nil {
                    PanelNavegacionLateral(
                        pantallaActual: pantallaSeleccionada,
                        alSeleccionarOpcion: seleccionarPantalla
                    )
                    .frame(maxHeight: .infinity)
                    .transition(.move(edge: .leading))
                    .zIndex(2)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            if modelos == nil {
                modelos = ModelosNavegacion()
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: ProgramadorNotificacionesEvento.eventoAbrirCalendario
            )
        ) { notificacion in
            guard let eventoId = notificacion.userInfo?["evento_id"] as? Int64 else {
                return
            }

            historial = [.calendario]
            cerrarMenu()
            modelos?.calendario.cargarEventos()

            print(
                "Solicitud para abrir el evento \(eventoId) en el calendario."
            )
        }
        .animation(.easeInOut(duration: 0.22), value: mostrarMenu)
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func contenidoPrincipal(
        _ modelos: ModelosNavegacion
    ) -> some View {
        switch destinoActual {
        case .resumen:
            PantallaInicioView(
                viewModel: modelos.calendario,
                onMenuClick: abrirMenu
            )

        case .calendario:
            PantallaCalendarioView(
                viewModel: modelos.calendario,
                onMenuClick: abrirMenu
            )

        case .asignaturas:
            PantallaAsignaturasView(
                viewModel: modelos.asignaturas,
                onMenuClick: abrirMenu,
                onAgregarClick: {
                    asignaturaSeleccionada = nil
                    navegarA(.crearAsignatura)
                },
                onAsignaturaClick: { asignatura in
                    asignaturaSeleccionada = asignatura
                    navegarA(.detalleAsignatura)
                },
                onEditarClick: { asignatura in
                    asignaturaSeleccionada = asignatura
                    navegarA(.crearAsignatura)
                }
            )

        case .calificaciones:
            PantallaCalificacionesView(
                calificacionViewModel: modelos.calificaciones,
                asignaturaViewModel: modelos.asignaturas,
                onMenuClick: abrirMenu,
                onAgregarClick: {
                    calificacionSeleccionada = nil
                    navegarA(.crearCalificacion)
                },
                onEditarClick: { calificacion in
                    calificacionSeleccionada = calificacion
                    navegarA(.crearCalificacion)
                }
            )

        case .cuestionarios:
            PantallaCuestionariosView(
                viewModel: modelos.cuestionarios,
                onMenuClick: abrirMenu,
                onAgregarClick: {
                    cuestionarioSeleccionado = nil
                    navegarA(.crearCuestionario)
                },
                onEditarClick: { cuestionario in
                    cuestionarioSeleccionado = cuestionario
                    navegarA(.crearCuestionario)
                },
                onEliminarClick: { cuestionario in
                    Task { @MainActor in
                        modelos.cuestionarios.eliminarCuestionario(cuestionario)
                    }
                },
                onCuestionarioClick: { cuestionario in
                    cuestionarioSeleccionado = cuestionario
                    navegarA(.realizarCuestionario)
                }
            )

        case .crearAsignatura:
            CrearAsignaturaView(
                viewModel: modelos.asignaturas,
                asignaturaAEditar: asignaturaSeleccionada,
                onBack: retroceder
            )

        case .detalleAsignatura:
            DetalleAsignaturaView(
                asignatura: asignaturaSeleccionada,
                calificacionViewModel: modelos.calificaciones,
                onBack: retroceder
            )

        case .crearCalificacion:
            CrearCalificacionesView(
                calificacionViewModel: modelos.calificaciones,
                asignaturaViewModel: modelos.asignaturas,
                onBack: {
                    Task { @MainActor in
                        modelos.calificaciones.cargarCalificaciones()
                        retroceder()
                    }
                },
                onCrearAsignatura: {
                    asignaturaSeleccionada = nil
                    navegarA(.crearAsignatura)
                },
                calificacionAEditar: calificacionSeleccionada
            )

        case .crearCuestionario:
            CrearCuestionarioView(
                viewModel: modelos.cuestionarios,
                onVolver: retroceder,
                onCreado: {
                    Task { @MainActor in
                        modelos.cuestionarios.cargarCuestionarios()
                        retroceder()
                    }
                },
                cuestionarioAEditar: cuestionarioSeleccionado
            )

        case .realizarCuestionario:
            RealizarCuestionarioView(
                cuestionario: cuestionarioSeleccionado,
                onVolver: retroceder
            )
        }
    }

    private func abrirMenu() {
        withAnimation(.easeInOut(duration: 0.22)) {
            mostrarMenu = true
        }
    }

    private func cerrarMenu() {
        withAnimation(.easeInOut(duration: 0.22)) {
            mostrarMenu = false
        }
    }

    private func seleccionarPantalla(
        _ pantalla: PantallaSeleccionada
    ) {
        let destino: DestinoNavegacion

        switch pantalla {
        case .resumen:
            destino = .resumen

        case .calendario:
            destino = .calendario

        case .asignaturas:
            destino = .asignaturas

        case .calificaciones:
            destino = .calificaciones

        case .cuestionarios:
            destino = .cuestionarios
        }

        historial = [destino]
        cerrarMenu()
    }

    private func navegarA(_ destino: DestinoNavegacion) {
        cerrarMenu()
        historial.append(destino)
    }

    private func retroceder() {
        cerrarMenu()

        if historial.count > 1 {
            historial.removeLast()
        } else {
            historial = [.resumen]
        }
    }
}

