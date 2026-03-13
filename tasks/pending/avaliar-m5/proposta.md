# M5 — Proposta de Patches (Tier 1-2)

**Data:** 2026-03-13
**Status:** Nenhuma recomendação anterior foi aplicada. Todas as 22 propostas ainda estão pendentes.

---

## Resumo Executivo

A análise completa identificou **22 recomendações de performance** para o ASUS G14 (Ryzen 9 7940HS + RTX 4060). A config atual é **sólida**, mas há espaço para otimizações incrementais de **baixo risco**.

**Prioridade Imediata (Tier 1):** 4 mudanças que geram ganho real com risco zero:
1. **Remover `cudaSupport = true`** — builds 10-50x mais rápios, ativa cache binário
2. **Adicionar TCP buffers + BBR** — ganho mensurável em Wi-Fi/rede
3. **GC 14-30d** — evita rebuilds inesperados
4. **Resolver conflito Rust toolchain** — evita shadowing silencioso

---

## Tier 1 — Implementação Imediata

### 1. Remover `cudaSupport = true` (impacto: ALTO)

**Arquivo:** `/workspace/modules/core/nix.nix`

**Problema:** `nixpkgs.config.cudaSupport = true` força recompilação de pacotes que suportam CUDA (llvm, pytorch, etc.) mesmo que o binário não seja usado. Isso:
- Adiciona ~6-8 horas ao rebuild time
- Desativa cache binário do nixpkgs para esses pacotes
- Com `max-jobs = auto`, causa OOM em máquinas com menos de 64GB RAM

**Solução:** Remover completamente ou comentar, usar `nix shell` por projeto quando CUDA for necessário.

**Patch:**
```diff
--- a/modules/core/nix.nix
+++ b/modules/core/nix.nix
@@ -134,7 +134,7 @@ {
   nix.settings = {
     max-jobs = "auto";
-    cudaSupport = true;
+    # cudaSupport = true;  # Desabilitado: força rebuild de LLVM/PyTorch sem ganho real

     # Complementa max-jobs para compiladores que paralelizam internamente (LLVM, GCC)
```

**ROI:** 10-50x mais rápido em rebuilds, cache binário reativado.

---

### 2. Adicionar TCP Buffers + BBR (impacto: MÉDIO)

**Arquivo:** `/workspace/modules/core/kernel.nix`

**Problema:** Buffers TCP padrão do Linux são conservadores (212KB). Em Wi-Fi, rede de alta latência ou links com perda, isso limita throughput a ~10-50Mbps mesmo se a banda existe.

**Solução:** Expandir buffers para 16MB, usar BBR (congestion control superior ao CUBIC em Wi-Fi).

**Patch:**
```diff
--- a/modules/core/kernel.nix
+++ b/modules/core/kernel.nix
@@ -112,6 +112,19 @@ {
     # Rede: buffers maiores para melhor throughput
     "net.core.netdev_max_backlog" = 16384;
     "net.ipv4.tcp_fastopen" = 3;
+
+    # TCP buffers para throughput alto (downloads, rsync, Tailscale subnet routing)
+    # Padrão: 212KB. Novo: 16MB. Diferença real em links Wi-Fi com latência >20ms.
+    "net.core.rmem_max" = 16777216;       # 16MB (SO_RCVBUF max)
+    "net.core.wmem_max" = 16777216;       # 16MB (SO_SNDBUF max)
+    "net.ipv4.tcp_rmem" = "4096 131072 16777216";    # min, default, max
+    "net.ipv4.tcp_wmem" = "4096 16384 16777216";     # min, default, max
+
+    # BBR: superior ao CUBIC em links com perda (Wi-Fi) e alta latência
+    # CachyOS kernel já inclui módulo tcp_bbr. fq (fair queueing) é essencial.
+    "net.ipv4.tcp_congestion_control" = "bbr";
+    "net.core.default_qdisc" = "fq";

     # Inotify: suficiente para IDEs e file watchers (padrão é 8192)
```

