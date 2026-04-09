import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../models/doctor.dart';
import '../../models/review.dart';
import '../../services/api_service.dart';

class ReviewsScreen extends StatefulWidget {
  final Doctor doctor;
  const ReviewsScreen({super.key, required this.doctor});
  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final _api = ApiService();
  final _commentCtrl = TextEditingController();
  List<Review> _reviews = [];
  bool _loading = true;
  double _myRating = 5.0;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final reviews = await _api.getReviews(widget.doctor.id);
    setState(() { _reviews = reviews; _loading = false; });
  }

  Future<void> _submitReview() async {
    if (_commentCtrl.text.isEmpty) return;
    setState(() => _submitting = true);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    await _api.createReview({
      'userId': userId,
      'doctorId': widget.doctor.id,
      'rating': _myRating,
      'comment': _commentCtrl.text,
      'createdAt': DateTime.now().toIso8601String(),
    });
    _commentCtrl.clear();
    await _loadReviews();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Отзыв добавлен!')));
    }
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Отзывы — ${widget.doctor.name}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(children: [

        Card(
          margin: const EdgeInsets.all(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Text('Оставить отзыв',
                  style: TextStyle(fontSize: 16,
                    fontWeight: FontWeight.bold)),

                const SizedBox(height: 8),

                RatingBar.builder(
                  initialRating: _myRating,
                  minRating: 1, maxRating: 5,
                  itemBuilder: (_, __) => const Icon(
                    Icons.star, color: Colors.amber),
                  onRatingUpdate: (r) => setState(() => _myRating = r),
                ),

                const SizedBox(height: 8),

                TextField(
                  controller: _commentCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Ваш комментарий...',
                    border: OutlineInputBorder()),
                ),

                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submitReview,
                    child: _submitting
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Отправить'),
                  ),
                ),

              ],
            ),
          ),
        ),

        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _reviews.isEmpty
              ? const Center(child: Text('Отзывов пока нет'))
              : ListView.builder(
                  itemCount: _reviews.length,
                  itemBuilder: (_, i) {
                    final r = _reviews[i];
                    return Card(
                      
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                      child: ListTile(

                        leading: CircleAvatar(
                          child: Text(r.rating.toStringAsFixed(0))),

                        title: Text(r.comment),

                        subtitle: Row(children: [

                          RatingBarIndicator(
                            rating: r.rating,
                            itemSize: 14,
                            itemBuilder: (_, __) => const Icon(
                              Icons.star, color: Colors.amber)),

                          const SizedBox(width: 8),

                          Text(r.createdAt.split('T').first,
                            style: const TextStyle(fontSize: 11)),

                        ]),
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
