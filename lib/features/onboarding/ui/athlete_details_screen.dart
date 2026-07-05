import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/logic/auth_cubit.dart';
import '../../auth/logic/auth_state.dart';
import 'user_metrics_screen.dart';

class AthleteDetailsScreen extends StatefulWidget {
  const AthleteDetailsScreen({super.key});

  @override
  State<AthleteDetailsScreen> createState() => _AthleteDetailsScreenState();
}

class _AthleteDetailsScreenState extends State<AthleteDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  
  int? _selectedSportId;
  String _selectedLevel = 'Amateur';
  String _selectedWeightClass = 'Middleweight';

  final List<String> levels = ['Novice', 'Amateur', 'Pro'];
  final List<String> weightClasses = ['Flyweight', 'Lightweight', 'Middleweight', 'Heavyweight'];

  @override
  void initState() {
    super.initState();
    context.read<AuthCubit>().fetchSports();
  }

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<AuthCubit>();

    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
  if (state is AuthSuccess) {
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(
        builder: (context) => UserMetricsScreen(sportId: _selectedSportId!), // تمرير الـ ID هنا
      ),
    );
  }else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error), backgroundColor: Colors.redAccent));
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFF070B0D),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
               child: Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    const SizedBox(height: 32),
    const Text('Define your cohort', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
    const SizedBox(height: 32),
    
    _buildLabel('PRIMARY SPORT'),
    const SizedBox(height: 8),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFF0F1315), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1E262A))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedSportId,
          hint: const Text('Select your sport', style: TextStyle(color: Colors.white24)),
          dropdownColor: const Color(0xFF0F1315),
          isExpanded: true,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          onChanged: (val) => setState(() => _selectedSportId = val),
          items: cubit.availableSports.map<DropdownMenuItem<int>>((sport) => DropdownMenuItem<int>(
            value: sport['id'],
            child: Text("${sport['icon'] ?? ''} ${sport['name']}"),
          )).toList(),
        ),
      ),
    ),
    const SizedBox(height: 24),
    
    _buildLabel('COMPETITIVE LEVEL'),
    const SizedBox(height: 12),
    _buildSegmentedControl(levels, _selectedLevel),
    const SizedBox(height: 24),

    // 🚀 هنا الـ Row اللي كان ناقص (Age & Weight)
    Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('AGE'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(filled: true, fillColor: Color(0xFF0F1315), border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('WEIGHT CLASS'),
              const SizedBox(height: 8),
              _buildStaticDropdown(value: _selectedWeightClass, items: weightClasses, onChanged: (val) => setState(() => _selectedWeightClass = val!)),
            ],
          ),
        ),
      ],
    ),
    const SizedBox(height: 48),
    
    ElevatedButton(
      onPressed: () {
        if (_formKey.currentState!.validate() && _selectedSportId != null) {
          int age = int.parse(_ageController.text);
          cubit.submitRegistration(dateOfBirth: '${DateTime.now().year - age}-01-01');
        }
      },
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5C1), padding: const EdgeInsets.symmetric(vertical: 18)),
      child: const Text('Complete Registration', style: TextStyle(color: Colors.black)),
    ),
  ],
),
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildLabel(String text) => Text(text, style: const TextStyle(fontSize: 11, color: Colors.white24));
  Widget _buildStaticDropdown({
  required String value,
  required List<String> items,
  required ValueChanged<String?> onChanged,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: const Color(0xFF0F1315),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF1E262A)),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        dropdownColor: const Color(0xFF0F1315),
        isExpanded: true,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        onChanged: onChanged,
        items: items.map<DropdownMenuItem<String>>((item) => DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        )).toList(),
      ),
    ),
  );
}
  Widget _buildSegmentedControl(List<String> levels, String selectedLevel) {
    return Container(
      height: 56,
      decoration: BoxDecoration(color: const Color(0xFF0F1315), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1E262A))),
      child: Row(
        children: levels.map((level) {
          final isSelected = selectedLevel == level;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedLevel = level),
              child: Container(
                decoration: BoxDecoration(color: isSelected ? const Color(0xFF1E2427) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                alignment: Alignment.center,
                child: Text(level, style: TextStyle(color: isSelected ? Colors.white : Colors.white24)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}