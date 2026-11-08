import 'package:flutter/material.dart';
import 'package:single_radio/config.dart';
import 'package:single_radio/language.dart';
import 'package:single_radio/theme.dart';
import 'package:single_radio/widgets/screen.dart';
import 'package:url_launcher/url_launcher.dart';

/// Native editorial about page, consistent with the privacy screen.
/// Full, original radio wordmark – no square/old brewery artwork.
class AboutView extends StatelessWidget {
  const AboutView({super.key});
  static const routeName = '/about';

  static const Color navy = Color(0xFF101D2C);
  static const Color muted = Color(0xFFB6C5D2);
  static const Color border = Color(0xFF26394A);

  Future<void> _open(String link) async {
    await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Screen(
      title: Language.aboutUs,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 20, 14, 24),
            decoration: BoxDecoration(
              color: const Color(0xFF080C13),
              border: Border.all(
                color: AppTheme.accentColor.withOpacity(0.30),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(23),
            ),
            child: Column(
              children: [
                const Text(
                  'HLAS ČESKÉHO RÁJE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12, letterSpacing: 2.1,
                    color: AppTheme.accentColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 15),
                Image.asset(
                  'assets/images/rcr_full_logo.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  width: double.infinity,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Náš kraj. Naše hudba. Váš den.',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _InfoCard(
            icon: Icons.favorite_border_rounded,
            eyebrow: 'KDO JSME',
            title: 'Rádio, které patří našemu kraji',
            description:
                'Rádio Český ráj spojuje hudbu s příběhy lidí a míst, '
                'které máme rádi. Jsme tu pro všechny, kdo se v našem '
                'kraji narodili, žijí v něm nebo se do něj rádi vracejí.',
          ),
          const SizedBox(height: 14),
          _InfoCard(
            icon: Icons.auto_stories_outlined,
            eyebrow: 'CO U NÁS USLYŠÍTE',
            title: 'Hudbu i skutečné příběhy',
            description:
                'Přinášíme pohodovou hudbu, regionální zajímavosti, '
                'vyprávění ze známých i zapomenutých míst a pořady, '
                'které mají k Českému ráji blízko.',
          ),
          const SizedBox(height: 26),
          const Text(
            'JSME SPOLU',
            style: TextStyle(
              color: AppTheme.accentColor, fontSize: 12,
              fontWeight: FontWeight.w700, letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: navy,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language,
                      color: AppTheme.accentColor),
                  title: const Text('Web Rádia Český ráj',
                      style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w600)),
                  subtitle: const Text('radioceskyraj.cz',
                      style: TextStyle(color: muted)),
                  trailing: const Icon(Icons.open_in_new, color: muted),
                  onTap: () => _open(Config.website),
                ),
                const Divider(height: 1, indent: 60,
                    endIndent: 18, color: border),
                ListTile(
                  leading: const Icon(Icons.article_outlined,
                      color: AppTheme.accentColor),
                  title: const Text('Mediální partner – Rájoviny.cz',
                      style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w600)),
                  subtitle: const Text('Příběhy, zprávy a zajímavosti',
                      style: TextStyle(color: muted)),
                  trailing: const Icon(Icons.open_in_new, color: muted),
                  onTap: () => _open(Config.partnerWebsite),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Zpět k vysílání'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: const Color(0xFF101A27),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AboutView.navy,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AboutView.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.accentColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(eyebrow,
                style: const TextStyle(
                  color: AppTheme.accentColor, fontSize: 11,
                  fontWeight: FontWeight.w700, letterSpacing: 1.2,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 17),
          Text(title, style: const TextStyle(
            color: Colors.white, fontSize: 21,
            fontWeight: FontWeight.w700, height: 1.27,
          )),
          const SizedBox(height: 12),
          Text(description, style: const TextStyle(
            color: AboutView.muted, fontSize: 15, height: 1.6,
          )),
        ],
      ),
    );
  }
}
