import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flexi_flow/data/exercise_data.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flexi_flow/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Community Hub"),
        backgroundColor: Colors.deepPurple,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Exercises"),
            Tab(text: "Info"),
            Tab(text: "Forum"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ExercisesTab(),
          InfoTab(),
          ForumTab(),
        ],
      ),
    );
  }
}

// ---------------------------
// Exercises Tab
class ExercisesTab extends StatelessWidget {
  const ExercisesTab({super.key});

  void _launchVideo(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: exerciseData.length,
      itemBuilder: (context, index) {
        final exercise = exerciseData[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: ListTile(
            title: Text(exercise['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(exercise['instructions'] ?? ''),
            trailing: IconButton(
              icon: const Icon(Icons.play_circle_fill, color: Colors.deepPurple),
              onPressed: () => _launchVideo(exercise['video_url'] ?? ''),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------
// Info Tab
class InfoTab extends StatelessWidget {
  const InfoTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("What is Arthritis?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
  "Arthritis refers to inflammation of the joints. It causes pain, swelling, stiffness, and reduced range of motion. "
  "There are over 100 different types, affecting people of all ages and backgrounds. Early diagnosis and management "
  "are crucial to reduce long-term damage.\n\n"
  "Types of Arthritis:\n"
  "- Osteoarthritis (OA): The most prevalent type, OA is a degenerative joint disease resulting from the breakdown of cartilage and underlying bone, often due to aging or joint injury.\n"
  "- Rheumatoid Arthritis (RA): An autoimmune disorder where the immune system attacks the synovial lining of joints, leading to inflammation and joint damage.\n"
  "- Psoriatic Arthritis: An inflammatory arthritis associated with psoriasis, causing joint pain, stiffness, and swelling.\n"
  "- Gout: Characterized by sudden, severe attacks of pain and swelling, typically in the big toe, due to the accumulation of urate crystals.\n"
  "- Ankylosing Spondylitis: A type of arthritis that primarily affects the spine, leading to inflammation of the vertebrae and potential fusion of the spine.\n"
  "- Juvenile Idiopathic Arthritis: The most common type of arthritis in children under 16, causing persistent joint pain, swelling, and stiffness.\n\n"
  "Global Prevalence:\n"
  "- Over 350 million people worldwide are affected by arthritis, making it a leading cause of disability globally.\n"
  "- Osteoarthritis alone affected approximately 595 million individuals globally in 2020.\n"
  "- In the United States, about 58.5 million adults have been diagnosed with arthritis, projected to rise to 78 million by 2040.\n\n"
  "Age and Gender Distribution:\n"
  "- Arthritis can occur at any age, but the risk increases with age.\n"
  "- Women are more likely to be affected than men, with a prevalence of 21.5% compared to 16.1% in men.\n"
  "- Osteoarthritis typically affects adults over 50, while rheumatoid arthritis commonly develops between ages 30 and 60.\n\n"
  "Early detection and appropriate management of arthritis are vital to prevent joint damage and maintain mobility. Treatment options may include medications, physical therapy, lifestyle modifications, and, in some cases, surgery.",
  style: TextStyle(fontSize: 16, height: 1.5),
),

          // ... (keep all other InfoTab content the same)
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}



class ForumTab extends StatefulWidget {
  const ForumTab({super.key});

  @override
  State<ForumTab> createState() => _ForumTabState();
}

class _ForumTabState extends State<ForumTab> with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  bool isPosting = false;
  bool isEditing = false;
  String? editingPostId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? currentUserEmail;
  late TabController _forumTabController;

  final List<String> blockedWords = [
    "die", "fuck", "hate", "kill", "stupid", "idiot", "dumb", "fool", "ugly", "nonsense"
  ];

  @override
  void initState() {
    super.initState();
    _forumTabController = TabController(length: 2, vsync: this);
    _getCurrentUserEmail();
  }

  @override
  void dispose() {
    _forumTabController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentUserEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        currentUserEmail = user.email;
      });
    }
  }

  bool containsBlockedWord(String text) {
    if (text.isEmpty) return false;
    final lowerText = text.toLowerCase();
    for (final word in blockedWords) {
      if (lowerText.contains(word)) {
        return true;
      }
    }
    return false;
  }

  Future<void> postMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    if (containsBlockedWord(message)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please avoid inappropriate language!")),
      );
      return;
    }

    setState(() {
      isPosting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You must be logged in to post!")),
        );
        return;
      }

      await _firestore.collection('Community_Posts').add({
        'user_id': user.uid,
        'username': user.displayName ?? 'Anonymous',
        'email': user.email ?? 'no-email',
        'message': message,
        'posted_at': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Post shared successfully!")),
      );
      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      setState(() {
        isPosting = false;
      });
    }
  }

  Future<void> editPost(String postId, String newMessage) async {
    if (newMessage.isEmpty || postId.isEmpty) return;

    setState(() {
      isPosting = true;
    });

    try {
      await _firestore.collection('Community_Posts').doc(postId).update({
        'message': newMessage,
        'posted_at': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Post updated successfully!")),
      );
      setState(() {
        isEditing = false;
        editingPostId = null;
        _messageController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      setState(() {
        isPosting = false;
      });
    }
  }

  Future<void> deletePost(String postId) async {
    if (postId.isEmpty) return;

    try {
      await _firestore.collection('Community_Posts').doc(postId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Post deleted successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        const Text("Connect with Other FlexiFlow Users!", 
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        const Text("Share your journey, tips, and encouragement 🌟", 
            style: TextStyle(fontSize: 16)),
        const SizedBox(height: 20),
        
        TabBar(
          controller: _forumTabController,
          tabs: const [
            Tab(text: "All Posts"),
            Tab(text: "My Posts"),
          ],
          labelColor: Colors.deepPurple,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.deepPurple,
        ),
        
        Expanded(
          child: TabBarView(
            controller: _forumTabController,
            children: [
              _buildAllPostsList(),
              _buildUserPostsList(),
            ],
          ),
        ),
        
        if (isEditing)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: "Edit your post...",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          isEditing = false;
                          editingPostId = null;
                          _messageController.clear();
                        });
                      },
                      child: const Text("Cancel"),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: isPosting ? null : () {
                        if (editingPostId != null) {
                          editPost(editingPostId!, _messageController.text.trim());
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                      child: isPosting
                          ? const SizedBox(width: 20, height: 20, 
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Save", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        
        if (!isEditing)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: "Share something with the community...",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: isPosting ? null : postMessage,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                    child: isPosting
                        ? const SizedBox(width: 20, height: 20, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Post", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAllPostsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('Community_Posts').orderBy('posted_at', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No posts yet. Be the first to share!"));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final post = doc.data() as Map<String, dynamic>;
            return _buildPostItem(doc.id, post, showActions: false);
          },
        );
      },
    );
  }

  Widget _buildUserPostsList() {
    if (currentUserEmail == null) {
      return const Center(child: Text("Please sign in to view your posts"));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('Community_Posts')
          .where('email', isEqualTo: currentUserEmail)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("You haven't posted anything yet"));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final post = doc.data() as Map<String, dynamic>;
            return _buildPostItem(doc.id, post, showActions: true);
          },
        );
      },
    );
  }

  Widget _buildPostItem(String docId, Map<String, dynamic> post, {required bool showActions}) {
    final timestamp = post['posted_at'] as Timestamp?;
    final postedAt = timestamp?.toDate() ?? DateTime.now();
    final isCurrentUserPost = post['email'] == currentUserEmail;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post["message"]?.toString() ?? "",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Posted by: ${post["username"]?.toString() ?? post["email"]?.toString() ?? "Anonymous"}",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Posted: ${postedAt.toLocal().toString().substring(0, 16)}",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (showActions && isCurrentUserPost)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _messageController.text = post['message']?.toString() ?? "";
                        isEditing = true;
                        editingPostId = docId;
                      });
                    },
                    child: const Text("Edit"),
                  ),
                  TextButton(
                    onPressed: () => _showDeleteDialog(docId),
                    child: const Text("Delete", style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(String postId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Post'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete this post?'),
                Text('This action cannot be undone.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                deletePost(postId);
              },
            ),
          ],
        );
      },
    );
  }
}