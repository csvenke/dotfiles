# Start from a base image with Nix pre-installed
FROM nixos/nix

# Install Zsh
RUN nix-env -iA nixpkgs.zsh

# Set the default shell to Zsh
SHELL ["/root/.nix-profile/bin/zsh", "-c"]

# Install Oh My Zsh
RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Copy your local files into the Docker image
COPY . /.dotfiles

# Run install script
RUN sh /.dotfiles/scripts/install.sh

# Run check script
RUN sh /.dotfiles/scripts/check.sh

# Start Zsh when the container runs
CMD ["/root/.nix-profile/bin/zsh"]
