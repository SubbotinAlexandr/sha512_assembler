# sha512_assembler

SHA-512 (FIPS 180-4) implemented in hand-written x86-64 assembly (GNU as, AT&T syntax).

## Build

```sh
make            # builds libsha512.so
make test       # compares against hashlib.sha512
```

## Usage

```c
#include <stddef.h>

void sha512(const void *data, size_t len, unsigned char out[64]);
```

```python
import ctypes
lib = ctypes.CDLL("./libsha512.so")
out = (ctypes.c_ubyte * 64)()
lib.sha512(b"abc", 3, out)
print(bytes(out).hex())
# ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad
```

## Implementation notes

- One 1024-byte stack frame per call: padding buffer, running state, working
  variables and the 80-word message schedule.
- Input is consumed block by block in 128-byte chunks; the tail is copied into
  the stack buffer, padded, and compressed as one or two final blocks.
- Message schedule is expanded into a full 80-word array, so the round loop
  needs no ring buffer arithmetic.
- Length is encoded as a 128-bit big-endian bit count, as required by the spec.
- No dynamic memory, no external dependencies, only caller-saved registers plus
  rbx inside the compression helper.
