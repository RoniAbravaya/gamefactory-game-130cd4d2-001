import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

/// Main game scene component that manages the puzzle game state and logic
class GameScene extends Component with HasGameRef, TapCallbacks {
  /// Current level being played
  late int currentLevel;
  
  /// Grid size for the current level
  late int gridSize;
  
  /// Number of different tile types
  late int tileTypes;
  
  /// Time limit for the current level in seconds
  late int timeLimit;
  
  /// Current game grid
  late List<List<int>> gameGrid;
  
  /// Target pattern to match
  late List<List<int>> targetPattern;
  
  /// Timer component for countdown
  late TimerComponent gameTimer;
  
  /// Current score
  int currentScore = 0;
  
  /// Stars earned in current level
  int starsEarned = 0;
  
  /// Game state flags
  bool isGameActive = false;
  bool isGamePaused = false;
  bool isLevelComplete = false;
  
  /// UI components
  late TextComponent scoreText;
  late TextComponent timerText;
  late TextComponent levelText;
  
  /// Grid visual components
  late List<List<RectangleComponent>> tileComponents;
  
  /// Selected tile position for swapping
  Vector2? selectedTile;
  
  /// Color palette for tiles
  final List<Color> tileColors = [
    const Color(0xFFFF6B6B),
    const Color(0xFF4ECDC4),
    const Color(0xFF45B7D1),
    const Color(0xFFFFA07A),
    const Color(0xFF98D8C8),
    const Color(0xFFFFD93D),
    const Color(0xFFB19CD9),
  ];

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Initialize UI components
    _setupUI();
    
