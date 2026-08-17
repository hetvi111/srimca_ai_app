import 'package:flutter/material.dart';

const Color vNavyDark = Color(0xFF001F3F);
const Color vBlueAccent = Color(0xFF1E88E5);
const Color vTextDark = Color(0xFF0F172A);
const Color vTextMuted = Color(0xFF64748B);

class VisitorInfoSheets {
  static void show(BuildContext context, String title, Widget content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.78,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 20, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: vNavyDark,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 24),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: content,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 1. About SRIMCA (Overview, Vision & Mission)
  static Widget aboutSrimca() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('About the Institute'),
        const Text(
          'Shrimad Rajchandra Institute of Management and Computer Application (SRIMCA) is a premier educational institution established in 2002 (MCA) and 2004 (MBA). It is a constituent institute of Uka Tarsadia University (UTU), Maliba Campus, Bardoli, Surat.',
          style: TextStyle(fontSize: 14, height: 1.5, color: vTextMuted),
        ),
        const SizedBox(height: 18),
        _heading('🌟 Vision'),
        const Text(
          'To become a globally recognized premier educational institute for academic excellence, innovative technological education, research, and holistic character building.',
          style: TextStyle(fontSize: 14, height: 1.5, color: vTextMuted),
        ),
        const SizedBox(height: 18),
        _heading('🎯 Mission'),
        const Text(
          'To remain on the cutting edge of education, research, and industry partnerships while upholding moral values, social commitment, and professional ethics.',
          style: TextStyle(fontSize: 14, height: 1.5, color: vTextMuted),
        ),
        const SizedBox(height: 18),
        _heading('🏛️ Approvals & Accreditation'),
        const Text(
          '• Approved by AICTE (All India Council for Technical Education), New Delhi\n• Approved by Government of Gujarat\n• Constituent institute of Uka Tarsadia University (NAAC Accredited)',
          style: TextStyle(fontSize: 14, height: 1.5, color: vTextMuted),
        ),
      ],
    );
  }

  // 2. Programs Offered (MCA, BCA, Other Programs)
  static Widget programsOffered() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _programCard(
          'Master of Computer Applications (MCA)',
          '2 Years (4 Semesters)',
          'Passed BCA / Bachelor Degree in Computer Science or B.Sc/B.Com/BA with Mathematics with min 50% marks (45% for reserved category).',
          'ACPC Gujarat Centralized Admission & Management Quota.',
          Icons.code_rounded,
          const Color(0xFF2563EB),
        ),
        _programCard(
          'Bachelor of Computer Applications (BCA)',
          '3 Years (6 Semesters)',
          'Passed 12th standard (HSC) examination from Gujarat Board or CBSE/ICSE in Science or General Stream (Commerce/Arts with English).',
          'Direct Online Admission through UTU Admission Portal.',
          Icons.laptop_chromebook_rounded,
          const Color(0xFF059669),
        ),
        _programCard(
          'Integrated MCA (5-Year Dual Degree)',
          '5 Years (10 Semesters)',
          'Passed 12th standard (HSC) in Science or General Stream.',
          'Direct Merit-Based Admission at UTU Campus.',
          Icons.school_rounded,
          const Color(0xFF7C3AED),
        ),
        _programCard(
          'Master of Business Administration (MBA)',
          '2 Years (4 Semesters)',
          'Recognized Bachelor degree in any discipline with min 50% marks.',
          'Through ACPC CMAT ranking & Management Quota.',
          Icons.business_center_rounded,
          const Color(0xFFD97706),
        ),
      ],
    );
  }

  // 3. Admission Information (Eligibility, Required Documents, Process)
  static Widget admissionInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('📝 Step-by-Step Admission Process'),
        const Text(
          '1. Online Registration on UTU Admission Portal (for BCA/Integrated) or ACPC portal (for MCA/MBA).\n'
          '2. Document Verification and Merit Ranking generation.\n'
          '3. Choice Filling and Seat Allotment.\n'
          '4. Document submission and Tuition Fee Token Payment.\n'
          '5. Orientation & Commencement of Classes.',
          style: TextStyle(fontSize: 14, height: 1.6, color: vTextMuted),
        ),
        const SizedBox(height: 20),
        _heading('📄 Required Documents Checklist'),
        const Text(
          '• 10th Standard Marksheet & Passing Certificate\n'
          '• 12th Standard (HSC) Marksheet\n'
          '• Graduation Marksheets & Degree Certificate (for MCA/MBA)\n'
          '• School/College Leaving Certificate (Transfer Certificate)\n'
          '• Caste Certificate & Non-Creamy Layer (NCL) Certificate (if applicable)\n'
          '• Aadhar Card Copy & Recent Passport Sized Photographs (4 copies)\n'
          '• Migration Certificate (for students outside Gujarat Board/University)',
          style: TextStyle(fontSize: 14, height: 1.6, color: vTextMuted),
        ),
      ],
    );
  }

  // 4. Placement Highlights (Recruiters, Statistics)
  static Widget placementHighlights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('💼 Placement Records & Highlights'),
        const Text(
          'SRIMCA has an exceptional track record of training and placing students in top-tier multinational companies and fast-growing tech startups.',
          style: TextStyle(fontSize: 14, height: 1.5, color: vTextMuted),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _statBox('85%+', 'Placement Rate')),
            const SizedBox(width: 10),
            Expanded(child: _statBox('₹8.5 LPA', 'Highest Package')),
            const SizedBox(width: 10),
            Expanded(child: _statBox('50+', 'Tech Recruiters')),
          ],
        ),
        const SizedBox(height: 20),
        _heading('🏢 Top Recruiting Partners'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            'TCS',
            'Infosys',
            'Wipro',
            'Capgemini',
            'L&T Infotech',
            'TatvaSoft',
            'Bacancy',
            'WebOccult',
            'Dhyey Consulting',
            'Crest Data Systems',
            'Gateway Group',
            'Zealous System',
          ].map((c) => Chip(
            label: Text(c, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            backgroundColor: const Color(0xFFF1F5F9),
          )).toList(),
        ),
        const SizedBox(height: 16),
        _heading('🎯 Training & Placement Cell Activities'),
        const Text(
          '• Pre-placement Aptitude & Soft-skill Grooming\n• Mock Technical Interviews & Coding Challenges\n• Final Semester 6-Month Industrial Internships',
          style: TextStyle(fontSize: 14, height: 1.5, color: vTextMuted),
        ),
      ],
    );
  }

  // 5. Campus Facilities (Library, Labs, Seminar Hall, Sports)
  static Widget campusFacilities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _facilityTile(
          'High-Tech Computer Labs',
          'Over 250+ high-end networked workstations equipped with modern programming IDEs, AI/ML tools, and Gigabit LAN.',
          Icons.computer_rounded,
          const Color(0xFF2563EB),
        ),
        _facilityTile(
          'Dedicated 200 Mbps Leased-Line Wi-Fi',
          'High-speed seamless wireless connectivity available across all academic blocks, hostels, and libraries.',
          Icons.wifi_rounded,
          const Color(0xFF059669),
        ),
        _facilityTile(
          'Central Digital Library',
          'Rich collection of thousands of textbooks, international research journals (IEEE, ACM), e-books, and reading zones.',
          Icons.local_library_rounded,
          const Color(0xFF7C3AED),
        ),
        _facilityTile(
          'AC Auditorium & Seminar Halls',
          'State-of-the-art 500-seater acoustic auditorium and air-conditioned interactive seminar rooms with smart projectors.',
          Icons.theater_comedy_rounded,
          const Color(0xFFD97706),
        ),
        _facilityTile(
          'Hostel & Sports Amenities',
          'Separate on-campus AC/Non-AC hostels for boys and girls, 24/7 security, gymnasium, cricket ground, and indoor badminton arena.',
          Icons.sports_cricket_rounded,
          const Color(0xFFE11D48),
        ),
      ],
    );
  }

  // 6. Fees Structure & Scholarships
  static Widget feesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('💰 Estimated Annual Academic Fees'),
        const Text(
          '• MCA: Approx. ₹65,000 - ₹75,000 / Year\n'
          '• BCA: Approx. ₹45,000 - ₹55,000 / Year\n'
          '• Integrated MCA: Approx. ₹48,000 - ₹58,000 / Year\n'
          '• MBA: Approx. ₹68,000 - ₹78,000 / Year\n'
          '*(Tuition fees as approved by Fee Regulatory Committee, Gujarat)*',
          style: TextStyle(fontSize: 14, height: 1.6, color: vTextMuted),
        ),
        const SizedBox(height: 20),
        _heading('🎓 Government & University Scholarships'),
        const Text(
          '• MYSY (Mukhyamantri Yuva Swavalamban Yojana) - 50% tuition fee scholarship for eligible students.\n'
          '• Digital Gujarat SC/ST/SEBC Post-Matric Scholarships.\n'
          '• UTU Merit Scholarships for semester toppers and sports achievers.',
          style: TextStyle(fontSize: 14, height: 1.6, color: vTextMuted),
        ),
      ],
    );
  }

  // 7. Faculty Details
  static Widget facultyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('👨‍🏫 Qualified Academic Faculty'),
        const Text(
          'SRIMCA has dedicated, experienced faculty holding Ph.D. and M.Tech degrees from reputed institutions with extensive research in Artificial Intelligence, Cloud Computing, Cybersecurity, and Software Architecture.',
          style: TextStyle(fontSize: 14, height: 1.5, color: vTextMuted),
        ),
        const SizedBox(height: 14),
        const Text(
          '• Dedicated 1-on-1 Faculty Mentorship counseling\n• Industrial Expert Guest Lectures & Tech Workshops\n• Research Paper publishing guidance for students',
          style: TextStyle(fontSize: 14, height: 1.5, color: vTextMuted),
        ),
      ],
    );
  }

  // 8. Contact & Helpline
  static Widget contactContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('📞 Contact SRIMCA Helpdesk'),
        const Text(
          '• Central Phone: +91 2625 290074 / 290075\n'
          '• Admissions Hotline: +91 99099 12345\n'
          '• Email: director.srimca@utu.ac.in\n'
          '• Official Website: srimca.utu.ac.in / www.utu.ac.in\n'
          '• Office Timings: Monday to Saturday (8:30 AM - 4:30 PM)',
          style: TextStyle(fontSize: 14, height: 1.6, color: vTextMuted),
        ),
      ],
    );
  }

  // 9. Campus Location & Transportation
  static Widget locationContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('📍 Campus Address'),
        const Text(
          'Shrimad Rajchandra Institute of Management & Computer Application (SRIMCA)\n'
          'Maliba Campus, Gopal Vidyanagar, Bardoli-Mahuva Road, Tarsadi, Surat, Gujarat - 394350.',
          style: TextStyle(fontSize: 14, height: 1.5, color: vTextMuted),
        ),
        const SizedBox(height: 16),
        _heading('🚌 Campus Bus Transportation'),
        const Text(
          'The university runs 50+ dedicated buses covering major routes in:\n'
          '• Surat City (Adajan, Varachha, Katargam, City Light, Rander)\n'
          '• Navsari City & surrounding towns\n'
          '• Bardoli, Vyara, Kadod, Mandvi, and Valod.',
          style: TextStyle(fontSize: 14, height: 1.5, color: vTextMuted),
        ),
      ],
    );
  }

  // --- Helper Builders ---
  static Widget _heading(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: vNavyDark,
        ),
      ),
    );
  }

  static Widget _statBox(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: vBlueAccent),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: vTextMuted),
          ),
        ],
      ),
    );
  }

  static Widget _programCard(
    String title,
    String duration,
    String eligibility,
    String admission,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: vNavyDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('⏱ Duration: $duration', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: vTextDark)),
          const SizedBox(height: 4),
          Text('🎓 Eligibility: $eligibility', style: const TextStyle(fontSize: 12, color: vTextMuted)),
          const SizedBox(height: 4),
          Text('📝 Admission: $admission', style: const TextStyle(fontSize: 12, color: vTextMuted)),
        ],
      ),
    );
  }

  static Widget _facilityTile(String title, String desc, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: vNavyDark),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 12, color: vTextMuted, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
