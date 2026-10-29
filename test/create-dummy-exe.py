#!/usr/bin/env python3
"""Create a minimal PE32+ executable fixture with a single .text section."""

import struct
from pathlib import Path
import sys


def build_pe() -> bytes:
    dos = bytearray(0x80)
    dos[0:2] = b"MZ"
    struct.pack_into("<I", dos, 0x3C, 0x80)

    coff = struct.pack(
        "<HHIIIHH",
        0x8664,  # x86-64
        1,
        0,
        0,
        0,
        0xF0,
        0x0022,  # executable, large-address-aware
    )
    optional = bytearray(0xF0)
    struct.pack_into("<H", optional, 0x00, 0x20B)
    struct.pack_into("<BB", optional, 0x02, 14, 0)
    struct.pack_into("<III", optional, 0x04, 0x200, 0, 0)
    struct.pack_into("<II", optional, 0x10, 0x1000, 0x1000)
    struct.pack_into("<Q", optional, 0x18, 0x140000000)
    struct.pack_into("<II", optional, 0x20, 0x1000, 0x200)
    struct.pack_into("<HHHHHH", optional, 0x28, 6, 0, 0, 0, 6, 0)
    struct.pack_into("<I", optional, 0x40, 0)
    struct.pack_into("<II", optional, 0x44, 0x2000, 0x200)
    struct.pack_into("<I", optional, 0x50, 0)
    struct.pack_into("<H", optional, 0x54, 3)  # console
    struct.pack_into("<H", optional, 0x56, 0x8160)
    struct.pack_into("<QQQQ", optional, 0x58, 0x100000, 0x1000, 0x100000, 0x1000)
    struct.pack_into("<II", optional, 0x78, 0, 16)

    section = bytearray(40)
    section[0:8] = b".text\x00\x00\x00"
    struct.pack_into("<IIII", section, 0x08, 1, 0x1000, 0x200, 0x200)
    struct.pack_into("<II", section, 0x14, 0x200, 0)
    struct.pack_into("<I", section, 0x24, 0x60000020)

    headers = dos + b"PE\x00\x00" + coff + optional + section
    headers += b"\x00" * (0x200 - len(headers))
    code = b"\xC3" + b"\x00" * (0x200 - 1)
    return bytes(headers + code)


if __name__ == "__main__":
    destination = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("test/fixtures/dummy.exe")
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(build_pe())
