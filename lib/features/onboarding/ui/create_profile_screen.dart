import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/logic/auth_cubit.dart';
import 'athlete_details_screen.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  int _bioLength = 0;

  @override
  void initState() {
    super.initState();
    _bioController.addListener(() {
      setState(() {
        _bioLength = _bioController.text.length;
      });
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AuthCubit>();

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.0, -0.9),
              radius: 1.2,
              colors: [Color(0xFF0F1E21), Color(0xFF070B0D)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                height: 56, padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20)),
                    const Expanded(child: Text('CREATE PROFILE', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1.0))),
                    const SizedBox(width: 24),
                  ],
                ),
              ),
              // Progress Line
              Stack(
                children: [
                  Container(height: 2, color: const Color(0xFF14191C)),
                  Container(height: 2, width: MediaQuery.of(context).size.width * 0.33, color: const Color(0xFF00E5C1)),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 40),
                        // Avatar Placeholder
                        Center(
                          child: Container(
                            width: 132, height: 132,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF0F1315), border: Border.all(color: const Color(0xFF1E262A))),
                            child: const Icon(Icons.person_outline, size: 54, color: Colors.white24),
                          ),
                        ),
                        const SizedBox(height: 48),
                        
                        // Username
                        const Text('USERNAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white24, letterSpacing: 0.8)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _usernameController,
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                          validator: (val) => val == null || val.length < 3 ? 'Min 3 chars' : null,
                          decoration: InputDecoration(
                            prefixIcon: const Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Text('@', style: TextStyle(color: Colors.white24, fontSize: 18))),
                            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                            filled: true, fillColor: const Color(0xFF0F1315),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E262A))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E262A))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00E5C1))),
                          ),
                        ),
                        const SizedBox(height: 28),
                        
                        // Bio
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('BIO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white24, letterSpacing: 0.8)),
                            Text('$_bioLength / 150', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white24)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _bioController,
                          maxLines: 5, maxLength: 150,
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                          decoration: InputDecoration(
                            hintText: 'Tell the community about yourself...', hintStyle: const TextStyle(color: Colors.white12),
                            filled: true, fillColor: const Color(0xFF0F1315),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E262A))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E262A))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00E5C1))),
                          ),
                        ),
                        const SizedBox(height: 40),
                        
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              // 1. Save Profile Data
                              cubit.saveProfileData(username: _usernameController.text);
                              // 2. Navigate Next
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const AthleteDetailsScreen()));
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00E5C1),
                            foregroundColor: const Color(0xFF070B0D),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Next', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(height: 24),
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