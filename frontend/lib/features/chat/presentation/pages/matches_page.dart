import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/api_service.dart';
import '../../../../shared/models/match_model.dart';
import 'chat_screen.dart';

class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key});

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  final ApiService _apiService = ApiService.instance;
  final TextEditingController _searchController = TextEditingController();
  List<MatchModel> _matches = [];
  List<MatchModel> _filteredMatches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMatches();
    _searchController.addListener(_filterMatches);
  }

  Future<void> _loadMatches() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final matches = await _apiService.getMatches();
      setState(() {
        _matches = matches;
        _filteredMatches = matches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterMatches() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredMatches = _matches.where((match) {
        final otherUser = match.otherUser;
        if (otherUser == null) return false;
        final userName = otherUser.name.toLowerCase();
        return userName.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AmoraTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        showSearch(
                          context: context,
                          delegate: MatchSearchDelegate(_matches),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: AmoraTheme.glassmorphism(
                          color: Colors.white,
                          borderRadius: 16,
                        ),
                        child: const Icon(
                          Icons.search,
                          color: AmoraTheme.deepMidnight,
                        ),
                      ),
                    ),
                    
                    const Text(
                      'Matches',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AmoraTheme.deepMidnight,
                      ),
                    ),
                    
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: AmoraTheme.glassmorphism(
                        color: Colors.white,
                        borderRadius: 16,
                      ),
                      child: const Icon(
                        Icons.filter_list,
                        color: AmoraTheme.deepMidnight,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AmoraTheme.sunsetRose,
                          ),
                        ),
                      )
                    : _filteredMatches.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: AmoraTheme.sunsetRose,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No matches found',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: AmoraTheme.deepMidnight,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try adjusting your search',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AmoraTheme.deepMidnight.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _matches.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color: AmoraTheme.sunsetRose,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No matches yet',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: AmoraTheme.deepMidnight,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Start swiping to find your perfect match',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AmoraTheme.deepMidnight.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredMatches.length,
                            itemBuilder: (context, index) {
                              final match = _filteredMatches[index];
                              return _buildMatchCard(match, index);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchCard(MatchModel match, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AmoraTheme.glassmorphism(
        color: Colors.white,
        borderRadius: 20,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Stack(
          children: [
            const CircleAvatar(
              radius: 28,
              child: Icon(Icons.person, size: 28),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Text(
              match.otherUser?.name ?? 'Unknown User',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AmoraTheme.deepMidnight,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.verified,
              color: AmoraTheme.warmGold,
              size: 16,
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              match.lastMessage ?? 'Say hello to start the conversation!',
              style: TextStyle(
                fontSize: 14,
                color: match.lastMessage != null 
                    ? AmoraTheme.deepMidnight.withOpacity(0.7)
                    : AmoraTheme.sunsetRose,
                fontWeight: match.lastMessage != null 
                    ? FontWeight.normal 
                    : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _getTimeText(match.lastMessageAt),
              style: TextStyle(
                fontSize: 12,
                color: AmoraTheme.deepMidnight.withOpacity(0.5),
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            gradient: AmoraTheme.primaryGradient,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.chat_bubble,
            color: Colors.white,
            size: 20,
          ),
        ),
        onTap: () {
          _openChat(match);
        },
      ),
    ).animate()
      .fadeIn(delay: (index * 100).ms, duration: 600.ms)
      .slideX(begin: 0.3, end: 0);
  }

  void _openChat(MatchModel match) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(match: match),
      ),
    );
  }

  String _getTimeText(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class MatchSearchDelegate extends SearchDelegate<MatchModel?> {
  final List<MatchModel> matches;

  MatchSearchDelegate(this.matches);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          query = '';
        },
        icon: const Icon(Icons.clear),
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        close(context, null);
      },
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final filteredMatches = matches.where((match) {
      final otherUser = match.otherUser;
      if (otherUser == null) return false;
      final userName = otherUser.name.toLowerCase();
      return userName.contains(query.toLowerCase());
    }).toList();

    if (filteredMatches.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AmoraTheme.sunsetRose,
            ),
            SizedBox(height: 16),
            Text(
              'No matches found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AmoraTheme.deepMidnight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredMatches.length,
      itemBuilder: (context, index) {
        final match = filteredMatches[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: AmoraTheme.glassmorphism(
            color: Colors.white,
            borderRadius: 16,
          ),
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.person),
            ),
            title: Text(
              match.otherUser?.name ?? 'Unknown User',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              match.lastMessage ?? 'Say hello!',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              close(context, match);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(match: match),
                ),
              );
            },
          ),
        );
      },
    );
  }
}