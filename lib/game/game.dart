import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

/// Main game class for the tile-swapping puzzle game
class Batch20260107102709Puzzle01Game extends FlameGame with HasTapDetector, HasCollisionDetection {
  /// Current game state
  GameState _gameState = GameState.menu;
  GameState get gameState => _gameState;

  /// Current level being played
  int _currentLevel = 1;
  int get currentLevel => _currentLevel;

  /// Player's current score
  int _score = 0;
  int get score => _score;

  /// Stars earned in current level
  int _starsEarned = 0;
  int get starsEarned => _starsEarned;

  /// Total stars collected
  int _totalStars = 0;
  int get totalStars => _totalStars;

  /// Level timer
  late Timer _levelTimer;
  double _timeRemaining = 60.0;
  double get timeRemaining => _timeRemaining;

  /// Grid system for tiles
  late GridComponent _gameGrid;
  late PatternComponent _targetPattern;

  /// Game components
  final List<TileComponent> _tiles = [];
  TileComponent? _selectedTile;

  /// Level configuration
  late LevelConfig _currentLevelConfig;

  /// Random number generator
  final Random _random = Random();

  /// Analytics and services hooks
  Function(String event, Map<String, dynamic> parameters)? onAnalyticsEvent;
  Function()? onShowRewardedAd;
  Function(String key, dynamic value)? onSaveData;
  Function(String key)? onLoadData;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Initialize camera
    camera.viewfinder.visibleGameSize = size;
    
    // Load saved data
    await _loadGameData();
    
    // Initialize overlays
    _setupOverlays();
    
    // Start with menu state
    _changeGameState(GameState.menu);
    
