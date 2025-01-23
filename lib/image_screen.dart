import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class ImageScreen extends StatefulWidget {
  const ImageScreen({Key? key}) : super(key: key);

  @override
  ImageScreenState createState() => ImageScreenState();
}

class ImageScreenState extends State<ImageScreen> {
  String? _currentDogImage;
  late FirebaseFirestore _firestore;
  int _likedCount = 0;
  int _dislikedCount = 0;

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _fetchNewDogImage();
    _loadLikesAndDislikes();
  }

  // Fetch random dog image from The Dog API
  Future<void> _fetchNewDogImage() async {
    final response = await http.get(Uri.parse('https://dog.ceo/api/breeds/image/random'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _currentDogImage = data['message'];
      });
    } else {
      throw Exception('Failed to load dog image');
    }
  }

  // Load likes and dislikes from Firestore
  Future<void> _loadLikesAndDislikes() async {
    final userDoc = await _firestore.collection('user_likes').doc('userId').get();
    if (userDoc.exists) {
      setState(() {
        _likedCount = userDoc['likedCount'];
        _dislikedCount = userDoc['dislikedCount'];
      });
    }
  }

  // Update Firestore with the new like/dislike
  Future<void> _updateLikesInFirestore() async {
    final userRef = _firestore.collection('user_likes').doc('userId');

    await userRef.update({
      'likedCount': _likedCount,
      'dislikedCount': _dislikedCount,
    });
  }

  // Handle like action
  void _handleLike() {
    setState(() {
      _likedCount++;
      _fetchNewDogImage();
    });
    _updateLikesInFirestore();
  }

  // Handle dislike action
  void _handleDislike() {
    setState(() {
      _dislikedCount++;
      _fetchNewDogImage();
    });
    _updateLikesInFirestore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Likes: $_likedCount | Dislikes: $_dislikedCount',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
      body: _currentDogImage == null
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Display the image with fixed size and 'contain' to avoid cropping
                  Container(
                    width: 300, // Fixed width for consistency
                    height: 300, // Fixed height for consistency
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black),
                    ),
                    child: Image.network(
                      _currentDogImage!,
                      fit: BoxFit.contain, // Ensure the whole image is displayed without cropping
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.favorite, color: Colors.red),
                        onPressed: _handleLike,
                        iconSize: 40,
                      ),
                      IconButton(
                        icon: const Icon(Icons.thumb_down, color: Colors.blue),
                        onPressed: _handleDislike,
                        iconSize: 40,
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
