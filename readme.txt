# DSS — Dynamic Steering System

Mod Lua para Assetto Corsa com Custom Shaders Patch (CSP). Permite jogar com mouse como volante, com sistemas de assistência (ABS, TC, Launch Control, Cruise Control, etc.).

## Estrutura do Projeto

```
Repositorio DSS/
├── TxylorMouseSteer/        ← Script de gameplay (roda todo frame)
│   ├── assist.lua           ← Entry point / orquestrador do loop principal
│   ├── dss_config.lua       ← Carrega config.ini a cada 1s (chaves UPPERCASE)
│   ├── dss_steering.lua     ← Algoritmo mouse→steer + FFB
│   ├── dss_abs.lua          ← Simulação de ABS (slip-based)
│   ├── dss_tc.lua           ← Controle de tração
│   ├── dss_pedals.lua       ← Rampa de gás/freio/embreagem/freio-de-mão
│   ├── dss_clutch.lua       ← Auto-embreagem + anti-stall
│   ├── dss_blip.lua         ← Auto-blip em downshifts
│   ├── dss_nls.lua          ← No-Lift Shift (power cut em upshifts)
│   ├── dss_launch.lua       ← Launch control
│   ├── dss_cruise.lua       ← Cruise control / speed limiter
│   ├── dss_keybinds.lua     ← Hotkeys configuráveis
│   └── manifest.ini         ← Metadados do script (v1.0)
└── TxylorConfig/            ← App de UI in-game
    ├── TxylorConfig.lua     ← Entry point / roteador de abas
    ├── cfg_data.lua         ← Defaults + tabelas de nível ABS/TC (chaves lowercase)
    ├── cfg_io.lua           ← Leitura/escrita config.ini + sistema de presets
    ├── cfg_ui.lua           ← Helpers de UI compartilhados
    ├── config.ini           ← Arquivo de config compartilhado (gerado/lido por ambos)
    ├── manifest.ini         ← Metadados da app (v6.1.0, window 530×450)
    ├── logo_dss.png         ← Branding
    ├── fonts/               ← Fontes personalizadas
    └── tab_*.lua            ← Uma aba da interface por arquivo
        ├── tab_direcao.lua  ← Steering (inclui gamma curve + monitor FFB)
        ├── tab_pedais.lua   ← Pedals
        ├── tab_abs.lua      ← ABS
        ├── tab_tc.lua       ← Traction Control
        ├── tab_transmissao.lua ← Transmission (Blip, NLS, Launch)
        ├── tab_extras.lua   ← Extras (Cruise, Scroll Gas)
        ├── tab_keybinds.lua ← Keybinds
        ├── tab_presets.lua  ← Preset manager
        └── tab_sobre.lua    ← About
```

## Arquitetura Central

### Dois mundos de config compartilham um arquivo

Ambos os módulos (script e app) lêem/escrevem `config.ini` mas com naming conventions diferentes:

| Aspecto | Game Script | UI App |
|---|---|---|
| Módulo | `dss_config.lua` | `cfg_data.lua` + `cfg_io.lua` |
| Chaves | UPPERCASE (`cfg.FFB_GAIN`) | lowercase (`cfg.ffb_gain`) |
| Escala | Física interna (float) | Escala UI (int ou float exibido) |
| Reload | Polling a cada 1s (`configTimer`) | On require + ação do usuário |
| Escrita | Nunca escreve | Escreve com debounce ~0.5s |

### Pipeline de Execução em `assist.lua` (ordem CRÍTICA)

