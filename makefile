.PHONY: lock-hardware unlock-hardware

lock-hardware:
	git add hardware.nix
	git update-index --skip-worktree hardware.nix

unlock-hardware:
	git update-index --no-skip-worktree hardware.nix
