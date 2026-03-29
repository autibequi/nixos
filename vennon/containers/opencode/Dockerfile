# vennon-opencode — herda de vennon-vennon + instala opencode
FROM vennon-vennon:latest

RUN nix profile install nixpkgs#opencode && \
    cp -r /root/.nix-profile /home/claude/.nix-profile && \
    chown -R 1000:1000 /home/claude/.nix-profile
