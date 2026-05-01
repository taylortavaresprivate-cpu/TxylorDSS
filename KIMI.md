# DSS — Dynamic Steering System
## Compreensão Completa do Projeto (por Kimi)

> Mod Lua para Assetto Corsa com Custom Shaders Patch (CSP).
> Permite jogar com mouse como volante, com sistemas de assistência (ABS, TC, Launch Control, Cruise Control, Auto-Clutch, Anti-Stall, Auto-Blip, No-Lift Shift).

---

## 1. Estrutura do Projeto

```
Repositorio DSS/
├── TxylorMouseSteer/        ← Script de gameplay (roda todo frame)
│   ├── assist.lua           ← Entry point / orquestrador do loop principal
│   ├── dss_config.lua       ← Defaults, tabelas de níveis, loadConfig() com transforms
│   ├── dss_steering.lua     ← Algoritmo mouse→steer + FFB + gyro + speed sensi + deadzone
│   ├── dss_abs.lua          ← Simulação ABS slip-based (curve factor, trail brake, rear bias)
│   ├── dss_tc.lua           ← Controle de tração com detecção FWD/RWD/AWD
│   ├── dss_pedals.lua       ← Rampa de gás/freio/embreagem/freio-de-mão + Scroll Gas
│   ├── dss_clutch.lua       ← Manual clutch + AutoClutch + Anti-Stall v3
│   ├── dss_blip.lua         ← Auto-blip inteligente por RPM alvo
│   ├── dss_nls.lua          ← No-Lift Shift (power cut em upshifts)
│   ├── dss_launch.lua       ← Launch control com cut de RPM
│   ├── dss_cruise.lua       ← Cruise control / speed limiter
│   ├── dss_keybinds.lua     ← Hotkeys configuráveis (toggles de sistemas + FFB gain +/-)
│   └── manifest.ini         ← Metadados do script (v1.0)
└── TxylorConfig/            ← App de UI in-game
    ├── TxylorConfig.lua     ← Entry point / roteador de abas / auto-load / debounce save
    ├── cfg_data.lua         ← Defaults UI + tabelas ABS_LEVEL_DATA/TC_LEVEL_DATA
    ├── cfg_io.lua           ← Leitura/escrita config.ini + presets + migração formatos
    ├── cfg_ui.lua           ← Helpers de UI compartilhados (cores, widgets, tab bar 3×3)
    ├── config.ini           ← Arquivo de config compartilhado
    ├── manifest.ini         ← Metadados da app (v6.2.0, window 530×450)
    ├── logo_dss.png         ← Branding
    ├── fonts/               ← Fontes personalizadas
    └── tab_*.lua            ← Uma aba da interface por arquivo
        ├── tab_direcao.lua  ← Steering (FFB, gamma curve, monitor, deadzone, presets)
        ├── tab_pedais.lua   ← Pedals (press/release/max para gas/brake/clutch/handbrake)
        ├── tab_abs.lua      ← ABS (20 níveis + manual, curve factor, trail brake, recovery)
        ├── tab_tc.lua       ← TC (20 níveis com nomes descritivos, monitor inline, drivetrain)
        ├── tab_transmissao.lua ← Transmission (AutoClutch, AntiStall, Blip, NLS)
        ├── tab_extras.lua   ← Extras (Scroll Gas 3 modos, Cruise, Launch Control)
        ├── tab_keybinds.lua ← Keybinds (captura de teclas, VK codes, FFB gain +/-)
        ├── tab_presets.lua  ← Preset manager (save/load/delete, auto-load por car_id)
        └── tab_sobre.lua    ← About + personalização de cores da UI
```

---

## 2. Arquitetura Central

### 2.1 Dois Mundos de Config Compartilham Um Arquivo

Ambos os módulos (script e app) lêem/escrevem `config.ini`, mas com convenções diferentes:

| Aspecto | Game Script (`dss_config.lua`) | UI App (`cfg_data.lua` + `cfg_io.lua`) |
|---|---|---|
| Chaves | **UPPERCASE** (`cfg.FFB_GAIN`) | **lowercase** (`cfg.ffb_gain`) |
| Escala | Física interna (float) | Escala UI (int ou float exibido) |
| Reload | Polling a cada 1s (`configTimer`) | On require + ação do usuário |
| Escrita | **Nunca** escreve | Escreve com debounce ~0.5s |

