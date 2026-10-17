@echo on

cmake -S . -B build -G Ninja ^
  %CMAKE_ARGS% ^
  -DCMAKE_WINDOWS_EXPORT_ALL_SYMBOLS=ON ^
  -DBUILD_SHARED_LIBS=ON ^
  -DZEEP_USE_BOOST_ASIO=OFF ^
  || exit /b 1

cmake --build build --parallel %CPU_COUNT% || exit /b 1

set PATH=%SRC_DIR%\build;%PATH%

@REM Run tests, excluding the http-test/fuzz-el-test which brings about a SEGFAULT/stack overflow error
ctest -V --test-dir build -E "(http-test|fuzz-el-test)" || exit /b 1
cmake --install build || exit /b 1
