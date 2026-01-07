import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

/// Player component for puzzle game that handles tile selection and interaction
class Player extends PositionComponent with HasGameRef, TapCallbacks {
  /// Current selected tile position
  Vector2? selectedTilePosition;
  
  /// Player's current star count
  int stars = 0;
  
  /// Current level being played
  int currentLevel = 1;
  
  /// Player's health (lives remaining)
  int health = 3;
  
  /// Maximum health
  static const int maxHealth = 3;
  
  /// Whether player is currently invulnerable
  bool isInvulnerable = false;
  
  /// Duration of invulnerability frames in seconds
  static const double invulnerabilityDuration = 1.0;
  
  /// Timer for invulnerability
  Timer? invulnerabilityTimer;
  
  /// Selection indicator sprite
  late SpriteComponent selectionIndicator;
  
  /// Player cursor/pointer sprite
  late SpriteComponent cursor;
  
  /// Animation states
  PlayerAnimationState currentAnimationState = PlayerAnimationState.idle;
  
  /// Callback for when player selects a tile
  Function(Vector2)? onTileSelected;
  
  /// Callback for when player attempts to swap tiles
  Function(Vector2, Vector2)? onTileSwap;
  
  /// Callback for when player takes damage
  Function()? onDamage;
  
  /// Callback for when player collects stars
  Function(int)? onStarsCollected;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Initialize selection indicator
    selectionIndicator = SpriteComponent()
      ..sprite = await Sprite.load('selection_indicator.png')
      ..size = Vector2(64, 64)
      ..anchor = Anchor.center
      ..opacity = 0.0;
    add(selectionIndicator);
    
    // Initialize cursor
    cursor = SpriteComponent()
      ..sprite = await Sprite.load('cursor.png')
      ..size = Vector2(32, 32)
      ..anchor = Anchor.center;
    add(cursor);
    
    // Set initial animation state
    _updateAnimationState(PlayerAnimationState.idle);
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Update cursor position to follow touch/mouse
    // This would be updated by the game's input handler
    
    // Handle invulnerability timer
    if (isInvulnerable && invulnerabilityTimer?.isActive != true) {
      _endInvulnerability();
    }
    
