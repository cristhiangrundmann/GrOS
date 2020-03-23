Single sector disk editor
for IBM-PC compatibles

Created by Cristhian Grundmann

Code for reading and writing into disk.

ESC: enter "edit board" loop
board is the central panel, 64x16 cells

ARROW KEYS: move cursor

A-F 0-1: write nibble

F1: enter "edit target" loop
target is the 8 byte variable below the board
it is the LBA to read and write

F5: read from sector at target

F6: write into sector at target