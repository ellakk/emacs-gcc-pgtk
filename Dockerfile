FROM ubuntu:22.04
WORKDIR /opt
ENV DEBIAN_FRONTEND=noninteractive

RUN sed -i 's/# deb-src/deb-src/' /etc/apt/sources.list &&\
    apt-get update && apt-get install --yes --no-install-recommends  \
    apt-transport-https\
    ca-certificates\
    build-essential \
    autoconf \
    gcc-10 \
    pkg-config \
    libgnutls28-dev \
    libasound2-dev \
    libacl1-dev \
    libgtk-3-dev \
    libgpm-dev \
    liblockfile-dev \
    libm17n-dev \
    libotf-dev \
    libsystemd-dev \
    libjansson-dev \
    libgccjit-10-dev \
    libgif-dev \
    librsvg2-dev  \
    libxml2-dev \
    libxpm-dev \
    libtiff-dev \
    libjbig-dev \
    libncurses-dev\
    liblcms2-dev\
    libwebp-dev\
    libsqlite3-dev \
    texinfo \
    wget


# Clone emacs
RUN update-ca-certificates \
    && wget https://gnuftp.uib.no/emacs/emacs-28.1.tar.xz \
    && tar xf emacs-28.1.tar.xz \
    && mv emacs-28.1/* .

# Build
ENV CC="gcc-10"
RUN ./autogen.sh && ./configure \
    --prefix "/usr/local" \
    --with-native-compilation \
    --with-pgtk \
    --with-json \
    --with-gnutls  \
    --with-rsvg  \
    --without-xwidgets \
    --without-toolkit-scroll-bars \
    --without-xaw3d \
    --with-mailutils \
    CFLAGS="-O2 -pipe"

RUN make NATIVE_FULL_AOT=1 -j $(nproc)

# Create package
RUN EMACS_VERSION=$(sed -ne 's/AC_INIT(GNU Emacs, \([0-9.]\+\), .*/\1/p' configure.ac) \
    && make install prefix=/opt/emacs-gcc-pgtk_${EMACS_VERSION}/usr/local \
    && mkdir emacs-gcc-pgtk_${EMACS_VERSION}/DEBIAN && echo "Package: emacs-gcc-pgtk\n\
Version: ${EMACS_VERSION}\n\
Section: base\n\
Priority: optional\n\
Architecture: amd64\n\
Depends: libc6, libc6-dev, libgif7, libotf1, libgccjit0, libgcc-s1, libm17n-0, libgtk-3-0, librsvg2-2, libtiff5, libjansson4, libacl1, libgmp10, libwebp7, libsqlite3-0\n\
Maintainer: konstare\n\
Description: Emacs with native compilation and pure GTK\n\
    --with-native-compilation\n\
    --with-pgtk\n\
    --with-json\n\
    --with-gnutls\n\
    --with-rsvg\n\
    --without-xwidgets\n\
    --without-toolkit-scroll-bars\n\
    --without-xaw3d\n\
    --with-mailutils\n\
 CFLAGS='-O2 -pipe'" \
    >> emacs-gcc-pgtk_${EMACS_VERSION}/DEBIAN/control \
    && dpkg-deb --build emacs-gcc-pgtk_${EMACS_VERSION} \
    && mkdir /opt/deploy \
    && mv /opt/emacs-gcc-pgtk_*.deb /opt/deploy
