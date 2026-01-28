# App Icon Fix Instructions

## Problem
App icon not showing after build due to:
1. Incorrect adaptive icon configuration
2. Missing foreground drawable
3. Icon files not properly copied

## Fixed
1. ✅ Updated adaptive icon XML files
2. ✅ Created proper foreground drawable
3. ✅ Copied icon files to all density folders
4. ✅ Fixed flutter_launcher_icons.yaml config

## To Apply Icon Changes:

### Method 1: Clean Build (Recommended)
```bash
cd /home/kali/Amora/frontend
flutter clean
flutter pub get
flutter build apk --release
```

### Method 2: If flutter command not available
```bash
cd /home/kali/Amora/frontend/android
./gradlew clean
./gradlew assembleRelease
```

## Files Changed:
- android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml
- android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml  
- android/app/src/main/res/drawable/ic_launcher_foreground.xml (NEW)
- All mipmap-*/ic_launcher.png files updated
- flutter_launcher_icons.yaml updated

## Result:
App icon will now show properly on Android devices with:
- Standard icon support
- Adaptive icon support (Android 8+)
- Proper background color (#E91E63 - Amora pink)
- Heart-shaped foreground design