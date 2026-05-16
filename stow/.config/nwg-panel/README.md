# nwg-panel — painel de controle

**Função:** botão de controle no canto superior direito (top bar nwg-panel
minimalista) que abre dropdown com sliders de volume/brilho, switcher de
audio output, atalhos pra `wiremix`/`nwg-displays`/`nmtui`, e menu Exit
(lock/logout/suspend/reboot/shutdown).

**Comportamento:** roda como bar overlay leve no `top`, `position right`.
`exclusive-zone: false` significa que **não rouba espaço** das janelas — só
sobrepõe.

## Customizar via GUI

Rodar `nwg-panel-config` (bind `SUPER + SHIFT + p`) abre a UI gráfica de
edição — toda mudança grava de volta nesse `config` JSON. Modelo
declarativo: editar manualmente também funciona.

## Tema

`style.css` importa `themes/dracula-black/colors.css`. Pra trocar de tema,
mexer em **uma linha** lá (não aqui).
