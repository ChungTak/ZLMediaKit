rm -rf zig-build\build-windows
mkdir zig-build\build-windows
cd zig-build\build-windows
cmake ..\.. -G "Visual Studio 17 2022" -A x64 -DDISABLE_REPORT=ON -DCMAKE_BUILD_TYPE=Release ^
-DUSE_SOLUTION_FOLDERS=OFF -DENABLE_WEBRTC=ON ^
-DSRTP_PREFIX="C:\libsrtp" ^
-DSRTP_INCLUDE_DIRS="C:\libsrtp\include" ^
-DSRTP_LIBRARIES="C:\libsrtp\lib\srtp2.lib"


cmake --build . --target ALL_BUILD  --config Release --parallel