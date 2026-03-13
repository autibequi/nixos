# M5 — Propostas de Otimização (Ciclos 1 + 2)

## Quick Wins — Baixo Esforço, Alto Impacto

---

### 1. Remover Inputs Mortos do Flake
**Situação:** `flake.nix` carrega 4 inputs que não são usados em lugar algum:
- `voxtype` — comentado em packages.nix
- `zed` — comentado, usa `unstable.zed-editor` no lugar
- `antigravity-nix` — comentado
- `nixified-ai` — módulo `comfyui` carregado mas sem `services.comfyui` configurado

**Proposta:** Remover as 4 entradas de `inputs {}` e do `outputs` em `flake.nix`.

**Impacto:** `flake update` ~25% mais rápido. `flake.lock` mais enxuto. Sem side effects.

---

### 2. Corrigir Nix Build Parallelism
**Situação:** `nix.settings.cores = 0` significa que cada build job usa 100% dos cores. Com `max-jobs = "auto"`, múltiplos jobs tentam usar todos os 16 threads simultaneamente.

**Proposta:** `modules/core/nix.nix`
```nix
nix.settings = {
  max-jobs = 4;   # 4 builds paralelas
  cores = 4;      # cada job usa 4 threads = 16 threads totais, previsível
};
```

**Impacto:** Elimina thrashing em builds pesadas (LLVM, Rust). Sistema fica responsivo durante rebuild.

---

### 3. Reativar TLP Parcialmente (Apenas Power Management de Hardware)
**Situação:** `tlp.nix` existe com configurações valiosas mas está comentado. Auto-epp cuida do CPU EPP, mas **não gerencia**: NVME power saving, PCIe ASPM, platform profile.

**Proposta:** Descomentar `./modules/tlp.nix` em `configuration.nix` — mas remover os settings de CPU governor que conflitam com auto-epp:
```nix
# Remover do tlp.nix (auto-epp já faz isso):
# CPU_SCALING_GOVERNOR_ON_AC / _BAT
# CPU_ENERGY_PERF_POLICY_ON_AC / _BAT

# Manter (auto-epp NÃO faz):
NVME_POWER_SAVING_ON_BAT = 1;       # +0.5-1W economia
PCIE_ASPM_ON_BAT = "powersave";     # +1-2W economia
PLATFORM_PROFILE_ON_BAT = "low-power";  # fan curve BIOS
```

**Impacto estimado:** +1.5-3W de economia na bateria (20-40min a mais de autonomia).

---

### 4. Aumentar HibernateDelaySec
**Situação:** `HibernateDelaySec=30m` — com suspensão s2idle consumindo ~5-10% bateria por hora, 30min significa hibernação frequente se esquecer laptop suspenso.

**Proposta:** `modules/core/hibernate.nix`
```nix
HibernateDelaySec = "60m";   # era 30m
```

**Impacto:** Bateria sobrevive bem a sessões de suspensão de 1h+ sem despertar para hibernar.

---

### 5. Ativar TCP BBR + Buffers Grandes
**Situação:** Kernel atual usa congestion control `cubic` (padrão). Sem configuração de rmem/wmem.

**Proposta:** Adicionar em `modules/core/kernel.nix` sysctl:
```nix
# TCP BBR (melhor para WiFi 6 + links com perda)
"net.core.default_qdisc" = "fq";
"net.ipv4.tcp_congestion_control" = "bbr";

# Buffers TCP maiores (16MB) para throughput em Gigabit/WiFi 6
"net.core.rmem_max" = 16777216;
"net.core.wmem_max" = 16777216;
"net.ipv4.tcp_rmem" = "4096 87380 16777216";
"net.ipv4.tcp_wmem" = "4096 65536 16777216";

# SYN flood protection (faltava)
"net.ipv4.tcp_syncookies" = 1;

# TCP window scaling (necessário para buffers > 64KB)
"net.ipv4.tcp_window_scaling" = 1;
```

**Requer:** `boot.kernelModules = [ "tcp_bbr" ]` (ou está no CachyOS built-in).

**Impacto:** +30% throughput em WiFi com perda de pacote. Sem impacto em LAN Gigabit limpa.

---

### 6. Limpar Redundâncias em Packages

**6a. Remover `tailscale` dos packages (já incluído pelo serviço):**
```nix
# packages.nix — remover esta linha:
tailscale   # serviço em services.nix já adiciona o pacote
```

