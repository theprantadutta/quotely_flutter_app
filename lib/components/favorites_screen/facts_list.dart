import 'package:flutter/material.dart';
import 'package:quotely_flutter_app/components/facts_screen/single_fact.dart';
import 'package:quotely_flutter_app/dtos/ai_fact_dto.dart';
import 'package:quotely_flutter_app/services/drift_fact_service.dart';

class FactsList extends StatelessWidget {
  const FactsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: MediaQuery.sizeOf(context).height * 0.05,
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
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
                return ListView.builder(
                  itemCount: 10,
                  itemBuilder: (context, index) {
                    return SingleFactSkeletor();
                  },
                );
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Something went wrong'));
              }
              final facts = snapshot.data!;
              if (facts.isEmpty) {
                return const Center(child: Text('No favorite facts found'));
              }
              return ListView.builder(
                itemCount: facts.length,
                itemBuilder: (context, index) {
                  final fact = facts[index];
                  final factDto = AiFactDto.fromDrift(fact);
                  return SingleFact(aiFact: factDto);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
