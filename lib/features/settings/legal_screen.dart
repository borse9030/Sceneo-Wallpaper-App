import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LegalScreen extends StatelessWidget {
  final String type; // 'privacy' or 'terms'

  const LegalScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final isPrivacy = type == 'privacy';
    final title = isPrivacy ? 'Privacy Policy' : 'Terms of Service';
    final content = isPrivacy ? _privacyPolicyText : _termsText;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            centerTitle: true,
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 22,
                letterSpacing: 1.0,
              ),
            ).animate().fade().slideY(begin: 0.2, end: 0.0),
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  color: AppColors.background.withOpacity(0.5),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20.0),
            sliver: SliverToBoxAdapter(
              child: Text(
                content,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.6,
                ),
              ).animate().fade(delay: 100.ms),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }

  static const _privacyPolicyText = '''
**Privacy Policy for Sceneo**

Effective Date: January 1, 2024

**1. Introduction**
Welcome to Sceneo. We are committed to protecting your personal information and your right to privacy. If you have any questions or concerns about this privacy notice, or our practices with regards to your personal information, please contact us at support@sceneo.app.

**2. Information We Collect**
We collect personal information that you voluntarily provide to us when you register on the App, express an interest in obtaining information about us or our products and Services, when you participate in activities on the App or otherwise when you contact us.

**3. Use of Your Information**
We use personal information collected via our App for a variety of business purposes described below. We process your personal information for these purposes in reliance on our legitimate business interests, in order to enter into or perform a contract with you, with your consent, and/or for compliance with our legal obligations.

**4. Data Storage and Images**
All wallpapers uploaded are stored securely on Firebase. By uploading images, you grant Sceneo a license to display them within the app. We use on-device caching to save images on your device for better performance. 

**5. Third-Party Services**
We may share your data with third-party vendors, service providers, contractors or agents who perform services for us or on our behalf and require access to such information to do that work.

**6. Changes to This Notice**
We may update this privacy notice from time to time. The updated version will be indicated by an updated "Revised" date and the updated version will be effective as soon as it is accessible.

**7. Contact Us**
If you have questions or comments about this notice, you may email us at support@sceneo.app.
''';

  static const _termsText = '''
**Terms of Service for Sceneo**

Effective Date: January 1, 2024

**1. Agreement to Terms**
By viewing or using this App, which is accessible from Sceneo, you agree to be bound by all these Terms of Service. If you disagree with any of these terms, you are prohibited from using this app.

**2. Intellectual Property Rights**
Other than the content you own, under these Terms, Sceneo and/or its licensors own all the intellectual property rights and materials contained in this App. 

**3. User Content**
In these App Standard Terms and Conditions, "Your Content" shall mean any audio, video text, images or other material you choose to display on this App. By displaying Your Content, you grant Sceneo a non-exclusive, worldwide irrevocable, sub licensable license to use, reproduce, adapt, publish, translate and distribute it in any and all media.

**4. Restrictions**
You are specifically restricted from all of the following:
- publishing any App material in any other media;
- selling, sublicensing and/or otherwise commercializing any App material;
- publicly performing and/or showing any App material;
- using this App in any way that is or may be damaging to this App;
- using this App contrary to applicable laws and regulations.

**5. No Warranties**
This App is provided "as is," with all faults, and Sceneo express no representations or warranties, of any kind related to this App or the materials contained on this App.

**6. Governing Law & Jurisdiction**
These Terms will be governed by and interpreted in accordance with the laws of the State, and you submit to the non-exclusive jurisdiction of the state and federal courts located in us for the resolution of any disputes.
''';
}
