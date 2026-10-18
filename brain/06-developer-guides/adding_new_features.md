# 06. Developer Guides — Extending Inka & Adding Features

This step-by-step checklist guides developers or AI agents on how to safely introduce new features, models, screens, and PDF templates without breaking existing architecture.

---

## 🛠️ Step 1: Adding a New Data Model

1. **Check Assigned TypeIds**:
   Consult [Hive Registry](file:///Users/saravana/flutter/final%20clg%20management%20application/invoice%20generator/invoice_generator/brain/03-data-models/hive_registry.md). Pick an unused `typeId` (must be `>= 9`).
2. **Define Model (`lib/data/models/my_entity.dart`)**:
   ```dart
   import 'package:hive/hive.dart';
   part 'my_entity.g.dart';

   @HiveType(typeId: 9)
   class MyEntity extends HiveObject {
     @HiveField(0) final String id;
     @HiveField(1) final String title;

     MyEntity({required this.id, required this.title});

     Map<String, dynamic> toMap() => {'id': id, 'title': title};
     factory MyEntity.fromMap(Map<String, dynamic> map) =>
         MyEntity(id: map['id'], title: map['title']);
   }
   ```
3. **Generate Adapter**:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
4. **Register in `lib/main.dart`**:
   ```dart
   if (!Hive.isAdapterRegistered(9)) Hive.registerAdapter(MyEntityAdapter());
   await _safeOpenBox<MyEntity>('my_entities');
   ```

---

## ⚡ Step 2: Creating a Riverpod ViewModel

1. Create `lib/presentation/viewmodels/my_entity_viewmodel.dart`.
2. Extend `StateNotifier<List<MyEntity>>`.
3. In constructor, read initial list from `Hive.box<MyEntity>('my_entities').values.toList()`.
4. When mutating:
   - Write to Hive box: `await box.put(entity.id, entity)`.
   - Update state: `state = [...state, entity]`.
   - Call Firestore asynchronously: `_firestoreService.saveMyEntity(uid, entity)`.

---

## 📱 Step 3: Adding a Screen & Route

1. Create screen widget in `lib/presentation/screens/my_entity_screen.dart`.
2. Connect to provider via `ref.watch(myEntityViewModelProvider)`.
3. Add route to `routerProvider` in `lib/main.dart`:
   - If it should have bottom navigation or sidebar, nest inside `ShellRoute` routes list.
   - If it is a modal/fullscreen overlay, define outside `ShellRoute` with `parentNavigatorKey: rootNavigatorKey`.

---

## 📄 Step 4: Adding a New PDF Template

1. Open `lib/services/pdf_service.dart`.
2. Add a `PdfTemplateOption` entry to `PdfService.availableTemplates`.
3. Implement builder function `pw.Widget _buildMyNewTemplate(Invoice invoice, BusinessProfile profile, ...)` using `pdf/widgets.dart`.
4. Add case statement in `PdfService.generateInvoicePdf` routing `invoice.templateId` to your builder function.
