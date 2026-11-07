import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const ink = Color(0xFF17213B);
const violet = Color(0xFF7357F6);
const pale = Color(0xFFF5F6FC);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppMakerApp());
}

class AppMakerApp extends StatelessWidget {
  const AppMakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppMaker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: pale,
        colorScheme: ColorScheme.fromSeed(seedColor: violet),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: pale,
          foregroundColor: ink,
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF5F6FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
      ),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const DashboardPage(),
    );
  }
}

class BookEntry {
  BookEntry({required this.title, required this.body});
  final String title;
  final String body;

  Map<String, dynamic> toJson() => {'title': title, 'body': body};
  factory BookEntry.fromJson(Map<String, dynamic> json) => BookEntry(
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
      );
}

class AppProject {
  AppProject({
    required this.name,
    required this.category,
    required this.createdAt,
    List<BookEntry>? books,
  }) : books = books ?? [];

  final String name;
  final String category;
  final String createdAt;
  final List<BookEntry> books;

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'createdAt': createdAt,
        'books': books.map((b) => b.toJson()).toList(),
      };

  factory AppProject.fromJson(Map<String, dynamic> json) => AppProject(
        name: json['name'] as String? ?? 'زما اپ',
        category: json['category'] as String? ?? 'کتابونه',
        createdAt: json['createdAt'] as String? ?? '',
        books: (json['books'] as List<dynamic>? ?? [])
            .map((e) => BookEntry.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class LocalStore {
  static const _key = 'appmaker_projects_v1';

  static Future<List<AppProject>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => AppProject.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<AppProject> projects) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(projects.map((p) => p.toJson()).toList()),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int tab = 0;
  bool loading = true;
  List<AppProject> projects = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loaded = await LocalStore.load();
    if (!mounted) return;
    setState(() {
      projects = loaded;
      loading = false;
    });
  }

  Future<void> _persist() async {
    await LocalStore.save(projects);
    if (mounted) setState(() {});
  }

  Future<void> _importProject() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (picked == null || picked.files.isEmpty) return;
      final bytes = picked.files.single.bytes;
      if (bytes == null) throw const FormatException('فایل لوستل کېدای نه شي.');
      final decoded = jsonDecode(utf8.decode(bytes));
      final imported = AppProject.fromJson(Map<String, dynamic>.from(decoded as Map));
      if (imported.name.trim().isEmpty) throw const FormatException('د پروژې نوم تش دی.');
      setState(() => projects.insert(0, imported));
      await _persist();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('پروژه په بریالیتوب وارد شوه.')),
        );
        _openProject(imported);
      }
    } on FormatException catch (e) {
      if (mounted) _showInfo('ناسم فایل', e.message);
    } catch (e) {
      if (mounted) _showInfo('واردول ناکام شول', 'دا د AppMaker معتبر JSON فایل نه دی.\n$e');
    }
  }

  Future<void> _newProject() async {
    final name = TextEditingController();
    String category = 'کتابونه';
    final result = await showDialog<AppProject>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: const Text('نوی اپ جوړ کړئ', style: TextStyle(fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'د اپ نوم',
                  hintText: 'لکه: زما د شعرونو ټولګه',
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(labelText: 'د اپ ډول'),
                items: const ['کتابونه', 'شعرونه', 'ښوونیز', 'مجله', 'شخصي ټولګه']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => refresh(() => category = v ?? category),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('بېرته')),
            FilledButton(
              onPressed: () {
                if (name.text.trim().isEmpty) return;
                Navigator.pop(
                  context,
                  AppProject(
                    name: name.text.trim(),
                    category: category,
                    createdAt: DateTime.now().toIso8601String(),
                  ),
                );
              },
              child: const Text('جوړول'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    if (result != null) {
      setState(() => projects.insert(0, result));
      await _persist();
      if (mounted) _openProject(result);
    }
  }

  Future<void> _openProject(AppProject project) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectPage(
          project: project,
          onChanged: _persist,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _deleteProject(AppProject project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('پروژه حذف کړئ؟'),
        content: Text('«${project.name}» او ټولې لیکنې به یې له دې موبایل څخه حذف شي.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('نه')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذفول'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    projects.remove(project);
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _home(),
      _projects(),
      _library(),
      _settings(),
    ];
    return Scaffold(
      body: SafeArea(child: loading ? const Center(child: CircularProgressIndicator()) : pages[tab]),
      floatingActionButton: tab == 0 || tab == 1
          ? FloatingActionButton.extended(
              onPressed: _newProject,
              backgroundColor: violet,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('نوی اپ'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'کورپاڼه'),
          NavigationDestination(icon: Icon(Icons.apps_outlined), selectedIcon: Icon(Icons.apps), label: 'زما اپونه'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'کتابتون'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'امستنې'),
        ],
      ),
    );
  }

  Widget _home() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
      children: [
        Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [violet, Color(0xFF9D80FF)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.widgets_rounded, color: Colors.white, size: 27),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AppMaker', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: ink)),
                  Text('خپل اپ، په خپل لاس جوړ کړئ', style: TextStyle(color: Colors.black54, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.offline_bolt_rounded, color: Color(0xFF1B9B70)),
            const SizedBox(width: 5),
            const Text('افلاین', style: TextStyle(color: Color(0xFF1B9B70), fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 26),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF30236F), Color(0xFF7658F5), Color(0xFF9B83FF)],
            ),
            boxShadow: [BoxShadow(color: violet.withOpacity(.22), blurRadius: 24, offset: const Offset(0, 12))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFD978), size: 30),
              const SizedBox(height: 15),
              const Text('ستا د خیالونو اپلیکیشن', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text('کتابونه، شعرونه او خپلې لیکنې په یوه ښکلي اپ کې راټولې کړه.', style: TextStyle(color: Colors.white70, height: 1.7)),
              const SizedBox(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: ink),
                onPressed: _newProject,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('خپل لومړی اپ جوړ کړه'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        Row(
          children: [
            Expanded(child: _statCard('ټول اپونه', '${projects.length}', Icons.apps_rounded, const Color(0xFFEDE8FF))),
            const SizedBox(width: 12),
            Expanded(child: _statCard('ټولې لیکنې', '${projects.fold<int>(0, (n, p) => n + p.books.length)}', Icons.article_outlined, const Color(0xFFE4F6F0))),
          ],
        ),
        const SizedBox(height: 27),
        _sectionTitle('چټک پیل', 'ټول امکانات'),
        const SizedBox(height: 12),
        _quickTile(Icons.menu_book_rounded, 'د کتابونو اپ', 'کتابونه او لیکنې تنظیم کړه', () => _newProject()),
        _quickTile(Icons.palette_outlined, 'ډیزاین او بڼه', 'د اپ د ښکلا تنظیمات', () => _showInfo('ډیزاین او بڼه', 'د رنګونو، فونټونو او قالبونو تنظیمات به په راتلونکې مرحله کې ورزیات شي.')),
        _quickTile(Icons.file_download_outlined, 'د APK جوړول', 'د اپ د نصب فایل چمتو کول', _apkInfo),
        const SizedBox(height: 25),
        _sectionTitle('وروستي اپونه', 'ټول وګوره'),
        const SizedBox(height: 10),
        if (projects.isEmpty)
          _emptyCard('تر اوسه اپ نه دی جوړ شوی', 'د پیل لپاره د «نوی اپ» تڼۍ کېکاږه.')
        else
          ...projects.take(3).map((p) => _projectTile(p)),
      ],
    );
  }

  Widget _projects() => ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 100),
        children: [
          const Text('زما اپونه', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: ink)),
          const SizedBox(height: 6),
          const Text('ټولې جوړې شوې پروژې په همدې موبایل کې ساتل کېږي.', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _importProject,
            icon: const Icon(Icons.file_open_outlined),
            label: const Text('له JSON فایل څخه پروژه واردول'),
          ),
          const SizedBox(height: 12),
          if (projects.isEmpty)
            _emptyCard('ستاسې د اپونو ځای', 'لومړی اپ جوړ کړه، بیا به دلته ښکاره شي.')
          else
            ...projects.map(_projectTile),
        ],
      );

  Widget _library() {
    final all = projects.expand((p) => p.books.map((b) => (p.name, b))).toList();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('کتابتون', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: ink)),
        const SizedBox(height: 6),
        const Text('ستاسې ټولې لیکنې او کتابونه په یوه ځای کې.', style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 20),
        if (all.isEmpty)
          _emptyCard('کتابتون تش دی', 'لومړی یوه پروژه جوړه او لیکنې پکې اضافه کړه.')
        else
          ...all.map((item) => Card(
                elevation: 0,
                color: Colors.white,
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFFEDE8FF), child: Icon(Icons.menu_book, color: violet)),
                  title: Text(item.$2.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(item.$1),
                ),
              )),
      ],
    );
  }

  Widget _settings() => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('امستنې', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: ink)),
          const SizedBox(height: 18),
          _quickTile(Icons.wifi_off_rounded, 'افلاین کار', 'پروژې او لیکنې په همدې وسیله ساتل کېږي.', () => _showInfo('افلاین کار', 'د اپ معلومات په محلي حافظه کې ساتل کېږي؛ د عادي استعمال لپاره انټرنېټ ته اړتیا نشته.')),
          _quickTile(Icons.storage_rounded, 'محلي ذخیره', 'د پروژو معلومات ستا په موبایل کې دي.', () => _showInfo('محلي ذخیره', 'د اپ معلومات د موبایل په محلي ذخیره کې ساتل کېږي. د اپ پاکول یا د معلوماتو حذفول یې له منځه وړلی شي.')),
          _quickTile(Icons.info_outline, 'د AppMaker په اړه', 'نسخه 1.0.0', () => _showInfo('AppMaker', 'د Flutter په وسیله جوړېدونکی افلاین اپ جوړوونکی.')),
        ],
      );

  Widget _statCard(String label, String value, IconData icon, Color bg) => Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
        child: Row(
          children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: violet)),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: ink)),
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
            ]),
          ],
        ),
      );

  Widget _sectionTitle(String title, String action) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ink)),
          Text(action, style: const TextStyle(color: violet, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      );

  Widget _quickTile(IconData icon, String title, String subtitle, VoidCallback onTap) => Card(
        elevation: 0,
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          leading: Container(width: 45, height: 45, decoration: BoxDecoration(color: const Color(0xFFEDE8FF), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: violet)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: ink)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
          trailing: const Icon(Icons.chevron_left_rounded, color: Colors.black38),
        ),
      );

  Widget _projectTile(AppProject p) => Card(
        elevation: 0,
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ListTile(
          onTap: () => _openProject(p),
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
          leading: Container(width: 48, height: 48, decoration: BoxDecoration(gradient: const LinearGradient(colors: [violet, Color(0xFFA28EFF)]), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.phone_android_rounded, color: Colors.white)),
          title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, color: ink)),
          subtitle: Text('${p.category}  •  ${p.books.length} لیکنې'),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'open') _openProject(p);
              if (value == 'delete') _deleteProject(p);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'open', child: Text('پروژه پرانیستل')),
              PopupMenuItem(
                value: 'delete',
                child: Text('پروژه حذفول', style: TextStyle(color: Colors.red)),
              ),
            ],
            child: const Icon(Icons.more_vert_rounded),
          ),
        ),
      );

  Widget _emptyCard(String title, String subtitle) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
        child: Column(children: [
          const Icon(Icons.auto_stories_outlined, size: 42, color: violet),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: ink)),
          const SizedBox(height: 5),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54, fontSize: 12)),
        ]),
      );

  void _apkInfo() => _showInfo(
        'د APK جوړول',
        'پروژې او لیکنې افلاین جوړېږي او په موبایل کې ساتل کېږي. د موبایل دننه د هرې پروژې جلا APK جوړولو، لاسلیک او نصب انجن لا بشپړ شوی نه دی؛ د APK تڼۍ تر فعالېدو مخکې به د فایل جوړول او د Android په وسیله نصب په واقعي موبایل کې وازمویل شي.',
      );

  void _showInfo(String title, String message) => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          content: Text(message, style: const TextStyle(height: 1.7)),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('سمه ده'))],
        ),
      );
}

