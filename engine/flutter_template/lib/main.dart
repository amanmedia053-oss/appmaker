import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final raw = await rootBundle.loadString('assets/project.json');
  final data = jsonDecode(raw) as Map<String, dynamic>;
  runApp(GeneratedReadingApp(data: data));
}

class GeneratedReadingApp extends StatelessWidget {
  const GeneratedReadingApp({super.key, required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final name = data['name'] as String? ?? 'زما کتابتون';
    return MaterialApp(
      title: name,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: accent),
        scaffoldBackgroundColor: const Color(0xFFF6F5FB),
      ),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: ReadingHome(data: data),
    );
  }
}

class ReadingHome extends StatelessWidget {
  const ReadingHome({super.key, required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final name = data['name'] as String? ?? 'زما کتابتون';
    final category = data['category'] as String? ?? 'کتابونه';
    final themeSeed = data['themeColor'] as int? ?? 0xFF7054E8;
    final accent = Color(themeSeed);
    final books = (data['books'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
                colors: [accent, accent.withValues(alpha: .82), accent.withValues(alpha: .62)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 34),
                const SizedBox(height: 16),
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)),
                const SizedBox(height: 7),
                Text(category, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                Text('${books.length} لیکنې', style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text('کتابتون', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          if (books.isEmpty)
            const Card(child: Padding(
              padding: EdgeInsets.all(22),
              child: Text('تر اوسه کومه لیکنه نشته.', textAlign: TextAlign.center),
            ))
          else
            ...books.map((book) => Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: const CircleAvatar(
                  backgroundColor: accent.withValues(alpha: .12),
                  child: Icon(Icons.menu_book_rounded, color: accent),
                ),
                title: Text(book['title'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(book['body'] as String? ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ReadingPage(
                    title: book['title'] as String? ?? '',
                    body: book['body'] as String? ?? '',
                  ),
                )),
              ),
            )),
          const SizedBox(height: 18),
          const Center(child: Text('په AppMaker جوړ شوی', style: TextStyle(color: Colors.black45, fontSize: 12))),
        ],
      ),
    );
  }
}

class ReadingPage extends StatelessWidget {
  const ReadingPage({super.key, required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: SelectionArea(
      child: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),
          Text(body, style: const TextStyle(fontSize: 18, height: 2.0)),
        ],
      ),
    ),
  );
}
