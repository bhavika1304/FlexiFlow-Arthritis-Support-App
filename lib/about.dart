import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lottie/lottie.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
            FadeInDown(
              duration: const Duration(milliseconds: 800),
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepPurple.shade400,
                      Colors.deepPurple.shade600,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: 20,
                      bottom: -30,
                      child: ElasticIn(
                        delay: const Duration(milliseconds: 500),
                        child: Lottie.asset(
                          'animations/about.json',
                          width: 300,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 30,
                      top: 100,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FadeInLeft(
                            delay: const Duration(milliseconds: 300),
                            child: Text(
                              'About FlexiFlow',
                              style: GoogleFonts.poppins(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          FadeInLeft(
                            delay: const Duration(milliseconds: 500),
                            child: Text(
                              'Empowering arthritis patients\nwith AI-driven solutions',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Problem Statement Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
              child: FadeInUp(
                delay: const Duration(milliseconds: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'We Understand Your Pain',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 30),
                    BounceInLeft(
                      delay: const Duration(milliseconds: 800),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurple.withOpacity(0.1),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Text(
                          "Arthritis affects millions worldwide, causing chronic pain and mobility issues. "
                          "Daily activities become challenging, and finding personalized relief can be overwhelming. "
                          "We've seen our loved ones struggle with this invisible pain, and that's why we created FlexiFlow. "
                          "This app is specifically designed to treat Rheumatoid Arthritis (RA), Spondyloarthritis (SpA), and Osteoarthritis (OA), "
                          "based on clinically researched guidelines like EULAR recommendations. "
                          "Our AI model is enhanced with reinforcement learning, utilizing user feedback to improve suggestions and solutions over time.",
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            height: 1.6,
                            color: Colors.grey.shade800,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Team Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
              child: FadeInUp(
                delay: const Duration(milliseconds: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Meet The Team',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Wrap(
                        spacing: 30,
                        runSpacing: 30,
                        children: [
                          BounceInUp(
                            delay: const Duration(milliseconds: 900),
                            child: _buildTeamMember(
                              name: "Sarayu Krishna",
                              role: "Developer",
                              image: "images/sarayu.jfif",
                            ),
                          ),
                          BounceInUp(
                            delay: const Duration(milliseconds: 1000),
                            child: _buildTeamMember(
                              name: "Bhavika Gandham",
                              role: "Developer",
                              image: "images/bhavika.jpeg",
                            ),
                          ),
                          BounceInUp(
                            delay: const Duration(milliseconds: 1100),
                            child: _buildTeamMember(
                              name: "Trisha Vijayekkumaran",
                              role: "Developer",
                              image: "images/trishtrash.jpeg",
                            ),
                          ),
                          BounceInUp(
                            delay: const Duration(milliseconds: 1200),
                            child: _buildTeamMember(
                              name: "Dr. Nandu C. Nair",
                              role: "Mentor",
                              image: "images/nandumam.jpeg",
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    FadeInUp(
                      delay: const Duration(milliseconds: 1300),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "As computer science students, we combined our technical skills with a passion for healthcare "
                          "after seeing family members struggle with arthritis. Our mission is to make daily life easier "
                          "for arthritis patients through technology.",
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            height: 1.6,
                            color: Colors.grey.shade800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamMember({
    required String name,
    required String role,
    required String image,
  }) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.deepPurple.withOpacity(0.3),
              width: 5,
            ),
            image: DecorationImage(
              image: AssetImage(image),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 15),
        Text(
          name,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          role,
          style: GoogleFonts.poppins(
            color: Colors.deepPurple.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
