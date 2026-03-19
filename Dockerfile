FROM nixos/nix

# 1. Enable Flakes and nix-command (needed for modern Nix tools)
RUN set -eux \
	&& mkdir -p /etc/nix && echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf

# 2. Update channels and install basic tools + home-manager
RUN set -eux \
	&& nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager \
	&& nix-channel --update

# This handles the pre-installed git/nix collisions automatically
RUN nix profile install \
	--priority 4 \ 
    nixpkgs#python3 \
    nixpkgs#gemini-cli \
    nixpkgs#coreutils-full \
    nixpkgs#git \
    nixpkgs#home-manager \
    nixpkgs#nix \
    nixpkgs#curl \
    nixpkgs#wget \
    nixpkgs#gnutar \
    nixpkgs#gzip

# 4. Critical PATH setup
# Note: nix profile uses a different path than nix-env
ENV PATH="/root/.nix-profile/bin:${PATH}"

ENTRYPOINT ["gemini"]
# We leave CMD empty so that by default, no extra args are passed,
# triggering the CLI's internal interactive mode.
CMD []
