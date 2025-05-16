import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';

class PCMProcessor {
  bool isConnected = false; // 연결 상태 외부에서 관리
  PCMProcessor() {
    print('[PCMProcessor] 생성자 호출됨!!!!!!!!!!');

    // print('[PCMProcessor] 생성자 호출됨');
  }

  final StreamController<Float32List> _inputController =
      StreamController.broadcast();
  final Queue<double> _audioBuffer = Queue<double>();

  FlutterSoundPlayer? _player;
  bool _isProcessing = false;
  bool _playerInitialized = false;

  // 버퍼/청크/타이머 값 조정
  static const int CHUNK_SIZE = 4096;
  static const int MIN_BUFFER_SIZE = 8192; // 4096~8192로 실험
  static const int MAX_BUFFER_SIZE = 60000;

  Timer? _feedTimer;
  Timer? _healthCheckTimer;

  // 로그 중복 방지용 플래그
  bool _bufferSmallLogged = false;
  bool _initLogged = false;
  bool _feedLogged = false;
  bool _errorLogged = false;

  // Player 준비 전 임시 버퍼
  final List<Float32List> _pendingData = [];

  Future<void> initPlayer() async {
    await dispose(); // 혹시 남아있던 리소스 먼저 해제
    try {
      if (!_initLogged) {
        print('[PCMProcessor] initPlayer() called');
        _initLogged = true;
      }
      print('[PCMProcessor] FlutterSoundPlayer 인스턴스 생성');
      _player = FlutterSoundPlayer();
      print('[PCMProcessor] openPlayer() 호출');
      await _player!.openPlayer();

      print('[PCMProcessor] openPlayer() 완료');

      await _startPlayerFromStream();

      // Regular feeding timer
      _feedTimer = Timer.periodic(Duration(milliseconds: 30), (_) {
        print(
          '[PCMProcessor] Timer triggered, buffer length: \\${_audioBuffer.length}',
        );
        if (_audioBuffer.length == 0) return; // 버퍼가 0이면 아무것도 하지 않음
        if (!_isProcessing) {
          _tryProcessAudio();
        }
      });

      // Health check timer to ensure player is running
      _healthCheckTimer = Timer.periodic(Duration(milliseconds: 2000), (_) {
        _checkPlayerHealth();
      });
      // Listen to audio input stream
      _inputController.stream.listen((Float32List newData) {
        print(
          '[PCMProcessor] New PCM data in - length: \\${newData.length}, buffer before: \\${_audioBuffer.length}',
        );
        _audioBuffer.addAll(newData);
        // 버퍼가 너무 크면, 최근 데이터만 남기고 나머지 버림
        while (_audioBuffer.length > MAX_BUFFER_SIZE) {
          _audioBuffer.removeFirst();
        }
        print('[PCMProcessor] Buffer after: \\${_audioBuffer.length}');
      });
      // Player가 준비되면 pendingData 처리
      if (_pendingData.isNotEmpty) {
        for (final data in _pendingData) {
          _inputController.add(data);
        }
        _pendingData.clear();
      }
    } catch (e) {
      if (!_errorLogged) {
        print('[PCMProcessor] Error initializing player: \\${e}');
        _errorLogged = true;
      }
      await dispose();
      await Future.delayed(Duration(milliseconds: 500));
      return initPlayer();
    }
    isConnected = true;
  }

  void _checkPlayerHealth() async {
    if (_player != null) {
      bool playerRunning = _player!.isPlaying;
      // print(
      //   '[PCMProcessor] Health check - isPlaying: $playerRunning, initialized: $_playerInitialized, buffer: ${_audioBuffer.length}',
      // );
      if (!playerRunning && _playerInitialized) {
        // print('[PCMProcessor] Health check: Player not running, restarting');
        await _restartPlayerFromStream();
      }
    }
  }

  Future<void> _startPlayerFromStream() async {
    try {
      print('[PCMProcessor] startPlayerFromStream() 호출');
      await _player!.startPlayerFromStream(
        codec: Codec.pcmFloat32,
        numChannels: 1,
        sampleRate: 22000, // 24kHz로 변경
        bufferSize: CHUNK_SIZE,
        interleaved: false,
      );
      _playerInitialized = true;
      print('[PCMProcessor] Player started (startPlayerFromStream 완료)');
    } catch (e) {
      if (!_errorLogged) {
        print('[PCMProcessor] Error starting player: \\${e}');
        _errorLogged = true;
      }
      _playerInitialized = false;
    }
  }

  Future<void> _restartPlayerFromStream() async {
    try {
      print('[PCMProcessor] Restarting player...');
      print('[PCMProcessor] stopPlayer() 호출');
      await _player?.stopPlayer();
      print('[PCMProcessor] stopPlayer() 완료');
      await Future.delayed(Duration(milliseconds: 200));
      await _startPlayerFromStream();
    } catch (e) {
      if (!_errorLogged) {
        print('[PCMProcessor] Error restarting player: \\${e}');
        _errorLogged = true;
      }
    }
  }

  Float32List amplifyPCM(Float32List input, double gain) {
    final output = Float32List(input.length);
    for (int i = 0; i < input.length; i++) {
      output[i] = (input[i] * gain).clamp(-1.0, 1.0);
    }
    return output;
  }

