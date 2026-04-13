import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pawnder_app/theme.dart';

class ListingScreen extends StatelessWidget {
  const ListingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tagNames = ['Resident', 'FoundPet', 'Cat', 'Dog', 'Brooklyn', 'Queens'];

    return Scaffold(
      backgroundColor: AppColors.powderBlue,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.black,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'CREATE LISTING',
                style: GoogleFonts.lilitaOne(
                  fontSize: 34,
                  color: AppColors.seaBlue,
                ),
              ),
              const SizedBox(height: 22),
              Center(
                child: SizedBox(
                  width: 220,
                  child: Column(
                    children: [
                      _FieldPill(hintText: 'Title'),
                      const SizedBox(height: 14),
                      _DescriptionBox(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Center(
                child: Text(
                  'ADD TAGS',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: tagNames
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.seaBlue,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: Container(
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 58,
                        color: AppColors.seaBlue,
                      ),
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

class _FieldPill extends StatelessWidget {
  final String hintText;

  const _FieldPill({required this.hintText});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        hintText,
        style: const TextStyle(
          color: Color(0xFFCDD3DA),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _DescriptionBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Text(
        'Add a description',
        style: TextStyle(
          color: Color(0xFFCDD3DA),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}