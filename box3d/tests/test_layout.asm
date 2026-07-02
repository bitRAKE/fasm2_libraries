; Assembles the fasm2 bindings against the C compiler's layout ground truth.
; layout_check.inc is produced by gen_layout.py + the MSVC-compiled probe.
; Any offset, size, or constant mismatch fails assembly with an assert error.

include 'box3d.inc'
include 'layout_check.inc'
