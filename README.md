# Protótipo Quarto — Dashboard Mercado de Manga

Comparação visual entre o `flexdashboard` atual e o novo formato `Quarto dashboard`.

## Como renderizar

No RStudio:
1. Abra `dashboard.qmd`
2. Clique em **Render** (ou Ctrl+Shift+K)

No terminal:
```powershell
quarto render dashboard.qmd
```

Saída: `dashboard.html` (estático, pronto para GitHub Pages).

## Pré-requisitos

- Quarto >= 1.4 (https://quarto.org/docs/get-started/)
- R com os pacotes: `readxl`, `dplyr`, `ggplot2`, `plotly`, `scales`, `tidyr`, `knitr`

## O que mudou em relação ao Rmd atual

| Aspecto | flexdashboard (atual) | Quarto dashboard (protótipo) |
|---|---|---|
| Framework CSS | Bootstrap 3/4 | Bootstrap 5 |
| Layout | `Row { -height }` | `## Row {height=N%}` + colunas com `.tabset` |
| Cards | Bordas duras | Sombra suave, cantos arredondados |
| Tipografia | Default | Inter / system-ui |
| Valueboxes | `valueBox()` em chunk R | Sintaxe `:::` declarativa |
| Tema | `bootswatch` | SCSS customizável (`custom.scss`) |
| Tabs internas | Não nativo | `### Column {.tabset}` |

O código analítico em R continua **idêntico** — só muda a apresentação.
