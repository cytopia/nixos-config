FROM nixos/nix

# 1. Update the channels
RUN nix-channel --update

# 2. Install packages
RUN set -eux \
	&& nix-env -iA \
		nixpkgs.python3 \
		nixpkgs.gemini-cli

# 3. CRITICAL: Add the Nix profile to the PATH
ENV PATH="/root/.nix-profile/bin:${PATH}"

ENTRYPOINT ["gemini"]
# We leave CMD empty so that by default, no extra args are passed,
# triggering the CLI's internal interactive mode.
CMD []
