import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:to_do/Models/notification.dart';
import 'package:to_do/Models/to_do_list.dart';
import 'package:to_do/Providers/item_provider.dart';
import 'package:to_do/Providers/lists_provider.dart';
import 'package:to_do/Providers/notification_provider.dart';
import 'package:to_do/Utils/sort_by.dart';
import 'package:to_do/Utils/shared_preferences_helper.dart';
import '../fixtures/mock_database.dart';
import '../fixtures/mock_providers.dart';
import '../fixtures/test_data.dart';

void main() {
  late ItemProvider itemProvider;
  late ListsProvider listsProvider;
  late MockNotificationProvider mockNotificationProvider;

  setUpAll(() async {
    // Widget tests run under AutomatedTestWidgetsFlutterBinding (fake-async
    // zone). sqflite_common_ffi must be initialised here — before the first
    // testWidgets body — so that database calls complete without needing
    // platform channel round-trips.
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await dotenv.load(fileName: '.env');
    SharedPreferences.setMockInitialValues({});
    await SharedPreferencesHelper.instance.initialise();
    setupMocktailFallbacks();
  });

  setUp(() async {
    // All three providers share the SAME database instance so inserts are
    // visible across providers — essential for toggleItemDone to read list state.
    final testDb = await TestDatabaseHelper.getTestDatabase();
    itemProvider = ItemProvider(database: testDb);
    listsProvider = ListsProvider(database: testDb);
    mockNotificationProvider = MockNotificationProvider();
    listsProvider.notificationProvider = mockNotificationProvider;
    listsProvider.selectedOption = SortBy.creationNTL;
  });

  tearDown(() async {
    await TestDatabaseHelper.clearAllTables();
    await TestDatabaseHelper.closeTestDatabase();
  });

  // Pump a minimal widget tree with all three providers so that
  // toggleItemDone can resolve Provider.of<ListsProvider>(context) and
  // Provider.of<NotificationProvider>(context).
  Future<BuildContext> pumpProviderTree(WidgetTester tester) async {
    BuildContext? ctx;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ListsProvider>.value(value: listsProvider),
          ChangeNotifierProvider<ItemProvider>.value(value: itemProvider),
          ChangeNotifierProvider<NotificationProvider>.value(
              value: mockNotificationProvider),
        ],
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(builder: (c) {
            ctx = c;
            return const SizedBox.shrink();
          }),
        ),
      ),
    );
    await tester.pump();
    return ctx!;
  }

  // ─────────────────────────────────────────────────────────────────────────
  group('ItemProvider - toggleItemDone - basic toggle', () {
    testWidgets('marks undone item as done and increments accomplishedItems',
        (tester) async {
      // tester.runAsync runs code outside the fake-async zone so real FFI
      // futures (sqflite) complete normally.
      await tester.runAsync(() async {
        final db = await TestDatabaseHelper.getTestDatabase();

        // Insert parent list with totalItems=2, accomplishedItems=0
        final list = TestDataFactory.createTestList(
          id: 'list-1', totalItems: 2, accomplishedItems: 0, hasDeadline: false,
        );
        await db.insert('todo_lists', list.toMap());

        // Insert item directly (bypasses counter side-effects)
        await db.insert('todo_items', {
          'id': 'item-1', 'listId': 'list-1', 'title': 'Task',
          'content': '', 'done': 0, 'itemIndex': 0,
        });

        final item = TestDataFactory.createTestItem(
          id: 'item-1', listId: 'list-1', done: false,
        );

        final ctx = await pumpProviderTree(tester);
        await itemProvider.toggleItemDone(item, ctx);

        final itemRow = await db.query('todo_items',
            where: 'id = ?', whereArgs: ['item-1']);
        expect(itemRow.first['done'], 1);

        final listRow = await db.query('todo_lists',
            where: 'id = ?', whereArgs: ['list-1']);
        expect(listRow.first['accomplishedItems'], 1);
      });
    });

    testWidgets('marks done item as undone and decrements accomplishedItems',
        (tester) async {
      await tester.runAsync(() async {
        final db = await TestDatabaseHelper.getTestDatabase();

        final list = TestDataFactory.createTestList(
          id: 'list-1', totalItems: 2, accomplishedItems: 1, hasDeadline: false,
        );
        await db.insert('todo_lists', list.toMap());

        await db.insert('todo_items', {
          'id': 'item-1', 'listId': 'list-1', 'title': 'Task',
          'content': '', 'done': 1, 'itemIndex': 0,
        });

        final item = TestDataFactory.createTestItem(
          id: 'item-1', listId: 'list-1', done: true,
        );

        final ctx = await pumpProviderTree(tester);
        await itemProvider.toggleItemDone(item, ctx);

        final itemRow = await db.query('todo_items',
            where: 'id = ?', whereArgs: ['item-1']);
        expect(itemRow.first['done'], 0);

        final listRow = await db.query('todo_lists',
            where: 'id = ?', whereArgs: ['list-1']);
        expect(listRow.first['accomplishedItems'], 0);
      });
    });

    testWidgets('toggling twice returns item to original state',
        (tester) async {
      await tester.runAsync(() async {
        final db = await TestDatabaseHelper.getTestDatabase();

        final list = TestDataFactory.createTestList(
          id: 'list-1', totalItems: 2, accomplishedItems: 0, hasDeadline: false,
        );
        await db.insert('todo_lists', list.toMap());

        await db.insert('todo_items', {
          'id': 'item-1', 'listId': 'list-1', 'title': 'Task',
          'content': '', 'done': 0, 'itemIndex': 0,
        });

        final item = TestDataFactory.createTestItem(
          id: 'item-1', listId: 'list-1', done: false,
        );

        final ctx = await pumpProviderTree(tester);
        await itemProvider.toggleItemDone(item, ctx);  // done=1
        await itemProvider.toggleItemDone(item, ctx);  // done=0

        final itemRow = await db.query('todo_items',
            where: 'id = ?', whereArgs: ['item-1']);
        expect(itemRow.first['done'], 0);

        final listRow = await db.query('todo_lists',
            where: 'id = ?', whereArgs: ['list-1']);
        expect(listRow.first['accomplishedItems'], 0);
      });
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('ItemProvider - toggleItemDone - notification disabling', () {
    testWidgets('completing the last item triggers disableNotificationById',
        (tester) async {
      await tester.runAsync(() async {
        final db = await TestDatabaseHelper.getTestDatabase();

        // Pre-load the mock with a notification for list-1 so the forEach
        // inside toggleItemDone calls disableNotificationById once.
        mockNotificationProvider.addTestNotification(
          'list-1',
          TestDataFactory.createTestNotification(id: 'notif-1', listId: 'list-1'),
        );

        // Stub disableNotificationById (not concretely overridden in mock).
        when(() => mockNotificationProvider.disableNotificationById(
              any<Notifications>(),
              any<ToDoList>(),
            )).thenAnswer((_) async {});

        // List with totalItems=1, accomplishedItems=0 — marking item done = all done
        final list = TestDataFactory.createTestList(
          id: 'list-1', totalItems: 1, accomplishedItems: 0,
          hasDeadline: true, deadline: DateTime(2026, 12, 25),
        );
        await db.insert('todo_lists', list.toMap());
        await db.insert('todo_items', {
          'id': 'item-1', 'listId': 'list-1', 'title': 'Last Task',
          'content': '', 'done': 0, 'itemIndex': 0,
        });

        final item = TestDataFactory.createTestItem(
          id: 'item-1', listId: 'list-1', done: false,
        );

        final ctx = await pumpProviderTree(tester);
        await itemProvider.toggleItemDone(item, ctx);

        verify(() => mockNotificationProvider.disableNotificationById(
              any<Notifications>(), any<ToDoList>())).called(1);
      });
    });

    testWidgets(
        'completing a non-last item does NOT trigger disableNotificationById',
        (tester) async {
      await tester.runAsync(() async {
        final db = await TestDatabaseHelper.getTestDatabase();

        // Stub disableNotificationById so verifyNever can check it.
        when(() => mockNotificationProvider.disableNotificationById(
              any<Notifications>(),
              any<ToDoList>(),
            )).thenAnswer((_) async {});

        // List with totalItems=2, accomplishedItems=0 — marking one done leaves 1 pending
        final list = TestDataFactory.createTestList(
          id: 'list-1', totalItems: 2, accomplishedItems: 0,
          hasDeadline: true, deadline: DateTime(2026, 12, 25),
        );
        await db.insert('todo_lists', list.toMap());
        await db.insert('todo_items', {
          'id': 'item-1', 'listId': 'list-1', 'title': 'First Task',
          'content': '', 'done': 0, 'itemIndex': 0,
        });
        await db.insert('todo_items', {
          'id': 'item-2', 'listId': 'list-1', 'title': 'Second Task',
          'content': '', 'done': 0, 'itemIndex': 1,
        });

        final item = TestDataFactory.createTestItem(
          id: 'item-1', listId: 'list-1', done: false,
        );

        final ctx = await pumpProviderTree(tester);
        await itemProvider.toggleItemDone(item, ctx);

        verifyNever(() => mockNotificationProvider.disableNotificationById(
              any<Notifications>(), any<ToDoList>()));
      });
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('ItemProvider - toggleItemDone - edge cases', () {
    testWidgets('orphan item (no parent list) completes without throwing',
        (tester) async {
      await tester.runAsync(() async {
        final db = await TestDatabaseHelper.getTestDatabase();

        // Insert item with a listId that has no corresponding list row
        await db.insert('todo_items', {
          'id': 'item-orphan', 'listId': 'ghost-list', 'title': 'Orphan',
          'content': '', 'done': 0, 'itemIndex': 0,
        });

        final item = TestDataFactory.createTestItem(
          id: 'item-orphan', listId: 'ghost-list', done: false,
        );

        final ctx = await pumpProviderTree(tester);
        // Should not propagate — the internal try/catch in toggleItemDone handles it
        await itemProvider.toggleItemDone(item, ctx);

        // Item done state is unchanged
        final itemRow = await db.query('todo_items',
            where: 'id = ?', whereArgs: ['item-orphan']);
        expect(itemRow.first['done'], 0);
      });
    });
  });
}
