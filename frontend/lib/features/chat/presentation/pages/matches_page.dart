import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/call_service.dart';
import '../../../../shared/models/match_model.dart';
import '../../../calling/presentation/pages/video_call_page.dart';
import '../../../calling/presentation/widgets/wifi_warning_dialog.dart';
import 'chat_screen.dart';

class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key});

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  final ApiService _apiService = ApiService.instance;
  final CallService _callService = CallService.instance;
  final TextEditingController _searchController = TextEditingController();
  List<MatchModel> _matches = [];
  List<MatchModel> _filteredMatches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMatches();
    _searchController.addListener(_filterMatches);
    _callService.initialize();
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
                    
                    GestureDetector(
                      onTap: () {
                        _showSortOptions();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: AmoraTheme.glassmorphism(
                          color: Colors.white,
                          borderRadius: 16,
                        ),
                        child: const Icon(
                          Icons.sort,
                          color: AmoraTheme.deepMidnight,
                        ),
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
            CircleAvatar(
              radius: 28,
              backgroundImage: match.otherUser?.photos.isNotEmpty == true
                  ? NetworkImage(match.otherUser!.photos.first)
                  : null,
              child: match.otherUser?.photos.isEmpty != false
                  ? const Icon(Icons.person, size: 28)
                  : null,
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Video call button
            GestureDetector(
              onTap: () => _startVideoCall(match),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AmoraTheme.sunsetRose.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.videocam,
                  color: AmoraTheme.sunsetRose,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Chat button
            Container(
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
          ],
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
  
  Future<void> _startVideoCall(MatchModel match) async {
    if (match.otherUser == null) return;
    
    // Check network connection
    final isWiFi = await _callService.checkNetworkAndShowWarning();
    
    if (isWiFi) {
      // Show WiFi warning
      WiFiWarningDialog.show(
        context,
        onContinueAnyway: () => _initiateCall(match),
        onSwitchToMobile: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please switch to mobile data and try again'),
              backgroundColor: Colors.orange,
            ),
          );
        },
      );
    } else {
      _initiateCall(match);
    }
  }
  
  Future<void> _initiateCall(MatchModel match) async {
    try {
      // Navigate to video call screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoCallPage(
            otherUserId: match.otherUser!.id,
            otherUserName: match.otherUser!.name,
          ),
        ),
      );
      
      // Start the call
      await _callService.startCall(match.otherUser!.id, CallType.video);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start call: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: AmoraTheme.primaryGradient,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.sort,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Sort Your Matches',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            // Sort Options
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSortOption(
                    Icons.access_time,
                    'Recent Activity',
                    'Sort by latest messages',
                    () => _sortMatches('recent'),
                  ),
                  _buildSortOption(
                    Icons.favorite,
                    'New Matches',
                    'Show newest matches first',
                    () => _sortMatches('new'),
                  ),
                  _buildSortOption(
                    Icons.chat,
                    'Most Active',
                    'Sort by conversation activity',
                    () => _sortMatches('messages'),
                  ),
                  _buildSortOption(
                    Icons.star,
                    'Super Likes',
                    'Show super liked matches first',
                    () => _sortMatches('super'),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSortOption(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AmoraTheme.glassmorphism(
        color: Colors.white,
        borderRadius: 12,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AmoraTheme.sunsetRose.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AmoraTheme.sunsetRose,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AmoraTheme.deepMidnight,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: AmoraTheme.deepMidnight.withOpacity(0.7),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AmoraTheme.sunsetRose,
        ),
        onTap: () {
          Navigator.pop(context);
          onTap();
          _showSortConfirmation(title);
        },
      ),
    );
  }
  
  void _showSortConfirmation(String sortType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text('Sorted by $sortType'),
          ],
        ),
        backgroundColor: AmoraTheme.sunsetRose,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  void _sortMatches(String sortType) {
    setState(() {
      switch (sortType) {
        case 'recent':
          _filteredMatches.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
          break;
        case 'new':
          _filteredMatches.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case 'messages':
          _filteredMatches.sort((a, b) => (b.lastMessage?.length ?? 0).compareTo(a.lastMessage?.length ?? 0));
          break;
        case 'super':
          // Sort super likes first (placeholder logic)
          _filteredMatches.sort((a, b) => (b.createdAt.millisecondsSinceEpoch).compareTo(a.createdAt.millisecondsSinceEpoch));
          break;
      }
    });
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
            leading: CircleAvatar(
              backgroundImage: match.otherUser?.photos.isNotEmpty == true
                  ? NetworkImage(match.otherUser!.photos.first)
                  : null,
              child: match.otherUser?.photos.isEmpty != false
                  ? const Icon(Icons.person)
                  : null,
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