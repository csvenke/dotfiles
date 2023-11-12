# Start from a base image with Nix pre-installed
FROM nixos/nix

# Install Zsh and direnv
RUN nix-env -iA nixpkgs.zsh nixpkgs.direnv

# Set the default shell to Zsh
SHELL ["/root/.nix-profile/bin/zsh", "-c"]

# Install Oh My Zsh
RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Copy your local files into the Docker image
COPY . /.dotfiles

# Run nix-shell dotfiles init command
RUN nix-shell /.dotfiles/scripts --command dotfiles-init

# Run nix-shell dotfiles check command
RUN nix-shell /.dotfiles/scripts --command dotfiles-check

# Start Zsh when the container runs
CMD ["/root/.nix-profile/bin/zsh"]
