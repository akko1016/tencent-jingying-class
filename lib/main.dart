import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models/photo.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'db/database_helper.dart';
import 'pages/saved_photos_page.dart';
import 'widgets/cached_photo_image.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshConfiguration(
      headerBuilder: () => const WaterDropHeader(),
      footerBuilder: () => const ClassicFooter(),
      headerTriggerDistance: 80.0,
      springDescription: const SpringDescription(stiffness: 170, damping: 16, mass: 1.9),
      maxOverScrollExtent: 100,
      maxUnderScrollExtent: 0,
      enableScrollWhenRefreshCompleted: true,
      enableLoadingWhenFailed: true,
      hideFooterWhenNotFull: false,
      enableBallisticLoad: true,
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const MyHomePage(title: '精彩图库'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<Photo> _photos = [];
  bool _isGridView = true;
  int _page = 1;
  bool _isLoading = false;
  bool _isFirstLoad = true;
  final RefreshController _refreshController = RefreshController();

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    _page = 1;
    _photos.clear();
    await _loadPhotos();
    _refreshController.refreshCompleted();
  }

  Future<void> _onLoading() async {
    await _loadPhotos();
    _refreshController.loadComplete();
  }

  Future<void> _loadPhotos() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      
      final imagePaths = manifestMap.keys
          .where((String key) => key.startsWith('assets/images/') && 
              (key.endsWith('.jpg') || key.endsWith('.png') || key.endsWith('.gif')))
          .toList();

      if (imagePaths.isEmpty) {
        _refreshController.loadNoData();
      } else {
        final newPhotos = imagePaths.map((path) {
          final fileName = path.split('/').last;
          final id = fileName.split('.').first;
          return Photo(
            id: id,
            author: '本地图片',
            assetPath: path,
          );
        }).toList();

        setState(() {
          _photos.addAll(newPhotos);
          _isFirstLoad = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading photos: $e');
      if (_photos.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('加载失败，请检查资源文件'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleSavePhoto(Photo photo) async {
    final isSaved = await DatabaseHelper.instance.isPhotoSaved(photo.id);
    if (isSaved) {
      await DatabaseHelper.instance.deletePhoto(photo.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已取消保存')),
        );
      }
    } else {
      await DatabaseHelper.instance.savePhoto(photo);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存成功')),
        );
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.collections_bookmark),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SavedPhotosPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isFirstLoad 
          ? const Center(child: CircularProgressIndicator()) 
          : SmartRefresher(
              controller: _refreshController,
              enablePullDown: true,
              enablePullUp: true,
              header: const WaterDropHeader(
                complete: Text('刷新成功'),
                failed: Text('刷新失败'),
                waterDropColor: Colors.deepPurple,
              ),
              footer: CustomFooter(
                builder: (BuildContext context, LoadStatus? mode) {
                  Widget body;
                  if (mode == LoadStatus.idle) {
                    body = const Text("上拉加载更多");
                  } else if (mode == LoadStatus.loading) {
                    body = const CircularProgressIndicator();
                  } else if (mode == LoadStatus.failed) {
                    body = const Text("加载失败，点击重试");
                  } else if (mode == LoadStatus.canLoading) {
                    body = const Text("松手加载更多");
                  } else {
                    body = const Text("没有更多数据了");
                  }
                  return SizedBox(
                    height: 55.0,
                    child: Center(child: body),
                  );
                },
              ),
              onRefresh: () async {
                try {
                  _page = 1;
                  _photos.clear();
                  await _loadPhotos();
                  _refreshController.refreshCompleted();
                } catch (e) {
                  _refreshController.refreshFailed();
                }
              },
              onLoading: () async {
                try {
                  await _loadPhotos();
                  _refreshController.loadComplete();
                } catch (e) {
                  _refreshController.loadFailed();
                }
              },
              child: _photos.isEmpty
                  ? const Center(child: Text('暂无数据'))
                  : _isGridView 
                      ? _buildGridView() 
                      : _buildListView(),
            ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.8,
      ),
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
      itemCount: _photos.length,
      itemBuilder: (context, index) => _buildPhotoCard(_photos[index]),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
      itemCount: _photos.length,
      itemBuilder: (context, index) => _buildPhotoListItem(_photos[index]),
    );
  }

  Widget _buildPhotoCard(Photo photo) {
    return Card(
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Image.asset(
                  photo.assetPath,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            child: FutureBuilder<bool>(
              future: DatabaseHelper.instance.isPhotoSaved(photo.id),
              builder: (context, snapshot) {
                final isSaved = snapshot.data ?? false;
                return IconButton(
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: Colors.white,
                  ),
                  onPressed: () => _toggleSavePhoto(photo),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoListItem(Photo photo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.asset(
            photo.assetPath,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          ),
        ),
        subtitle: Text('ID: ${photo.id}'),
      ),
    );
  }
}
