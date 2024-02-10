import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import './list_item_tile.dart';
import '../Models/to_do_list.dart';

class ItemsScreen extends StatefulWidget {
  final int selectedIndex;
  final List<ToDoList> existingItems;
  final Function deleteItem;
  final Function refresh;

  const ItemsScreen({
    required this.selectedIndex,
    required this.existingItems,
    required this.deleteItem,
    required this.refresh,
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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentOrientation = MediaQuery.of(context).orientation;
    _loadAd();
  }

  void _loadAd() async {
    await _inlineAdaptiveAd?.dispose();
    setState(() {
      _inlineAdaptiveAd = null;
      _isLoaded = false;
    });

    // Get an inline adaptive size for the current orientation.
    AdSize size = AdSize.getCurrentOrientationInlineAdaptiveBannerAdSize(
        _adWidth.truncate());

    _inlineAdaptiveAd = BannerAd(
      adUnitId: dotenv.env['UNIT_ID']!,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) async {
          print('Inline adaptive banner loaded: ${ad.responseInfo}');

          // After the ad is loaded, get the platform ad size and use it to
          // update the height of the container. This is necessary because the
          // height can change after the ad is loaded.
          BannerAd bannerAd = (ad as BannerAd);
          final AdSize? size = await bannerAd.getPlatformAdSize();
          if (size == null) {
            print('Error: getPlatformAdSize() returned null for $bannerAd');
            return;
          }

          setState(() {
            _inlineAdaptiveAd = bannerAd;
            _isLoaded = true;
            _adSize = size;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          print('Inline adaptive banner failedToLoad: $error');
          ad.dispose();
        },
      ),
    );
    await _inlineAdaptiveAd!.load();
  }

  Widget _getAdWidget() {
    return OrientationBuilder(
      builder: (context, orientation) {
        if (_currentOrientation == orientation &&
            _inlineAdaptiveAd != null &&
            _isLoaded &&
            _adSize != null) {
          return Align(
              child: SizedBox(
            width: _adWidth,
            height: _adSize!.height.toDouble(),
            child: AdWidget(
              ad: _inlineAdaptiveAd!,
            ),
          ));
        }
        // Reload the ad if the orientation changes.
        if (_currentOrientation != orientation) {
          _currentOrientation = orientation;
          _loadAd();
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
    return ListView.separated(
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
    );
  }
}
