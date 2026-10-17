set -exo pipefail

export CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"

if [[ ${build_platform} != ${target_platform} ]]; then
    extra_cmake_args="-DCMAKE_CROSSCOMPILING=ON -DTEST_STD_CHRONO_FROM_STREAM_R=ON"
    if [[ ${target_platform} == linux-* ]]; then
        extra_cmake_args+=" -DTEST_STD_CHRONO_ZONED_TIME_R=0"
    else
        extra_cmake_args+=" -DTEST_STD_CHRONO_ZONED_TIME_R=ON"
    fi
fi

cmake -S . -B build -G Ninja \
  ${CMAKE_ARGS} \
  -DBUILD_SHARED_LIBS=ON \
  -DZEEP_USE_BOOST_ASIO=OFF \
  ${extra_cmake_args}
cmake --build build --parallel ${CPU_COUNT}

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" || "${CROSSCOMPILING_EMULATOR}" != "" ]]; then
    if [[ "${target_platform}" == "linux-ppc64le" && -n "${QEMU_LD_PREFIX:-}" ]]; then
        # Resolve date::current_zone() through the QEMU sysroot.
        test -f "${PREFIX}/share/zoneinfo/UTC"
        mkdir -p "${QEMU_LD_PREFIX}/etc"
        ln -sfn "${PREFIX}/share/zoneinfo/UTC" "${QEMU_LD_PREFIX}/etc/localtime"

        # QEMU rewrites /proc/self/exe, but not another process's exe.
        # Skip daemon PID checks while retaining the other HTTP tests.
        ctest -V --test-dir build -E '^(http|daemon)-test$'
        (
            cd build/test
            ${CROSSCOMPILING_EMULATOR} ./http-test \
                "~webapp_8" --docroot "${SRC_DIR}/test"
        )
    else
        ctest -V --test-dir build
    fi
fi

cmake --install build
