import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../Models/to_do_list.dart';
import './list_item_tile.dart';

class ItemsScreen extends StatefulWidget {
  final List<ToDoList> existingItems;
  final Function deleteItem;
  final Function refresh;
  final String title;

  const ItemsScreen({
    required this.existingItems,
    required this.deleteItem,
    required this.refresh,
    required this.title,
    Key? key,
  }) : super(key: key);

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  static const _insets = 16.0;
  BannerAd? _inlineAdaptiveAd;
  bool _isLoaded = false;
  AdSize? _adSize;
  late Orientation _currentOrientation;
  late int randomNumber;

  double get _adWidth => MediaQuery.of(context).size.width - (2 * _insets);

  @override
  void initState() {
    super.initState();
    randomNumber = widget.existingItems.isNotEmpty
        ? Random().nextInt(widget.existingItems.length)
        : 0;
    // Initial ad load attempt is deferred to didChangeDependencies or didUpdateWidget
    // to ensure we can check for placeholder data first.
  }

  @override
  void didUpdateWidget(ItemsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    bool isPlaceholder = widget.existingItems.any((item) => item.id == 'placeholder_id');
    if (isPlaceholder) {
      if (_inlineAdaptiveAd != null) {
        _inlineAdaptiveAd?.dispose();
        _inlineAdaptiveAd = null;
        if (_isLoaded) { // Only call setState if state actually changes
          setState(() {
            _isLoaded = false;
          });
        }
      }
      return;
    }

    if (widget.existingItems.length != oldWidget.existingItems.length) {
      setState(() {
        randomNumber = widget.existingItems.isNotEmpty
            ? Random().nextInt(widget.existingItems.length)
            : 0;
      });
    }

    // If widget is updated with actual data and no ad is loaded, try loading.
    if (!_isLoaded && widget.existingItems.isNotEmpty) {
      _loadAd();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentOrientation = MediaQuery.of(context).orientation;

    bool isPlaceholder = widget.existingItems.any((item) => item.id == 'placeholder_id');
    if (isPlaceholder) {
      if (_inlineAdaptiveAd != null || _isLoaded) {
        _inlineAdaptiveAd?.dispose();
        _inlineAdaptiveAd = null;
        if (_isLoaded) { // Only call setState if state actually changes
          setState(() {
            _isLoaded = false;
          });
        }
      }
      return;
    }

    // Load ad if not placeholder and not already loaded.
    // This typically runs once after initState for each ItemsScreen state.
    if (!_isLoaded) {
      _loadAd();
    }
  }

  void _loadAd() async {
    // Guard against loading ads for placeholder content, though call sites should also check.
    if (widget.existingItems.any((item) => item.id == 'placeholder_id')) {
      return;
    }

    // If an ad is already loaded and has a size, no need to reload unless orientation changes etc.
    // However, current logic reloads on every _loadAd call. For simplicity, let's keep this,
    // but ensure _isLoaded is reset.
    if (_isLoaded && _inlineAdaptiveAd != null && _currentOrientation == MediaQuery.of(context).orientation) {
        // Potentially skip if ad already loaded and orientation is same.
        // For now, let's allow reload to ensure it tries if previous failed silently.
    }

    await _inlineAdaptiveAd?.dispose();
    _inlineAdaptiveAd = null; // Clear previous ad instance

    // Important: Set _isLoaded to false before attempting a new load.
    // Call setState only if _isLoaded was true, to avoid unnecessary rebuilds.
    if (_isLoaded) {
      setState(() {
        _isLoaded = false;
      });
    }


    // Get an inline adaptive size for the current orientation.
    AdSize size = AdSize.getCurrentOrientationInlineAdaptiveBannerAdSize(
        _adWidth.truncate());

    // Create a new banner ad
    _inlineAdaptiveAd = BannerAd(
      adUnitId: dotenv.env['UNIT_ID']!,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) async {
          print('Inline adaptive banner loaded: ${ad.responseInfo}');

          // After the ad is loaded, get the platform ad size and use it to
          // update the height of the container.
          BannerAd bannerAd = (ad as BannerAd);
          final AdSize? size = await bannerAd.getPlatformAdSize();
          if (size == null) {
            print('Error: getPlatformAdSize() returned null for $bannerAd');
            return;
          }

          // Update state with loaded ad and size
          setState(() {
            _inlineAdaptiveAd = bannerAd;
            _isLoaded = true;
            _adSize = size;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          print('Inline adaptive banner failedToLoad: $error');
          ad.dispose();
          if (mounted) {
            setState(() {
              _isLoaded = false; // Ensure UI reflects that ad is not loaded
            });
          }
        },
      ),
    );

    // Load the ad
    await _inlineAdaptiveAd!.load();
  }

  Widget _getAdWidget() {
    return OrientationBuilder(
      builder: (context, orientation) {
        if (_currentOrientation != orientation) {
          _currentOrientation = orientation;
          _loadAd();
        }

        if (_inlineAdaptiveAd != null && _isLoaded && _adSize != null) {
          return Align(
            child: SizedBox(
              width: _adWidth,
              height: _adSize!.height.toDouble(),
              child: AdWidget(
                ad: _inlineAdaptiveAd!,
              ),
            ),
          );
        }

        return Container();
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    _inlineAdaptiveAd?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            title: Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            backgroundColor: Colors.transparent,
          ),
          SliverList.separated(
            itemCount: widget.existingItems.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: ToDoItemTile(
                  item: widget.existingItems[index],
                  onDelete: (item) {
                    widget.deleteItem(item);
                  },
                  refresh: widget.refresh,
                ),
              );
            },
            separatorBuilder: (BuildContext context, int index) {
              if (index == randomNumber) {
                return _getAdWidget();
              } else {
                return const SizedBox(
                  height: 0,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