**6b. Remover `rocmPackages.rocm-smi` (btop-rocm já cobre AMD):**
```nix
# shell.nix — remover:
rocmPackages.rocm-smi   # btop-rocm já mostra stats AMD
```

**6c. Consolidar Rust toolchain:**
```nix
# shell.nix — problema: rustup + rustc + cargo juntos criam PATH ambíguo
# Opção A: manter rustup, remover rustc/cargo/rustfmt do nix (rustup gerencia)
# Opção B: remover rustup, manter rustc/cargo/rustfmt do nixpkgs

# Recomendação: Opção A (rustup é mais flexível para múltiplas versões)
# Remover: rustc, cargo, rustfmt (manter: rustup, rust-analyzer)
```

---

## Médio Prazo — Investigação Necessária

### 7. `mitigations=auto,nosmt` vs `mitigations=off`
(Mantido do Ciclo 1 — decisão do usuário sobre trade-off segurança/perf)

### 8. NVIDIA Persistenced
`nvidiaPersistenced=true` se roda AI/ML local frequente. Medir com `nvidia-smi` idle W.

### 9. Mover Packages Pesados para Home-Manager
`onlyoffice-desktopeditors`, `sidequest`, `cool-retro-term`, `godot`, `geekbench` raramente precisam estar no sistema global. Mover para `home.packages` no home-manager reduz rebuild do sistema.

---

---

## Ciclo 4 — Novas Oportunidades: Hyprland, AI, Filesystem, Programs

### 9. VRR/Freesync para AMD Radeon 780M (165Hz Display)

**Situação:** G14 tem tela 165Hz com Radeon 780M iGPU que suporta freesync. Hyprland pode ativar VRR por workspace (dotfile), mas **requer kernel param para AMD funcionar**: `amdgpu.freesync_video=1`.

**Proposta:** Adicionar em `modules/core/kernel.nix` boot parameters:
```nix
boot.kernelParams = [
  "amdgpu.freesync_video=1"  # Enable VRR for AMD integrated GPU
];
```

**Impacto:** Tearing zero em jogos/vídeos com AMD iGPU, sem custo de performance. Hyprland já ativa por workspace no dotfile.

---

### 10. Remover wl-clipboard Duplicado

**Situação:** `wl-clipboard` instalado em `hyprland.nix:79` E `wl-clipboard-rs` em `programs.nix:19`. Ambos fornecem `wl-copy`/`wl-paste` — conflito de PATH potencial.

**Proposta:** Remover `wl-clipboard` de `hyprland.nix`, manter apenas `wl-clipboard-rs`:
```nix
# hyprland.nix — remover esta linha:
wl-clipboard   # mantém wl-clipboard-rs em programs.nix
```

**Impacto:** Evita conflito de binários, rebuild mais limpa. Rust impl é mais mantida.

---

### 11. Refinar Mount Options ext4 para NVMe

**Situação:** `hardware.nix` usa `options = ["defaults" "noatime"]`. Para NVMe moderno, cabe refinar:

**Proposta:** `hardware.nix` → root filesystem:
```nix
fileSystems."/" = {
  device = "/dev/disk/by-uuid/...";
  fsType = "ext4";
  options = [
    "defaults"
    "noatime"
    "nodiscard"      # fstrim semanal (kernel.nix) já faz, sem overhead contínuo
    "errors=continue" # não parar em single-bit error
    "discard=async"   # async TRIM quando possível (2.6.37+)
  ];
};
```

**Impacto:** Melhor I/O previsibilidade. Sem impacto negativo (fstrim semanal já existe).

---

### 12. Verificar GPU Acceleration em lmstudio

**Situação:** `lmstudio` instalado globalmente mas **sem CUDA/ROCm explícito** no sistema. LMStudio bundla libs, mas em NixOS pode não encontrar GPU drivers.

**Proposta:** Diagnóstico manual:
```sh
lmstudio → settings → performance → verificar GPU detectada
```

Se GPU não detectada, considerar:
```nix
# modules/core/packages.nix — adicionar se lmstudio não roda em GPU:
cudaPackages.cudatoolkit
# ou (para ROCm AMD):
rocmPackages.rocm-core
rocmPackages.hipblas
```

