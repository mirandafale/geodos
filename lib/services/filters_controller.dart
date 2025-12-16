// filters_controller.dart corregido y extendido

import 'package:flutter/foundation.dart';

class FiltersState {
  final String? type;
  final int? year;
  final String? scope;
  final String? category;
  final String search;

  const FiltersState({
    this.type,
    this.year,
    this.scope,
    this.category,
    this.search = '',
  });

  FiltersState copyWith({
    String? type,
    int? year,
    String? scope,
    String? category,
    String? search,
  }) {
    return FiltersState(
      type: type ?? this.type,
      year: year ?? this.year,
      scope: scope ?? this.scope,
      category: category ?? this.category,
      search: search ?? this.search,
    );
  }

  static const empty = FiltersState();
}

class FiltersController extends ChangeNotifier {
  FiltersState _state = FiltersState.empty;
  static final FiltersController instance = FiltersController._();
  FiltersController._();

  FiltersState get state => _state;

  void setType(String? type) {
    _state = _state.copyWith(type: type);
    notifyListeners();
  }

  void setYear(int? year) {
    _state = _state.copyWith(year: year);
    notifyListeners();
  }

  void setScope(String? scope) {
    _state = _state.copyWith(scope: scope);
    notifyListeners();
  }

  void setCategory(String? category) {
    _state = _state.copyWith(category: category);
    notifyListeners();
  }

  void setSearch(String search) {
    _state = _state.copyWith(search: search);
    notifyListeners();
  }

  void reset() {
    _state = FiltersState.empty;
    notifyListeners();
  }
}
