---
name: self:context:boot-debug
description: Debug do pipeline de boot — mostra o que foi carregado nesta sessão, flags ativas, lazy-loads pendentes e recomendações de otimização.
---

# /self:context:boot-debug — Boot Pipeline Debug

Radiografia do session-start: o que foi injetado, o que ficou de fora, por quê.
Útil para entender contexto inicial, diagnosticar comportamento inesperado e otimizar o boot.

---

## Executar

### 1. Coletar estado do boot

Ler o `session-start.sh` para mapear a lógica de decisão:

```bash
cat /home/claude/.claude/hooks/session-start.sh
```

Detectar valores atuais das flags a partir do contexto de boot injetado no início da sessão.

### 2. Detectar flags e estado real

Para cada flag, determinar:
- **Mecanismo de ativação** (`~/.leech KEY=` ou variável de processo)
- **Default** (o que acontece sem intervenção)
- **Valor nesta sessão** (ON/OFF/0/1/string)
- **Status**: ativo / inativo / lazy

### 3. Renderizar

Gerar conteúdo Markdown e servir via Chrome relay se disponível.
Se Chrome offline, imprimir ASCII diretamente no terminal.

---

## Formato de saída

### Tabela de flags

| Flag | Mecanismo | Default | Valor |
|------|-----------|---------|-------|
| `personality` | `~/.leech PERSONALITY=` | ON | ON |
| `autocommit` | `~/.leech AUTOCOMMIT=` | OFF | OFF |
| ... | ... | ... | ... |

### Pipeline vertical

Mostrar cada estágio do boot com status (ativo/inativo) e motivo.

### Recomendações

Avaliar e exibir recomendações baseadas no estado atual: lazy-loads, flags inativas, economia potencial.

---

## Notas

- Valores detectados devem vir do bloco `---BOOT---` injetado no início da sessão
- Se o bloco BOOT não estiver visível, inferir dos arquivos carregados
- Sempre mostrar ASCII no terminal antes (ou se Chrome offline)
