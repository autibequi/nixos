---
name: code/flutter
description: "Knowledge-base do app doings (Flutter/Dart) — stack, estrutura, padroes Drift/Provider, comandos uteis."
---

# Skill: Flutter — doings app

> Conhecimento acumulado pelo agente doings-auto.
> Atualizar a cada ciclo com o que foi aprendido.
> App em: `~/projects/doings`

## Stack

| Camada | Lib | Versao |
|--------|-----|--------|
| State | provider | ^6.1.2 |
| DB | drift + drift_flutter | ^2.32.0 |
| SQLite | sqlite3_flutter_libs | ^0.6.0 |
| ID | uuid | ^4.5.1 |
| Design | Material 3 (built-in) | — |

## Estrutura do projeto

```
lib/
├── main.dart                    — bootstrap, providers, DB init
├── app.dart                     — MaterialApp, theme
├── core/
│   ├── theme/app_theme.dart     — ThemeData Material3
│   └── services/
│       ├── recurrence_parser.dart
│       └── recurrence_service.dart
├── data/
│   ├── database.dart            — AppDatabase (Drift), tabelas, DAOs
│   ├── database.g.dart          — gerado: flutter pub run build_runner build
│   └── repositories/
│       ├── drift_todo_repository.dart
│       └── todo_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── todo.dart
│   │   └── recurrence.dart
│   └── repositories/
│       └── todo_repository.dart
└── presentation/
    ├── pages/home_page.dart
    ├── providers/todo_provider.dart
    └── widgets/
        ├── add_todo_field.dart
        ├── empty_state.dart
        ├── filter_bar.dart
        ├── recurrence_picker.dart
        └── todo_tile.dart
```

## Padroes Drift (banco de dados)

```dart
// Definir tabela
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get icon => text()();
  IntColumn get color => integer()();
  IntColumn get sortOrder => integer()();
}

// Migrations — sempre incrementar schemaVersion
@DriftDatabase(tables: [Todos, Categories])
class AppDatabase extends _$AppDatabase {
  @override
  int get schemaVersion => 2; // incrementar

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(todos, todos.categoryId);
        await m.createTable(categories);
      }
    },
  );
}

// Watch (stream reativo)
Stream<List<Category>> watchAll() =>
    (select(categories)..orderBy([(c) => OrderingTerm(expression: c.sortOrder)]))
        .watch();

// Regenerar apos mudar schema:
// flutter pub run build_runner build --delete-conflicting-outputs
```

## Padroes Provider

```dart
// Provider com stream do banco
class CategoryProvider extends ChangeNotifier {
  final CategoryRepository _repo;
  List<Category> _categories = [];
  int _activeIndex = 0;

  CategoryProvider({required CategoryRepository repo}) : _repo = repo {
    _repo.watchAll().listen((cats) {
      _categories = cats;
      notifyListeners();
    });
  }

  Category? get activeCategory =>
      _categories.isEmpty ? null : _categories[_activeIndex];

  void setActive(int index) {
    _activeIndex = index;
    notifyListeners();
  }
}

// MultiProvider no main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => TodoProvider(repository: todoRepo)),
    ChangeNotifierProvider(create: (_) => CategoryProvider(repository: catRepo)),
  ],
  child: const App(),
)
```

## Material 3 — snippets uteis

```dart
// FAB grande
FloatingActionButton.extended(
  onPressed: () => _showAddSheet(context),
  label: const Text('Nova tarefa'),
  icon: const Icon(Icons.add),
)

// BottomNavigationBar dinamica
BottomNavigationBar(
  currentIndex: provider.activeIndex,
  onTap: provider.setActive,
  type: BottomNavigationBarType.fixed,
  items: categories.map((c) => BottomNavigationBarItem(
    icon: Icon(c.iconData),
    label: c.name,
  )).toList(),
)

// Dismissible (swipe)
Dismissible(
  key: Key(todo.id),
  background: Container(color: Colors.green), // direita = completar
  secondaryBackground: Container(color: Colors.red), // esquerda = deletar
  onDismissed: (dir) {
    if (dir == DismissDirection.startToEnd) provider.complete(todo);
    else provider.delete(todo);
  },
  child: TodoTile(todo: todo),
)

// Bottom sheet modal
showModalBottomSheet(
  context: context,
  isScrollControlled: true, // expansivel
  builder: (ctx) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
    child: const AddTodoBottomSheet(),
  ),
)
```

## Comandos uteis

```bash
# Rodar no web (mais rapido para testar)
flutter run -d web-server --web-port 8080

# Regenerar codigo Drift apos mudar schema
flutter pub run build_runner build --delete-conflicting-outputs

# Analisar sem rodar
flutter analyze

# Listar dispositivos
flutter devices
```

## Icones Material sugeridos para categorias

```dart
const categoryIcons = {
  'Pessoal': Icons.person_outline,
  'Trabalho': Icons.work_outline,
  'Saude': Icons.favorite_outline,
  'Cachorro': Icons.pets,
  'Familia': Icons.family_restroom,
  'Financas': Icons.account_balance_wallet_outlined,
  'Estudos': Icons.school_outlined,
  'Casa': Icons.home_outlined,
  'Lazer': Icons.sports_esports_outlined,
  'Compras': Icons.shopping_cart_outlined,
};
```

## Erros conhecidos

> (preencher a medida que forem encontrados)

---

*Atualizado automaticamente pelo agente doings-auto. Ultima atualizacao: 2026-03-22*
