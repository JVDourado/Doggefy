import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final Set<Item> _favorites = {};
  late Future<List<Item>> _items;

  @override
  void initState() {
    super.initState();
    _items = fetchItems();
    _loadFavorites(); // Load favorites from Firestore
  }

  // Load favorites from Firestore
  Future<void> _loadFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final docSnapshot = await userRef.get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        final favorites = List<String>.from(data['favorites'] ?? []);
        setState(() {
          _favorites.addAll(favorites.map((title) => Item(title: title, imageUrl: '', temperament: '', lifeSpan: '', weight: '')));
        });
      }
    }
  }

  // Save favorites to Firestore
  Future<void> _saveFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final favorites = _favorites.map((item) => item.title).toList();
      await userRef.set({'favorites': favorites}, SetOptions(merge: true));
    }
  }

  // Fetch breed data
  Future<List<Item>> fetchItems() async {
    const url = 'https://api.thedogapi.com/v1/breeds';
    final response = await http.get(Uri.parse(url), headers: {
      'x-api-key': 'live_QzMzbsROanpeDTVnU2UIrcdGoeIx6llMzfdMShucVMAjFxDobZZgNXqnk2wyqCuD'
    });

    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((json) => Item.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load data');
    }
  }

  // Toggle favorite breed
  void _toggleFavorite(Item item) {
    setState(() {
      if (_favorites.contains(item)) {
        _favorites.remove(item);
      } else {
        _favorites.add(item);
      }
    });
    _saveFavorites(); // Save favorites after toggling
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Item>>(
        future: _items,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No items found.'));
          } else {
            final items = snapshot.data!;
            final favoriteItems = items.where((item) => _favorites.contains(item)).toList();
            final otherItems = items.where((item) => !_favorites.contains(item)).toList();

            return ListView(
              children: [
                // Section for favorites
                if (favoriteItems.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Raças favoritas',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                // Favorite breeds list
                if (favoriteItems.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: favoriteItems.length,
                    itemBuilder: (context, index) {
                      final item = favoriteItems[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(item.imageUrl),
                          onBackgroundImageError: (_, __) => const AssetImage('assets/images/placeholder.jpg'),
                        ),
                        title: Text(item.title),
                        trailing: GestureDetector(
                          child: Icon(
                            _favorites.contains(item) ? Icons.star : Icons.star_border,
                            color: Colors.yellow.shade800,
                          ),
                          onTap: () => _toggleFavorite(item),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailPage(item: item),
                          ),
                        ),
                      );
                    },
                  ),
                // Section for other breeds
                if (otherItems.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Raças',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                // Other breeds list
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: otherItems.length,
                  itemBuilder: (context, index) {
                    final item = otherItems[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(item.imageUrl),
                        onBackgroundImageError: (_, __) => const AssetImage('./assets/images/placeholderdogge.jpg'),
                      ),
                      title: Text(item.title),
                      trailing: GestureDetector(
                        child: Icon(
                          _favorites.contains(item) ? Icons.star : Icons.star_border,
                          color: Colors.yellow.shade800,
                        ),
                        onTap: () => _toggleFavorite(item),
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailPage(item: item),
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          }
        },
      ),
    );
  }
}

class Item {
  final String title;
  final String imageUrl;
  final String temperament;
  final String lifeSpan;
  final String weight;

  Item({
    required this.title,
    required this.imageUrl,
    required this.temperament,
    required this.lifeSpan,
    required this.weight,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      title: json['name'],
      imageUrl: json['image'] != null ? json['image']['url'] : '',
      temperament: json['temperament'] ?? 'Not available',
      lifeSpan: json['life_span'] ?? 'Not available',
      weight: json['weight'] != null ? json['weight']['imperial'] : 'Not available',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Item && other.title == title;
  }

  @override
  int get hashCode => title.hashCode;
}

class DetailPage extends StatelessWidget {
  final Item item;

  const DetailPage({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da raça'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Image.network(item.imageUrl),
              const SizedBox(height: 20),
              Text(
                item.title,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text('Temperament: ${item.temperament}'),
              const SizedBox(height: 10),
              Text('Life Span: ${item.lifeSpan} years'),
              const SizedBox(height: 10),
              Text('Weight: ${item.weight} lbs'),
            ],
          ),
        ),
      ),
    );
  }
}