  void addPCMData(Float32List newData) {
    print(
      '[PCMProcessor] addPCMData 호출됨, newData.length: \\${newData.length}, _player: \\${_player}, _playerInitialized: \\${_playerInitialized}',
    );
    if (_player == null || !_playerInitialized) {
      print('[PCMProcessor] addPCMData: Player not ready, buffering data');
      _inputController.add(amplifyPCM(newData, 3.0));
      _tryProcessAudio();
      if (_player == null) {
        print('[PCMProcessor] addPCMData: _player == null, initPlayer() 호출');
        initPlayer();
      } else {
        print(
          '[PCMProcessor] addPCMData: _player != null, _restartPlayerFromStream() 호출',
        );
        _restartPlayerFromStream();
      }
      return;
    }
    // Player가 준비된 경우, pendingData 먼저 모두 처리
    if (_pendingData.isNotEmpty) {
      print('[PCMProcessor] addPCMData: pendingData 처리');
      for (final data in _pendingData) {
        _inputController.add(data);
      }
      _pendingData.clear();
    }
    print('[PCMProcessor] addPCMData: adding \\${newData.length} samples');
    _inputController.add(amplifyPCM(newData, 2.0));
  }

  void _tryProcessAudio() {
    print(
      '[PCMProcessor] _tryProcessAudio 호출됨, _isProcessing: \\${_isProcessing}, _audioBuffer.length: \\${_audioBuffer.length}',
    );
    if (_isProcessing || _audioBuffer.length < MIN_BUFFER_SIZE) {
      // 버퍼가 충분히 쌓일 때까지 기다림
      if (_audioBuffer.length < MIN_BUFFER_SIZE && !_bufferSmallLogged) {
        print(
          '[PCMProcessor] _tryProcessAudio: 버퍼 부족 (\\${_audioBuffer.length}/$MIN_BUFFER_SIZE)',
        );
        _bufferSmallLogged = true;
      }
      return;
    }
    print(
      '[PCMProcessor] _tryProcessAudio: start processing, buffer: \\${_audioBuffer.length}',
    );
    _isProcessing = true;
    _processAudioChunk();
  }

  Future<void> _processAudioChunk() async {
    print(
      '[PCMProcessor] _processAudioChunk 호출됨, _player: \\${_player}, _playerInitialized: \\${_playerInitialized}, _audioBuffer.length: \\${_audioBuffer.length}',
    );
    if (_player == null ||
        !_playerInitialized ||
        _audioBuffer.length < CHUNK_SIZE) {
      print(
        '[PCMProcessor] _processAudioChunk: player not ready or buffer too small',
      );
      _isProcessing = false;
      return;
    }

    try {
      final List<double> chunk = List<double>.filled(CHUNK_SIZE, 0.0);
      for (int i = 0; i < CHUNK_SIZE; i++) {
        if (_audioBuffer.isNotEmpty) {
          chunk[i] = _audioBuffer.removeFirst();
        } else {
          break;
        }
      }
      print(
        '[PCMProcessor] _processAudioChunk: chunk 준비 완료, isPlaying: \\${_player!.isPlaying}',
      );
      if (!_feedLogged) {
        print(
          '[PCMProcessor] Feeding chunk: $CHUNK_SIZE, buffer left: \\${_audioBuffer.length}, isPlaying: \\${_player!.isPlaying}',
        );
        _feedLogged = true;
      }
      if (_player!.isPlaying) {
        print('[PCMProcessor] feedF32FromStream 호출');
        await _player!.feedF32FromStream([Float32List.fromList(chunk)]);
        print('[PCMProcessor] feedF32FromStream 완료');
      } else {
        print('[PCMProcessor] feedF32FromStream: player not playing');
      }
    } catch (e) {
      print('[PCMProcessor] Feed error: \\${e}');
      if (!_errorLogged) {
        print('[PCMProcessor] Feed error(최초): \\${e}');
        _errorLogged = true;
      }
      if (DateTime.now().millisecondsSinceEpoch % 5 == 0) {
        print(
          '[PCMProcessor] feedF32FromStream 에러, _restartPlayerFromStream() 호출',
        );
        await _restartPlayerFromStream();
      }
    } finally {
      _isProcessing = false;
      if (_audioBuffer.length > CHUNK_SIZE * 4) {
        print(
          '[PCMProcessor] _processAudioChunk: plenty of data left, re-triggering',
        );
        Future.microtask(_tryProcessAudio);
      }
    }
  }

  Future<void> dispose() async {
    print('[PCMProcessor] dispose() called');
    _feedTimer?.cancel();
    _feedTimer = null;
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
    _playerInitialized = false;
    _isProcessing = false;
    _bufferSmallLogged = false;
    _initLogged = false;
    _feedLogged = false;
    _errorLogged = false;
    _pendingData.clear();
    _audioBuffer.clear();
    await _inputController.close();
    if (_player != null) {
      try {
        await _player?.stopPlayer();
        await _player?.closePlayer();
      } catch (_) {}
      _player = null;
    }
    isConnected = false;
  }
}