    // Track game start
    _trackEvent('game_start', {});
  }

  /// Initialize game overlays for UI
  void _setupOverlays() {
    overlays.addEntry('menu', (context, game) => MenuOverlay(game: this));
    overlays.addEntry('hud', (context, game) => HudOverlay(game: this));
    overlays.addEntry('pause', (context, game) => PauseOverlay(game: this));
    overlays.addEntry('game_over', (context, game) => GameOverOverlay(game: this));
    overlays.addEntry('level_complete', (context, game) => LevelCompleteOverlay(game: this));
    overlays.addEntry('unlock_prompt', (context, game) => UnlockPromptOverlay(game: this));
  }

  /// Start a new level
  Future<void> startLevel(int levelNumber) async {
    _currentLevel = levelNumber;
    _currentLevelConfig = _getLevelConfig(levelNumber);
    _timeRemaining = _currentLevelConfig.timeLimit;
    _starsEarned = 0;
    
    await _setupLevel();
    _changeGameState(GameState.playing);
    
    // Start level timer
    _levelTimer = Timer(
      _currentLevelConfig.timeLimit,
      onTick: () {
        _timeRemaining -= 0.1;
        if (_timeRemaining <= 0) {
          _timeRemaining = 0;
          _onLevelFailed();
        }
      },
      repeat: true,
    );
    
    _trackEvent('level_start', {'level': levelNumber});
  }

  /// Setup the current level
  Future<void> _setupLevel() async {
    // Clear existing components
    removeAll(children.whereType<GameComponent>());
    _tiles.clear();
    _selectedTile = null;

    // Create game grid
    _gameGrid = GridComponent(
      gridSize: _currentLevelConfig.gridSize,
      tileSize: _calculateTileSize(),
    );
    add(_gameGrid);

    // Create target pattern
    _targetPattern = PatternComponent(
      pattern: _currentLevelConfig.targetPattern,
      position: Vector2(size.x * 0.1, size.y * 0.15),
      size: Vector2(size.x * 0.3, size.x * 0.3),
    );
    add(_targetPattern);

    // Generate and shuffle tiles
    await _generateTiles();
  }

  /// Generate tiles for the current level
  Future<void> _generateTiles() async {
    final gridSize = _currentLevelConfig.gridSize;
    final tileSize = _calculateTileSize();
    final startX = (size.x - (gridSize * tileSize)) / 2;
    final startY = size.y * 0.4;

    // Create tiles based on target pattern
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        final tileType = _currentLevelConfig.targetPattern[row][col];
        final tile = TileComponent(
          tileType: tileType,
          gridPosition: Vector2(col.toDouble(), row.toDouble()),
          size: Vector2.all(tileSize),
          position: Vector2(
            startX + col * tileSize,
            startY + row * tileSize,
          ),
        );
        
        _tiles.add(tile);
        add(tile);
      }
    }

    // Shuffle tiles to create puzzle
    _shuffleTiles();
  }

  /// Shuffle tiles to create the puzzle
  void _shuffleTiles() {
    final shuffleCount = _currentLevelConfig.shuffleComplexity;
    
    for (int i = 0; i < shuffleCount; i++) {
      final tile1 = _tiles[_random.nextInt(_tiles.length)];
      final tile2 = _getAdjacentTile(tile1);
      
      if (tile2 != null) {
        _swapTiles(tile1, tile2, animate: false);
      }
    }
  }

  /// Calculate appropriate tile size based on screen and grid
  double _calculateTileSize() {
    final availableWidth = size.x * 0.8;
    return availableWidth / _currentLevelConfig.gridSize;
  }

  /// Handle tap events
  @override
  bool onTapDown(TapDownInfo info) {
    if (_gameState != GameState.playing) return false;

    final tappedTile = _getTileAtPosition(info.eventPosition.global);
    if (tappedTile == null) return false;

    if (_selectedTile == null) {
      // Select first tile
      _selectTile(tappedTile);
    } else if (_selectedTile == tappedTile) {
      // Deselect if tapping same tile
      _deselectTile();
    } else if (_areAdjacent(_selectedTile!, tappedTile)) {
      // Swap adjacent tiles
      _swapTiles(_selectedTile!, tappedTile);
      _deselectTile();
      _checkLevelComplete();
    } else {
      // Select new tile
      _deselectTile();
      _selectTile(tappedTile);
    }

    return true;
  }

  /// Select a tile
  void _selectTile(TileComponent tile) {
    _selectedTile = tile;
    tile.setSelected(true);
  }

  /// Deselect current tile
  void _deselectTile() {
    _selectedTile?.setSelected(false);
    _selectedTile = null;
  }

  /// Swap two tiles
  void _swapTiles(TileComponent tile1, TileComponent tile2, {bool animate = true}) {
    final tempType = tile1.tileType;
    tile1.tileType = tile2.tileType;
    tile2.tileType = tempType;

    if (animate) {
      tile1.playSwapAnimation();
      tile2.playSwapAnimation();
    }
  }

  /// Check if two tiles are adjacent
  bool _areAdjacent(TileComponent tile1, TileComponent tile2) {
    final pos1 = tile1.gridPosition;
    final pos2 = tile2.gridPosition;
    
    final dx = (pos1.x - pos2.x).abs();
    final dy = (pos1.y - pos2.y).abs();
    
    return (dx == 1 && dy == 0) || (dx == 0 && dy == 1);
  }

  /// Get tile at screen position
  TileComponent? _getTileAtPosition(Vector2 position) {
    for (final tile in _tiles) {
      if (tile.containsPoint(position)) {
        return tile;
      }
    }
    return null;
  }

  /// Get adjacent tile for shuffling
  TileComponent? _getAdjacentTile(TileComponent tile) {
    final adjacentTiles = _tiles.where((t) => _areAdjacent(tile, t)).toList();
    return adjacentTiles.isEmpty ? null : adjacentTiles[_random.nextInt(adjacentTiles.length)];
  }

  /// Check if level is complete
  void _checkLevelComplete() {
    if (_isPatternMatched()) {
      _onLevelComplete();
    }
  }

  /// Check if current tile arrangement matches target pattern
  bool _isPatternMatched() {
    final gridSize = _currentLevelConfig.gridSize;
    
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        final tile = _tiles.firstWhere(
          (t) => t.gridPosition.x == col && t.gridPosition.y == row,
        );
        
        if (tile.tileType != _currentLevelConfig.targetPattern[row][col]) {
          return false;
        }
      }
    }
    
    return true;
  }

  /// Handle level completion
  void _onLevelComplete() {
    _levelTimer.stop();
    _calculateScore();
    _changeGameState(GameState.levelComplete);
    
    _trackEvent('level_complete', {
      'level': _currentLevel,
      'time_remaining': _timeRemaining,
      'stars_earned': _starsEarned,
    });
  }

  /// Handle level failure
  void _onLevelFailed() {
    _levelTimer.stop();
    _changeGameState(GameState.gameOver);
    
    _trackEvent('level_fail', {
      'level': _currentLevel,
      'time_remaining': _timeRemaining,
    });
  }

  /// Calculate score and stars for completed level
  void _calculateScore() {
    final baseScore = 100;
    final timeBonus = (_timeRemaining * 10).round();
    final levelScore = baseScore + timeBonus;
    
    _score += levelScore;
    
    // Calculate stars based on performance
    if (_timeRemaining > _currentLevelConfig.timeLimit * 0.7) {
      _starsEarned = 3;
    } else if (_timeRemaining > _currentLevelConfig.timeLimit * 0.4) {
      _starsEarned = 2;
    } else {
      _starsEarned = 1;
    }
    
    _totalStars += _starsEarned;
  }

  /// Change game state and manage overlays
  void _changeGameState(GameState newState) {
    _gameState = newState;
    
    // Remove all overlays
    overlays.removeAll();
    
    // Add appropriate overlay
    switch (newState) {
      case GameState.menu:
        overlays.add('menu');
        break;
      case GameState.playing:
        overlays.add('hud');
        break;
      case GameState.paused:
        overlays.add('pause');
        break;
      case GameState.gameOver:
        overlays.add('game_over');
        break;
      case GameState.levelComplete:
        overlays.add('level_complete');
        break;
    }
  }

  /// Pause the game
  void pauseGame() {
    if (_gameState == GameState.playing) {
      _levelTimer.stop();
      _changeGameState(GameState.paused);
    }
  }

  /// Resume the game
  void resumeGame() {
    if (_gameState == GameState.paused) {
      _levelTimer.start();
      _changeGameState(GameState.playing);
    }
  }

  /// Restart current level
  void restartLevel() {
    startLevel(_currentLevel);
  }

  /// Go to next level
  void nextLevel() {
    if (_currentLevel < 10) {
      if (_currentLevel >= 3 && !_isLevelUnlocked(_currentLevel + 1)) {
        _showUnlockPrompt();
      } else {
        startLevel(_currentLevel + 1);
      }
    } else {
      _changeGameState(GameState.menu);
    }
  }

  /// Check if level is unlocked
  bool _isLevelUnlocked(int level) {
    return level <= 3; // First 3 levels are free
  }

  /// Show unlock prompt for locked levels
  void _showUnlockPrompt() {
    overlays.add('unlock_prompt');
    _trackEvent('unlock_prompt_shown', {'level': _currentLevel + 1});
  }

  /// Handle rewarded ad completion
  void onRewardedAdCompleted() {
    // Unlock next level
    _trackEvent('rewarded_ad_completed', {'level': _currentLevel + 1});
    overlays.remove('unlock_prompt');
    startLevel(_currentLevel + 1);
  }

  /// Get level configuration
  LevelConfig _getLevelConfig(int level) {
    switch (level) {
      case 1:
        return LevelConfig(
          gridSize: 3,
          tileTypes: 3,
          timeLimit: 60.0,
          targetPattern: _generateSimplePattern(3, 3),
          shuffleComplexity: 10,
        );
      case 2:
        return LevelConfig(
          gridSize: 3,
          tileTypes: 3,
          timeLimit: 55.0,
          targetPattern: _generateSimplePattern(3, 3),
          shuffleComplexity: 15,
        );
      case 3:
        return LevelConfig(
          gridSize: 3,
          tileTypes: 4,
          timeLimit: 50.0,
          targetPattern: _generateSimplePattern(3, 4),
          shuffleComplexity: 20,
        );
      case 4:
      case 5:
        return LevelConfig(
          gridSize: 4,
          tileTypes: 5,
          timeLimit: 45.0,
          targetPattern: _generateSimplePattern(4, 5),
          shuffleComplexity: 25,
        );
      default:
        return LevelConfig(
          gridSize: 5,
          tileTypes: 7,
          timeLimit: 30.0,
          targetPattern: _generateSimplePattern(5, 7),
          shuffleComplexity: 35,
        );
    }
  }

  /// Generate a simple pattern for the level
  List<List<int>> _generateSimplePattern(int gridSize, int tileTypes) {
    final pattern = <List<int>>[];
    
    for (int row = 0; row < gridSize; row++) {
      final rowPattern = <int>[];
      for (int col = 0; col < gridSize; col++) {
        // Create checkerboard-like patterns
        final tileType = (row + col) % tileTypes;
        rowPattern.add(tileType);
      }
      pattern.add(rowPattern);
    }