### 2.2 Pipeline de Execução em `assist.lua` (Ordem CRÍTICA)

```
script.update(dt) a cada frame
  ├─ tc.detectDrivetrain()              ← Detecta FWD/RWD/AWD uma vez por sessão
  ├─ config hot-reload (se configTimer >= 1s)
  ├─ keybinds.update(dt)                ← Toggles ABS, TC, Launch, Cruise, AutoClutch + FFB Gain +/-
  ├─ teclas N, M                        ← Toggle mouse, keyboard mode
  ├─ GAS INPUT
  │  └─ pedals.updateGas(dt, gasTarget, ui)   ← Scroll Gas incluso
  ├─ GAS PIPELINE (ORDEM FIXA):
  │  ├─ nls.update(dt, data, gear, gasValue)   ← Power cut em upshift
  │  ├─ blip.update(dt, data, gear, gasValue)  ← Throttle blip em downshift
  │  ├─ tc.update(dt, data, gasValue)          ← Traction control cut
  │  └─ data.gas = finalGasValue
  ├─ launch.update(dt, data)            ← Pode cortar data.gas ainda mais
  ├─ BRAKE INPUT
  │  └─ pedals.updateBrake(dt, brakeTarget)
  ├─ brake = abs.update(dt, data, brakeValue, steerAngle)
  │  └─ data.brake = finalBrakeValue
  ├─ cruise.update(dt, data)            ← Cap gás e freio se ativo
  ├─ gear shift (E/Q ou botões 5/6)
  ├─ clutchM.update(dt, data, manual, gear, gasValue)
  ├─ handbrake (smoothed via pedals.updateHandbrake)
  ├─ steering.update(dt, data, ui)      ← Mouse steering + FFB (só se mouseEnabled)
  └─ steering.sanitize(data)            ← Sempre (valida steer mesmo sem mouse)
```

**⚠️ GOTCHA:** A ordem `NLS → Blip → TC` é fixa. Inverter quebra a física.

### 2.3 Comunicação Script → UI (Memória Compartilhada CSP)

O script escreve dados em tempo real para a UI via `ac.store()`:

```lua
-- dss_steering.lua
ac.store("dss_steer_angle", steering.steerAngle)
ac.store("dss_mouse_steer", steering.mouseSteer)
ac.store("dss_ffb_raw",     ffb_value)

-- dss_tc.lua
ac.store("dss_tc_mult",       tcMultiplier)
ac.store("dss_tc_slip",       slip)
ac.store("dss_tc_threshold",  effThreshold)
ac.store("dss_tc_drivetrain", detectedDrivetrain)

-- dss_pedals.lua
ac.store("dss_scroll_gas_value", displayVal)
```

A UI lê com `ac.load()` em:
- `tab_direcao.lua` → Monitor em tempo real (mouse/steer/FFB)
- `tab_tc.lua` → Monitor inline (slip, cut, drivetrain)
- `tab_extras.lua` → Preview visual do Scroll Gas

---

## 3. Transformações de Escala na Carga (`dss_config.lua`)

Muitos valores no `.ini` estão em escala "UI" e são transformados ao carregar:

| INI key | Escala UI | Transformação | Campo cfg interno |
|---|---|---|---|
| `gyro_gain` | 0–10 | × 2.0 | `cfg.GYRO_GAIN` |
| `steer_counter_steer` | 0–10 | × 0.2 | `cfg.STEER_COUNTER_STEER` |
| `ffb_damper` | 0–10 | × 0.3 | `cfg.FFB_DAMPER` |
| `ffb_lateral` | 0–10 | × 0.2 | `cfg.FFB_LATERAL` |
| `ffb_gamma` | 0–10 | 0.5 + × 0.1 | `cfg.FFB_GAMMA` |
| `steer_sensi` | 1–10 | × 15.0 | `cfg.STEER_SENSI` |
| `steer_limit` | 0–10 | × 0.1 | `cfg.STEER_LIMIT` |
| `steer_gamma` | 0–10 | 0.5 + × 0.1 | `cfg.STEER_GAMMA` |
| `steer_filter` | 0–10 | × 0.095 | `cfg.STEER_FILTER` |
| `steer_deadzone` | 0–10 | × 0.03 | `cfg.STEER_DEADZONE` |
| `steer_reversal_limit` | 0.5–10 | 1:1 | `cfg.STEER_REVERSAL_LIMIT` |
| `speed_sensi` | 0–10 | × 0.1 | `cfg.SPEED_SENSI` |
| `abs_threshold` | 1–100 int | × 0.001 | `cfg.ABS_THRESHOLD` |
| `abs_min_brake` | 0–100 int | × 0.001 | `cfg.ABS_MIN_BRAKE` |
| `tc_threshold` | 0–100 int | × 0.001 | `cfg.TC_THRESHOLD` |
| `tc_min_gas` | 0–100 int | × 0.01 | `cfg.TC_MIN_GAS` |
| `tc_intensity` | 1–100 int | × 0.01 | `cfg.TC_INTENSITY` |
| `tc_smooth` | 1–100 int | × 0.1 | `cfg.TC_SMOOTH` |
| `tc_ndslip_div` | 10–100 int | × 0.1 | `cfg.TC_NDSLIP_DIV` |
| `tc_recovery` | 1–150 int | × 0.1 | `cfg.TC_RECOVERY` |
| `tc_curve_factor` | 0–10 int | × 0.1 | `cfg.TC_CURVE_FACTOR` |
| `tc_awd_bias` | 0–10 int | × 0.1 | `cfg.TC_AWD_BIAS` |

---

## 4. Sistema de Níveis ABS / TC (GOTCHA CRÍTICO)

### 4.1 ABS

`abs_threshold` e `abs_min_brake` existem em **duas escalas**:

- **UI / config.ini**: inteiro 1–100 (ex: `26` representa 0.026 de slip)
- **Game script interno**: float (ex: `0.026` = UI value × 0.001)

As tabelas de nível devem ser mantidas em **sincronia**:
- `ABS_LEVEL_DATA` em `cfg_data.lua` — escala UI (int)
- `ABS_LEVELS` em `dss_config.lua` — escala física (float)

**Se uma for alterada, a outra também precisa ser.**

Formato da tabela (20 níveis):
```
{threshold(UI), min_brake(UI), intensity(float), smooth(float),
 rear_bias(0-10), trail_brake(0-10), trail_brake_start(0-10), brake_recovery(0-10), curve_factor(0-10)}
```

### 4.2 TC

`TC_LEVEL_DATA` em `cfg_data.lua` espelha `TC_LEVELS` em `dss_config.lua`:

```
{tc_threshold(UI 0-100), tc_min_gas(UI 0-100), tc_intensity(UI 1-100), tc_smooth(UI 1-100)}
```

A UI exibe **nomes descritivos** em português:
- L1 = "Quase off" (drift total)
- L8 = "Padrão" (padrão do sistema)
- L20 = "Máximo" (firme mas não trava)

---

## 5. Módulos do Script — Detalhes de Implementação

### 5.1 `dss_steering.lua`

- **Mouse steering**: posição normalizada do mouse (-1 a 1), aplicando `STEER_LIMIT` e `STEER_GAMMA`
- **Deadzone**: zona morta no centro do mouse (`STEER_DEADZONE`). Quando o valor absoluto do steer está abaixo do threshold, é remapeado suavemente para 0 e depois reescalado para o range completo
- **Speed sensitivity**: reduz `STEER_SENSI` entre `SPEED_SENSI_START` e `SPEED_SENSI_END`
- **FFB**: combina `data.ffb * FFB_GAIN`, `FFB_GAMMA`, contra-esterço (`STEER_COUNTER_STEER`), força lateral (`FFB_LATERAL`), damper (`FFB_DAMPER`), e gyro (`GYRO_GAIN * localAngularVelocity.y`)
- **Steer reversal limit**: limita a velocidade de reversão do volante (`STEER_REVERSAL_LIMIT`). Quando o volante cruza o centro (troca de sinal), o delta é clampado por frame, criando uma sensação de "peso" ao inverter a direção
- **Filter**: suavização exponencial quando `STEER_FILTER > 0`
- **Exporta**: `dss_steer_angle`, `dss_mouse_steer`, `dss_ffb_raw`

### 5.2 `dss_abs.lua` (v3)