    // Start with level 1
    await loadLevel(1);
  }

  /// Sets up the UI components for score, timer, and level display
  void _setupUI() {
    // Score display
    scoreText = TextComponent(
      text: 'Score: 0',
      position: Vector2(20, 50),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(scoreText);

    // Timer display
    timerText = TextComponent(
      text: 'Time: 60',
      position: Vector2(game.size.x - 120, 50),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(timerText);

    // Level display
    levelText = TextComponent(
      text: 'Level 1',
      position: Vector2(game.size.x / 2 - 40, 50),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(levelText);
  }

  /// Loads and initializes a specific level
  Future<void> loadLevel(int level) async {
    currentLevel = level;
    isLevelComplete = false;
    selectedTile = null;
    
    // Set level parameters based on difficulty curve
    _setLevelParameters(level);
    
    // Generate game grid and target pattern
    _generateLevel();
    
    // Create visual grid
    await _createVisualGrid();
    
    // Setup timer
    _setupTimer();
    
    // Update UI
    _updateUI();
    
    // Start the game
    startGame();
  }

  /// Sets level parameters based on the current level
  void _setLevelParameters(int level) {
    if (level <= 3) {
      gridSize = 3;
      tileTypes = 3;
      timeLimit = 60;
    } else if (level <= 6) {
      gridSize = 4;
      tileTypes = 4;
      timeLimit = 50;
    } else if (level <= 8) {
      gridSize = 4;
      tileTypes = 5;
      timeLimit = 45;
    } else {
      gridSize = 5;
      tileTypes = min(7, 3 + (level - 1));
      timeLimit = max(30, 70 - (level * 4));
    }
  }

  /// Generates the game grid and target pattern
  void _generateLevel() {
    final random = Random();
    
    // Initialize grids
    gameGrid = List.generate(
      gridSize,
      (i) => List.generate(gridSize, (j) => random.nextInt(tileTypes)),
    );
    
    // Generate target pattern based on level
    targetPattern = _generateTargetPattern();
  }

  /// Generates a target pattern based on the current level
  List<List<int>> _generateTargetPattern() {
    final random = Random();
    
    if (currentLevel <= 3) {
      // Simple checkerboard pattern
      return List.generate(
        gridSize,
        (i) => List.generate(
          gridSize,
          (j) => (i + j) % 2,
        ),
      );
    } else if (currentLevel <= 6) {
      // Diagonal stripe patterns
      return List.generate(
        gridSize,
        (i) => List.generate(
          gridSize,
          (j) => (i + j) % tileTypes,
        ),
      );
    } else {
      // Complex patterns
      final pattern = List.generate(
        gridSize,
        (i) => List.generate(gridSize, (j) => 0),
      );
      
      // Create concentric squares pattern
      for (int i = 0; i < gridSize; i++) {
        for (int j = 0; j < gridSize; j++) {
          final distanceFromEdge = min(min(i, j), min(gridSize - 1 - i, gridSize - 1 - j));
          pattern[i][j] = distanceFromEdge % tileTypes;
        }
      }
      
      return pattern;
    }
  }

  /// Creates the visual representation of the game grid
  Future<void> _createVisualGrid() async {
    // Remove existing grid if any
    if (tileComponents.isNotEmpty) {
      for (final row in tileComponents) {
        for (final tile in row) {
          tile.removeFromParent();
        }
      }
    }
    
    tileComponents = [];
    
    final tileSize = min(
      (game.size.x - 40) / gridSize,
      (game.size.y - 200) / gridSize,
    );
    
    final startX = (game.size.x - (tileSize * gridSize)) / 2;
    final startY = 120;
    
    for (int i = 0; i < gridSize; i++) {
      final row = <RectangleComponent>[];
      
      for (int j = 0; j < gridSize; j++) {
        final tile = RectangleComponent(
          position: Vector2(
            startX + (j * tileSize),
            startY + (i * tileSize),
          ),
          size: Vector2(tileSize - 2, tileSize - 2),
          paint: Paint()..color = tileColors[gameGrid[i][j]],
        );
        
        add(tile);
        row.add(tile);
      }
      
      tileComponents.add(row);
    }
  }

  /// Sets up the game timer
  void _setupTimer() {
    gameTimer = TimerComponent(
      period: 1.0,
      repeat: true,
      onTick: () {
        if (isGameActive && !isGamePaused) {
          timeLimit--;
          _updateTimerDisplay();
          
          if (timeLimit <= 0) {
            _gameOver(false);
          }
        }
      },
    );
    
    add(gameTimer);
  }

  /// Updates the UI displays
  void _updateUI() {
    scoreText.text = 'Score: $currentScore';
    timerText.text = 'Time: $timeLimit';
    levelText.text = 'Level $currentLevel';
  }

  /// Updates the timer display
  void _updateTimerDisplay() {
    timerText.text = 'Time: $timeLimit';
  }

  /// Starts the game
  void startGame() {
    isGameActive = true;
    isGamePaused = false;
    gameTimer.timer.start();
  }

  /// Pauses the game
  void pauseGame() {
    isGamePaused = true;
    gameTimer.timer.pause();
  }

  /// Resumes the game
  void resumeGame() {
    isGamePaused = false;
    gameTimer.timer.resume();
  }

  @override
  bool onTapDown(TapDownEvent event) {
    if (!isGameActive || isGamePaused || isLevelComplete) {
      return false;
    }
    
    final tilePosition = _getTileFromPosition(event.localPosition);
    if (tilePosition != null) {
      _handleTileSelection(tilePosition);
    }
    
    return true;
  }

  /// Converts screen position to grid coordinates
  Vector2? _getTileFromPosition(Vector2 position) {
    if (tileComponents.isEmpty) return null;
    
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        final tile = tileComponents[i][j];
        if (tile.containsLocalPoint(position - tile.position)) {
          return Vector2(i.toDouble(), j.toDouble());
        }
      }
    }
    
    return null;
  }

  /// Handles tile selection and swapping logic
  void _handleTileSelection(Vector2 tilePos) {
    final row = tilePos.x.toInt();
    final col = tilePos.y.toInt();
    
    if (selectedTile == null) {
      // First tile selection
      selectedTile = tilePos;
      _highlightTile(row, col, true);
    } else {
      final selectedRow = selectedTile!.x.toInt();
      final selectedCol = selectedTile!.y.toInt();
      
      // Check if tiles are adjacent
      if (_areAdjacent(selectedRow, selectedCol, row, col)) {
        // Perform swap
        _swapTiles(selectedRow, selectedCol, row, col);
        
        // Check for pattern match
        if (_checkPatternMatch()) {
          _levelComplete();
        }
      }
      
      // Clear selection
      _highlightTile(selectedRow, selectedCol, false);
      selectedTile = null;
    }
  }

  /// Checks if two tiles are adjacent
  bool _areAdjacent(int row1, int col1, int row2, int col2) {
    final rowDiff = (row1 - row2).abs();
    final colDiff = (col1 - col2).abs();
    
    return (rowDiff == 1 && colDiff == 0) || (rowDiff == 0 && colDiff == 1);
  }

  /// Swaps two tiles in the grid
  void _swapTiles(int row1, int col1, int row2, int col2) {
    final temp = gameGrid[row1][col1];
    gameGrid[row1][col1] = gameGrid[row2][col2];
    gameGrid[row2][col2] = temp;
    
    // Update visual representation
    final tempColor = tileComponents[row1][col1].paint.color;
    tileComponents[row1][col1].paint.color = tileComponents[row2][col2].paint.color;
    tileComponents[row2][col2].paint.color = tempColor;
  }

  /// Highlights or unhighlights a tile
  void _highlightTile(int row, int col, bool highlight) {
    if (highlight) {
      tileComponents[row][col].paint.color = Colors.yellow;
    } else {
      tileComponents[row][col].paint.color = tileColors[gameGrid[row][col]];
    }
  }

  /// Checks if the current grid matches the target pattern
  bool _checkPatternMatch() {
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (gameGrid[i][j] != targetPattern[i][j]) {
          return false;
        }
      }
    }
    return true;
  }

  /// Handles level completion
  void _levelComplete() {
    isLevelComplete = true;
    isGameActive = false;
    
    // Calculate score based on remaining time
    final timeBonus = timeLimit * 10;
    currentScore += timeBonus;
    
    // Calculate stars (1-3 based on performance)
    if (timeLimit > timeLimit * 0.7) {
      starsEarned = 3;
    } else if (timeLimit > timeLimit * 0.4) {
      starsEarned = 2;
    } else {
      starsEarned = 1;
    }
    
    _updateUI();
    
    // Trigger level complete event
    _onLevelComplete();
  }

  /// Handles game over (time ran out)
  void _gameOver(bool success) {
    isGameActive = false;
    gameTimer.timer.stop();
    
    if (!success) {
      // Handle failure
      _onLevelFailed();
    }
  }

  /// Called when level is completed successfully
  void _onLevelComplete() {
    // This would typically trigger UI showing success screen
    // and options to continue to next level
  }

  /// Called when level is failed
  void _onLevelFailed() {
    // This would typically trigger UI showing failure screen
    // and option to retry
  }

  /// Restarts the current level
  Future<void> restartLevel() async {
    await loadLevel(currentLevel);
  }

  /// Proceeds to the next level
  Future<void> nextLevel() async {
    if (currentLevel < 10) {
      await loadLevel(currentLevel + 1);
    }
  }

  @override
  void onRemove() {
    gameTimer.removeFromParent();
    super.onRemove();
  }
}