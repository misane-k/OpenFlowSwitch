clear
# -Wall
verilator -MMD --build --cc --exe --trace-fst \
  -O3 -j 0 -DDPIC -CFLAGS -g -LDFLAGS -lpcap \
  top.sv *.cpp
