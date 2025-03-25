#[

64x32 pixels display
64 width x 32 height

With this format:

(0,0)	(63,0)
(0,31)	(63,31)

A sprite is a group of bytes which are a binary representation of the desired picture.
Chip-8 sprites may be up to 15 bytes. for a possible sprite size of 8x15.

]#

#[
ij0 1 2 3 4 5 6 7
0 0 0 0 0 0 0 0 0
1 0 0 0 0 0 0 0 0
2 0 0 0 1 0 0 0 0
3 0 0 0 0 0 0 0 0

00000000 00000000 00010000 00000000
01234567 89012345 67890123 45678901

position 19 = w * i + j = 8 * 2 + 3
]#