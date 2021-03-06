FROM ubuntu:20.04

# needed to install tzdata in disco
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install --no-install-recommends -y \
	build-essential \
	ca-certificates \
	cmake \
	git \
	libavahi-compat-libdnssd-dev \
	libboost-dev \
	libcap-dev \
	libgrpc++-dev \
	libprotobuf-dev \
	libprotoc-dev \
	libssl-dev \
	libzeroc-ice-dev \
	pkg-config \
	protobuf-compiler \
	protobuf-compiler-grpc \
	qt5-default \
	&& rm -rf /var/lib/apt/lists/*

RUN git clone -b 1.4.0-development-snapshot-003 https://github.com/mumble-voip/mumble.git /root/mumble/

WORKDIR /root/mumble/build
RUN cmake -Dclient=OFF -DCMAKE_BUILD_TYPE=Release -Dgrpc=ON ..
RUN make -j $(nproc)

# Clean distribution stage
FROM ubuntu:20.04

RUN adduser murmur
RUN apt-get update && apt-get install --no-install-recommends -y \
	ca-certificates \
	libavahi-compat-libdnssd1 \
	libcap2 \
	libgrpc++1 \
	libgrpc6 \
	libprotobuf17 \
	libqt5core5a \
	libqt5dbus5 \
	libqt5network5 \
	libqt5sql5 \
	libqt5sql5-sqlite \
	libqt5xml5 \
	libzeroc-ice3.7 \
	&& rm -rf /var/lib/apt/lists/* 

COPY --from=0 /root/mumble/build/murmurd /usr/bin/murmurd
COPY --from=0 /root/mumble/scripts/murmur.ini /etc/murmur/murmur.ini

RUN mkdir /var/lib/murmur && \
	chown murmur:murmur /var/lib/murmur && \
	sed -i 's/^database=$/database=\/var\/lib\/murmur\/murmur.sqlite/' /etc/murmur/murmur.ini

EXPOSE 64738/tcp 64738/udp 50051
USER murmur

CMD /usr/bin/murmurd -v -fg -ini /etc/murmur/murmur.ini
