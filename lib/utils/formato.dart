/// Pesos colombianos con punto de miles: 12500 -> $12.500
String pesos(num valor) {
  final n = valor.round();
  final miles = n.abs().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return '${n < 0 ? '-' : ''}\$$miles';
}

/// 25/11/2026 · 3:05 pm. Si no es una fecha válida devuelve '-'.
String fechaHora(dynamic iso) {
  final d = DateTime.tryParse('${iso ?? ''}');
  if (d == null) return '-';
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '$dd/$mm/${d.year} · $h:$m ${d.hour < 12 ? 'am' : 'pm'}';
}
