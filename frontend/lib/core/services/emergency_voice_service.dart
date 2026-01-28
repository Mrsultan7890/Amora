import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmergencyVoiceService {
  static EmergencyVoiceService? _instance;
  static EmergencyVoiceService get instance => _instance ??= EmergencyVoiceService._();
  
  EmergencyVoiceService._();
  
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  String? _recordedFilePath;
  bool _isRecording = false;
  
  static const String _voiceMessageKey = 'emergency_voice_message_path';
  
  Future<void> initialize() async {
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();
    
    await _recorder!.openRecorder();
    await _player!.openPlayer();
    
    await _loadExistingVoiceMessage();
  }
  
  Future<void> _loadExistingVoiceMessage() async {
    final prefs = await SharedPreferences.getInstance();
    _recordedFilePath = prefs.getString(_voiceMessageKey);
    
    // Check if file still exists
    if (_recordedFilePath != null) {
      final file = File(_recordedFilePath!);
      if (!await file.exists()) {
        _recordedFilePath = null;
        await prefs.remove(_voiceMessageKey);
      }
    }
  }
  
  Future<bool> requestPermissions() async {
    final micPermission = await Permission.microphone.request();
    return micPermission.isGranted;
  }
  
  Future<String?> startRecording() async {
    try {
      if (!await requestPermissions()) {
        throw Exception('Microphone permission denied');
      }
      
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/emergency_voice_${DateTime.now().millisecondsSinceEpoch}.aac';
      
      await _recorder!.startRecorder(
        toFile: filePath,
        codec: Codec.aacADTS,
      );
      
      _isRecording = true;
      print('🎤 Emergency voice recording started: $filePath');
      return filePath;
    } catch (e) {
      print('❌ Failed to start recording: $e');
      return null;
    }
  }
  
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) return null;
      
      final path = await _recorder!.stopRecorder();
      _isRecording = false;
      
      if (path != null) {
        _recordedFilePath = path;
        
        // Save to preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_voiceMessageKey, path);
        
        print('✅ Emergency voice recorded: $path');
      }
      
      return path;
    } catch (e) {
      print('❌ Failed to stop recording: $e');
      return null;
    }
  }
  
  Future<void> playRecording() async {
    if (_recordedFilePath == null) return;
    
    try {
      await _player!.startPlayer(
        fromURI: _recordedFilePath!,
        codec: Codec.aacADTS,
      );
      print('🔊 Playing emergency voice message');
    } catch (e) {
      print('❌ Failed to play recording: $e');
    }
  }
  
  Future<void> stopPlaying() async {
    try {
      await _player!.stopPlayer();
    } catch (e) {
      print('❌ Failed to stop playing: $e');
    }
  }
  
  Future<void> deleteRecording() async {
    if (_recordedFilePath == null) return;
    
    try {
      final file = File(_recordedFilePath!);
      if (await file.exists()) {
        await file.delete();
      }
      
      _recordedFilePath = null;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_voiceMessageKey);
      
      print('🗑️ Emergency voice message deleted');
    } catch (e) {
      print('❌ Failed to delete recording: $e');
    }
  }
  
  // Getters
  bool get hasRecording => _recordedFilePath != null;
  bool get isRecording => _isRecording;
  String? get recordingPath => _recordedFilePath;
  
  Future<int> getRecordingDuration() async {
    if (_recordedFilePath == null) return 0;
    
    try {
      final file = File(_recordedFilePath!);
      if (await file.exists()) {
        // Simple duration calculation (approximate)
        final fileSize = await file.length();
        // AAC roughly 1KB per second at low quality
        return (fileSize / 1024).round();
      }
    } catch (e) {
      print('❌ Failed to get duration: $e');
    }
    return 0;
  }
  
  void dispose() {
    _recorder?.closeRecorder();
    _player?.closePlayer();
  }
}