const List<String> _mesesCortos = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

String _dos(int n) => n.toString().padLeft(2, '0');

DateTime soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);

bool mismoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// 2026-10-03 -> "3 oct 2026"
String formatoFechaCorta(DateTime d) => '${d.day} ${_mesesCortos[d.month - 1]} ${d.year}';

/// 2026-10-03 -> "03/10/2026"
String formatoFecha(DateTime d) => '${_dos(d.day)}/${_dos(d.month)}/${d.year}';

/// 8:05 -> "08:05"   20:30 -> "20:30"
String formatoHora(int hora, int minuto) => '${_dos(hora)}:${_dos(minuto)}';

/// 2026-10-03 10:30 -> "3 oct · 10:30"
String formatoFechaHora(DateTime d) =>
    '${d.day} ${_mesesCortos[d.month - 1]} · ${formatoHora(d.hour, d.minute)}';