```
script.update(dt) cada frame
  ├─ tc.detectDrivetrain()
  ├─ config hot-reload (se configTimer >= 1s)
  ├─ keybinds.update(dt)
  ├─ teclas N, +/-, M (toggles mouse, FFB gain, keyboard mode)
  ├─ GAS INPUT
  │  └─ pedals.updateGas(dt, gasTarget, ui)
  ├─ GAS PIPELINE (ORDEM FIXA):
  │  ├─ nls.update(dt, data, gear, gasValue)        ← Power cut em upshift
  │  ├─ blip.update(dt, data, gear, gasValue)       ← Throttle blip em downshift
  │  ├─ tc.update(dt, data, gasValue)                ← Traction control cut
  │  └─ data.gas = finalGasValue
  ├─ launch.update(dt, data)                         ← Pode cortar data.gas ainda mais
  ├─ BRAKE INPUT
  │  └─ pedals.updateBrake(dt, brakeTarget)
  ├─ brake = abs.update(dt, data, brakeValue, steerAngle)
  │  └─ data.brake = finalBrakeValue
  ├─ cruise.update(dt, data)                         ← Cap gás e freio se ativo
  ├─ gear shift (E/Q ou botões 5/6)
  ├─ clutchM.update(dt, data, manual, gear, gasValue)
  ├─ handbrake (smoothed via pedals.updateHandbrake)
  ├─ steering.update(dt, data, ui)                   ← Mouse steering + FFB (só se mouseEnabled)
  └─ steering.sanitize(data)                         ← Sempre (valida steer mesmo sem mouse)
```

**GOTCHA:** A ordem `NLS → Blip → TC` é fixa. Inverter quebra a física.

### Comunicação Script → UI (memória compartilhada CSP)

O script escreve dados em tempo real para a UI via `ac.store()`:

```lua
ac.store("dss_steer_angle", steering.steerAngle)
ac.store("dss_mouse_steer", steering.mouseSteer)
ac.store("dss_ffb_raw", ffb_value)
```

A UI lê com `ac.load()` em `tab_direcao.lua` para exibir monitores em tempo real.

### Escalas ABS (GOTCHA CRÍTICO)

`abs_threshold` e `abs_min_brake` existem em duas escalas:

- **UI / config.ini**: inteiro 1–100 (ex: `26` representa 0.026 de slip)
- **Game script interno**: float (ex: `0.026` = UI value × 0.001)

As tabelas de nível devem ser mantidas em sincronia:
- `ABS_LEVEL_DATA` em `cfg_data.lua` — escala UI (int)
- `ABS_LEVELS` em `dss_config.lua` — escala física (float)

Se uma for alterada, a outra também precisa ser.

### Sistema de Presets

Presets ficam em `apps/lua/TxylorConfig/presets/*.ini`. Cada preset armazena:
- Todos os campos de config
- `car_id` — para auto-load automático
- `author` e `version`

Auto-load acontece uma vez por sessão via `cfg_io.tryAutoLoad()` — match por `car_id`.

### Transformações de Escala na Carga (dss_config.lua)

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
| `speed_sensi` | 0–10 | × 0.1 | `cfg.SPEED_SENSI` |
| `abs_threshold` | 1–100 int | × 0.001 | `cfg.ABS_THRESHOLD` |
| `abs_min_brake` | 0–100 int | × 0.001 | `cfg.ABS_MIN_BRAKE` |

## Fluxo de Trabalho com Git

Cada alteração é commitada e enviada para o GitHub automaticamente:

```bash
git add .
git commit -m "fix: descrição da alteração"
git push origin main
```

Convenções:
- `fix:` — correção de bug
- `feat:` — nova funcionalidade
- `refactor:` — reorganização / limpeza

O histórico de commits é o backup — qualquer versão anterior pode ser restaurada com `git checkout <hash>`.

## Padrão de Chat por Módulo

Para cada novo objetivo:

1. Abrir um chat novo no Claude Code
2. O `CLAUDE.md` é carregado automaticamente
3. Descrever o bug ou melhoria do módulo específico
4. Claude edita apenas os arquivos relevantes
5. Commit + push automático ao final

Exemplo: "Quero melhorar o sistema de ABS" → novo chat focado em `dss_abs.lua` e `tab_abs.lua`.

## Referência CSP

A pasta `Repositorio CSP/` contém o SDK oficial do CSP (somente leitura, não é código do mod).
Deixado como referência para consultar a API do Assetto Corsa.

## Versioning

- **TxylorMouseSteer**: v1.0 (manifest.ini)
- **TxylorConfig**: v6.1.0 (manifest.ini)
