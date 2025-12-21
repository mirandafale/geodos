// filters_controller.dart corregido y extendido

import 'package:flutter/foundation.dart';
import 'package:geodos/models/project.dart';

const _unset = Object();

const _defaultCategory = 'MEDIOAMBIENTE';
const _defaultIsland = 'CANARIAS';

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
    Object? year = _unset,
    Object? scope = _unset,
    Object? category = _unset,
    Object? island = _unset,
    Object? search = _unset,
  }) {
    return FiltersState(
      year: year == _unset ? this.year : year as int?,
      scope: scope == _unset ? this.scope : scope as ProjectScope?,
      category: category == _unset ? this.category : category as String?,
      island: island == _unset ? this.island : island as String?,
      search: search == _unset ? this.search : (search as String? ?? ''),
    );
  }

  static const defaults = FiltersState(
    category: _defaultCategory,
    island: _defaultIsland,
  );
}

class FiltersController extends ChangeNotifier {
  FiltersState _state = FiltersState.defaults;
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
    _state = FiltersState.defaults;
    notifyListeners();
  }
}
