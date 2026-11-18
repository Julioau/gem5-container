# gem5 em Container (INF01113 / ORGB — Trabalho Prático 2)

Este diretório substitui a VM de **4,3 GiB** (`gem5 VirtualBox.ova`) por um container leve baseado em **Ubuntu 18.04 LTS + Python 2.7** usando **exatamente o mesmo binário `gem5.opt` pré-compilado da VM do professor** e os mesmos scripts `orgb_configs`, `configs/minhas_configs` e `orgb_progs`.

- **Zero compilação do gem5:** o binário pré-compilado da VM já está incluído (apenas sem os ~605 MiB de símbolos de debug DWARF, reduzindo o total da pasta para ~35 MiB), então o `build` da imagem leva poucos segundos.
- **Compatível com Podman e Docker:** há um `Containerfile` e um symlink `Dockerfile -> Containerfile`.
- **Mesmos caminhos da VM:** usuário `orgb` (senha `orgb`) e diretório de trabalho `/home/orgb/gem5`.

---

## Pré-requisitos

- **Podman** ou **Docker** instalado no Linux (ou WSL2/Docker Desktop no Windows/macOS).

---

## 1. Construir a imagem (instantâneo)

Entre na pasta `gem5-container/` e execute **um** dos comandos abaixo:

- **Com Podman:**
  ```bash
  podman build -t gem5-orgb .
  ```
- **Com Docker:**
  ```bash
  docker build -t gem5-orgb .
  ```

---

## 2. Iniciar o container

### Modo simples (tudo dentro do container)

Ideal para testar rapidamente o ambiente padrão:

- **Podman:**
  ```bash
  podman run --rm -it gem5-orgb
  ```
- **Docker:**
  ```bash
  docker run --rm -it gem5-orgb
  ```

### Modo recomendado (pastas sincronizadas com o seu computador)

Montando `orgb_configs`, `orgb_progs` e `m5out` como volumes, você edita os arquivos `.py` e `.c` no seu editor local (VS Code, Neovim, etc.) e os resultados gerados em `m5out/` permanecem salvos na sua máquina mesmo depois de sair do container.

Antes de iniciar, crie a pasta de saída no host:

```bash
mkdir -p m5out
```

- **Podman** (`--userns=keep-id` e `:Z` mantêm permissões e rótulos SELinux corretos):
  ```bash
  podman run --rm -it --userns=keep-id \
    -v ./orgb_configs:/home/orgb/gem5/orgb_configs:Z \
    -v ./orgb_progs:/home/orgb/gem5/orgb_progs:Z \
    -v ./m5out:/home/orgb/gem5/m5out:Z \
    gem5-orgb
  ```
- **Docker:**
  ```bash
  docker run --rm -it \
    -v "$PWD/orgb_configs:/home/orgb/gem5/orgb_configs" \
    -v "$PWD/orgb_progs:/home/orgb/gem5/orgb_progs" \
    -v "$PWD/m5out:/home/orgb/gem5/m5out" \
    gem5-orgb
  ```

---

## 3. Passo a passo de uso dentro do container

Ao entrar no container, você já estará em `/home/orgb/gem5` como usuário `orgb`.

### Testar o binário `hello` incluído no gem5

```bash
./gem5 orgb_configs/simulate.py run-benchmark -c tests/test-progs/hello/bin/x86/linux/hello
```

### Compilar e rodar um programa em C (`orgb_progs/hello.c`)

O modo *Syscall Emulation* (`SE`) do gem5 exige binários ligados estaticamente (**obrigatório usar `-static`**):

```bash
gcc orgb_progs/hello.c -o orgb_progs/hello -static
./gem5 orgb_configs/simulate.py run-benchmark -c orgb_progs/hello
```

### Passar argumentos para o programa (`-o`) ou salvar em outra pasta (`-d`)

Note que `-d <pasta>` é argumento do próprio `./gem5` (vai **antes** de `orgb_configs/simulate.py`), enquanto `-c` e `-o` vão depois de `run-benchmark`:

```bash
./gem5 -d m5out/teste1 orgb_configs/simulate.py run-benchmark -c orgb_progs/hello -o "arg1 arg2"
```

### Script alternativo (`configs/minhas_configs/` — Anexo A da especificação)

Os scripts originais do Anexo A também estão incluídos em `configs/minhas_configs/`:

```bash
./gem5 configs/minhas_configs/single_thread_sim.py -c tests/test-progs/hello/bin/x86/linux/hello
```

---

## 4. Onde alterar os parâmetros da arquitetura

Os arquivos principais para o Trabalho Prático 2 ficam em `orgb_configs/`:

- **CPU superescalar (`MyO3CPU`) e Preditor de Desvios:** `orgb_configs/systems/cpus/MyO3CPU.py`
  - **Preditor de desvios** (linha 127): `branchPred = TournamentBP()` (outros disponíveis no gem5, ex.: `LocalBP()`, `BiModeBP()`).
  - **Larguras do pipeline** (linhas 178–185): `fetchWidth`, `decodeWidth`, `renameWidth`, `dispatchWidth`, `issueWidth`, `wbWidth`, `commitWidth`, `squashWidth`.
  - **Buffers, filas e registradores físicos** (linhas 161–169): `fetchBufferSize`, `fetchQueueSize`, `numIQEntries`, `numROBEntries`, `LQEntries`, `SQEntries`, `numPhysIntRegs`, `numPhysFloatRegs`.
  - **Latências entre estágios** (linhas 134–154) e **Unidades Funcionais** (`MyFUPool`, linhas 52–113).
- **Memória Cache (L1I, L1D, L2 e L3):** `orgb_configs/systems/caches/basic_caches.py`
  - Classes `BasicL1ICache`, `BasicL1DCache`, `BasicL2Cache`, `BasicL3Cache`: `size`, `assoc`, `tag_latency`, `data_latency`, `response_latency`, `mshrs`, `tgts_per_mshr`.
- **Clock do sistema (`clk_domain`):** `orgb_configs/systems/base_system.py`
  - Linha 20: `self.clk_domain.clock = '2.0GHz'`.

---

## 5. Onde ler os resultados (`m5out/stats.txt`)

Após cada simulação, o gem5 grava o relatório completo em `m5out/stats.txt` (ou na subpasta passada em `-d`). Métricas principais pedidas na especificação:

| Métrica no `stats.txt` | Significado |
| --- | --- |
| `sim_seconds` | Tempo total simulado (segundos) |
| `sim_insts` | Número de instruções simuladas |
| `system.cpu.numCycles` | Total de ciclos da CPU |
| `system.cpu.ipc` | Instruções por ciclo (IPC) |
| `system.cpu.icache.overall_miss_rate::total` | Taxa de miss da cache L1 de instruções |
| `system.cpu.dcache.overall_miss_rate::total` | Taxa de miss da cache L1 de dados |
| `system.l2cache.overall_miss_rate::total` | Taxa de miss da cache L2 |
| `system.l3cache.overall_miss_rate::total` | Taxa de miss da cache L3 |
| `system.cpu.branchPred.condPredicted` | Total de desvios condicionais preditos |
| `system.cpu.branchPred.condIncorrect` | Total de desvios condicionais preditos incorretamente |

Comando rápido para filtrar todas essas métricas de uma vez:

```bash
grep -E '^(sim_seconds|sim_insts|system\.cpu\.(numCycles|ipc|(dcache|icache)\.overall_miss_rate::total|branchPred\.cond(Predicted|Incorrect))|system\.l[23]cache\.overall_miss_rate::total)\b' m5out/stats.txt
```