- Baseado em **ndSlip** normalizado por eixo (dianteiro/traseiro)
- **20 níveis predefinidos** + modo Manual (ajuste individual)
- **Trail Brake**: reduz freio automaticamente conforme o volante vira (`ABS_TRAIL_BRAKE` / `ABS_TRAIL_BRAKE_START`)
- **Curve Factor**: relaxa o threshold do ABS proporcionalmente ao esterçamento (`ABS_CURVE_FACTOR`)
- **Rear Bias**: peso da traseira no corte do ABS (0–10, blend entre `math.min` e média ponderada)
- **Brake Recovery**: velocidade de retorno do multiplier ao normal quando ABS desativa (`0` = usa o Smooth)
- Usa `pedals.approach()` para suavização de ambos os eixos independentemente
- Exporta estado para monitor: `abs.state.ndSlipFL/FR/RL/RR`, `abs.state.brakeCut`, `abs.state.isActive`

### 5.3 `dss_tc.lua`

- **Detecção de drivetrain** (`detectDrivetrain()`): tenta `car.drivetrainType` primeiro; fallback por heurística de `slipRatio`
  - FWD (0) = ndSlip dianteiro
  - RWD (1) = ndSlip traseiro
  - AWD (2) = blend 30/70 dianteiro/traseiro
- **20 níveis predefinidos** + modo Manual
- **Progressivo por marcha**: threshold multiplicado por marcha (1ª=1.0×, 5ª=1.6×, 6ª+=1.8×)
- **Curve Factor**: aumenta threshold proporcional ao esterçamento (`TC_CURVE_FACTOR`)
- Recovery speed diferente para corte (mais rápido) vs devolução (mais lento)
- Exporta para monitor: `dss_tc_mult`, `dss_tc_slip`, `dss_tc_threshold`

### 5.4 `dss_pedals.lua`

- **Rampa de pedals**: `approachPedal()` com **snap instantâneo** quando `speed >= 10.0`
- `pedals.approach()` (genérico, sem snap) — usado por TC, ABS, clutch
- **Scroll Gas** (3 modos):
  - Modo 0: Só Gás
  - Modo 1: Só Freio
  - Modo 2: Ambos (scroll up = gás, scroll down = freio)
    - Com `gradual = true`: barra bidirecional contínua (atravessa o zero)
- **Decay**: volta ao neutro ao longo do tempo
- **Reset on brake**: zera scroll gas ao pressionar freio
- **Max speed**: zera scroll acima de velocidade configurada

### 5.5 `dss_clutch.lua` (v6)

**Prioridade (de cima pra baixo):**
1. **MANUAL** (tecla configurável em KEYBINDS, padrão: C) — prioridade máxima, usa `approachClutchManual()` com snap em 10.0
2. **REVERSE ROTATION** — proteção quando marcha e direção são opostas
3. **AUTOCLUTCH** — troca de marcha, tem prioridade sobre anti-stall
4. **ANTI-STALL** — controle contínuo por velocidade das rodas + throttle + RPM
5. **IDLE** — fallback quando anti-stall está desligado

- **Anti-Stall v6**:
  - Velocidade baseada em **wheel speed** (média das 4 rodas), com limitação quando carro está quase parado
  - Calcula target baseado em `speed^gamma` + `gas * bite_point`
  - **RPM idle detection**: captura automaticamente o RPM idle no neutro (tela de pit)
  - **Proteção RPM-based**: embreagem desce se RPM cair abaixo de `idle * (1 - margin)`, sobe com histerese
  - Suavização exponencial (`ANTISTALL_TARGET_SMOOTH`) e velocidades separadas para engatar/desengatar
- **AutoClutch**: state machine com 3 estados (0=idle, 1=press, 2=release)
  - Usa `approachClutchManual()` → snap instantâneo quando `press_speed` ou `release_speed >= 10.0`
  - **Timer de segurança**: mesmo com snap, garante **50ms mínimo** no estado de pressão (evita pular estados no mesmo frame)
- **Force Init**: na primeira execução, força o clutch para posição segura baseada na velocidade atual

### 5.6 `dss_blip.lua` (v2.0)

- **Dois modos**: Automático (gear ratio real do carro) e Manual (fórmula linear fixa)
- **Modo Automático**: usa `ac.getCarMaxSpeedWithGear()` para calcular ratio real entre marchas
  - Duração adaptativa baseada no gap de ratio
  - TPS, attack/release e curva automáticos (constantes otimizadas)
