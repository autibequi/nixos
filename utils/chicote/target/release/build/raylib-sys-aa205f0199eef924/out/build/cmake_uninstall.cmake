if(NOT EXISTS "/home/pedrinho/nixos/utils/chicote/target/release/build/raylib-sys-aa205f0199eef924/out/build/install_manifest.txt")
  message(FATAL_ERROR "Cannot find install manifest: /home/pedrinho/nixos/utils/chicote/target/release/build/raylib-sys-aa205f0199eef924/out/build/install_manifest.txt")
endif()

file(READ "/home/pedrinho/nixos/utils/chicote/target/release/build/raylib-sys-aa205f0199eef924/out/build/install_manifest.txt" files)
string(REGEX REPLACE "\n" ";" files "${files}")
foreach(file ${files})
  message(STATUS "Uninstalling $ENV{DESTDIR}${file}")
  if(IS_SYMLINK "$ENV{DESTDIR}${file}" OR EXISTS "$ENV{DESTDIR}${file}")
    exec_program(
      "/nix/store/k1b82rs72af124wmq6nb00nhw5i7ikp7-cmake-4.1.2/bin/cmake" ARGS "-E remove \"$ENV{DESTDIR}${file}\""
      OUTPUT_VARIABLE rm_out
      RETURN_VALUE rm_retval
      )
    if(NOT "${rm_retval}" STREQUAL 0)
      message(FATAL_ERROR "Problem when removing $ENV{DESTDIR}${file}")
    endif()
  else(IS_SYMLINK "$ENV{DESTDIR}${file}" OR EXISTS "$ENV{DESTDIR}${file}")
    message(STATUS "File $ENV{DESTDIR}${file} does not exist.")
  endif()
endforeach()
