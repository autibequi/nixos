---
name: feedback_gtk_css_waybar
description: GTK CSS @keyframes não funcionam no Waybar — só propriedades estáticas
type: feedback
---

`@keyframes` com `color`, `text-shadow`, `opacity`, `box-shadow` e `background-color` **não animam** no Waybar (GTK CSS). Testado com múltiplas propriedades e variações de shorthand vs longhand — nenhuma produziu efeito visual.

**Why:** Waybar usa GTK CSS que tem suporte muito limitado a animações. O `animation:` aceita a declaração sem erro mas não executa. O `@keyframes urgent-pulse` que existe no style.css provavelmente também não funciona (nunca foi testado em produção — está lá como aspiração).

**How to apply:** Ao editar `style.css` do Waybar:
- Só usar propriedades **estáticas**: `color`, `text-shadow`, `background-color`, `box-shadow` diretamente no seletor
- Não tentar `@keyframes` nem `animation:` para efeitos visuais
- Para efeitos "vivos" (pulsing, flicker) seria necessário um script externo que troca classes CSS via `waybar --reload` — não via CSS puro
- Se o usuário pedir animação: informar a limitação antes de tentar, não desperdiçar iterações