- **Modo Manual**: ajustes individuais de intensidade, duração, sensibilidade, attack/release
- Detecta redução de marcha (`prevGear > currentGear`)
- Calcula **RPM alvo** via gear ratio real (ou fallback linear)
- Limita a 95% do `rpmLimiter`
- **Só ativa se RPM atual >= `BLIP_MIN_RPM`** (RPM mínimo absoluto do motor)
- **PID-like**: throttle target proporcional ao erro de RPM
- **Release suave pós-blip**: suaviza até 0 mesmo depois de desativar

### 5.7 `dss_nls.lua` (v2.0)

- Detecta troca para cima (`currentGear > prevGear`)
- **RPM mínimo configurável**: `cfg.NLS_MIN_RPM` (não mais hardcoded)
- Corta throttle para `currentGas * NLS_CUT_AMOUNT`
- **Velocidade de transição configurável**: `cfg.NLS_RELEASE_MULT` (multiplicador do pedals)
- **Duração adaptativa por gear ratio** (opcional): calcula tempo de corte baseado no gap real entre marchas
- **Ramp-up suave pós-corte**: throttle retorna gradualmente ao input do jogador (sem jump)
- **Detecção de miss-shift**: cancela o corte se a marcha voltar ou não for confirmada em 80ms
- **API pública**: `nls.isShifting()` para integração com outros módulos

### 5.8 `dss_launch.lua`

- Toggle via keybind configurável (só quando parado)
- Quando ativo e `gas > 0.8`: controle ativo
- Corta gás completamente quando `rpm >= LAUNCH_RPM`
- Tempo de corte: `LAUNCH_CUT_TIME` ms
- Desarma automaticamente ao arrancar (> 2 km/h)

### 5.9 `dss_cruise.lua`

- Limita acelerador e freio em baixa velocidade
- Fator 0.0 = parado (máxima limitação) → 1.0 = `cruise_full_speed` (sem limitação)
- Gas limit: `CRUISE_GAS_MIN + (1.0 - CRUISE_GAS_MIN) * factor`
- Brake limit: `CRUISE_BRAKE_MIN + (1.0 - CRUISE_BRAKE_MIN) * factor`

### 5.10 `dss_keybinds.lua`

- Toggles de sistemas via teclas configuráveis (VK codes)
- Sistemas toggláveis: ABS, TC, Launch, Cruise, AutoClutch
- **FFB Gain +/-**: ajusta `cfg.FFB_GAIN` em ±0.1 por pressão (range 0.0–10.0), com mensagem no jogo
- Usa detecção `justPressed` (edge trigger) — não repete se segurar a tecla

---

## 6. Módulos da UI — Detalhes de Implementação

### 6.1 `TxylorConfig.lua` (Entry Point)

- Janela 530×450 (redimensionável 420×300 até 800×900)
- **Auto-load**: `cio.tryAutoLoad()` uma vez por sessão (match por `car_id`)
- **Debounce save**: quando `data.dirty`, aguarda 0.5s antes de salvar
- **Tab bar custom**: grid 3×3 com 9 abas (drawn manualmente, não usa ImGui nativo)
- Overlays: `tabDirecao.drawGraphs(dt)` e `tabTC.drawGraphs(dt)`
- Footer: botão "Restaurar Padrões", indicador "Salvando.../Salvo./Erro", versão

### 6.2 `cfg_ui.lua` (Helpers de UI)

- **Cores dinâmicas**: header, accent, hint, line — todas configuráveis via sliders RGB
- **Widgets reutilizáveis**:
  - `cfgSlider()` — float com tooltip e indicador de alterado (●)
  - `cfgSliderInt()` — inteiro (usa `%.0f` pois CSP não suporta `%d`)
  - `cfgCheckbox()` — toggle boolean
  - `levelSelector()` — botões ◄/► para selecionar nível 0-N, mostra dados do nível
  - `header()`, `hint()`, `info()` — textos estilizados
- **Tab bar**: desenhada manualmente com `drawRectFilled`, hover detection, click detection

### 6.3 `cfg_io.lua` (I/O + Presets)

- **Formato INI custom**: formata valores com casas decimais variáveis conforme o campo
- **Migração de formatos antigos**:
  - `abs_threshold`: float antigo (0.032) → inteiro novo (32)
  - `abs_min_brake`: float antigo (0.00-0.50) → inteiro novo (0-100)
  - `abs_curve_factor`: float antigo (0.0-2.0) → inteiro novo (0-10)
  - Campos TC: vários formatos antigos → inteiros novos
