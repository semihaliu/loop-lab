# Loop Lab

A 2D time-loop puzzle platformer made with Godot 4 (GDScript). Your recorded runs replay as clones that help you solve each lab room.

## How to play

Each room has a goal door. You cannot reach it alone, so you play in rounds:

1. Play a round. Your inputs are recorded.
2. Press `R` to end the round. Time rewinds, and the recorded round replays as a clone that behaves like a real character (not a ghost).
3. Play the next round together with your clones, for example by letting a clone hold a pressure plate while you ride the elevator it opens.

Each room limits how many clones you can record. When the limit is reached, further `R` presses no longer add a clone. The world is simulated from the start every round and is fully deterministic.

Restart is also bound to `T` (same as the Restart button; it is a system key, never recorded into a clone, and is ignored on the result screen). Two on-screen buttons are available:

- **Restart** ("Baştan başla"): a full reset. All clones are deleted and you return to round 1.
- **Main menu**: returns to the menu and also clears all clones.

The main menu opens a level map where any room can be selected.

## Controls

| Action | Keys |
| --- | --- |
| Move left | Left arrow, A |
| Move right | Right arrow, D |
| Jump | Space, Up arrow, W |
| Drop through a one-way platform | S, Down arrow |
| End round (record clone) | R |
| Restart (reset all clones, back to round 1) | T |

The main menu has a Controls screen that lists the current key bindings.

## Mechanics

- **Pressure plate**: active while any character or box stands on it.
- **Elevator**: moves while its plate is pressed; stops if a character is underneath on the way down.
- **Lever**: flipped by pushing it sideways; no interaction key.
- **Gate**: opens and closes from plates and levers (OR logic); stops while a character stands in its way.
- **Laser**: kills a living player (the round restarts) and freezes a clone in place; plates and levers can switch it off or on.
- **Box**: can be pushed (not pulled); holds plates down and can be used as a step.
- **Spring pad**: launches whatever lands on it upward, including boxes.
- **Conveyor belt**: carries characters and boxes standing on it.
- **Timed plate**: stays active for about three seconds after you step off.
- **Latching plate**: once pressed, stays active for the rest of the round.
- **One-way platform**: can be jumped through from below and stood on from above; press S (or Down) to drop through it. Clones replay the drop.

## Levels

21 rooms, from a short tutorial to multi-clone puzzles that combine the mechanics above. The later rooms require three clones, timed and latching plates, multi-floor elevators and tight timing. The level map shows each room's name on hover; the result screen shows clones used, rounds and time.

## Run it

1. Open the project folder with Godot 4.7 (GL Compatibility renderer).
2. Press F5. The game starts at the main menu.

Run the automated tests headless:

```
<GODOT_YOLU> --headless --path . --fixed-fps 60 --script res://tests/test_runner.gd
```

The exit code is 1 if any test fails. Append `-- --rapor` to also write a dated report to `docs/testler.md`.

## Tests

The test runner drives the real game by injecting input events, so it exercises the same code path as a player. It checks that the simulation is deterministic (the same inputs repeated many times give identical positions), that every level is solvable with the intended number of clones, that wrong timings or missing clones fail, that gates and walls cannot be bypassed by jumping, and that shortcuts using fewer clones do not exist.

## Project notes

This is a graduation project, developed with Claude Code. Design decisions, measured timing windows and open issues are recorded in `docs/kararlar.md` and `docs/sorunlar.md`.
