import 'package:flutter/material.dart';

import 'package:swoosh/screens/news_service.dart'; 

class CardSwipePage extends StatefulWidget {
  @override
  _CardSwipePageState createState() => _CardSwipePageState();
}

class _CardSwipePageState extends State<CardSwipePage> {
  final List<NewsItem> newsItems = [/* List of your news items */];
  int currentIndex = 0; // Ensure this variable is defined

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: newsItems.asMap().entries.map((entry) {
            int idx = entry.key;
            NewsItem newsItem = entry.value;

            // Offset each card slightly for stacking effect
            if (idx >= currentIndex) {
              return Positioned(
                top: 20.0 * (idx - currentIndex),
                child: Draggable(
                  axis: Axis.horizontal,
                  feedback: Transform(
                    transform: Matrix4.rotationZ(0.05),
                    child: NewsCard(newsItem: newsItem, index: idx),
                  ),
                  childWhenDragging: Container(),  // Empty when dragged
                  onDragEnd: (dragDetails) {
                    // Check drag direction to determine swipe behavior
                    if (dragDetails.velocity.pixelsPerSecond.dx < 0) {
                      // Swiped left
                      setState(() {
                        if (currentIndex < newsItems.length - 1) {
                          currentIndex++;
                        }
                      });
                    } else {
                      // Swiped right
                      setState(() {
                        if (currentIndex > 0) {
                          currentIndex--;
                        }
                      });
                    }
                  },
                  child: AnimatedOpacity(
                    duration: Duration(milliseconds: 300),
                    opacity: idx == currentIndex ? 1 : 0.5,
                    child: NewsCard(newsItem: newsItem, index: idx),
                  ),
                ),
              );
            }
            return Container();  // Don't display cards that are out of range
          }).toList(),
        ),
      ),
    );
  }
}

class NewsCard extends StatelessWidget {
  final NewsItem newsItem;
  final int index;

  const NewsCard({Key? key, required this.newsItem, required this.index})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      color: index == 0
          ? Color(0xFFFFF9C4)
          : (index % 2 == 0 ? Color(0xFFCB6CE6) : Color(0xFF00F1FF)), // Fixed color code
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  newsItem.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                // Add other components of the card here, e.g., image, description, etc.
              ],
            ),
          ),
        ],
      ),
    );
  }
}
