import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/ott_library_tab.dart';
import '../widgets/device_videos_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController(); // For search query
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
         _searchQuery = '';
         _searchController.clear();
      }
    });
  }

  void _onSearchChanged(String query) {
     setState(() {
       _searchQuery = query;
     });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: _isSearching 
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: theme.textTheme.titleMedium,
                decoration: const InputDecoration(
                  hintText: 'Search videos...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white54),
                ),
                onChanged: _onSearchChanged,
              )
            : Text('Drama', style: theme.textTheme.headlineLarge),
        backgroundColor: Colors.transparent, // Immersive feel
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
           // Optional: Profile or notification icon if needed
           if (!_isSearching)
            IconButton(
               icon: const Icon(Icons.shopping_bag_outlined), // Placeholder for bag/profile
               onPressed: () {},
            ),
        ],
      ),
      body: Column(
        children: [
          // Glossy Tab Bar Container
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 55, // Fixed height for the glassy container
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(30),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: LinearGradient(
                  colors: [
                    theme.primaryColor.withOpacity(0.8),
                    theme.primaryColor.withOpacity(0.4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                 Tab(text: 'OTT Library'),
                 Tab(text: 'My Device Videos'),
              ],
            ),
          ),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Pass Search Query to tabs
                // We need to update OttLibraryTab to accept search query too
                OttLibraryTab(searchQuery: _searchQuery),
                DeviceVideosTab(searchQuery: _searchQuery),
              ],
            ),
          ),
        ],
      ),
      extendBodyBehindAppBar: false,
    );
  }
}
