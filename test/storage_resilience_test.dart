import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:krypton_ai/data/atomic_file.dart';
import 'package:krypton_ai/data/storage.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('krypton_store');
  });

  tearDown(() async {
    try {
      await dir.delete(recursive: true);
    } catch (_) {}
  });

  String path(String name) => '${dir.path}/$name';

  test('atomik yazma: tmp kalmaz, önceki sağlam sürüm .bak olarak saklanır', () async {
    final p = path('a.json');
    await AtomicFile.writeJson(p, {'a': 1});
    await AtomicFile.writeJson(p, {'a': 2});
    expect(await AtomicFile.readJson(p), {'a': 2});
    expect(File('$p.tmp').existsSync(), isFalse);
    expect(jsonDecode(File('$p.bak').readAsStringSync()), {'a': 1});
  });

  test('yarım yazılmış (bozuk) ana dosya: kenara alınır, yedekten kurtarılır, istisna yok', () async {
    final p = path('b.json');
    await AtomicFile.writeJson(p, {'a': 1});
    await AtomicFile.writeJson(p, {'a': 2});
    File(p).writeAsStringSync('{"a":'); // yarım kalmış yazma
    expect(await AtomicFile.readJson(p), {'a': 1});
    expect(File('$p.corrupt').existsSync(), isTrue);
    expect(jsonDecode(File(p).readAsStringSync()), {'a': 1}, reason: 'ana dosya geri yüklendi');
  });

  test('ana dosya yok ama tam yazılmış tmp var: tmp okunur; yarım tmp ise yedek okunur', () async {
    final p = path('c.json');
    await AtomicFile.writeJson(p, {'v': 1});
    await AtomicFile.writeJson(p, {'v': 2});
    File(p).deleteSync(); // rename penceresinde ölen süreç
    File('$p.tmp').writeAsStringSync('{"v":3}');
    expect(await AtomicFile.readJson(p), {'v': 3});

    File(p).deleteSync();
    File('$p.tmp').writeAsStringSync('{"v":'); // yarım tmp
    expect(await AtomicFile.readJson(p), {'v': 1}, reason: 'yedek');
  });

  test('bozuk dosya ve yedek yoksa null döner (çökmez)', () async {
    final p = path('d.json');
    File(p).writeAsStringSync('\u0000\u0000 bozuk');
    expect(await AtomicFile.readJson(p), isNull);
    expect(await AtomicFile.readJson(path('yok.json')), isNull);
  });

  test('bozuk ana dosya sağlam yedeğin üzerine yazılmaz', () async {
    final p = path('e.json');
    await AtomicFile.writeJson(p, {'g': 1});
    await AtomicFile.writeJson(p, {'g': 2}); // bak = g1
    File(p).writeAsStringSync('{bozuk');
    await AtomicFile.writeJson(p, {'g': 3});
    expect(await AtomicFile.readJson(p), {'g': 3});
    expect(jsonDecode(File('$p.bak').readAsStringSync()), {'g': 1});
  });

  test('eşzamanlı 20 yazma sıraya girer; son değer sağlam JSON; kuyruk boşalır', () async {
    final p = path('f.json');
    await Future.wait([for (var i = 0; i < 20; i++) AtomicFile.writeJson(p, {'i': i})]);
    expect(await AtomicFile.readJson(p), {'i': 19});
    await Future<void>.delayed(Duration.zero);
    expect(AtomicFile.pendingPaths, 0);
  });

  test('silme yedeği de siler: silinen kayıt yedekten geri gelmez', () async {
    final p = path('g.json');
    await AtomicFile.writeJson(p, {'x': 1});
    await AtomicFile.writeJson(p, {'x': 2});
    await AtomicFile.delete(p);
    expect(await AtomicFile.readJson(p), isNull);
  });

  test('Storage: bozuk ayar/kayıt dosyaları açılışta istisna fırlatmaz', () async {
    File(path('settings.json')).writeAsStringSync('{"theme":"ge');
    File(path('model_registry.json')).writeAsStringSync('{"a":{"path":1,"x":null},"b":5}');
    final st = Storage(root: dir);
    expect(await st.loadSettings(), isEmpty);
    final reg = await st.loadRegistry();
    expect(reg['a'], {'path': '1'});
    expect(reg.containsKey('b'), isFalse);
  });

  test('Storage: ayarlar yaz-oku gidiş dönüşü ve bozulma sonrası yedekten kurtarma', () async {
    final st = Storage(root: dir);
    await st.saveSettings({'theme': 'gece'});
    await st.saveSettings({'theme': 'gun'});
    File(path('settings.json')).writeAsStringSync('');
    expect((await st.loadSettings())['theme'], 'gece');
  });
}
