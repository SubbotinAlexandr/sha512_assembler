#!/usr/bin/env python3
"""Compare the assembly implementation against hashlib.sha512."""

import ctypes
import hashlib
import os
import random
import sys

LIB = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "libsha512.so")


def load():
    lib = ctypes.CDLL(LIB)
    lib.sha512.argtypes = (ctypes.c_void_p, ctypes.c_size_t, ctypes.c_void_p)
    lib.sha512.restype = None
    return lib


def digest(lib, data: bytes) -> bytes:
    out = (ctypes.c_ubyte * 64)()
    buf = ctypes.create_string_buffer(data, len(data)) if data else None
    lib.sha512(buf, len(data), out)
    return bytes(out)


def main() -> int:
    lib = load()
    sizes = [0, 1, 2, 3, 55, 56, 63, 64, 111, 112, 113, 127, 128, 129,
             240, 255, 256, 1000, 4096, 100_000]
    rnd = random.Random(20261026)
    cases = [(f"len={n}", bytes(rnd.getrandbits(8) for _ in range(n))) for n in sizes]
    cases.append(("empty", b""))
    cases.append(("abc", b"abc"))
    cases.append(("quick brown fox",
                  b"The quick brown fox jumps over the lazy dog"))
    cases.append(("million a", b"a" * 1_000_000))

    failed = 0
    for name, data in cases:
        got = digest(lib, data)
        want = hashlib.sha512(data).digest()
        if got != want:
            failed += 1
            print(f"FAIL {name}\n  got  {got.hex()}\n  want {want.hex()}")
        else:
            print(f"ok   {name}")

    print(f"\n{len(cases) - failed}/{len(cases)} passed")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