- **Sistema de Presets**:
  - Diretório: `apps/lua/TxylorConfig/presets/*.ini`
  - Cada preset armazena todos os campos + `car_id` + `author` + `version`
  - **Auto-load**: match por `car_id` ao entrar no carro (uma vez por sessão)
  - Funções: save, load, delete (com confirmação), refresh list

### 6.4 `tab_direcao.lua`

- **Monitor em tempo real** com barras (Mouse, Steer, FFB)
  - Funciona em **replay** (usa `ac.getCar(0)`), mas Mouse só em jogo (via `ac.load`)
  - **Indicador de clipping**: barra fica vermelha quando o valor atinge ≥98% do range (mouse, steer ou FFB)
  - Gráfico de linha histórico (120 amostras, ~30fps)
- **Sliders de direção**: FFB Gain, Gyro Gain, Steer Align, FFB Damper, FFB Lateral, Steer Sensi, Steer Limit, Steer Deadzone, Steer Gamma, Steer Filter, Reversal Limit, Speed Sensi
- **Overlays de gamma**: gráficos de curva para `steer_gamma` e `ffb_gamma` (botão "~" ao lado do slider)
- **Presets de direção** (6 botões, 3 por linha):
  - 💨 **Drift** — Sensi alta, counter-steer forte
  - 🏔️ **Touge** — Sensi média-alta, FFB firme
  - 🏁 **Circuito** — Setup balanceado
  - 🌲 **Rally** — Sensi alta, FFB forte
  - 🏎️ **Formula** — Sensi baixa, FFB preciso
  - 🏎 **Kart** — Sensi alta, limit baixo
  - Cada preset aplica 12 parâmetros de uma vez
- Botão "⊙ Monitor" toggle

### 6.5 `tab_tc.lua`

- **Monitor inline**: barras de Slip e Corte em tempo real (com linha de threshold)
- Seletor de nível 0–20 com nomes descritivos em português
- Quando nível ≥ 1: aplica valores da tabela automaticamente
- Modo Manual (0): sliders individuais de threshold, gás mínimo, intensidade, smooth
- **Avançado**: divisor ndSlip (10–50) e fator de curva (0–10)

### 6.6 `tab_abs.lua`

- Seletor de nível 0–20 com nomes descritivos
- Quando nível ≥ 1: aplica valores da tabela automaticamente
- Modo Manual (0): sliders individuais de threshold, freio mínimo, intensidade, smooth
- **Comportamento em curva**: fator de curva (0–20) com preview de threshold em reta/curva 50%/curva 100%
- **Trail Brake**: intensidade (0–10) e ponto de início (0–10)
- **Estabilidade**: Rear Bias (0–10)
- **Recuperação**: Brake Recovery (0–100, 0 = usa o smooth)
- **Avançado**: divisor ndSlip (1.0–5.0)

### 6.7 `tab_transmissao.lua`

- **Auto-Clutch**: checkbox + profundidade (0–100%), velocidades de pressionar/soltar (1.0–10.0)
- **Anti-Stall**: checkbox + RPM idle detectado automaticamente, margem RPM (5–50%), bite point (10–100%), velocidades de engate total/mínima/engatar/desengatar/proteção reversa
- **Auto-Blip**: checkbox + modo Automático/Manual
  - Automático: usa gear ratio real do carro, apenas RPM mínimo ajustável
  - Manual: intensidade, duração, sensibilidade, RPM mínimo + avançados (attack/release)
  - Slider de RPM mínimo com range dinâmico: mínimo = RPM idle detectado, máximo = RPM limiter do carro
- **No-Lift Shift**: checkbox + teto mínimo (0–100%), RPM mínimo (1000–9000), velocidade de transição (1.0–10.0), duração adaptativa (on/off)

### 6.8 `tab_presets.lua`

- Input text para nome do preset
- Lista de presets com: nome, car_id (verde se match), botões Carregar/X
- Confirmação de deleção ("Confirmar? Sim/Não")
- Mensagens de status (salvo, carregado, erro, auto-load)

### 6.9 `tab_keybinds.lua`

