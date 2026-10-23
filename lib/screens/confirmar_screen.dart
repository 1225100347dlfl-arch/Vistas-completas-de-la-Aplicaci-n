import 'package:flutter/material.dart';

import '../core/fechas.dart';
import '../domain/builders/pedido_builder.dart';
import '../presentation/app_scope.dart';
import '../presentation/tema.dart';
import '../presentation/widgets/componentes.dart';
import 'rutas.dart';

/// 4. "Confirmar recolección": dirección, día, hora y notas para el repartidor.
/// Paso 2 de 3. Al confirmar se crea el pedido y se abre el seguimiento.
class ConfirmarScreen extends StatefulWidget {
  const ConfirmarScreen({super.key});

  @override
  State<ConfirmarScreen> createState() => _ConfirmarScreenState();
}

class _ConfirmarScreenState extends State<ConfirmarScreen> {
  final _form = GlobalKey<FormState>();
  final _direccion = TextEditingController();
  final _fecha = TextEditingController();
  final _hora = TextEditingController();
  final _notas = TextEditingController();

  DateTime? _dia;
  TimeOfDay? _horaElegida;
  bool _enviando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Si ya pidió antes, la dirección viene escrita.
    _direccion.text = AppScope.leer(context).ultimaDireccion ?? '';
  }

  @override
  void dispose() {
    _direccion.dispose();
    _fecha.dispose();
    _hora.dispose();
    _notas.dispose();
    super.dispose();
  }

  void _ponerDia(DateTime dia) {
    setState(() {
      _dia = soloFecha(dia);
      _fecha.text = formatoFecha(dia);
    });
  }

  Future<void> _elegirDia() async {
    final hoy = soloFecha(AppScope.leer(context).ahora);
    final elegido = await showDatePicker(
      context: context,
      initialDate: _dia ?? hoy,
      firstDate: hoy,
      lastDate: hoy.add(const Duration(days: 60)),
      helpText: 'Día de recolección',
    );
    if (elegido != null) _ponerDia(elegido);
  }

  Future<void> _elegirHora() async {
    final elegida = await showTimePicker(
      context: context,
      initialTime: _horaElegida ?? const TimeOfDay(hour: 10, minute: 0),
      helpText: 'Hora de recolección',
    );
    if (elegida == null) return;
    setState(() {
      _horaElegida = elegida;
      _hora.text = formatoHora(elegida.hour, elegida.minute);
    });
  }

  Future<void> _confirmar() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final dia = _dia;
    final hora = _horaElegida;
    if (dia == null || hora == null) return;

    final app = AppScope.leer(context);
    final nav = Navigator.of(context);
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      final pedido = await app.confirmarPedido(
        direccion: _direccion.text,
        recoleccion: DateTime(dia.year, dia.month, dia.day, hora.hour, hora.minute),
        notas: _notas.text,
      );
      if (!mounted) return;
      // Se quita todo lo que había encima del Home y se abre el seguimiento.
      nav.pushNamedAndRemoveUntil(
        rutaSeguimiento,
        (ruta) => ruta.isFirst,
        arguments: pedido.id,
      );
    } on DatosInvalidosException catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _error = e.errores.join('\n');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final servicio = app.servicioElegido;
    final estimado = app.estimado;
    final hoy = soloFecha(app.ahora);
    final manana = hoy.add(const Duration(days: 1));

    return Scaffold(
      backgroundColor: Tema.fondo,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                const CabeceraPantalla(titulo: 'Confirmar recolección', paso: 2),
                Expanded(
                  child: servicio == null || estimado == null
                      ? const _SinServicio()
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LavaTarjeta(
                                padding: const EdgeInsets.all(16),
                                color: Tema.primarioSuave,
                                bordeColor: Tema.primario.withAlpha(60),
                                child: Row(
                                  children: [
                                    const IconoBurbuja(
                                      icono: Icons.local_laundry_service_rounded,
                                      fondo: Colors.white,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(servicio.nombre, style: Tema.subtitulo()),
                                          Text(
                                            '${app.kilos} kg aprox.',
                                            style: Tema.cuerpo(color: Tema.textoSuave, tamano: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${estimado.texto} aprox.',
                                      style: Tema.subtitulo(color: Tema.primario),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              LavaTarjeta(
                                padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
                                child: Form(
                                  key: _form,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      LavaCampo(
                                        etiqueta: 'Dirección',
                                        controller: _direccion,
                                        hint: 'Calle y número, colonia',
                                        icono: Icons.location_on_outlined,
                                        accion: TextInputAction.next,
                                        validator: (v) => (v == null || v.trim().length < 5)
                                            ? 'Escribe tu calle, número y colonia.'
                                            : null,
                                      ),
                                      Text(
                                        'Día de recolección',
                                        style: Tema.cuerpo(tamano: 14)
                                            .copyWith(fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        children: [
                                          ChoiceChip(
                                            label: const Text('Hoy'),
                                            selected: _dia != null && mismoDia(_dia!, hoy),
                                            onSelected: (_) => _ponerDia(hoy),
                                          ),
                                          ChoiceChip(
                                            label: const Text('Mañana'),
                                            selected: _dia != null && mismoDia(_dia!, manana),
                                            onSelected: (_) => _ponerDia(manana),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: LavaCampo(
                                              etiqueta: 'Fecha',
                                              controller: _fecha,
                                              hint: 'dd/mm/aaaa',
                                              icono: Icons.calendar_today_rounded,
                                              soloLectura: true,
                                              onTap: _elegirDia,
                                              validator: (v) => (v == null || v.isEmpty)
                                                  ? 'Elige el día.'
                                                  : null,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: LavaCampo(
                                              etiqueta: 'Hora',
                                              controller: _hora,
                                              hint: 'hh:mm',
                                              icono: Icons.schedule_rounded,
                                              soloLectura: true,
                                              onTap: _elegirHora,
                                              validator: (v) => (v == null || v.isEmpty)
                                                  ? 'Elige la hora.'
                                                  : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                      LavaCampo(
                                        etiqueta: 'Notas para el repartidor (opcional)',
                                        controller: _notas,
                                        hint: 'Ej. Portón negro, tocar el timbre 2',
                                        icono: Icons.sticky_note_2_outlined,
                                        maxLineas: 3,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              if (_error != null) MensajeError(_error!),
                              FilledButton(
                                onPressed: _enviando ? null : _confirmar,
                                child: _enviando
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(strokeWidth: 3),
                                      )
                                    : const Text('Confirmar pedido'),
                              ),
                              const SizedBox(height: 10),
                              Center(
                                child: Text(
                                  'El precio final se confirma al pesar tu ropa.',
                                  style: Tema.cuerpo(color: Tema.textoSuave, tamano: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Por si se llega aquí sin haber elegido un servicio.
class _SinServicio extends StatelessWidget {
  const _SinServicio();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const IconoBurbuja(icono: Icons.local_laundry_service_rounded, tamano: 64),
            const SizedBox(height: 16),
            Text('Primero elige un servicio', style: Tema.subtitulo()),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }
}
