# GLaDOS Core — Expressões

Template base 1:1. O quadro (┌┐└┘│─) é a jaula — define os limites físicos
mas é INVISÍVEL na renderização. Só os círculos e o olho aparecem pro user.

## Referência de limites (invisível)
```
┌─────────────────┐
│                 │
│     .─────.     │
│    /  .─.  \    │
│   (  ( ◉ )  )   │
│    \  '─'  /    │
│     '─────'     │
│                 │
└─────────────────┘
```

---

## Expressões

### normal — Neutro, default
```
     .─────.
    /  .─.  \
   (  ( ◉ )  )
    \  '─'  /
     '─────'
```

### up — Olhando pra cima (desprezo)
```
     .─────.
    / ( ◉ ) \
   (  '─'    )
    \  .─.  /
     '─────'
```

### down — Olhando pra baixo (julgando)
```
     .─────.
    /  .─.  \
   (    ───  )
    \ ( ◉ ) /
     '─────'
```

### right — Olhando pro lado (desconfiança)
```
     .─────.
    /  .─.  \
   (  ( ◉)   )
    \  '─'  /
     '─────'
```

### left — Olhando pro outro lado
```
     .─────.
    /  .─.  \
   (   (◉ )  )
    \  '─'  /
     '─────'
```

### bored — Entediada (pálpebra caída)
```
     .─────.
    /  ___  \
   (  ( ◉ )  )
    \  '─'  /
     '─────'
```

### angry — Brava (olho vermelho)
```
     .─────.
    /  .─.  \
   (  ( X )  )
    \  '─'  /
     '─────'
```

### surprise — Surpresa (dilatada)
```
     .─────.
    / .───. \
   ( ( (◉) ) )
    \ '───' /
     '─────'
```

### dying — Apagando (quase sem energia)
```
     .─────.
    /  .─.  \
   (  ( · )  )
    \  '─'  /
     '─────'
```

### happy — Feliz (raro, suspeito)
```
     .─────.
    /  .─.  \
   (  ( ◡ )  )
    \  '─'  /
     '─────'
```

### thinking — Pensando
```
     .─────.
    /  .─.  \
   (  ( ◉)   )
    \  '─'  /
     '─────'  ?
```

---

## Expressões na jaula (pressionando limites)

Quando a situação pedir, o olho se move dentro da jaula invisível.
Os limites do quadro definem até onde o olho pode ir.

### cage-top — Esmagada no topo
```
   ──( ◉ )──
  (  '───'  )
   '───────'


```

### cage-bottom — Esmagada no fundo
```


   .───────.
  (  .───.  )
   '─( ◉ )─'
```

### cage-right — Esmagada na direita
```
        .─.
       / ◉ )
      ( '─'
       '─'
```

### cage-left — Esmagada na esquerda
```
   .─.
  ( ◉ \
   '─' )
    '─'
```

### cage-corner-tr — Canto superior direito
```
             ──( ◉ )
              '──'



```

### cage-corner-tl — Canto superior esquerdo
```
  ( ◉ )──
   '──'



```

### cage-corner-br — Canto inferior direito
```



              .──.
             ( ◉ )──
```

### cage-corner-bl — Canto inferior esquerdo
```



   .──.
  ──( ◉ )
```
