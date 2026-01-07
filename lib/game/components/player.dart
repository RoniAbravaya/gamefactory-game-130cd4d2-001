import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

/// Player component for the puzzle game that manages cursor/selection state
/// and provides visual feedback for tile interactions
class Player extends PositionComponent with HasGameRef, TapCallbacks {
  /// Current selected tile position
  Vector2? selectedTilePosition;
  
  /// Visual indicator for selected tile
  RectangleComponent? selectionIndicator;
  
  /// Animation component for selection effects
  SpriteAnimationComponent? selectionAnimation;
  
  /// Current score accumulated by the player
  int _score = 0;
  
  /// Number of moves made by the player
  int _moveCount = 0;
  
  /// Whether the player can currently interact with tiles
  bool _canInteract = true;
  
  /// Callback for when tiles are swapped
  Function(Vector2, Vector2)? onTileSwap;
  
  /// Callback for score updates
  Function(int)? onScoreUpdate;
  
  /// Callback for move count updates
  Function(int)? onMoveUpdate;

  /// Gets the current player score
  int get score => _score;
  
  /// Gets the current move count
  int get moveCount => _moveCount;
  
  /// Gets whether player can currently interact
  bool get canInteract => _canInteract;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    // Create selection indicator
    selectionIndicator = RectangleComponent(
      size: Vector2(64, 64),
      paint: Paint()
        ..color = const Color(0xFF45B7D1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );
    selectionIndicator!.anchor = Anchor.center;
    
    // Create selection animation effect
    final selectionSprite = await Sprite.load('selection_effect.png');
    final selectionSpriteAnimation = SpriteAnimation.spriteList(
      [selectionSprite],
      stepTime: 0.1,
      loop: true,
    );
    
    selectionAnimation = SpriteAnimationComponent(
      animation: selectionSpriteAnimation,
      size: Vector2(80, 80),
      anchor: Anchor.center,
    );
    
    add(selectionIndicator!);
    add(selectionAnimation!);
    
    // Initially hide selection indicators
    _hideSelection();
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Update selection animation opacity for pulsing effect
    if (selectedTilePosition != null && selectionAnimation != null) {
      final pulseValue = (sin(game.time * 4) + 1) / 2;
      selectionAnimation!.opacity = 0.5 + (pulseValue * 0.5);
    }
  }

  /// Handles tile selection and swapping logic
  void selectTile(Vector2 tilePosition) {
    if (!_canInteract) return;
    
    if (selectedTilePosition == null) {
      // First tile selection
      _selectFirstTile(tilePosition);
    } else if (selectedTilePosition == tilePosition) {
      // Deselect current tile
      _deselectTile();
    } else if (_areAdjacent(selectedTilePosition!, tilePosition)) {
      // Swap adjacent tiles
      _swapTiles(selectedTilePosition!, tilePosition);
    } else {
      // Select new tile
      _selectFirstTile(tilePosition);
    }
  }

  /// Selects the first tile and shows visual feedback
  void _selectFirstTile(Vector2 tilePosition) {
    selectedTilePosition = tilePosition;
    _showSelection(tilePosition);
  }

  /// Deselects the current tile
  void _deselectTile() {
    selectedTilePosition = null;
    _hideSelection();
  }

  /// Swaps two adjacent tiles
  void _swapTiles(Vector2 firstTile, Vector2 secondTile) {
    if (onTileSwap != null) {
      onTileSwap!(firstTile, secondTile);
    }
    
    _incrementMoveCount();
    _deselectTile();
  }

  /// Checks if two tile positions are adjacent
  bool _areAdjacent(Vector2 pos1, Vector2 pos2) {
    final dx = (pos1.x - pos2.x).abs();
    final dy = (pos1.y - pos2.y).abs();
    
    return (dx == 1 && dy == 0) || (dx == 0 && dy == 1);
  }

  /// Shows selection indicator at the specified position
  void _showSelection(Vector2 tilePosition) {
    if (selectionIndicator != null && selectionAnimation != null) {
      // Convert tile position to world position
      final worldPos = _tileToWorldPosition(tilePosition);
      
      selectionIndicator!.position = worldPos;
      selectionAnimation!.position = worldPos;
      
      selectionIndicator!.opacity = 1.0;
      selectionAnimation!.opacity = 1.0;
    }
  }

