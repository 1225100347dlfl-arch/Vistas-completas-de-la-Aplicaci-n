// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:lavaya/app.dart';
import 'package:lavaya/data/adapters/catalogo_local_adapter.dart';
import 'package:lavaya/data/datos_demo.dart';
import 'package:lavaya/data/memoria_lavaya_repository.dart';
import 'package:lavaya/presentation/app_state.dart';
import 'package:lavaya/screens/auth_gate.dart';
import 'package:lavaya/screens/atender_pedido_screen.dart';
import 'package:lavaya/screens/repartidor_pedidos_screen.dart';
import 'package:lavaya/screens/rutas.dart';
import 'package:lavaya/screens/splash_screen.dart';

void main() {
  testWidgets('renders the LavaYa splash screen', (WidgetTester tester) async {
    final appState = AppState(
      repo: MemoriaLavaYaRepository(),
      catalogo: CatalogoLocalAdapter(),
    );
    await appState.iniciar();

    await tester.pumpWidget(
      LavaYaApp(
        appState: appState,
        home: const SplashScreen(duracion: Duration(hours: 1)),
      ),
    );

    expect(find.text('LavaYa'), findsOneWidget);
    expect(find.text('Tu ropa limpia, sin salir de casa'), findsOneWidget);
  });

  testWidgets('repartidor can open and view an assigned order',
      (WidgetTester tester) async {
    final repo = MemoriaLavaYaRepository();
    final appState = AppState(
      repo: repo,
      catalogo: CatalogoLocalAdapter(),
    );
    await appState.iniciar();
    await sembrarDatosDemo(repo);
    expect(await appState.iniciarSesion(correoRepartidorDemo, contrasenaDemo),
        isNull);

    await tester.pumpWidget(
      LavaYaApp(
        appState: appState,
        home: const AuthGate(),
        routes: {
          rutaAtender: (_) => const AtenderPedidoScreen(),
          rutaMisPedidos: (_) => const RepartidorPedidosScreen(),
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hola, Carlos'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Atender pedido'));
    await tester.pumpAndSettle();

    expect(find.text('Datos de la recolección'), findsOneWidget);
    expect(find.text('Registrar peso'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
