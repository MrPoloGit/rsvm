--timing
-j 0
-Wall
-Wno-fatal
--assert
--trace-fst
--trace-structs

# Deterministic X behavior in sim:
--x-assign unique
--x-initial unique

# Promote common problems to errors:
-Werror-IMPLICIT
-Werror-USERERROR
-Werror-LATCH