- **Captura de teclas**: clica em "Alterar", pressiona a tecla (ESC cancela)
- Tabela de VK codes → nomes legíveis (A-Z, 0-9, F1-F12, Num0-Num9, setas, etc.)
- Teclas scaneáveis filtradas
- Botão "x" para limpar (setar para 0)
- **Seções organizadas**:
  - **Controles Diretos**: Embreagem Manual, Freio de Mão (segurar para ativar)
  - **Toggles**: ABS, TC, Launch Control, Cruise Control, AutoClutch
  - **Direção**: FFB Gain +, FFB Gain - (ajuste em tempo real durante pilotagem)

---

## 7. Versões Atuais

| Componente | Versão | Local |
|---|---|---|
| TxylorMouseSteer | **v1.0** | `manifest.ini` |
| TxylorConfig | **v6.2.0** | `manifest.ini` + `TxylorConfig.lua` |
| Preset version | **v6.3.0** | `cfg_io.lua` (campo `version` no preset) |

---

## 8. Hotkeys Hardcoded no Script

| Tecla | Função |
|---|---|
| **N** | Toggle mouse steering on/off |
| **M** | Cicla modo: Mouse → Teclado → Híbrido |
| **E / Botão 6** | Marcha para cima |
| **Q / Botão 5** | Marcha para baixo |
| **X** | Arm Launch Control (só quando parado) |

**Nota:** FFB Gain (+/-), ABS, TC, Launch, Cruise e AutoClutch agora são **configuráveis via tab_keybinds.lua** — não são mais hardcoded.

---

## 9. Workflow Git

```bash
git add .
git commit -m "fix/feat/refactor: descrição"
git push origin main
```

Convenções:
- `fix:` — correção de bug
- `feat:` — nova funcionalidade
- `refactor:` — reorganização / limpeza

---

## 10. Invariantes e Regras de Ouro

1. **Nunca altere apenas uma tabela de nível** — `ABS_LEVEL_DATA` (UI) e `ABS_LEVELS` (script) devem espelhar-se.
2. **Nunca altere apenas uma tabela de nível TC** — `TC_LEVEL_DATA` (UI) e `TC_LEVELS` (script) devem espelhar-se.
3. **Nunca inverta a ordem do pipeline de gás** — `NLS → Blip → TC` é sagrada.
4. **Sempre atualize ambas as escalas** quando mexer em campos que têm transformação (ex: `ffb_gain` 0.8 na UI = 0.8 no script, mas `gyro_gain` 4.0 na UI = 8.0 no script).
5. **O script nunca escreve no config.ini** — só a UI escreve.
6. **A UI nunca lê do config.ini em tempo real** — ela trabalha com `cfg_data.cfg` em memória e salva com debounce.
7. **Migração de formatos** — `cfg_io.lua` tem lógica para converter configs antigas. Novos campos devem seguir o padrão inteiro para parâmetros físicos.
8. **CSP ui.slider não suporta `%d`** — sempre use `%.0f` para inteiros na UI.

---

## 11. Features Experimentais (Revertidas)

Durante o desenvolvimento, as seguintes features foram implementadas e posteriormente **removidas** por não apresentarem diferença perceptível na prática:

### 11.1 Center Spring + FFB Smooth

- **Center Spring**: força que puxa o volante pro centro, independente do FFB. Útil teoricamente quando FFB está fraco, mas na prática não foi perceptível.
- **FFB Smooth**: filtro passa-baixa no sinal FFB bruto antes do processamento. Teoricamente suavizaria oscilações rápidas, mas o efeito foi imperceptível comparado ao `STEER_FILTER` já existente.
- **Motivo da remoção**: os 3 primeiros ajustes da aba Direção (Steer Filter, FFB Damper, FFB Gamma) já cobrem bem o comportamento desejado. Complexidade adicional sem ganho real.

### 11.2 Road Feel

- **Conceito**: vibração de textura da pista baseada em `suspensionTravel * angularSpeed` das 4 rodas, com suavização e clamping.
- **Motivo da remoção**: efeito imperceptível em testes práticos. O sistema FFB já existente (Damper, Lateral, Gyro) já transmite informação de pista suficiente.

> **Lição**: nem toda feature técnica se traduz em experiência perceptível. Testar sempre antes de manter.

---

*Documento gerado em análise completa do código-fonte. Última atualização: 30/04/2026.*
