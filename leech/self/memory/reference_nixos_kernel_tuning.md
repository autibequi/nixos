---
name: reference_nixos_kernel_tuning
description: Anti-padrões e armadilhas em kernel.nix para sistemas AMD com RAM grande (32GB+)
type: reference
---

# NixOS kernel.nix — Armadilhas em sistemas AMD / RAM grande

## Settings que são no-op e podem ser removidos

- `vm.dirty_expire_centisecs = 3000` — é o **default do kernel**. Setar explicitamente não faz nada.
- `kernel.sched_autogroup_enabled = 1` — **letra morta quando SCX está ativo**. SCX substitui o CFS scheduler; o autogroup só tem efeito quando SCX não está rodando.
- `vm.compaction_proactiveness = 20` com `transparent_hugepage=madvise` — causa kswapd acordar em background para manter hugepages contíguas, mas `madvise` só serve apps que pedem hugepages explicitamente (Java, Redis). Containers Go/Node não pedem. Remover.

## Sizing de dirty_ratio para RAM grande

`vm.dirty_ratio = 20` em 48GB = ~9.6GB de writes pendentes em caso de crash. Usar valores menores:

```nix
"vm.dirty_ratio" = 10;           # ~4.8GB max em 48GB
"vm.dirty_background_ratio" = 5; # flush background começa em ~2.4GB
```

NVMe rápido não precisa de buffers tão generosos — a drive não é gargalo.

## watermark_scale_factor em RAM grande

`vm.watermark_scale_factor = 125` faz kswapd começar reclaim quando ainda tem ~6GB livres em 48GB — muito cedo. Default é `10` (~480MB). Usar `50` como meio-termo conservador que evita cliff de reclaim sem acordar kswapd o tempo todo.

## no_console_suspend

Manter console ativo durante suspend (`no_console_suspend`) é útil só para debug de kernel panics. Em produção: custo de energia e pode interferir com resume em setups Nvidia/AMD híbridos.