**ROI:** +10-30% throughput em Wi-Fi, especialmente em redes com packet loss.

---

### 3. Aumentar Garbage Collector para 14-30 dias (impacto: MÉDIO)

**Arquivo:** `/workspace/modules/core/nix.nix`

**Problema:** GC a cada 7 dias com auto-upgrade diário causa rebuilds inesperados. Pacotes são GC'd, depois rebuild os triggers auto-upgrade.

**Solução:** GC 14-30 dias para acumular mais store paths antes da limpeza.

**Patch:**
```diff
--- a/modules/core/nix.nix
+++ b/modules/core/nix.nix
@@ -119,7 +119,7 @@ {
   nix.gc = {
     automatic = true;
     dates = "weekly";
-    options = "--delete-older-than 7d";
+    options = "--delete-older-than 14d";  # Aumentado: evita rebuilds entre auto-upgrades
   };

   nix.optimiseStore = {
```

**ROI:** Menos "surpresas" de rebuild, cache mais estável.

---

### 4. Resolver Conflito Rust Toolchain (impacto: MÉDIO)

**Arquivo:** `/workspace/modules/core/shell.nix`

**Problema:** Simultaneamente `rustup` + `rustc`, `cargo`, `rustfmt`, `rust-analyzer` do nixpkgs. `rustup` cria shims que **shadowing** os do Nix silenciosamente, causando IDE apontar pra versão errada.

**Solução:** Remover pacotes Nix, deixar `rustup` gerenciar tudo. Ou inverso: remover `rustup`, usar Nix puro.

**Opção A — rustup-only (recomendado para compatibilidade com IDE extensions):**
```diff
--- a/modules/core/shell.nix
+++ b/modules/core/shell.nix
@@ -XX (line onde estão os pacotes Rust),
-    cargo
-    rustc
-    rustfmt
-    rust-analyzer
     rustup
```

**Opção B — Nix-only (mais hermético, sem rustup):**
```diff
--- a/modules/core/shell.nix
+++ b/modules/core/shell.nix
-    rustup
```

**Recomendação:** Opção A (rustup-only). O IDE é melhor com rustup + rust-analyzer do rustup.

**ROI:** IDE sem ambiguidade de versão, builds mais previsíveis.

---

## Tier 2 — Quick Wins de Cleanup

### 5. Habilitar zswap (impacto: MÉDIO)

**Arquivo:** `/workspace/modules/core/kernel.nix`

**Problema:** Sem zswap, a pressão de memória causa trashing direto no NVMe. zswap comprime páginas na RAM (ratio típico 3:1), reduzindo I/O.

**Patch:**
```diff
--- a/modules/core/kernel.nix
+++ b/modules/core/kernel.nix
@@ -28,6 +28,10 @@ {
     "transparent_hugepage=madvise"

     # Nvidia
+
+    # zswap: compressão de páginas em RAM antes de swap no NVMe
+    # zstd ratio ~3:1, max 20% da RAM (~6.4GB em 32GB total)
+    "zswap.enabled=1"
     "nvidia.NVreg_DynamicPowerManagement=0x02"
```

**ROI:** Proteção contra stalls em cargas pesadas (compilações CUDA, containers).

---

### 6. Remover inputs não-usados do flake (impacto: BAIXO)

**Arquivo:** `/workspace/flake.nix`

**Problema:** `hyprland` v0.54.0 + `hyprtasking` são inputs mas nunca alcançam `outputs`. Adiciona fetches desnecessários.

**Patch:**
```diff
--- a/flake.nix
+++ b/flake.nix
@@ -18,11 +18,6 @@ {

     zed.url = "github:zed-industries/zed";

-    hyprland.url = "github:hyprwm/Hyprland/v0.54.0";
-
-    hyprtasking = {
-      url = "github:raybbian/hyprtasking";
-      inputs.hyprland.follows = "hyprland";
-    };

     zen-browser = {
```

