import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alpukat_app/main.dart';
import 'package:alpukat_app/injection/injection_container.dart'; // Import setup injection

void main() {
  // Inisialisasi semua dependencies (GetIt) sebelum test dijalankan
  // agar pemanggilan sl<AuthBloc>() dan lainnya di main.dart tidak error.
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initDependencies();
  });

  testWidgets('App initialization smoke test', (WidgetTester tester) async {
    // Render aplikasi AlpukatApp
    await tester.pumpWidget(const AlpukatApp());
    
    // Tunggu jika ada frame animasi atau microtask yang sedang berjalan
    await tester.pumpAndSettle(); 

    // Verifikasi dasar: Memastikan bahwa root aplikasi (MaterialApp) 
    // berhasil di-render ke layar tanpa menyebabkan crash.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}