/// Dinero en pesos enteros. Se usa en lugar de un `int` suelto para que
/// el formato ("$90") y la multiplicación por kilos vivan en un solo lugar.
class Dinero {
  const Dinero(this.pesos);

  final int pesos;

  static const Dinero cero = Dinero(0);

  Dinero operator *(int factor) => Dinero(pesos * factor);

  /// Para pesos con decimales (por ejemplo 4.5 kg). Se redondea al peso más cercano.
  Dinero porKilos(double kilos) => Dinero((pesos * kilos).round());

  String get texto => '\$$pesos';

  @override
  bool operator ==(Object other) => other is Dinero && other.pesos == pesos;

  @override
  int get hashCode => pesos.hashCode;

  @override
  String toString() => texto;
}
