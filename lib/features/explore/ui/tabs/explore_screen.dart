import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/api/api_client.dart';
import '../../data/explore_service.dart';
import '../../logic/explore_cubit.dart';
import 'explore_people_tab.dart';
import 'explore_programs_tab.dart';
import 'explore_top_tab.dart';
import '../../../programs/explore/ai_advisor_chat_screen.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ExploreCubit(
        ExploreService(context.read<ApiClient>()),
      )..loadExploreData(),
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          backgroundColor: const Color(0xFF09090b),
          appBar: AppBar(
            backgroundColor: const Color(0xFF09090b),
            elevation: 0,
            title: const Text(
              'EXPLORE',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w900,
                fontSize: 24,
                color: Colors.white,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(110),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 45,
                            decoration: BoxDecoration(
                              color: const Color(0xFF18181b),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const TextField(
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Search athletes, programs...',
                                hintStyle: TextStyle(
                                  color: Colors.white24,
                                  fontSize: 14,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Colors.white24,
                                ),
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          height: 45,
                          width: 45,
                          decoration: BoxDecoration(
                            color: const Color(0xFF18181b),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.tune,
                            color: Color(0xFF2dd4bf),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const TabBar(
                    indicatorColor: Color(0xFF2dd4bf),
                    indicatorWeight: 3,
                    labelColor: Color(0xFF2dd4bf),
                    unselectedLabelColor: Colors.white38,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                    tabs: [
                      Tab(text: 'TOP'),
                      Tab(text: 'PEOPLE'),
                      Tab(text: 'PROGRAMS'),
                      Tab(text: 'POSTS'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          body: const TabBarView(
            children: [
              ExploreTopTab(),
              ExplorePeopleTab(),
              ExploreProgramsTab(),
              Center(
                child: Text(
                  'POSTS',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AiAdvisorChatScreen(),
                ),
              );
            },
            backgroundColor: const Color(0xFF2dd4bf),
            child: const Icon(Icons.auto_awesome, color: Colors.black),
          ),
        ),
      ),
    );
  }
}