class ProjectPage extends StatefulWidget {
  const ProjectPage({super.key, required this.project, required this.onChanged});
  final AppProject project;
  final Future<void> Function() onChanged;

  @override
  State<ProjectPage> createState() => _ProjectPageState();
}

class _ProjectPageState extends State<ProjectPage> {
  Future<void> _exportProject() async {
    try {
      final directory = await Directory.systemTemp.createTemp('appmaker_export_');
      final safeName = widget.project.name
          .replaceAll(RegExp(r'[^a-zA-Z0-9ء-ي _-]'), '')
          .trim()
          .replaceAll(RegExp(r'\s+'), '_');
      final file = File('${directory.path}/${safeName.isEmpty ? 'project' : safeName}.json');
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(widget.project.toJson()),
        encoding: utf8,
        flush: true,
      );
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        text: 'AppMaker project: ${widget.project.name}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('صادرول ناکام شو: $e')),
        );
      }
    }
  }

  Future<void> _editBook(int index) async {
    final current = widget.project.books[index];
    final title = TextEditingController(text: current.title);
    final body = TextEditingController(text: current.body);
    final updated = await showDialog<BookEntry>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('لیکـنه سمول'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: title, decoration: const InputDecoration(labelText: 'عنوان')),
                const SizedBox(height: 12),
                TextField(
                  controller: body,
                  minLines: 6,
                  maxLines: 10,
                  decoration: const InputDecoration(labelText: 'متن', alignLabelWithHint: true),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('بېرته')),
          FilledButton(
            onPressed: () {
              if (title.text.trim().isEmpty || body.text.trim().isEmpty) return;
              Navigator.pop(
                dialogContext,
                BookEntry(title: title.text.trim(), body: body.text.trim()),
              );
            },
            child: const Text('بدلون ساتل'),
          ),
        ],
      ),
    );
    title.dispose();
    body.dispose();
    if (updated != null) {
      setState(() => widget.project.books[index] = updated);
      await widget.onChanged();
    }
  }

  Future<void> _deleteBook(int index) async {
    final entry = widget.project.books[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('لیکنه حذف کړئ؟'),
        content: Text('«${entry.title}» به حذف شي.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('نه')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذفول'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => widget.project.books.removeAt(index));
    await widget.onChanged();
  }

  Future<void> _addBook() async {
    final title = TextEditingController();
    final body = TextEditingController();
    final entry = await showDialog<BookEntry>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('نوې لیکنه اضافه کړه', style: TextStyle(fontWeight: FontWeight.w800)),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(children: [
              TextField(controller: title, decoration: const InputDecoration(labelText: 'د لیکنې عنوان')),
              const SizedBox(height: 12),
              TextField(controller: body, minLines: 6, maxLines: 10, decoration: const InputDecoration(labelText: 'د لیکنې متن', alignLabelWithHint: true)),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('بېرته')),
          FilledButton(
            onPressed: () {
              if (title.text.trim().isEmpty || body.text.trim().isEmpty) return;
              Navigator.pop(context, BookEntry(title: title.text.trim(), body: body.text.trim()));
            },
            child: const Text('ساتل'),
          ),
        ],
      ),
    );
    title.dispose();
    body.dispose();
    if (entry != null) {
      setState(() => widget.project.books.add(entry));
      await widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.project;
    return Scaffold(
      appBar: AppBar(title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w900))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addBook,
        backgroundColor: violet,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text('نوې لیکنه'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(colors: [Color(0xFF30236F), violet]),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 32),
              const SizedBox(height: 12),
              Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 5),
              Text('${p.category}  •  ${p.books.length} لیکنې', style: const TextStyle(color: Colors.white70)),
            ]),
          ),
          const SizedBox(height: 24),
          const Text('د پروژې لیکنې', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ink)),
          const SizedBox(height: 12),
          if (p.books.isEmpty)
            const Padding(
              padding: EdgeInsets.all(25),
              child: Text('تر اوسه لیکنه نشته. د نوې لیکنې تڼۍ کېکاږه.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
            )
          else
            ...p.books.asMap().entries.map((e) => Card(
                  elevation: 0,
                  color: Colors.white,
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: const Color(0xFFEDE8FF), child: Text('${e.key + 1}', style: const TextStyle(color: violet, fontWeight: FontWeight.bold))),
                    title: Text(e.value.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(e.value.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: () => _editBook(e.key),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') _editBook(e.key);
                        if (value == 'delete') _deleteBook(e.key);
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('سمول')),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('حذفول', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                )),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _exportProject,
            icon: const Icon(Icons.ios_share_rounded),
            label: const Text('پروژه د JSON فایل په توګه صادرول'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('د APK جوړول'),
                content: const Text('پروژه او لیکنې افلاین ساتل او JSON ته صادرولای شې. خو د همدې موبایل دننه د جلا APK جوړولو، لاسلیک او نصب انجن لا نه دی بشپړ شوی. دا تڼۍ تر هغه نه فعالیږي چې APK په واقعي Android وسیله کې جوړ، لاسلیک او د نصب له لارې تایید شوی نه وي.'),
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('سمه ده'))],
              ),
            ),
            icon: const Icon(Icons.android),
            label: const Text('د APK حالت'),
          ),
        ],
      ),
    );
  }
}
