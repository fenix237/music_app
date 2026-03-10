import 'package:flutter/material.dart';



class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Contenu principal scrollable
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100), // Espace pour la bottom nav bar
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildGreeting(),
                  const SizedBox(height: 24),
                  _buildCategoryChips(),
                  const SizedBox(height: 30),
                  _buildForYouSection(),
                  const SizedBox(height: 30),
                  _buildPopularSection(),
                ],
              ),
            ),
            
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundImage: AssetImage('assets/images/profile.jpeg'),
          ),
          Row(
            children: [
              _buildIconButton(Icons.search),
              const SizedBox(width: 10),
              _buildIconButton(Icons.notifications_none),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.05),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white70),
        onPressed: () {},
      ),
    );
  }

  Widget _buildGreeting() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        'Hello, Kyser',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = ['All', 'New Artists', 'Hot Tracks', 'Editor\'s Picks'];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: categories.asMap().entries.map((entry) {
          int index = entry.key;
          String label = entry.value;
          bool isSelected = index == 0;
          
          return Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFA838FF) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Colors.transparent : Colors.white30,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildForYouSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'For you',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _buildForYouCard(),
              const SizedBox(width: 16),
              // Un deuxième bloc partiellement visible comme sur le design
              Opacity(opacity: 0.5, child: _buildForYouCard()), 
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildForYouCard() {
    return Container(
      width: 320,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: DecorationImage(image: AssetImage('assets/images/cover1.jpg'), fit: BoxFit.cover),
        gradient: const LinearGradient(
          colors: [Color(0xFFA838FF), Color(0xFF4B66EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Image de fond (la fille avec le casque)
          Positioned(
            right: 0,
            bottom: 0,
            top: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              // child: Image.asset(
              //       'assets/images/cover1.jpg',
              //       fit: BoxFit.cover,
              //       width: 300,
              //     ),
            ),
          ),
          // Contenu texte et bouton
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Feel the Beat',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 160,
                  child: Text(
                    'Explore trending tracks and hidden gems curated just for you.',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Start Listening', style: TextStyle(color: Colors.white)),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularSection() {
    final List<Map<String, String>> popularTracks = [
      {'title': 'Blinding Light', 'artist': 'Top Hit', 'color': '0xFF8A2387'},
      {'title': 'Ocean Eyes', 'artist': 'Soft Vibe', 'color': '0xFF0F2027'},
      {'title': 'Circles Run', 'artist': 'Fan Fav', 'color': '0xFFF2709C'},
      {'title': 'Peaches', 'artist': 'Trending', 'color': '0xFF11998E'},
      {'title': 'Commando', 'artist': 'Niska', 'color': '0xFF11998E'},
      {'title': 'Mr sal', 'artist': 'Niska', 'color': '0xFF11998E'},

    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Popular', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Show all >', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6))),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: popularTracks.length,
            itemBuilder: (context, index) {
              final track = popularTracks[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Color(int.parse(track['color']!)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.music_note, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(track['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(track['artist']!, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.play_circle_fill),
                      color: Colors.white54,
                      iconSize: 32,
                      onPressed: () {},
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
    );
  }

  
}
