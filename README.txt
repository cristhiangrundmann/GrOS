Control keys:
LEFT, RIGHT, UP AND DOWN ARROW: move cursor.
TAB: swap cursor position, from ASCII panel to hex and vice versa.
F8: read sector from disk.
F9: write buffer into disk.
ESC: call code on buffer

On ASCII panel, any ASCII key writes into buffer.
On HEX panel, only [0-9A-F] writes into buffer (note uppercase letters).

Concepts:
There are THREE relevant references for the sector being edited.
One, of course, is the sector on the disk. Only the read and write commands touch it.

Another is the buffer that is used to interface between RAM and disk. It's 512 bytes of continous memory. Again, only the read and write commands touch it.

The last one is the video data that displays the buffer data. Only this data is changed when the user types chars on the keyboard.
There are two panels, an ASCII panel and an HEX panel. The ASCII panel displays printable chars normally and non-printable chars as a centered dot, not the usual '.'. These panels are always synchronized. 
The HEX panel consists of 2 chars per byte. To easily distinguish which chars belong to which bytes, vertical strips of alternating color are present in this panel.
When the cursor is on the ASCII panel, any ASCII char typed is written on the panel.
When the cursor is on the HEX panel, only the ten digits and the uppercase letter from A to F (including them) are written on the board.
When any byte is written on screen, both its ASCII char representation and its hexadecimal representation change their text color to white (or blinking white depending on BIOS).
When the read and write commands are invoked, the white chars become black again. This is useful to see what are the alterations done in the sector.

The TARGET is the 8-byte LBA (sector address) of the sector being edited on disk.
These 8 bytes appear on the bottom right of both panels.
The byte order is LITTLE ENDIAN, while the nibble order is BIG ENDIAN.