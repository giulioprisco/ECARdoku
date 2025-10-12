# ECARdoku.m - Elementary Cellular Automata Sudoku-like Puzzle Simulator

## Overview

ECARdoku.m is a MATLAB script that simulates an interactive puzzle based on Wolfram's reversible Rule 37 elementary cellular automaton (ECA) with periodic boundaries. It precomputes all possible m x n grids evolving from every initial row configuration (2^n possibilities) and allows users to apply constraints (clues) to filter down to a unique solution board. The puzzle is akin to Sudoku but governed by cellular automata rules.

This script serves as the foundational logic for the web-based game 37Rdoku, which adapts the concept into an interactive browser puzzle with visual elements.

This script has been developed with AI assistance from Grok.

## Features

- **Rule and Mode**: Hardwired to reversible Rule 37 (37R), where each cell in row t+1 is computed as the XOR of the standard Rule 37 output for its neighborhood (left, center, right in row t) and the cell in row t-1 (0 for the second row). The script can be easily modified (by changing `rule = 37;`) to handle the reversible version of any elementary cellular automaton (rules 0-255).
- **Board Size**: Configurable via `n` (width/columns) and `m` (rows/generations) (default: n=8 columns, m=6 rows for an 8x6 grid).
- **Precomputation**: Generates all 2^n possible boards starting from every binary initial row.
- **Modes**:
  - **Manual**: User inputs clues (row, column, value: 0 or 1) interactively. Invalid clues (leading to zero possibilities) are discarded.
  - **Random**: Automatically generates reducing clues until a unique board remains, with diagnostics for each addition.
- **Validation**: Checks constraints without duplicates in positions for random mode.
- **Output**:
  - Displays the final unique board using `imagesc`.
  - Saves the board as a scaled PNG image (1800x1800 pixels by default).
  - Saves the final clues to `clues.txt` (format: row column value per line).
- **Error Handling**: Validates inputs, handles zero-possibility constraints gracefully.

## Requirements

- MATLAB (tested on recent versions; no additional toolboxes required).
- Basic functions like `bitget`, `mod`, `bitxor`, `imwrite`, `imresize`, `imagesc`.

## Usage

1. **Run the Script**:
   - Open MATLAB and execute `ECARdoku.m`.
   - Initial output: "Initial number of possible boards: 256" (for n=8).

2. **Select Mode**:
   - Prompt: "Enter 0 for manual clues, 1 for random: "
   - **Manual Mode**: Enter row (1-m), column (1-n), value (0/1). Repeat until one board remains.
   - **Random Mode**: Automatically adds clues, displaying each and remaining board count.

3. **Output Files**:
   - `final_board.png`: Scaled image of the unique board (black for 1, white for 0).
   - `clues.txt`: List of applied clues.

4. **Customization**:
   - Edit `n` and `m` in the script to change board dimensions (e.g., n=8, m=6; note: computation grows exponentially with n).
   - Adjust image size in `imresize` for output.

## Example

For a 4x4 board (set n=4, m=4):
- Initial possibilities: 16.
- Apply clues until unique.
- Final board displayed and saved.

## Limitations

- Exponential memory/time for large n (>16 may be impractical on standard hardware).
- No GUI; console-based interaction.

## Related

- The web game 37Rdoku is directly inspired by this script, offering a browser-based version with clickable cells, difficulties, hints, and visual rule explanations.
- Based on concepts from Stephen Wolfram's *A New Kind of Science*.

## License

This script is provided for educational purposes. Feel free to modify and share.