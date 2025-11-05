import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(EduConnectApp(isDark: false, prefs: prefs));
}

class EduConnectApp extends StatefulWidget {
  final bool isDark;
  final SharedPreferences prefs;

  EduConnectApp({required this.isDark, required this.prefs});

  @override
  State<EduConnectApp> createState() => _EduConnectAppState();
}

class _EduConnectAppState extends State<EduConnectApp> {
  @override
  void initState() {
    super.initState();
    if (!widget.prefs.containsKey('admin')) {
      widget.prefs.setString('admin', 'admin123');
    }
  }

  void addUser(String username, String password) {
    widget.prefs.setString(username, password);
  }

  bool validateUser(String username, String password) {
    return widget.prefs.getString(username) == password;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduConnect',
      theme: widget.isDark ? ThemeData.dark() : ThemeData.light(),
      home: AuthGate(
        onRegister: addUser,
        onValidate: validateUser,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthGate extends StatefulWidget {
  final void Function(String username, String password) onRegister;
  final bool Function(String username, String password) onValidate;

  AuthGate({required this.onRegister, required this.onValidate});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool showingLogin = true;

  void toggle() {
    setState(() {
      showingLogin = !showingLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return showingLogin
        ? LoginPage(onToggle: toggle, onValidate: widget.onValidate)
        : SignupPage(onToggle: toggle, onRegister: widget.onRegister);
  }
}

class LoginPage extends StatefulWidget {
  final VoidCallback onToggle;
  final bool Function(String, String) onValidate;

  LoginPage({required this.onToggle, required this.onValidate});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController userC = TextEditingController();
  final TextEditingController passC = TextEditingController();

  void tryLogin() {
    final u = userC.text.trim();
    final p = passC.text;
    if (u.isEmpty || p.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Enter username & password')));
      return;
    }
    final ok = widget.onValidate(u, p);
    if (!ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Invalid credentials')));
      return;
    }
    final isAdmin = (u == 'admin');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomePage(username: u, isAdmin: isAdmin),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('EduConnect Egypt'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Login'),
              SizedBox(height: 12),
              TextField(
                controller: userC,
                decoration: InputDecoration(labelText: 'Username'),
              ),
              SizedBox(height: 12),
              TextField(
                controller: passC,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              SizedBox(height: 18),
              ElevatedButton(onPressed: tryLogin, child: Text('Login')),
              SizedBox(height: 12),
              TextButton(
                  onPressed: widget.onToggle,
                  child: Text('Don\'t have an account? Sign up'))
            ]),
          ),
        ),
      ),
    );
  }
}

class SignupPage extends StatefulWidget {
  final VoidCallback onToggle;
  final void Function(String username, String password) onRegister;

  SignupPage({required this.onToggle, required this.onRegister});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController userC = TextEditingController();
  final TextEditingController passC = TextEditingController();
  final TextEditingController manualPercentC = TextEditingController();

  String percentOption = 'manual'; // 'manual' or 'calculate'
  String system = 'National';
  String nationalCategory = 'Literature';

  double? calculatedPercent;

  Map<String, TextEditingController> subjectControllers = {};

  // 🎓 Subjects per system/category
  final Map<String, List<String>> subjectsPerSystem = {
    'American': [
      'English',
      'Math',
      'Biology',
      'Chemistry',
      'Physics',
      'History',
      'Economics'
    ],
    'IGCSE': [
      'English',
      'Math',
      'Physics',
      'Chemistry',
      'Biology',
      'Computer Science',
      'Business'
    ],
    'National_Literature': [
      'Arabic',
      'English',
      'History',
      'Geography',
      'Philosophy',
      'Sociology'
    ],
    'National_Scientific Science': [
      'Arabic',
      'English',
      'Biology',
      'Chemistry',
      'Physics',
      'Geology'
    ],
    'National_Scientific Mathematics': [
      'Arabic',
      'English',
      'Math',
      'Physics',
      'Chemistry',
      'Applied Math'
    ],
  };

  List<String> get currentSubjects {
    if (system == 'National') {
      return subjectsPerSystem['National_$nationalCategory']!;
    }
    return subjectsPerSystem[system]!;
  }

  void updateSubjects() {
    subjectControllers.clear();
    for (var subject in currentSubjects) {
      subjectControllers[subject] = TextEditingController();
    }
  }

