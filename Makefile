.PHONY: all
all: Debug/libDatagramSocket.so

.PHONY: clean
clean:
	rm -f Debug/libDatagramSocket.so

Debug/libDatagramSocket.so: src/DatagramSocket.c
	@mkdir -p Debug
	gcc -fPIC -O3 -I /usr/lib/swi-prolog/include -shared -o $@ $<

