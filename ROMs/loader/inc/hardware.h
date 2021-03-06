/*

MSX1 FPGA project

Copyright (c) 2016 Fabio Belavenuto

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

#ifndef _HARDWARE
#define _HARDWARE

// Switched I/O ports
__sfr __at 0x40 SWIOP_MKID;
__sfr __at 0x48 SWIOP_REGNUM;
__sfr __at 0x49 SWIOP_REGVAL;

// My Maker ID
static const unsigned char mymkid = 40;

// Register numbers
#define REG_HWID		0x00
#define REG_HWTXT		0x01
#define REG_HWVER		0x02
#define REG_RESET		0x0A
#define REG_KMLOWADDR	0x0D
#define REG_KMHIGHADDR	0x0E
#define REG_KMBYTE		0x0F
#define REG_OPTIONS		0x10
#define REG_MAPPER		0x11
#define REG_TURBO		0x12

// VDP
__sfr __at 0x98 VDP_DATA;
__sfr __at 0x99 VDP_CMD;


#endif
