// engine.js — Dot Matrix Eye — Motor de animação
// Espera window.SEQUENCE definido pelo index.html antes de carregar.
// Não edite este arquivo para mudar expressões — edite o SEQUENCE em index.html.

(function () {
  const SEQ   = window.SEQUENCE;
  const canvas = document.getElementById('c');
  const ctx    = canvas.getContext('2d');
  const label  = document.getElementById('step-label');

  // ── config de grid ────────────────────────────────────────────────────────
  const DOT  = 8;   // diâmetro do dot em px
  const GAP  = 5;   // espaço entre dots
  const STEP = DOT + GAP;

  const GREEN_ON  = '#39ff6a';
  const GREEN_DIM = '#071509';
  const BG        = '#020904';

  // ── buffers e dimensões ───────────────────────────────────────────────────
  let W, H, COLS, ROWS, OX, OY;
  let faceBuffer, target, current;

  function resize() {
    W = canvas.width  = window.innerWidth;
    H = canvas.height = window.innerHeight;
    COLS = Math.ceil(W / STEP) + 2;
    ROWS = Math.ceil(H / STEP) + 2;
    const cx = Math.floor(COLS / 2);
    const cy = Math.floor(ROWS / 2);
    // offset para o dot central cair exatamente no centro da tela
    OX = Math.round(W / 2 - cx * STEP - DOT / 2);
    OY = Math.round(H / 2 - cy * STEP - DOT / 2);
    faceBuffer = new Float32Array(COLS * ROWS);
    target     = new Float32Array(COLS * ROWS);
    current    = new Float32Array(COLS * ROWS);
  }
  window.addEventListener('resize', resize);

  // ── sequencer ─────────────────────────────────────────────────────────────
  let seqIdx = 0, seqT = 0;
  let paused = false;
  let manualEmotion = null;

  function advanceSeq(dt) {
    if (paused) return;
    seqT += dt / SEQ[seqIdx].dur;
    if (seqT >= 1) {
      seqT = seqT % 1;
      seqIdx = (seqIdx + 1) % SEQ.length;
      manualEmotion = null;
    }
  }

  // ── easing ────────────────────────────────────────────────────────────────
  function ease(t, type) {
    switch (type) {
      case 'in':     return t * t;
      case 'out':    return 1 - (1-t)*(1-t);
      case 'inout':  return t < 0.5 ? 2*t*t : 1-2*(1-t)*(1-t);
      case 'bounce': {
        let n = 1-t;
        if (n < 1/2.75)      return 1 - 7.5625*n*n;
        if (n < 2/2.75)      return 1 - 7.5625*(n-=1.5/2.75)*n - .75;
        if (n < 2.5/2.75)    return 1 - 7.5625*(n-=2.25/2.75)*n - .9375;
                             return 1 - 7.5625*(n-=2.625/2.75)*n - .984375;
      }
      case 'elastic': {
        if (t <= 0 || t >= 1) return t;
        return Math.pow(2,-10*t) * Math.sin((t-.075)*(2*Math.PI)/.3) + 1;
      }
      default: return t;
    }
  }

  function getCurrentTransform() {
    const cur  = SEQ[seqIdx];
    const prev = SEQ[(seqIdx - 1 + SEQ.length) % SEQ.length];
    const e    = ease(seqT, cur.ease || 'linear');

    const scale     = lerp(prev.scale     || 1, cur.scale     || 1, e);
    const twistAmp  = lerp(prev.twistAmp  || 0, cur.twistAmp  || 0, e);
    const twistFreq = lerp(prev.twistFreq || 2, cur.twistFreq || 2, e);
    const twistFlow = lerp(prev.twistFlow || 0, cur.twistFlow || 0, e);

    const hz    = cur.shakeHz || 8;
    const angle = seqT * Math.PI * 2 * hz * (cur.dur / 1000);
    const offX  = Math.sin(angle)             * (cur.shakeX || 0);
    const offY  = Math.sin(angle + Math.PI/3) * (cur.shakeY || 0);

    return {
      scale, offX, offY,
      twistAmp, twistFreq, twistFlow,
      glitch:  cur.glitch  || 0,
      emotion: manualEmotion || cur.emotion || 'neutral',
    };
  }

  // ── estado de runtime ─────────────────────────────────────────────────────
  let mouse  = { x: 0, y: 0 };
  let pupOff = { x: 0, y: 0 };
  let blinkClose = 0, blinkTarget = 0, blinkNext = 2800+Math.random()*3000, blinking = false;
  let breath = 0, scanY = 0, globalTime = 0;

  document.addEventListener('mousemove', e => { mouse.x = e.clientX; mouse.y = e.clientY; });

  // ── utils ─────────────────────────────────────────────────────────────────
  function lerp(a, b, t) { return a + (b-a)*t; }
  function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)); }

  // escreve no faceBuffer (coords absolutas de grid)
  function fdot(c, r, v=1) {
    if (c<0||c>=COLS||r<0||r>=ROWS) return;
    faceBuffer[r*COLS+c] = Math.max(faceBuffer[r*COLS+c], v);
  }
  function fhline(r, c0, c1, v=1) { for (let c=c0;c<=c1;c++) fdot(c,r,v); }
  function fvline(c, r0, r1, v=1) { for (let r=r0;r<=r1;r++) fdot(c,r,v); }
  function frect(c0, r0, c1, r1, v=1) {
    fhline(r0,c0,c1,v); fhline(r1,c0,c1,v);
    fvline(c0,r0+1,r1-1,v); fvline(c1,r0+1,r1-1,v);
  }

  // ── face builder → faceBuffer ─────────────────────────────────────────────
  function buildFaceBuffer(emotion, px, py) {
    faceBuffer.fill(0);
    const cx = Math.floor(COLS/2);
    const cy = Math.floor(ROWS/2);

    // olhos relativos ao centro do grid
    const L = { c0:cx-12, c1:cx-4,  r0:cy-6, r1:cy+2 };
    const R = { c0:cx+4,  c1:cx+12, r0:cy-6, r1:cy+2 };

    drawEye(L, px, py, emotion);
    drawEye(R, px, py, emotion);
    drawBrows(L, R, emotion);

    if (blinkClose > 0.02) {
      applyBlink(L);
      applyBlink(R);
    }
  }

  function drawEye({c0,c1,r0,r1}, px, py, emo) {
    const ecx = Math.floor((c0+c1)/2);
    const ecy = Math.floor((r0+r1)/2);

    if (emo === 'happy') {
      fhline(r0, c0+1, c1-1);
      fdot(c0,r0+1); fdot(c1,r0+1);
      fdot(c0+1,r0+2,0.6); fdot(c1-1,r0+2,0.6);
      return;
    }
    if (emo === 'sad') {
      fhline(r1, c0+1, c1-1);
      fdot(c0,r1-1); fdot(c1,r1-1);
      fdot(c0+1,r1-2,0.6); fdot(c1-1,r1-2,0.6);
      return;
    }

    frect(c0,r0,c1,r1);

    if (emo === 'sleepy') {
      fhline(r0+1,c0+1,c1-1,0.9);
      fhline(r0+2,c0+1,c1-1,0.8);
      fdot(ecx+px, ecy+1+py);
      fdot(ecx+px, ecy+2+py, 0.7);
      return;
    }

    const ir = emo === 'surprised' ? 3 : 2;
    for (let a=0; a<16; a++) {
      const ang = a/16*Math.PI*2;
      fdot(Math.round(ecx+px+Math.cos(ang)*ir), Math.round(ecy+py+Math.sin(ang)*ir), 0.7);
    }
    fdot(ecx+px,   ecy+py,   1.0);
    fdot(ecx+px+1, ecy+py,   0.9);
    fdot(ecx+px,   ecy+py+1, 0.9);
    fdot(ecx+px-1, ecy+py,   0.8);
    fdot(ecx+px,   ecy+py-1, 0.8);
    fdot(ecx+px-1, ecy+py-1, 0.95);

    if (emo === 'surprised') {
      for (let a=0; a<20; a++) {
        const ang = a/20*Math.PI*2;
        fdot(Math.round(ecx+px+Math.cos(ang)*(ir+2)), Math.round(ecy+py+Math.sin(ang)*(ir+2)), 0.35);
      }
    }
  }

  function drawBrows(L, R, emo) {
    const lby = L.r0-3, rby = R.r0-3;
    if (emo === 'angry') {
      fhline(lby,  L.c0+2,L.c1,  1); fhline(lby+1,L.c0,  L.c0+1,1);
      fhline(rby,  R.c0,  R.c1-2,1); fhline(rby+1,R.c1-1,R.c1,  1);
    } else if (emo === 'sad') {
      fhline(lby,  L.c0,  L.c1-2,1); fhline(lby+1,L.c1-1,L.c1,  1);
      fhline(rby,  R.c0+2,R.c1,  1); fhline(rby+1,R.c0,  R.c0+1,1);
    } else if (emo === 'surprised') {
      fhline(lby-1,L.c0+1,L.c1-1,1);
      fhline(rby-1,R.c0+1,R.c1-1,1);
    } else {
      fhline(lby,  L.c0+1,L.c1-1,1);
      fhline(rby,  R.c0+1,R.c1-1,1);
    }
  }

  function applyBlink({c0,c1,r0,r1}) {
    const lid = Math.min(Math.round(blinkClose*(r1-r0+1)), r1-r0+1);
    for (let r=r0; r<=r0+lid&&r<=r1; r++)
      for (let c=c0; c<=c1; c++) faceBuffer[r*COLS+c] = 0;
    const sr = r0+lid;
    if (sr <= r1) fhline(sr, c0, c1, 0.7);
  }

  // ── transform: faceBuffer → target ───────────────────────────────────────
  // Aplica scale, shake (offX/offY), twist e glitch sobre o faceBuffer.
  // Todas as coords são relativas ao centro do grid (cx, cy).
  function applyTransform(T) {
    target.fill(0);
    const cx = Math.floor(COLS/2);
    const cy = Math.floor(ROWS/2);

    for (let r=0; r<ROWS; r++) {
      for (let c=0; c<COLS; c++) {
        const v = faceBuffer[r*COLS+c];
        if (v < 0.01) continue;
        // face-space (relativo ao centro)
        const fc = c - cx;
        const fr = r - cy;
        // scale + offset de shake
        let tc = cx + Math.round(fc * T.scale + T.offX);
        let tr = cy + Math.round(fr * T.scale + T.offY);
        // twist: desloca coluna com onda senoidal animada
        if (T.twistAmp > 0.01) {
          const phase = (tr / ROWS) * Math.PI * 2 * T.twistFreq
                      + globalTime * 0.001 * T.twistFlow * 6;
          tc += Math.round(Math.sin(phase) * T.twistAmp);
        }
        if (tc>=0 && tc<COLS && tr>=0 && tr<ROWS)
          target[tr*COLS+tc] = Math.max(target[tr*COLS+tc], v);
      }
    }

    // glitch: dots aleatórios piscam
    if (T.glitch > 0) {
      for (let i=0; i<COLS*ROWS; i++) {
        if (Math.random() < T.glitch * 0.08)
          target[i] = Math.random() > 0.5 ? Math.random()*0.9 : 0;
      }
    }
  }

  // ── renderer ──────────────────────────────────────────────────────────────
  function drawDots(breathOff) {
    for (let r=0; r<ROWS; r++) {
      for (let c=0; c<COLS; c++) {
        const v = current[r*COLS+c];
        const x = OX + c*STEP + DOT/2;
        const y = OY + r*STEP + DOT/2 + breathOff;
        if (v > 0.05) {
          ctx.shadowColor = GREEN_ON;
          ctx.shadowBlur  = v * 14;
          ctx.fillStyle   = `rgba(57,255,106,${v})`;
        } else {
          ctx.shadowBlur = 0;
          ctx.fillStyle  = GREEN_DIM;
        }
        ctx.beginPath();
        ctx.arc(x, y, DOT/2, 0, Math.PI*2);
        ctx.fill();
      }
    }
    ctx.shadowBlur = 0;
  }

  function drawScanline(dt) {
    scanY = (scanY + dt*0.05) % (H + 80);
    const sy = -40 + scanY;
    const sg = ctx.createLinearGradient(0, sy-40, 0, sy+40);
    sg.addColorStop(0,   'rgba(57,255,106,0)');
    sg.addColorStop(0.5, 'rgba(57,255,106,0.05)');
    sg.addColorStop(1,   'rgba(57,255,106,0)');
    ctx.fillStyle = sg;
    ctx.fillRect(0, sy-40, W, 80);
  }

  // ── main loop ─────────────────────────────────────────────────────────────
  let last = 0;
  function frame(ts) {
    const dt = ts - last; last = ts;
    globalTime += dt;
    breath += dt * 0.0009;

    advanceSeq(dt);

    // blink autônomo
    blinkNext -= dt;
    if (blinkNext <= 0 && !blinking) {
      blinking = true; blinkTarget = 1;
      blinkNext = 2200 + Math.random()*4000;
      setTimeout(() => { blinkTarget = 0; setTimeout(() => { blinking = false; }, 120); }, 80);
    }
    blinkClose = lerp(blinkClose, blinkTarget, blinking ? 0.2 : 0.25);

    // pupila segue o mouse
    pupOff.x = lerp(pupOff.x, clamp((mouse.x - W/2) / (W/2), -1, 1), 0.07);
    pupOff.y = lerp(pupOff.y, clamp((mouse.y - H/2) / (H/2), -1, 1), 0.07);
    const px = Math.round(clamp(pupOff.x * 3.5, -3, 3));
    const py = Math.round(clamp(pupOff.y * 2.5, -2, 2));

    const T = getCurrentTransform();
    buildFaceBuffer(T.emotion, px, py);
    applyTransform(T);

    // suaviza transição entre frames
    for (let i=0; i<COLS*ROWS; i++) current[i] = lerp(current[i], target[i], 0.18);

    ctx.clearRect(0, 0, W, H);
    ctx.fillStyle = BG;
    ctx.fillRect(0, 0, W, H);

    drawDots(Math.sin(breath) * 4);
    drawScanline(dt);

    if (label) label.textContent = (paused ? '⏸ ' : '') + SEQ[seqIdx].name;

    requestAnimationFrame(frame);
  }

  // ── input ─────────────────────────────────────────────────────────────────
  const KEY = { h:'happy', s:'sad', a:'angry', z:'sleepy', r:'surprised', n:'neutral' };
  document.addEventListener('keydown', e => {
    if (e.key === ' ')               paused = !paused;
    if (e.key==='f'||e.key==='F')    document.documentElement.requestFullscreen?.();
    if (KEY[e.key.toLowerCase()])    manualEmotion = KEY[e.key.toLowerCase()];
  });
  document.addEventListener('click', () => {
    const em = ['neutral','happy','sad','angry','surprised','sleepy'];
    manualEmotion = em[Math.floor(Math.random() * em.length)];
  });

  resize();
  requestAnimationFrame(frame);
})();
