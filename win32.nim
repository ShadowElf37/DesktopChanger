proc SystemParametersInfoA(cmd: cuint, arg1: cuint, arg2: cstring, flags: cuint): bool {.importc, dynlib: "User32.dll".}

proc getDesktopWindow*(): uint64 {.importc, header: "deskhandle.h", cdecl.}
# proc GetModuleFileNameA(hmodule: pointer, into_buffer: array[MAX_PATH, char], size: cdouble): uint {.importc, dynlib: "Kernel32.dll", cdecl.}

proc setDesktop*(img_path: cstring): bool =
    # 0x0014 is set desktop command
    # 0 is nonsense
    # 3 is some flags that make it very slow but it tells windows to record that, yes, this is in fact the desktop
    SystemParametersInfoA(0x0014, 0, img_path, 3)

from os import walkDirRec, splitFile
from strutils import toLowerAscii
proc getFilesInDir*(dir: string, restrict_to: openArray[string] = []): seq[string] =
    for file in walkDirRec(dir):
        if not (restrict_to.len > 0 and splitFile(file)[2].toLowerAscii() in restrict_to):
            continue
        result.add(file)

# echo getDesktopWindow()