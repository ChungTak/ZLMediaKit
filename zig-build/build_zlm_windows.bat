mkdir zig-build/build-windows
cd zig-build/build-windows
cmake ../.. -DDISABLE_REPORT=ON ^
    -DUSE_SOLUTION_FOLDERS=OFF ^
    -DOPENSSL_ROOT_DIR="../install/openssl/x86_64-windows-gnu/" ^
    -DOPENSSL_LIBRARIES="../install/openssl/x86_64-windows-gnu/lib/" ^
    -DENABLE_WEBRTC=ON ^
    -DENABLE_SCTP=ON ^
    -DSRTP_INCLUDE_DIRS="../install/libsrtp/x86_64-windows-gnu/include/" ^
    -DSRTP_LIBRARIES="../install/libsrtp/x86_64-windows-gnu/lib/libsrtp2.a" ^
    -DCMAKE_BUILD_TYPE=Release

cmake --build . --target ALL_BUILD --parallel