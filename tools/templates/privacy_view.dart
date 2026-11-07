import 'package:flutter/material.dart';
import 'package:single_radio/config.dart';
import 'package:single_radio/theme.dart';
import 'package:url_launcher/url_launcher.dart';

/// Native, full-screen privacy page; no Markdown dialog over the player.
class PrivacyView extends StatelessWidget {
  const PrivacyView({super.key});

  static const routeName = '/privacy';

  static const _muted = Color(0xFFB6C5D2);
  static const _card = Color(0xFF101D2C);
  static const _stroke = Color(0xFF26394A);

  Future<void> _open(String address) async {
    final uri = Uri.parse(address);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Soukromí v aplikaci'),
        centerTitle: true,
        backgroundColor: AppTheme.headerColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E3646), Color(0xFF101A27)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.accentColor.withOpacity(0.38),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.shield_outlined,
                      size: 38, color: AppTheme.accentColor),
                  SizedBox(height: 16),
                  Text(
                    'Vaše soukromí.\nJasně a přehledně.',
                    style: TextStyle(
                      fontSize: 25,
                      height: 1.18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Jak funguje ochrana údajů při poslechu Rádia Český ráj.',
                    style: TextStyle(fontSize: 15, height: 1.5, color: _muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const _PrivacyCard(
              icon: Icons.person_outline_rounded,
              title: 'Bez účtu a registrace',
              description:
                  'K poslechu rádia nepotřebujete uživatelský účet ani zadávat osobní údaje.',
            ),
            const SizedBox(height: 12),
            const _PrivacyCard(
              icon: Icons.wifi_rounded,
              title: 'Internetové připojení',
              description:
                  'Přehrávání vyžaduje připojení ke streamovacímu serveru. '
                  'Jeho provozovatel může zpracovávat IP adresu a technické '
                  'informace o připojení.',
            ),
            const SizedBox(height: 12),
            const _PrivacyCard(
              icon: Icons.headphones_outlined,
              title: 'Poslech na pozadí',
              description:
                  'Vysílání může pokračovat také po přepnutí do jiné aplikace '
                  'nebo při zamknuté obrazovce.',
            ),
            const SizedBox(height: 12),
            const _PrivacyCard(
              icon: Icons.share_outlined,
              title: 'Odkazy a sdílení',
              description:
                  'Sdílení je dobrovolné a využívá funkce vašeho telefonu. '
                  'Při otevření externího webu platí zásady příslušného webu.',
            ),
            const SizedBox(height: 26),
            const Text(
              'DALŠÍ INFORMACE',
              style: TextStyle(
                color: AppTheme.accentColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _stroke),
              ),
              child: Column(
                children: [
                  _LinkRow(
                    icon: Icons.language_rounded,
                    title: 'Oficiální web rádia',
                    subtitle: 'radioceskyraj.cz',
                    onTap: () => _open(Config.website),
                  ),
                  const Divider(
                    height: 1, indent: 62, endIndent: 18, color: _stroke),
                  _LinkRow(
                    icon: Icons.article_outlined,
                    title: 'Mediální partner',
                    subtitle: 'rajoviny.cz',
                    onTap: () => _open(Config.partnerWebsite),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tyto informace se vztahují k mobilní aplikaci Rádio Český ráj.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, height: 1.5, color: _muted),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Zpět k vysílání'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: AppTheme.headerColor,
                  backgroundColor: AppTheme.accentColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: PrivacyView._card,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: PrivacyView._stroke),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.11),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: AppTheme.accentColor, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(
                  fontSize: 16, color: Colors.white,
                  fontWeight: FontWeight.w700, height: 1.35,
                )),
                const SizedBox(height: 7),
                Text(description, style: const TextStyle(
                  fontSize: 14, height: 1.55,
                  color: PrivacyView._muted,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 5),
      leading: Icon(icon, size: 25, color: AppTheme.accentColor),
      title: Text(title, style: const TextStyle(
        color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(
        color: PrivacyView._muted, fontSize: 13)),
      trailing: const Icon(Icons.open_in_new_rounded,
        size: 19, color: PrivacyView._muted),
      onTap: onTap,
    );
  }
}
