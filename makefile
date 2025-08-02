.PHONY: lock-hardware unlock-hardware

lock-hardware:
	git update-index --skip-worktree hardware.nix

unlock-hardware:
	git update-index --no-skip-worktree hardware.nix
