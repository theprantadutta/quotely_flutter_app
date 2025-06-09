import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:quotely_flutter_app/components/facts_screen/single_fact.dart';
import 'package:quotely_flutter_app/dtos/ai_fact_dto.dart';
import 'package:quotely_flutter_app/service_locator/init_service_locators.dart';
import 'package:quotely_flutter_app/services/drift_fact_service.dart';

// Converted to StatefulWidget to manage the analytics instance
class FactsList extends StatefulWidget {
  const FactsList({super.key});

  @override
  State<FactsList> createState() => _FactsListState();
}

class _FactsListState extends State<FactsList> {
  // --- Analytics Instance ---
  final _analytics = getIt.get<FirebaseAnalytics>();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: MediaQuery.of(context).size.height * 0.05,
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'All Favorite Facts',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder(
            stream: DriftFactService.watchAllFavoriteFacts(null),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Using a Column and Expanded to prevent layout errors with ListView in StreamBuilder
                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: 10,
                        itemBuilder: (context, index) {
                          return const SingleFactSkeletor();
                        },
                      ),
                    ),
                  ],
                );
              }
              if (snapshot.hasError) {
                // --- Analytics Event for Errors ---
                _analytics.logEvent(
                  name: 'favorites_facts_load_failed',
                  parameters: {'error': snapshot.error.toString()},
                );
                return const Center(child: Text('Something went wrong'));
              }
              final facts = snapshot.data!;
              if (facts.isEmpty) {
                return SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.hourglass_empty_outlined,
                          size: 80,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'No Favorites added yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'When you like a fact, it\'s going to show up here, this section helps you to read your Favorite facts over and over',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              // Using a Column and Expanded here as well for consistency and safety
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: facts.length,
                      itemBuilder: (context, index) {
                        final fact = facts[index];
                        final factDto = AiFactDto.fromDrift(fact);
                        return SingleFact(aiFact: factDto);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
