import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core.dart';
import 'tabs.dart';

export 'core.dart';
export 'learning_screens.dart';
export 'lessons_data.dart';
export 'tabs.dart';
export 'tracking_screens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Progress.instance.load();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lingo Gold',
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child ?? const SizedBox()),
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: kGreen, primary: kGreen),
        splashFactory: InkSparkle.splashFactory,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: kGreen,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: kGreenDark,
            minimumSize: const Size(0, 52),
            side: const BorderSide(color: kGreen, width: 1.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(backgroundColor: kInk, behavior: SnackBarBehavior.floating),
        dividerTheme: const DividerThemeData(color: kLine, thickness: 1),
      ),
      home: const Shell(),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: IndexedStack(
        index: _tab,
        children: const [
          HomeScreen(),
          LessonsScreen(),
          StoriesScreen(),
          TrainingScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNav(index: _tab, onTap: (i) => setState(() => _tab = i)),
    );
  }
}

class BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const BottomNav({super.key, required this.index, required this.onTap});

  static const labels = ['الرئيسية', 'الدروس', 'القصص', 'تدريب', 'ملفي'];
  static const icons = [
    Icons.home_rounded,
    Icons.menu_book_rounded,
    Icons.auto_stories_rounded,
    Icons.fitness_center_rounded,
    Icons.person_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: SafeArea(
        top: false,
        child: Container(
          height: 66,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: kLine),
            boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 6))],
          ),
          child: Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: index == i ? kGreen : Colors.transparent,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icons[i],
                            size: 19,
                            color: index == i ? Colors.white : kMuted,
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            child: Text(
                              labels[i],
                              style: TextStyle(
                                color: index == i ? Colors.white : kMuted,
                                fontWeight: FontWeight.w900,
                                fontSize: 10.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
