import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'news_service.dart';
import 'cache_service.dart';
import 'web_search_service.dart';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:lottie/lottie.dart'; // Add this import at the top of the file

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);



  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  List<NewsItem> newsItems = [];
  bool isLoading = true; // Add a loading state
  String? errorMessage; // Add an error message state
   String selectedCategory = 'Trending';

   final NewsService _newsService = NewsService();
  final WebSearchService _webSearchService = WebSearchService();

  late AnimationController _animationController;
  late Animation<Offset> _animation;
  

  @override
  void initState() {
    super.initState();
    _fetchNews(); // Fetch news when the screen initializes


    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  int _countWords(String text) {
    return text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
  }

  Future<void> _fetchNews({String category = 'general'}) async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final fetchedNewsItems = await _newsService.fetchNews(category: category);

      for (var item in fetchedNewsItems) {
        try {
          developer.log('Fetching full article for: ${item.title}');
          String fullArticle = await _webSearchService.searchAndExtractContent(item.title, item.originalDescription);
          
          // Log the lengths of the descriptions in words
          int originalDescriptionWordCount = _countWords(item.originalDescription);
          int fetchedArticleWordCount = _countWords(fullArticle);
          
          developer.log('Original description word count: $originalDescriptionWordCount');
          developer.log('Fetched article word count: $fetchedArticleWordCount');
          
          if (fetchedArticleWordCount > 100 && fetchedArticleWordCount > originalDescriptionWordCount) {
            item.fullArticle = fullArticle;
            item.description = fullArticle; // Update the description with the full article
            developer.log('Successfully fetched longer article for: ${item.title}');
          } else {
            item.fullArticle = item.originalDescription;
            item.description = item.originalDescription;
            developer.log('Fetched article not longer or too short. Using original description for: ${item.title}');
          }
          
          developer.log('Final article content: ${item.description.substring(0, min(100, item.description.length))}...');
        } catch (e) {
          item.fullArticle = 'Error fetching full article: $e';
          item.description = item.originalDescription;
          developer.log('Error fetching full article for ${item.title}: $e');
        }
      }

      setState(() {
        newsItems = fetchedNewsItems;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load news: $e';
      });
      developer.log('Error in _fetchNews: $e');
    }
  }


  int currentIndex = 0;


 

  @override
  void dispose() {
    
    _animationController.dispose();
    super.dispose();
  }

 void _onSwipe(DragEndDetails details) {
 if (details.primaryVelocity! > 0) {
   // Swiped right (go to previous card)
   setState(() {
     if (currentIndex > 0) currentIndex--;
   });
 } else if (details.primaryVelocity! < 0) {
   // Swiped left (go to next card)
   if (currentIndex < newsItems.length - 1) {
     _animationController.forward().then((_) {
       setState(() {
         currentIndex++;
       });
       _animationController.reset();
     });
   }
 }
}

  void _onCategorySelected(String category) {
    setState(() {
      selectedCategory = category;
    });

    if (category == 'Health') {
      _fetchNews(category: 'health');  // Fetch health-related news
    } else {
      _fetchNews();  // Fetch general news for other categories
    }
  }

final Color _appBackgroundColor = Colors.black;





 @override
  Widget build(BuildContext context) {
  return Scaffold(
      backgroundColor: _appBackgroundColor, // Set the Scaffold background color
      appBar: AppBar(
        title: Text('S News'),
        backgroundColor: _appBackgroundColor,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
          onPressed: () => _fetchNews(category: selectedCategory == 'Health' ? 'health' : 'general'),
          ),
        ],
      ),
     body: isLoading
          ? Center(
              child: Image.asset(
                'assets/images/loading.gif', // Path to your Lottie animation file
                width: 200,
                height: 200,
                fit: BoxFit.fill,
              ),
            )
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : Column(
                  children: [
                    Container(
                      color: _appBackgroundColor,
                      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildCategoryChip('Trending', isSelected: selectedCategory == 'Trending'),
                            _buildCategoryChip('Health', isSelected: selectedCategory == 'Health'),
                            _buildCategoryChip('Sports', isSelected: selectedCategory == 'Sports'),
                            _buildCategoryChip('Finance', isSelected: selectedCategory == 'Finance'),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          ...newsItems.asMap().entries.map((entry) {
                            int idx = entry.key;  // Index of the card
                            if (idx >= currentIndex && idx < currentIndex + 3) {
                              return Positioned(
                                top: 20.0 * (idx - currentIndex) + 10 * idx,
                                left: 20.0 * (idx - currentIndex) + 10 * idx,
                                right: 0,
                                child: IgnorePointer(
                                  ignoring: idx != currentIndex,
                                  child: Opacity(
                                    opacity: 1.0 - (0.3 * (idx - currentIndex)),
                                     child: NewsCard(newsItem: entry.value, index: idx),
                                  ),
                                ),
                              );
                            } else {
                              return Container();
                            }
                          }).toList(),
                          SlideTransition(
                            position: _animation,
                            child: GestureDetector(
                              onHorizontalDragEnd: _onSwipe,
                              child: NewsCard(newsItem: newsItems[currentIndex], index: currentIndex),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: _appBackgroundColor,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Saved'),
        ],
      ),
    );
  }
 
    

    Widget _buildCategoryChip(String label, {bool isSelected = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: GestureDetector(
        onTap: () => _onCategorySelected(label),
        child: AnimatedDefaultTextStyle(
          style: TextStyle(
            color: Colors.white,
            fontSize: isSelected ? 18 : 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          duration: Duration(milliseconds: 200),
          child: Text(label),
        ),
      ),
    );
  }
}



class NewsCard extends StatelessWidget {
  final NewsItem newsItem;
  final int index;

  const NewsCard({Key? key, required this.newsItem, required this.index}) : super(key: key);

  String _truncateTitle(String title) {
    List<String> words = title.split(' ');
    if (words.length > 8) {
      return words.take(8).join(' ') + '...';
    }
    return title;
  }

  String _truncateDescription(String description) {
    List<String> words = description.split(' ');
    if (words.length > 100) {
      return words.take(100).join(' ') + '...';
    }
    return description;
  }


  String _truncateAuthor(String author) {
    List<String> words = author.split(' ');
    if (words.length > 4) {
      return words.take(2).join(' ') + '...';
    }
    return author;
  }


  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      color: index == 0 ? Color(0xFFFFF9C4) : (index % 2 == 0 ? Color(0xFFCB6CE6) : Color(0xFFE0F1FF)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _truncateTitle(newsItem.title),
                  style: GoogleFonts.outfit(
                    textStyle: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Text('Updated Just now', style: TextStyle(color: Colors.grey[600])),
                SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: AssetImage(newsItem.authorImageUrl),
                      radius: 15,
                    ),
                    SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Published by', style: TextStyle(color: Colors.grey[800])),
                        Text(_truncateAuthor(newsItem.author), style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Spacer(),
                    ElevatedButton(
                      onPressed: () {},
                      child: Text('Follow'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  _truncateDescription(newsItem.description),
                  style: GoogleFonts.schoolbell(
                    textStyle: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                   maxLines: 13,  // Set the maximum number of lines you want to display
                  overflow: TextOverflow.ellipsis, 
                ),
                TextButton(
                  onPressed: () {
                    // Open the URL in a web browser
                    // launch(newsItem.url);
                       showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text(newsItem.title),
                    content: SingleChildScrollView(
                      child: Text(newsItem.fullArticle),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: Text('Close'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
                  },
                  child: Text('Read Full Article'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}