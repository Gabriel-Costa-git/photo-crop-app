import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  static const String _bannerId = 'ca-app-pub-5529897414041848/3756789825';
  static const String _interstitialId = 'ca-app-pub-5529897414041848/4160114503';

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _isBannerLoaded = false;
  bool _isInterstitialLoaded = false;
  int _cropCount = 0;

  bool get isBannerLoaded => _isBannerLoaded;
  BannerAd? get bannerAd => _bannerAd;

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    _loadBannerAd();
    _loadInterstitialAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: _bannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => _isBannerLoaded = true,
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _isBannerLoaded = false;
        },
      ),
    );
    _bannerAd!.load();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoaded = true;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) => _isInterstitialLoaded = false,
      ),
    );
  }

  Future<void> showInterstitialAfterCrop() async {
    _cropCount++;
    if (_cropCount >= 2 && _isInterstitialLoaded && _interstitialAd != null) {
      await _interstitialAd!.show();
      _cropCount = 0;
      _isInterstitialLoaded = false;
    }
  }

  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
  }
}
