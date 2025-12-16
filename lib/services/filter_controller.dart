import 'package:flutter/foundation.dart';

class FiltersState {
  final String type;   // Tipo de proyecto
  final int? year;     // Año
  final String scope;  // Ámbito
  final String search; // Texto

  const FiltersState({
    this.type = 'Todos',
    this.year,
    this.scope = 'Todos',
    this.search = '',
  });

  FiltersState copyWith({String? type, int? year, String? scope, String? search}) => FiltersState(
    type: type ?? this.type,
    year: year ?? this.year,
    scope: scope ?? this.scope,
    search: search ?? this.search,
  );
}

class FiltersController extends ChangeNotifier {
  FiltersState _state = const FiltersState();
  FiltersState get state => _state;

  static final FiltersController instance = FiltersController._();
  FiltersController._();

  // sets
  void setType(String v)  { _state = _state.copyWith(type: v);  notifyListeners(); }
  void setYear(int? v)    { _state = _state.copyWith(year: v);  notifyListeners(); }
  void setScope(String v) { _state = _state.copyWith(scope: v); notifyListeners(); }
  void setSearch(String v){ _state = _state.copyWith(search: v);notifyListeners(); }

  // reset
  void reset() { _state = const FiltersState(); notifyListeners(); }
}