  @override
  void initState() {
    super.initState();
    updateSubjects();
  }

  void calculatePercent() {
    double total = 0;
    int count = 0;

    subjectControllers.forEach((name, controller) {
      final val = double.tryParse(controller.text.trim());
      if (val != null) {
        total += val;
        count++;
      }
    });

    if (count == 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Enter subject marks')));
      return;
    }

    double avg = total / count;

    // Apply system-based adjustment
    if (system == 'American') avg *= 1.0;
    else if (system == 'IGCSE') avg *= 0.95;
    else if (system == 'National') {
      if (nationalCategory == 'Literature') avg *= 0.9;
      else if (nationalCategory == 'Scientific Science') avg *= 1.0;
      else if (nationalCategory == 'Scientific Mathematics') avg *= 1.05;
    }

    setState(() {
      calculatedPercent = avg.clamp(0, 100);
    });
  }

  void register() {
    final u = userC.text.trim();
    final p = passC.text;
    if (u.isEmpty || p.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Enter username & password')));
      return;
    }
    if (u.toLowerCase() == 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Username "admin" is reserved.')));
      return;
    }

    double percent = 0;
    if (percentOption == 'manual') {
      final val = double.tryParse(manualPercentC.text.trim());
      if (val == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Enter a valid percent')));
        return;
      }
      percent = val;
    } else {
      if (calculatedPercent == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please calculate your percent first')));
        return;
      }
      percent = calculatedPercent!;
    }

    widget.onRegister(u, p);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text('Account created — your percent: ${percent.toStringAsFixed(1)}%')));
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('EduConnect Egypt')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 450),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sign Up', style: TextStyle(fontSize: 22)),
                SizedBox(height: 10),
                TextField(controller: userC, decoration: InputDecoration(labelText: 'Username')),
                SizedBox(height: 10),
                TextField(controller: passC, decoration: InputDecoration(labelText: 'Password'), obscureText: true),

                SizedBox(height: 20),
                Text('Percent option:', style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Radio<String>(
                        value: 'manual',
                        groupValue: percentOption,
                        onChanged: (v) => setState(() => percentOption = v!)),
                    Text('Enter manually'),
                    Radio<String>(
                        value: 'calculate',
                        groupValue: percentOption,
                        onChanged: (v) => setState(() => percentOption = v!)),
                    Text('Calculate automatically'),
                  ],
                ),

                if (percentOption == 'manual') ...[
                  TextField(
                    controller: manualPercentC,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        InputDecoration(labelText: 'Your percent (e.g. 88.5)'),
                  ),
                ] else ...[
                  SizedBox(height: 10),
                  DropdownButton<String>(
                    value: system,
                    onChanged: (v) {
                      setState(() {
                        system = v!;
                        updateSubjects();
                      });
                    },
                    items: ['American', 'IGCSE', 'National']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                  ),

                  if (system == 'National') ...[
                    DropdownButton<String>(
                      value: nationalCategory,
                      onChanged: (v) {
                        setState(() {
                          nationalCategory = v!;
                          updateSubjects();
                        });
                      },
                      items: [
                        'Literature',
                        'Scientific Science',
                        'Scientific Mathematics'
                      ]
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                    ),
                  ],

                  SizedBox(height: 10),
                  Text('Enter your subject marks (0–100):'),
                  ...subjectControllers.entries.map((e) => Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: TextField(
                          controller: e.value,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: e.key),
                        ),
                      )),
                  SizedBox(height: 10),
                  ElevatedButton(
                      onPressed: calculatePercent, child: Text('Calculate')),
                  if (calculatedPercent != null)
                    Text('Calculated percent: ${calculatedPercent!.toStringAsFixed(1)}%',
                        style:
                            TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                ],

                SizedBox(height: 20),
                ElevatedButton(onPressed: register, child: Text('Create account')),
                TextButton(onPressed: widget.onToggle, child: Text('Back to login')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------------------- Home & Data -----------------------------
class Faculty {
  String name;
  String university;
  int fees;
  int credits;
  double requiredPercent;
  String extraRequirements;

  Faculty({
    required this.name,
    required this.university,
    required this.fees,
    required this.credits,
    required this.requiredPercent,
    required this.extraRequirements,
  });
}

class HomePage extends StatefulWidget {
  final String username;
  final bool isAdmin;

  HomePage({required this.username, this.isAdmin = false});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Faculty> faculties = [
    Faculty(
      name: 'Computer Science',
      university: 'Nile University',
      fees: 25000,
      credits: 120,
      requiredPercent: 85.0,
      extraRequirements: 'High school diploma, Math >= 85%',
    ),
    Faculty(
      name: 'Electrical Engineering',
      university: 'Cairo University',
      fees: 30000,
      credits: 140,
      requiredPercent: 80.0,
      extraRequirements: 'High school diploma, Physics & Math >= 80%',
    ),
    Faculty(
      name: 'Business Administration',
      university: 'Helwan University',
      fees: 20000,
      credits: 130,
      requiredPercent: 70.0,
      extraRequirements: 'High school diploma, English proficiency',
    ),
    Faculty(
      name: 'Architecture',
      university: 'Ain Shams University',
      fees: 28000,
      credits: 150,
      requiredPercent: 82.0,
      extraRequirements: 'Portfolio may be required',
    ),
  ];

  double? enteredPercent;
  final TextEditingController percentController = TextEditingController();

  void calculatePercent() {
    final text = percentController.text.trim();
    if (text.isEmpty) {
      setState(() {
        enteredPercent = null;
      });
      return;
    }
    final val = double.tryParse(text);
    if (val == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Enter a valid number')));
      return;
    }
    setState(() {
      enteredPercent = val;
    });
  }

  List<Faculty> eligibleFaculties() {
    if (enteredPercent == null) return [];
    return faculties.where((f) => enteredPercent! >= f.requiredPercent).toList();
  }

  @override
  void dispose() {
    percentController.dispose();
    super.dispose();
  }

  Widget facultyCard(Faculty f) {
    final eligible = (enteredPercent != null && enteredPercent! >= f.requiredPercent);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text('${f.name} — ${f.university}'),
        subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 6),
              Text('Fees: ${f.fees}'),
              Text('Credits: ${f.credits}'),
              Text('Min percent: ${f.requiredPercent}%'),
              Text('Requirements: ${f.extraRequirements}'),
              SizedBox(height: 6),
              Row(
                children: [
                  Chip(
                    label: Text(eligible ? 'Eligible' : 'Not eligible'),
                    backgroundColor: eligible ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                  ),
                ],
              )
            ]),
        isThreeLine: true,
      ),
    );
  }

  void showDetailsDialog(Faculty f) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${f.name} — ${f.university}'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Fees: ${f.fees}'),
          Text('Credits: ${f.credits}'),
          Text('Min percent: ${f.requiredPercent}%'),
          SizedBox(height: 8),
          Text('Requirements:'),
          Text(f.extraRequirements),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Close')),
        ],
      ),
    );
  }

  Widget headerArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Enter your high school percent to see where you can join:', style: TextStyle(fontSize: 16)),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: percentController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(hintText: 'e.g. 87.5', labelText: 'Your percent'),
              ),
            ),
            SizedBox(width: 10),
            ElevatedButton(onPressed: calculatePercent, child: Text('Check')),
            SizedBox(width: 8),
            TextButton(onPressed: () {
              percentController.clear();
              setState((){ enteredPercent = null; });
            }, child: Text('Clear')),
          ],
        ),
        SizedBox(height: 12),
        if (enteredPercent != null)
          Text('You entered: ${enteredPercent!.toStringAsFixed(1)}% — Eligible for ${eligibleFaculties().length} faculties')
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final eligible = eligibleFaculties();
    return Scaffold(
      appBar: AppBar(
        title: Text('EduConnect Egypt — Welcome ${widget.username}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            headerArea(),
            SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  Text('All faculties:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  ...faculties.map((f) => InkWell(
                    onTap: () => showDetailsDialog(f),
                    child: facultyCard(f),
                  )),
                  SizedBox(height: 16),
                  if (enteredPercent != null) ...[
                    Divider(),
                    Text('You are eligible for:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    if (eligible.isEmpty)
                      Text('No faculties match your percent. Try improving your score or contact admissions.'),
                    ...eligible.map((f) => ListTile(
                      title: Text('${f.name} - ${f.university}'),
                      subtitle: Text('Min ${f.requiredPercent}%, Fees: ${f.fees}'),
                      onTap: () => showDetailsDialog(f),
                    )),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
