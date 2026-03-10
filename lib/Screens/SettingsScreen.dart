import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Assure un fond sombre si le thème global ne le fait pas
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildHeader(context),
              const SizedBox(height: 30),
              _buildProfileSection(),
              const SizedBox(height: 30),
              _buildSectionTitle('Playback'),
              _buildSettingsTile(
                icon: Icons.offline_bolt_outlined,
                title: 'Offline Mode',
                subtitle: 'Play downloaded music only',
                trailing: Switch(
                  value: false,
                  onChanged: (val) {},
                  activeColor: const Color(0xFFA838FF),
                ),
              ),
              _buildSettingsTile(
                icon: Icons.equalizer,
                title: 'Equalizer',
                subtitle: 'Adjust audio settings',
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Account & App'),
              _buildSettingsTile(
                icon: Icons.notifications_none,
                title: 'Notifications',
                subtitle: 'Manage push notifications',
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
              ),
              _buildSettingsTile(
                icon: Icons.data_saver_off,
                title: 'Data Saver',
                subtitle: 'Set audio quality for cellular',
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('About'),
              _buildSettingsTile(
                icon: Icons.info_outline,
                title: 'Version',
                subtitle: '1.0.0 (Build 14)',
                trailing: const SizedBox.shrink(),
              ),
              const SizedBox(height: 40),
              //_buildLogoutButton(),
            ],
          ),
        ),
      ),
    );
  }

  // En-tête avec bouton retour et titre
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white70),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 20),
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Section Profil de l'utilisateur
  Widget _buildProfileSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 35,
            backgroundImage: AssetImage('assets/images/profile.jpeg'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kyser',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Premium Plan',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFFA838FF), // Couleur d'accentuation violette
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Edit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Titre des sections
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white.withOpacity(0.5),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // Tuile réutilisable pour chaque paramètre
  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white70),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.white.withOpacity(0.6),
          fontSize: 13,
        ),
      ),
      trailing: trailing,
      onTap: () {
        // Action au clic sur la ligne
      },
    );
  }

  // Bouton de déconnexion
  Widget _buildLogoutButton() {
    return Center(
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.redAccent, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
        ),
        child: const Text(
          'Log Out',
          style: TextStyle(
            color: Colors.redAccent,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}