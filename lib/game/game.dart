import 'dart:async';
import 'dart:math';
import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Main game states for the puzzle game
enum GameState {
  playing,
  paused,
  gameOver,
  levelComplete,
  loading
}

/// Main FlameGame class for the tile swap puzzle game
class Batch20260107102709Puzzle01Game extends FlameGame
    with HasTappableComponents, HasCollisionDetection {
  
  /// Current game state
  GameState _gameState = GameState.loading;
  GameState get gameState => _gameState;
  
  /// Current level configuration
  int _currentLevel = 1;
  int get currentLevel => _currentLevel;
  
  /// Game grid dimensions
  late int _gridSize;
  late int _tileTypes;
  late int _timeLimit;
  
  /// Game components
  late World gameWorld;
  late CameraComponent gameCamera;
  
  /// Grid and tiles
  late List<List<int>> _currentGrid;
  late List<List<int>> _targetGrid;
  late List<List<TileComponent>> _tileComponents;
  
  /// Game metrics
  int _score = 0;
  int _stars = 0;
  int _moves = 0;
  late Timer _gameTimer;
  int _remainingTime = 0;
  
  /// Selected tile for swapping
  TileComponent? _selectedTile;
  
  /// Game controller reference
  GameController? _gameController;
  
  /// Analytics service reference
  AnalyticsService? _analyticsService;
  
  /// Level configurations
  static const Map<int, Map<String, dynamic>> _levelConfigs = {
    1: {
      'gridSize': 3,
      'tileTypes': 3,
      'timeLimit': 60,
      'pattern': 'checkerboard'
    },
    2: {
      'gridSize': 3,
      'tileTypes': 4,
      'timeLimit': 55,
      'pattern': 'stripes'
    },
    3: {
      'gridSize': 4,
      'tileTypes': 4,
      'timeLimit': 50,
      'pattern': 'corners'
    },
    4: {
      'gridSize': 4,
      'tileTypes': 5,
      'timeLimit': 45,
      'pattern': 'diagonal'
    },
    5: {
      'gridSize': 4,
      'tileTypes': 5,
      'timeLimit': 45,
      'pattern': 'diagonal_stripes'
    },
    6: {
      'gridSize': 5,
      'tileTypes': 6,
      'timeLimit': 40,
      'pattern': 'cross'
    },
    7: {
      'gridSize': 5,
      'tileTypes': 6,
      'timeLimit': 38,
      'pattern': 'spiral'
    },
    8: {
      'gridSize': 5,
      'tileTypes': 7,
      'timeLimit': 35,
      'pattern': 'diamond'
    },
    9: {
      'gridSize': 5,
      'tileTypes': 7,
      'timeLimit': 32,
      'pattern': 'complex_mandala'
    },
    10: {
      'gridSize': 5,
      'tileTypes': 7,
      'timeLimit': 30,
      'pattern': 'complex_mandala'
    },
  };
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Initialize camera and world
    gameWorld = World();
    gameCamera = CameraComponent.withFixedResolution(
      world: gameWorld,
      width: 400,
      height: 800,
    );
    
    addAll([gameCamera, gameWorld]);
    
    // Initialize game timer
    _gameTimer = Timer(1.0, repeat: true, onTick: _onTimerTick);
    
    // Load initial level
    await _loadLevel(_currentLevel);
    
    _analyticsService?.logEvent('game_start', {
      'level': _currentLevel,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
  
  /// Sets the game controller reference
  void setGameController(GameController controller) {
    _gameController = controller;
  }
  
  /// Sets the analytics service reference
  void setAnalyticsService(AnalyticsService service) {
    _analyticsService = service;
  }
  
  /// Loads a specific level
  Future<void> _loadLevel(int level) async {
    try {
      _gameState = GameState.loading;
      
      final config = _levelConfigs[level];
      if (config == null) {
        throw Exception('Level $level configuration not found');
      }
      
      _gridSize = config['gridSize'];
      _tileTypes = config['tileTypes'];
      _timeLimit = config['timeLimit'];
      _remainingTime = _timeLimit;
      
      // Clear existing tiles
      gameWorld.removeAll(gameWorld.children.whereType<TileComponent>());
      
      // Generate grids
      _generateGrids(config['pattern']);
      
      // Create tile components
      await _createTileComponents();
      
      // Reset game state
      _moves = 0;
      _selectedTile = null;
      
      _gameState = GameState.playing;
      _gameTimer.start();
      
      _analyticsService?.logEvent('level_start', {
        'level': level,
        'grid_size': _gridSize,
        'tile_types': _tileTypes,
        'time_limit': _timeLimit,
      });
      
    } catch (e) {
      debugPrint('Error loading level $level: $e');
      _gameState = GameState.gameOver;
    }
  }
  
  /// Generates the current and target grids based on pattern
  void _generateGrids(String pattern) {
    final random = Random();
    
    // Initialize grids
    _currentGrid = List.generate(_gridSize, 
        (i) => List.generate(_gridSize, (j) => random.nextInt(_tileTypes)));
    
    _targetGrid = List.generate(_gridSize, 
        (i) => List.generate(_gridSize, (j) => 0));
    
    // Generate target pattern
    switch (pattern) {
      case 'checkerboard':
        _generateCheckerboardPattern();
        break;
      case 'stripes':
        _generateStripesPattern();
        break;
      case 'corners':
        _generateCornersPattern();
        break;
      case 'diagonal':
        _generateDiagonalPattern();
        break;
      case 'diagonal_stripes':
        _generateDiagonalStripesPattern();
        break;
      case 'cross':
        _generateCrossPattern();
        break;
      case 'spiral':
        _generateSpiralPattern();
        break;
      case 'diamond':
        _generateDiamondPattern();
        break;
      case 'complex_mandala':
        _generateComplexMandalaPattern();
        break;
      default:
        _generateCheckerboardPattern();
    }
  }
  
  /// Generates checkerboard pattern
  void _generateCheckerboardPattern() {
    for (int i = 0; i < _gridSize; i++) {
      for (int j = 0; j < _gridSize; j++) {
        _targetGrid[i][j] = (i + j) % 2;
      }
    }
  }
  
  /// Generates stripes pattern
  void _generateStripesPattern() {
    for (int i = 0; i < _gridSize; i++) {
      for (int j = 0; j < _gridSize; j++) {
        _targetGrid[i][j] = i % min(_tileTypes, 3);
      }
    }
  }
  
  /// Generates corners pattern
  void _generateCornersPattern() {
    for (int i = 0; i < _gridSize; i++) {
      for (int j = 0; j < _gridSize; j++) {
        if ((i == 0 || i == _gridSize - 1) && (j == 0 || j == _gridSize - 1)) {
          _targetGrid[i][j] = 1;
        } else {
          _targetGrid[i][j] = 0;
        }
      }
    }
  }
  
  /// Generates diagonal pattern
  void _generateDiagonalPattern() {
    for (int i = 0; i < _gridSize; i++) {
      for (int j = 0; j < _gridSize; j++) {
        _targetGrid[i][j] = i == j ? 1 : 0;
      }
    }
  }
  
  /// Generates diagonal stripes pattern
  void _generateDiagonalStripesPattern() {
    for (int i = 0; i < _gridSize; i++) {
      for (int j = 0; j < _gridSize; j++) {
        _targetGrid[i][j] = (i + j) % min(_tileTypes, 3);
      }
    }
  }
  
  /// Generates cross pattern
  void _generateCrossPattern() {
    final center = _gridSize ~/ 2;
    for (int i = 0; i < _gridSize; i++) {
      for (int j = 0; j < _gridSize; j++) {
        _targetGrid[i][j] = (i == center || j == center) ? 1 : 0;
      }
    }
  }
  
  /// Generates spiral pattern
  void _generateSpiralPattern() {
    final center = _gridSize ~/ 2;
    for (int i = 0; i < _gridSize; i++) {
      for (int j = 0; j < _gridSize; j++) {
        final distance = max((i - center).abs(), (j - center).abs());
        _targetGrid[i][j] = distance % min(_tileTypes, 3);
      }
    }
  }
  
  /// Generates diamond pattern
  void _generateDiamondPattern() {
    final center = _gridSize ~/ 2;
    for (int i = 0; i < _gridSize; i++) {
      for (int j = 0; j < _gridSize; j++) {
        final distance = (i - center).abs() + (j - center).abs();
        _targetGrid[i][j] = distance <= center ? 1 : 0;
      }
    }
  }
  
  /// Generates complex mandala pattern
  void _generateComplexMandalaPattern() {
    final center = _gridSize ~/ 2;
    for (int i = 0; i < _gridSize; i++) {
      for (int j = 0; j < _gridSize; j++) {
        final dx = i - center;
        final dy = j - center;
        final distance = sqrt(dx * dx + dy * dy);
        final angle = atan2(dy.toDouble(), dx.toDouble());
        final pattern = (distance * 2 + angle * 4).round();
        _targetGrid[i][j] = pattern % min(_tileTypes, 4);
      }
    }
  }
  
  /// Creates tile components for the grid
  Future<void> _createTileComponents() async {
    _tileComponents = List.generate(_gridSize, 
        (i) => List.generate(_gridSize, (j) => TileComponent()));
    
    final tileSize = 60.0;
    final spacing = 5.0;
    final totalWidth = _gridSize * tileSize + (_gridSize - 1) * spacing;
    final startX = -totalWidth / 2 + tileSize / 2;
    final startY = -totalWidth / 2 + tileSize / 2;
    
    for (int i = 0; i < _gridSize; i++) {
      for (int j = 0; j < _gridSize; j++) {
        final tile = TileComponent(
          gridX: j,
          gridY: i,
          tileType: _currentGrid[i][j],
          size: Vector2.all(tileSize),
        );
        
        tile.position = Vector2(
          startX + j * (tileSize + spacing),
          startY + i * (tileSize + spacing),
        );
        
        _tileComponents[i][j] = tile;
        gameWorld.add(tile);
      }
    }
  }
  
  /// Handles tile tap events
  void onTileTapped(TileComponent tile) {
    if (_gameState != GameState.playing) return;
    
    HapticFeedback.lightImpact();
    
    if (_selectedTile == null) {
      // Select first tile
      _selectedTile = tile;
      tile.setSelected(true);
    } else if (_selectedTile == tile) {
      // Deselect same tile
      _selectedTile!.setSelected(false);
      _selectedTile = null;
    } else {
      // Try to swap tiles
      if (_areAdjacent(_selectedTile!, tile)) {
        _swapTiles(_selectedTile!, tile);
        _selectedTile!.setSelected(false);
        _selectedTile = null;
        _moves++;
        
        // Check for level completion
        if (_checkLevelComplete()) {
          _onLevelComplete();
        }
      } else {
        // Select new tile
        _selectedTile!.setSelected(false);
        _selectedTile = tile;
        tile.setSelected(true);
      }
    }
  }
  
  /// Checks if two tiles are adjacent
  bool _areAdjacent(TileComponent tile1, TileComponent tile2) {
    final dx = (tile1.gridX - tile2.gridX).abs();
    final dy = (tile1.gridY - tile2.gridY).abs();
    return (dx == 1 && dy == 0) || (dx == 0 && dy == 1);
  }
  
  /// Swaps two tiles
  void _swapTiles(TileComponent tile1, TileComponent tile2) {
    // Swap in grid
    final temp = _currentGrid[tile1.gridY][tile1.gridX];
    _currentGrid[tile1.gridY][tile1.gridX] = _currentGrid[tile2.gridY][tile2.gridX];
    _currentGrid[tile2.gridY][tile2.gridX] = temp;
    
    // Update tile types
    final tempType = tile1.tileType;
    tile1.setTileType(_currentGrid[tile1.gridY][tile1.gridX]);
    tile2.setTileType(_currentGrid[tile2.gridY][tile2.gridX]);
  }
  
  /// Checks if the current level is complete
  bool _checkLevelComplete() {
    for (int i = 0; i < _gridSize; i++) {
      for (int j = 0; j < _gridSize; j++) {
        if (_currentGrid[i][j] != _targetGrid[i][j]) {
          return false;
        }
      }
    }
    return true;
  }
  
  /// Handles level completion
  void _onLevelComplete() {
    _gameState = GameState.levelComplete;
    _gameTimer.stop();
    
    // Calculate score
    final timeBonus = _remainingTime * 10;
    final moveBonus = max(0, 100 - _moves * 5);
    final levelScore = 100 + timeBonus + moveBonus;
    _score += levelScore;
    
    // Calculate stars (1-3 based on performance)
    int earnedStars = 1;
    if (_remainingTime > _timeLimit *