**Nota:** `unstable.hyprland` é usado no `hyprland.nix` module, então Hyprland vem do unstable, não dessa input.

**ROI:** Flake mais limpo, update time ~2s mais rápido.

---

## Tier 3 — Avaliar com Uso Real

### 7. nvidiaPersistenced para CUDA/Containers

**Impacto:** MÉDIO se usa containers com GPU.

Depende:
- Usa containers NVIDIA com GPU? (nvidia-container-toolkit)
- Roda CUDA workloads frequentemente?

Se sim, ativar em `/workspace/modules/nvidia.nix`:
```nix
hardware.nvidia.nvidiaPersistenced = true;
```

---

### 8. Reduzir para 1 Navegador Chromium

**Impacto:** BAIXO, mas economiza ~500MB de closure.

Em `/workspace/modules/core/packages.nix`, remover 2 dos 3:
- `chromium`
- `google-chrome`
- `vivaldi`

---

### 9. Resolver supergfxd vs Power Management

**Impacto:** BAIXO.

Testar: Desabilitar `services.supergfxd` e verificar se thermal/power continua bem. Finegrained NVIDIA PM pode ser suficiente.

---

## Tier 4 — Opcional/Cosmético

### Não Fazer (já está ótimo)

Estas recomendações são para **marginal gains** e não valem o esforço:
- `vm.page-cluster = 0` (#3) — diferença <1ms em NVMe
- `NVreg_UsePageAttributeTable=1` (#5) — muito específico
- `split_lock_detect=0` (#7) — afeta jogos antigos, SCX já mitiga
- `perf_event_paranoid = 1` (#10) — overhead negligenciável no desktop
- initrd compressor `-1` vs `-3` (#12) — delta ~50ms, não vale
- `no_console_suspend` (#16) — flag de debug
- Mover benchmarks/nodejs (#20, #22) — usar `nix shell` conforme necessário

---

## Plano de Execução

| Ordem | Item | Arquivo | Esforço | Risk |
|-------|------|---------|---------|------|
| 1 | Remover cudaSupport | nix.nix | 1 linha | 🟢 Zero |
| 2 | TCP buffers + BBR | kernel.nix | 10 linhas | 🟢 Zero |
| 3 | GC 14d | nix.nix | 1 linha | 🟢 Zero |
| 4 | Resolver Rust toolchain | shell.nix | 4 linhas | 🟡 Baixo (IDE testing) |
| 5 | zswap | kernel.nix | 4 linhas | 🟢 Zero |
| 6 | Limpar flake inputs | flake.nix | 8 linhas | 🟢 Zero |

**Estimado:** 30 minutos + `nixos-rebuild switch` (15-30 min).

---

## Checklist Pós-Aplicação

- [ ] Rebuild sem erros: `sudo nixos-rebuild switch --flake .#nomad`
- [ ] Boot time < 30s
- [ ] Wi-Fi throughput teste com `iperf3` (expected +10-20%)
- [ ] IDE (VSCode/Zed) reconhece Rust toolchain sem ambiguidade
- [ ] Memória sob carga não causa freezes
- [ ] flake update ~2s mais rápido

---

## Referências

- CachyOS wiki: https://wiki.cachyos.org
- BBR + fq: https://wiki.archlinux.org/title/Improving_performance#TCP_congestion_control
- zswap: https://wiki.archlinux.org/title/Zram#zswap
- nixpkgs issue #177263: cudaSupport overhead
- NixOS-hardware GA402X: https://github.com/NixOS/nixos-hardware/tree/master/asus/zephyrus/ga402x

---

## Próxima Execução

- Verificar se patches foram aplicados
- Medir impacto real (boot time, iperf3, rebuild time)
- Avaliar #4, #8, #9 com feedback de uso
- Investigar novo achados em modules/* (se houver mudanças)