**Impacto:** Se lmstudio roda em GPU, perf +10-20x. Atual: provavelmente CPU-only.

---

---

## Ciclo 5 — Novas Propostas

### 13. Corrigir Dynamic-Cursors Plugin Mismatch

**Situacao:** `stow/.config/hypr/plugins/dynamic-cursors.conf` executa `hyprctl plugin load "$HYPR_PLUGIN_DIR/lib/libhypr-dynamic-cursors.so"` no startup. Porem em `modules/hyprland.nix` o plugin esta comentado (linha 17) — o `.so` nunca e compilado no `HYPR_PLUGIN_DIR`.

**Resultado:** Hyprland tenta carregar um `.so` inexistente no startup. Dependendo da versao, pode gerar erro silencioso ou mensagem no journal (`journalctl --user -u hyprland`).

**Proposta:** Habilitar o plugin em `modules/hyprland.nix`:
```nix
hypr-plugin-dir = pkgs.symlinkJoin {
  name = "hyrpland-plugins";
  paths = (with unstable.hyprlandPlugins; [
    hypr-dynamic-cursors   # descomentar esta linha
  ]) ++ [ ... ];
};
```

**Impacto:** Cursor com animacao de tilt (ja configurado no dotfile). Zero overhead de performance — apenas efeito visual. Corrige erro silencioso de startup.

---

### 14. Consolidar Triple-Clipboard

**Situacao:** `wl-clipboard` aparece em tres modulos distintos:
- `modules/hyprland.nix:79` — `wl-clipboard`
- `modules/whisper-ptt.nix:32` — `wl-clipboard`
- `modules/core/programs.nix:20` — `wl-clipboard-rs`

`wl-clipboard` e `wl-clipboard-rs` fornecem os mesmos binarios (`wl-copy`, `wl-paste`). O PATH acaba com ambos, e o comportamento depende de qual vem primeiro.

**Proposta:** Remover `wl-clipboard` dos dois modulos que o duplicam:
```nix
# modules/hyprland.nix — remover linha 79:
# wl-clipboard

# modules/whisper-ptt.nix — remover linha 32:
# wl-clipboard
```
Manter apenas `wl-clipboard-rs` em `programs.nix` (Rust, mais mantido, API identica).

**Impacto:** PATH sem ambiguidade. `cliphist` e `wl-paste` chamam sempre o mesmo binario.

---

## Status Geral (Ciclos 1-5)
- **Ciclo 1:** Analise kernel, NVIDIA, ASUS, services, packages, flake
- **Ciclo 2:** TLP, nix build, flake inputs, hibernate, network, packages redundancy
- **Ciclo 3:** Hyprland config (EXCELENTE), AI module (LIMPO), Filesystem (TOP-TIER)
- **Ciclo 4:** Programs, package redundancy validation, VRR kernel param
- **Ciclo 5:** Profiling readiness, whisper-ptt CUDA padrao, plugin mismatch, triple-clipboard
- **Ciclo 6 (proximo):** Conclusoes finais + implementation guide

## Tabela de Prioridades Final (Ciclos 1-5)
| # | Proposta | Arquivo | Impacto | Esforco | Prioridade |
|---|----------|---------|---------|---------|------------|
| 2 | Remover inputs mortos flake | flake.nix | Alto | Baixo | CRITICO |
| 2 | Fix nix build thrashing | core/nix.nix | Alto | Baixo | CRITICO |
| 13 | Fix plugin mismatch dynamic-cursors | hyprland.nix | Medio | Baixo | IMPORTANTE |
| 14 | Consolidar triple-clipboard | hyprland.nix + whisper-ptt.nix | Baixo | Baixo | IMPORTANTE |
| 3 | Remover tailscale duplicado | core/packages.nix | Baixo | Baixo | IMPORTANTE |
| 6 | Remover google-chrome | core/packages.nix | Medio | Baixo | IMPORTANTE |
| 4 | HibernateDelaySec=60m | core/hibernate.nix | Medio | Baixo | IMPORTANTE |
| 9 | amdgpu.freesync_video=1 | core/kernel.nix | Alto | Baixo | REFINAMENTO |
| 5 | TCP BBR + buffers | core/kernel.nix | Medio | Baixo | REFINAMENTO |
| 7 | mitigations decision | core/kernel.nix | Baixo | Zero | DECISAO DO USUARIO |
