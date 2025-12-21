// filters_controller.dart corregido y extendido

import 'package:flutter/foundation.dart';
import 'package:geodos/models/project.dart';

class FiltersState {
  final int? year;
  final ProjectScope? scope;
  final String? category;
  final String? island;
  final String search;

  const FiltersState({
    this.year,
    this.scope,
    this.category,
    this.island,
    this.search = '',
  });

  FiltersState copyWith({
    int? year,
    ProjectScope? scope,
    String? category,
    String? island,
    String? search,
  }) {
    return FiltersState(
      year: year ?? this.year,
      scope: scope ?? this.scope,
      category: category ?? this.category,
      island: island ?? this.island,
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

  void setYear(int? year) {
    _state = _state.copyWith(year: year);
    notifyListeners();
  }

  void setScope(ProjectScope? scope) {
    _state = _state.copyWith(scope: scope);
    notifyListeners();
  }

  void setCategory(String? category) {
    _state = _state.copyWith(category: category);
    notifyListeners();
  }

  void setIsland(String? island) {
    _state = _state.copyWith(island: island);
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