  /// Hides selection indicators
  void _hideSelection() {
    if (selectionIndicator != null && selectionAnimation != null) {
      selectionIndicator!.opacity = 0.0;
      selectionAnimation!.opacity = 0.0;
    }
  }

  /// Converts tile grid position to world position
  Vector2 _tileToWorldPosition(Vector2 tilePosition) {
    // Assuming tiles are 64x64 pixels with some padding
    const tileSize = 64.0;
    const padding = 8.0;
    
    return Vector2(
      tilePosition.x * (tileSize + padding) + tileSize / 2,
      tilePosition.y * (tileSize + padding) + tileSize / 2,
    );
  }

  /// Adds points to the player's score
  void addScore(int points) {
    _score += points;
    if (onScoreUpdate != null) {
      onScoreUpdate!(_score);
    }
  }

  /// Increments the move counter
  void _incrementMoveCount() {
    _moveCount++;
    if (onMoveUpdate != null) {
      onMoveUpdate!(_moveCount);
    }
  }

  /// Resets player state for a new level
  void resetForNewLevel() {
    _score = 0;
    _moveCount = 0;
    selectedTilePosition = null;
    _hideSelection();
    _canInteract = true;
    
    if (onScoreUpdate != null) {
      onScoreUpdate!(_score);
    }
    if (onMoveUpdate != null) {
      onMoveUpdate!(_moveCount);
    }
  }

  /// Disables player interaction
  void disableInteraction() {
    _canInteract = false;
    _deselectTile();
  }

  /// Enables player interaction
  void enableInteraction() {
    _canInteract = true;
  }

  /// Calculates bonus score based on remaining time and efficiency
  int calculateLevelBonus(int remainingTime, int targetMoves) {
    int timeBonus = remainingTime * 10;
    int efficiencyBonus = 0;
    
    if (_moveCount <= targetMoves) {
      efficiencyBonus = (targetMoves - _moveCount) * 50;
    }
    
    return timeBonus + efficiencyBonus;
  }

  /// Provides hint by highlighting a beneficial move
  void showHint(Vector2 hintTile1, Vector2 hintTile2) {
    if (!_canInteract) return;
    
    // Flash both tiles to indicate the suggested swap
    _flashTile(hintTile1);
    _flashTile(hintTile2);
  }

  /// Creates a flashing effect on a specific tile
  void _flashTile(Vector2 tilePosition) {
    final flashIndicator = RectangleComponent(
      size: Vector2(64, 64),
      paint: Paint()
        ..color = const Color(0xFFFFA07A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0,
    );
    flashIndicator.anchor = Anchor.center;
    flashIndicator.position = _tileToWorldPosition(tilePosition);
    
    add(flashIndicator);
    
    // Remove flash after animation
    Timer(const Duration(seconds: 2), () {
      remove(flashIndicator);
    });
  }

  @override
  bool onTapDown(TapDownEvent event) {
    if (!_canInteract) return false;
    
    // Convert tap position to tile position
    final tilePos = _worldToTilePosition(event.localPosition);
    if (_isValidTilePosition(tilePos)) {
      selectTile(tilePos);
      return true;
    }
    
    return false;
  }

  /// Converts world position to tile grid position
  Vector2 _worldToTilePosition(Vector2 worldPosition) {
    const tileSize = 64.0;
    const padding = 8.0;
    
    return Vector2(
      (worldPosition.x / (tileSize + padding)).floor().toDouble(),
      (worldPosition.y / (tileSize + padding)).floor().toDouble(),
    );
  }

  /// Validates if a tile position is within the game grid
  bool _isValidTilePosition(Vector2 tilePosition) {
    // This should be configured based on current level grid size
    const maxGridSize = 5; // Maximum grid size for level 10
    
    return tilePosition.x >= 0 && 
           tilePosition.y >= 0 && 
           tilePosition.x < maxGridSize && 
           tilePosition.y < maxGridSize;
  }
}