    // Update animation based on current state
    _updateAnimation(dt);
  }

  /// Handles tile selection at given position
  void selectTile(Vector2 tilePosition) {
    if (isInvulnerable) return;
    
    if (selectedTilePosition == null) {
      // First tile selection
      selectedTilePosition = tilePosition.clone();
      _showSelectionIndicator(tilePosition);
      _updateAnimationState(PlayerAnimationState.selecting);
      onTileSelected?.call(tilePosition);
    } else if (selectedTilePosition == tilePosition) {
      // Deselect current tile
      _clearSelection();
    } else {
      // Second tile selection - attempt swap
      final firstTile = selectedTilePosition!;
      final secondTile = tilePosition;
      
      if (_areAdjacent(firstTile, secondTile)) {
        _performSwap(firstTile, secondTile);
      } else {
        // Select new tile instead
        selectedTilePosition = tilePosition.clone();
        _showSelectionIndicator(tilePosition);
      }
    }
  }

  /// Performs tile swap animation and logic
  void _performSwap(Vector2 tile1, Vector2 tile2) {
    _updateAnimationState(PlayerAnimationState.swapping);
    onTileSwap?.call(tile1, tile2);
    
    // Clear selection after swap
    Timer(const Duration(milliseconds: 300), () {
      _clearSelection();
      _updateAnimationState(PlayerAnimationState.idle);
    });
  }

  /// Checks if two tiles are adjacent
  bool _areAdjacent(Vector2 tile1, Vector2 tile2) {
    final dx = (tile1.x - tile2.x).abs();
    final dy = (tile1.y - tile2.y).abs();
    return (dx == 1 && dy == 0) || (dx == 0 && dy == 1);
  }

  /// Shows selection indicator at given tile position
  void _showSelectionIndicator(Vector2 tilePosition) {
    selectionIndicator.position = tilePosition;
    selectionIndicator.add(
      OpacityEffect.to(
        0.8,
        EffectController(duration: 0.2),
      ),
    );
    
    // Add pulsing effect
    selectionIndicator.add(
      ScaleEffect.by(
        Vector2.all(1.1),
        EffectController(
          duration: 0.5,
          alternate: true,
          infinite: true,
        ),
      ),
    );
  }

  /// Clears current tile selection
  void _clearSelection() {
    selectedTilePosition = null;
    selectionIndicator.removeAll(selectionIndicator.children.whereType<Effect>());
    selectionIndicator.add(
      OpacityEffect.to(
        0.0,
        EffectController(duration: 0.2),
      ),
    );
    selectionIndicator.scale = Vector2.all(1.0);
    _updateAnimationState(PlayerAnimationState.idle);
  }

  /// Handles player taking damage
  void takeDamage(int damage) {
    if (isInvulnerable || health <= 0) return;
    
    health = max(0, health - damage);
    _startInvulnerability();
    onDamage?.call();
    
    // Add damage effect
    add(
      ColorEffect(
        Colors.red,
        EffectController(duration: 0.1, alternate: true, repeatCount: 3),
      ),
    );
    
    if (health <= 0) {
      _updateAnimationState(PlayerAnimationState.defeated);
    } else {
      _updateAnimationState(PlayerAnimationState.damaged);
    }
  }

  /// Heals player by specified amount
  void heal(int amount) {
    health = min(maxHealth, health + amount);
  }

  /// Adds stars to player's collection
  void collectStars(int amount) {
    stars += amount;
    onStarsCollected?.call(amount);
    
    // Add collection effect
    _updateAnimationState(PlayerAnimationState.collecting);
    Timer(const Duration(milliseconds: 500), () {
      _updateAnimationState(PlayerAnimationState.idle);
    });
  }

  /// Starts invulnerability period
  void _startInvulnerability() {
    isInvulnerable = true;
    invulnerabilityTimer = Timer(
      const Duration(milliseconds: (invulnerabilityDuration * 1000).round()),
      () => _endInvulnerability(),
    );
    
    // Add flashing effect during invulnerability
    add(
      OpacityEffect.to(
        0.5,
        EffectController(
          duration: 0.1,
          alternate: true,
          infinite: true,
        ),
      ),
    );
  }

  /// Ends invulnerability period
  void _endInvulnerability() {
    isInvulnerable = false;
    invulnerabilityTimer?.cancel();
    invulnerabilityTimer = null;
    
    // Remove flashing effect
    removeAll(children.whereType<OpacityEffect>());
    opacity = 1.0;
  }

  /// Updates animation state
  void _updateAnimationState(PlayerAnimationState newState) {
    if (currentAnimationState == newState) return;
    
    currentAnimationState = newState;
    
    // Remove existing animation effects
    cursor.removeAll(cursor.children.whereType<Effect>());
    
    switch (newState) {
      case PlayerAnimationState.idle:
        cursor.add(
          MoveEffect.by(
            Vector2(0, -5),
            EffectController(
              duration: 1.0,
              alternate: true,
              infinite: true,
            ),
          ),
        );
        break;
      case PlayerAnimationState.selecting:
        cursor.add(
          ScaleEffect.by(
            Vector2.all(1.2),
            EffectController(duration: 0.1),
          ),
        );
        break;
      case PlayerAnimationState.swapping:
        cursor.add(
          RotateEffect.by(
            2 * pi,
            EffectController(duration: 0.3),
          ),
        );
        break;
      case PlayerAnimationState.collecting:
        cursor.add(
          ScaleEffect.by(
            Vector2.all(1.5),
            EffectController(
              duration: 0.2,
              alternate: true,
            ),
          ),
        );
        break;
      case PlayerAnimationState.damaged:
        cursor.add(
          MoveEffect.by(
            Vector2(10, 0),
            EffectController(
              duration: 0.05,
              alternate: true,
              repeatCount: 6,
            ),
          ),
        );
        break;
      case PlayerAnimationState.defeated:
        cursor.add(
          ScaleEffect.to(
            Vector2.all(0.5),
            EffectController(duration: 0.5),
          ),
        );
        cursor.add(
          OpacityEffect.to(
            0.3,
            EffectController(duration: 0.5),
          ),
        );
        break;
    }
  }

  /// Updates animation frame
  void _updateAnimation(double dt) {
    // Animation updates are handled by effects
    // This method can be used for custom animation logic if needed
  }

  /// Resets player to initial state
  void reset() {
    health = maxHealth;
    stars = 0;
    selectedTilePosition = null;
    isInvulnerable = false;
    invulnerabilityTimer?.cancel();
    invulnerabilityTimer = null;
    
    _clearSelection();
    _updateAnimationState(PlayerAnimationState.idle);
    
    // Reset visual effects
    opacity = 1.0;
    removeAll(children.whereType<Effect>());
  }

  /// Advances to next level
  void advanceLevel() {
    currentLevel++;
    // Reset any level-specific state if needed
  }

  @override
  bool onTapDown(TapDownEvent event) {
    // Convert tap position to tile coordinates
    // This would depend on your grid system implementation
    final tilePosition = _screenToTilePosition(event.localPosition);
    if (tilePosition != null) {
      selectTile(tilePosition);
      return true;
    }
    return false;
  }

  /// Converts screen position to tile grid position
  Vector2? _screenToTilePosition(Vector2 screenPosition) {
    // This method should be implemented based on your grid system
    // For now, returning a placeholder
    // You would calculate which tile the screen position corresponds to
    return null;
  }

  @override
  void onRemove() {
    invulnerabilityTimer?.cancel();
    super.onRemove();
  }
}

/// Enumeration of player animation states
enum PlayerAnimationState {
  idle,
  selecting,
  swapping,
  collecting,
  damaged,
  defeated,
}