AA Assignment

# Slimes
Eat, Observe, Eliminate, these are things the slimes will be doing in this game.
You are playing God for these creatuers giving them the necessary food for survival however they do multiply and they may not always have the same needs as their parents.
It is up to you what to give and remove from their environment.
Judge morality and play god.

Solo Project by Jello Sarmiento (C22531133)

## Video
[![YouTube](https://img.youtube.com/vi/chGdpWPDGrw/hqdefault.jpg)](https://youtu.be/chGdpWPDGrw)

## Itch Link
https://jellytots04.itch.io/slimes-simulator

## Key features
- Behaviour Trees.
- Finite State Machine (FSM).
- Interactable UI.
- Infinite play loop.
- VR Interactions:
  - Placing Down objects.
  - Controller movement capabilities.
  - Pick up the creatures.
  - Look around.

## VR Technologies used
- 3D UI.
- Spatial Audio.
- Controller Tracking.

# Main Gameplay
- Spawn in a creature.
- Give it life (Favourite Food, Name, Color, Style)
- Release it into the environment.
- Place down its food "spawner".
- Watch it eat and grow.
- Once it has eaten enough it will multiply a new creature.
- It spawns in with its own attributes.
- Feed it properly.
- Wait until too many have spawned and not enough food is present.
- Creatures will start too fight over the food.
- Observe the suffering.
- When a creature has been to cruel remove them from the environment.

# Slimes

Summon and observe slimes, give and take their food away, watch them fight and suffer or live peacefully.

Student Name: Jello Sarmiento

Student Number: C22531133

Class: TU858

## Video

# Table of Contents
1. Overview
2. Features
3. Controls
4. Design
5. Reflection
6. References

## Overview
This is a slime ecosystem with pesronality based AI, the AI has 3 defining traits, Aggression Type, Defensive Type and Food Preference.
Be prepared to give and take their food watch watch them react to their environment and do their best to survive.
With a slight chance to get an environment changing mutation be watch out for mutated slimes.

## Features

### AI Behavior
  - Finite State Machine:
    - Wander.
    - SeekFood.
    - Combat.
    - Flee.

  - Reynolds Steering Behaviors:
    - Wander.
    - SeekFood.
    - SeekTarget.
    - Flee.
    - Avoidance. 
    - Flocking.
    - Whisker Avoidance.

  - Whisker-based Obstacle Avoidance:
    - Using raycasts, steer the slime around static obstacles.
  - Perception system with detection range.

### Personality Traits
  - 3 Aggression types:
    - Flocker: Peaceful, flocks with other slimes.
    - Alpha: Avoids threats, has a flee burst.
    - Killer: Actively hunts.
  - 5 Defensive types:
    - Daring: Killer-only, retreat when low.
    - Flocker: Defends only when with pack.
    - Healthy: Retreats at 50% HP.
    - Runner: Retreats at 75% HP with a 1.4x speed buff.
    - Last Stand: Never retreats - Mutation-only.
  - Food Preferences:
    - Omnivore (All foods).
    - Carnivore (Meat only).
    - Herbivore (Fruit only).
  - Special Quirk: Heal only with killing, last stand mutation that lets slimes heal only by killing, preventing food consumption.

### Reproduction & Genetics
  - 3 Stage levelling: (1->2->3), reproduction rolls at each level.
  - Recurring reproduction: Every 5 minutes at level 3.
  - Stat inheritance with variation: Offspring stats drift from parent stats -/= HP, Damage, Defense, Speed.
  - Personality mutation: Low chance per trait generation.
  - Body color drift: RGB drifts -/+ per generation, visible lineage divergence.
  - Aggression-based stat archtectypes: Flockers are balanced, Alphas are tanky, Killers are glass cannons.

### Combat & Survival
  - Damage System: Damage and defense stats, with a minimum 1 damage to prevent stalemating.
  - Kill-heal mechanic: Successful kills heals the attacker (15% normal, 50% for Kill heal only quirked slimes). (It must be the killing blow)
  - Health Decay: Slime HP decays overtime, accelerated when overeating (above max health).
  - Food consumption: Eating food restores health with a cap.

### Environment & World
  - Food Spawners: 3 distinct types (Fruit Tree, Meat Cave, Multi Bin), spawns in bursts 3-5 food every 5 seconds with a cap per spawner.
  - Pre-placed spawners: Scene starts with food spawners upon start up.
  - Boundary walls: keeps slimes in starting area.
  - Ambient Sound looping.

### Player Controls
  - Top-down angled camera with WASD movement, Q/E rotaiton around a pivot point.
  - Scroll-wheel zoom with min / max bounds.
  - Title screen with start and quit buttons, decoration slimes wandering as background visuals.

### HUD & UI
  - Creation panel: Spawn slimes with custom name, aggression, defensive type, food preference, and body color picker.
  - Constraint Enforcement: Defensive options dynamically filter based on aggression (Flocker only shows when Aggression Flocker, Daring only for Killer slimes, Last Stand hidden mutation only.)
  - Spawn placement preview: Green ground marker follows mouse cursor when in placement mode.
  - Right-click cancellation for all active modes.
  - Three spawner buttons for placing each food spawner type.

### Inspection System
  - Click inspect: Clicking on any slime or spawner will inspect it.
  - Cinematic tween over to face the entity.
  - Live inspection panel shows, stats (Different fields for slimes and spawners).
  - Dynamic title relabelling on entity type.
  - Remove button to delete the inspected entity.
  - Right click to exit inspection mode.

### Minimap
  - Top-down orthogonal minimap on screen.
  - Layer-filteterd rendering, main view doesn't show minimap markers.
  - Custom colored markers, distinguish between slimes and spawners.
  - Click teleport: Clicking a spot on the minimap will move the player to that spot.

### Visual & Audio
  - Slime visuals: Eye colors based on aggression (left eye) and fensive type (right eye) - Last stand overrides both to black.
  - User-costum body color.
  - Sound effects for slimes, UI and Spawners.
  - Animations for slimes, UI and Spawners.

## Controls
| Action | Key/Mouse |
|--------|-----------|
| Camera Forward | W |
| Camera Backward | S |
| Camera Left | A |
| Camera Right | D |
| Rotate Left | Q |
| Rotate Right | E |
| UI action | Left Click |
| Exit action | Right Click |

## Reflection
### Learning Results
### Technical Hurdles
  - Floats vs Ints: Decisions between ints and floats we're unexpected, choosing whole numbers over a floating number for Health was a big choice, as a 0.5 tick and integer arithmetic turned the decimals into zeros, this would make slimes never die from starving.
  - Decentralised vs Centralised state machines, the early design for the state machines was handling every transition in a central function, but as aggression and defensive types kept coming in, refactoring was necessary so each state owns its own _think() condition, making the code cleaner and easier to read.
  - Steering forces with a weighted sum: Reynolds' approach allows each behavior to produce a force vector independently, summing them weighted produces navigation.
  This makes adding new behaviors is easier as it doesn't require changing existing behaviors they all just contribute to the total.
  - Look_at can produce Null / NaN positions, on smaller / less powerful devices with a lower framerate a camera bug was present overshooting the cinematic camera tween.
  Look at was not able to compute the correct forward direction, adding in a distance guard so look_at is only called when far enough away from the target prevents these crashes.

### Self-directed learning
  - Reynolds' steering behaviors: To understand the foundation to creating emerging life and boids, reading through Reynolds' paper about the wander algorithm directly informed the Wander implementation, with slight differences from the forward cone approach for random slime movements.
  - Scene scripting and composition: Researching scene instanes and patterns exposed me to things like static decoration should be in scenes without complex scripts, this led to the creation of DecorSlimes for the title screen as regular Slimes would cause scene-transition crashing.


### Proudest Achievment
I am most proud of the behaviors I have created.
After implementations all the personality types and reproduction inheritence were done, I let the scene run for a few minutes without any intervention.
Killer lineages started to dominate certain areas, while flocker groups would have clusters around food spawners, any quirked Last Stand Killers appeared occasionally and would take out most of the population for a few minutes but would then die from starvation.
The assignment shows how these different life forms

## References
### Papers
  - Reynolds, C .W "Flocks, herds, and school: A distributed behavioral model". Computer Graphics
  https://www.red3d.com/cwr/papers/1987/boids.html

### Github
  - Skooter500, Miniature Rotary Phone: https://github.com/skooter500/miniature-rotary-phone

### Documentation
  - Godot Engine Documentation, Godot 4 Manual: https://docs.godotengine.org/en/stable/
  - Godot Engine Documentation, AnimationPlayer: https://docs.godotengine.org/en/stable/classes/class_animationplayer.html
  - Godot Engine Documentation, PhysicsRayQueryParameters3D: https://docs.godotengine.org/en/stable/classes/class_physicsrayqueryparameters3d.html
  - Godot Engine Documentation, Subviewport: https://docs.godotengine.org/en/stable/classes/class_subviewport.html

### Asset Credits
Audio Assets: https://downloads.khinsider.com/game-soundtracks/album/plants-vs.-zombies-2009-gamerip-pc-ios-x360-ps3-ds-android-mobile-psvita-xbox-one-ps4-switch
Pixabay: https://pixabay.com/music/

### Software Used
Godot Engine 4.6
