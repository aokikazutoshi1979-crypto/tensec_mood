import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tensec_mood/screens/home_screen.dart';
import 'package:tensec_mood/services/mood_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<Map> box;
  late MoodRepository repository;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('tensec_mood_test_');
    Hive.init(tempDir.path);
    box = await Hive.openBox<Map>('mood_entries_test');
    repository = MoodRepository(box);
    await repository.loadEntries();
  });

  tearDownAll(() async {
    await box.clear();
    await box.close();
    await Hive.deleteBoxFromDisk('mood_entries_test');
    await tempDir.delete(recursive: true);
  });

  testWidgets('Home screen shows core UI', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(repository: repository),
      ),
    );

    expect(find.text('10秒で気分を記録'), findsOneWidget);
    expect(find.text('原因タグ (任意)'), findsOneWidget);
    expect(find.text('保存する'), findsOneWidget);
  });
}
