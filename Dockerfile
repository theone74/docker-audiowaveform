FROM alpine:3.12 AS builder

ARG FLAC_VER="1.3.3"
ARG AWF_VER="master"
ARG AWF_HASH="278139abefcd9736ec889d06e11001c185dbf512"
ARG GOOGLETEST_VERSION="1.10.0"
ENV FLAC_VER=${FLAC_VER}
ENV AWF_VER=${AWF_VER}
ENV AWF_HASH=${AWF_HASH}
ENV GOOGLETEST_VERSION=${GOOGLETEST_VERSION}

RUN apk add --no-cache git make cmake gcc g++ libmad-dev libid3tag-dev libsndfile-dev gd-dev boost-dev libgd libpng-dev zlib-dev zlib-static libpng-static boost-static autoconf automake libtool gettext
RUN git config --global advice.detachedHead false

RUN git clone -b ${FLAC_VER} https://github.com/xiph/flac.git && cd flac && git rev-parse HEAD
RUN cd flac && \
	./autogen.sh && \
	./configure --enable-shared=no && \
	make && make install

RUN git clone -b ${AWF_VER} https://github.com/bbc/audiowaveform.git && cd /audiowaveform && git checkout ${AWF_HASH}
WORKDIR /audiowaveform
RUN wget https://github.com/google/googletest/archive/release-${GOOGLETEST_VERSION}.tar.gz && \
    tar xzf release-${GOOGLETEST_VERSION}.tar.gz && \
    ln -s googletest-release-${GOOGLETEST_VERSION}/googletest googletest && \
    ln -s googletest-release-${GOOGLETEST_VERSION}/googlemock googlemock
RUN mkdir /audiowaveform/build
RUN cd /audiowaveform/build && \
	cmake -D ENABLE_TESTS=1 -D BUILD_STATIC=1 .. && \
	make 
RUN ./build/audiowaveform_tests ; /bin/true

RUN apk add --no-cache file && file /audiowaveform/build/audiowaveform


FROM alpine:3.12
RUN apk add --no-cache libmad libsndfile libid3tag gd boost boost-program_options
COPY --from=builder /audiowaveform/build/audiowaveform .
