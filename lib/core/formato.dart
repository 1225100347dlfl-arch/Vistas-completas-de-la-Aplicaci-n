/// 4.0 -> "4"   4.5 -> "4.5"
String formatoKilos(double kilos) =>
    kilos == kilos.roundToDouble() ? kilos.toInt().toString() : kilos.toStringAsFixed(1);
