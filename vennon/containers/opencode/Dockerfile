# vennon-opencode — herda de vennon-leech + instala opencode
FROM vennon-leech:latest

RUN nix profile install nixpkgs#opencode && \
    cp -r /root/.nix-profile /home/claude/.nix-profile && \
    chown -R 1000:1000 /home/claude/.nix-profile
