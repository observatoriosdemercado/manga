# Mapa de Seções — Dashboard Mercado de Manga

Inventário do `index.Rmd` atual (1.799 linhas) para guiar a migração para Quarto.

## Visão geral

| # | Menu | Página | Linhas Rmd | Linhas (#) | Fonte primária | Migrado |
|---|---|---|---|---|---|---|
| 1 | DADOS GERAIS | **BRASIL** | 67–283 | 217 | IBGE/PAM | ✅ (protótipo) |
| 2 | DADOS GERAIS | **VALE DO S. FRANCISCO** | 284–451 | 168 | IBGE/PAM | ✅ (protótipo) |
| 3 | MERCADO INTERNO | **VOLUME CEASAS** | 452–719 | 268 | CEAGESP / CONAB | ⏳ |
| 4 | MERCADO INTERNO | **CONSUMO MANGA** | 720–938 | 219 | POF/IBGE | ⏳ |
| 5 | MERCADO INTERNO | **MERCADO TRABALHO** | 939–1208 | 270 | Caged/MTE | ⏳ |
| 6 | PREÇOS AO PRODUTOR | **PALMER** | 1209–1510 | 302 | CEPEA/ESALQ + IGP-DI | ⏳ |
| 7 | PREÇOS AO PRODUTOR | **TOMMY** | 1511–1799 | 289 | CEPEA/ESALQ + IGP-DI | ⏳ |

**Total:** 3 menus, 7 páginas. Página externa de metodologia (`/fonte/`) fica fora deste repositório.

---

## Detalhe por seção

### 1. BRASIL — DADOS GERAIS
- **Linhas:** 67–283
- **Dados:** `manga_ibge2024.xlsx` (filtro `abrangencia == 'brasil'`)
- **Conteúdo:** 4 valueBoxes (área, produtividade, volume, VBP) + 4 gráficos de barra anuais 2011–2024
- **Atualização:** anual (saída do PAM em setembro)
- **Migrado em:** `prototipo_quarto/dashboard.qmd`

### 2. VALE DO S. FRANCISCO — DADOS GERAIS
- **Linhas:** 284–451
- **Dados:** mesmo arquivo, filtro `abrangencia == 'vale'`
- **Conteúdo:** espelho da BRASIL com escalas próprias
- **Migrado em:** `prototipo_quarto/dashboard.qmd`

### 3. VOLUME CEASAS — MERCADO INTERNO
- **Linhas:** 452–719
- **Dados:** `ceagesp_total.xlsx`, `ceagesp_variedades.xlsx`, `ceagesp_tempo.xlsx`
- **Conteúdo:** 3 valueBoxes (volume total + por variedade Palmer/Tommy) + 4 gráficos: série mensal CEAGESP, tendência (decomposição), estatísticas de oferta, comparação por variedade
- **Nota:** dados parados em 2021–2022 (verificar com usuário se ainda fazem sentido)

### 4. CONSUMO MANGA — MERCADO INTERNO
- **Linhas:** 720–938
- **Dados:** `consumo_brasil.xlsx`, `consumo_estados.xlsx`, `consrenda_brasil.csv`
- **Conteúdo:** 3 valueBoxes (per capita, região Sul, Centro-Oeste) + 4 gráficos: evolução do consumo, variação por região, faixas de renda
- **Atualização:** POF é decenal (próxima ~2027–2028)

### 5. MERCADO TRABALHO — MERCADO INTERNO
- **Linhas:** 939–1208
- **Dados:** `marco_2026.csv` (Caged) — ⚠ **arquivo muda todo mês**
- **Conteúdo:** 3 valueBoxes (admissões, desligamentos, saldo) + 4 gráficos: série mensal de saldo, distribuição por gênero, idade, grau de instrução
- **Atualização:** mensal — bom candidato a parametrizar o nome do arquivo

### 6. PALMER — PREÇOS AO PRODUTOR
- **Linhas:** 1209–1510
- **Dados:** `dados_manga_palmer_semana.csv` + `igpdi.csv` (deflator)
- **Conteúdo:** 3 valueBoxes (preço semana atual / mesma semana ano anterior / 2 anos atrás) + 4 gráficos: mín/máx/média histórica por semana, variação semanal, preço + tendência (HP filter), sazonalidade (decomposição STL)
- **Atualização:** semanal — usa `isoweek(Sys.Date())`
- **Modelagem pesada:** `mFilter`, `forecast::stl`, `seasonal::seas`

### 7. TOMMY — PREÇOS AO PRODUTOR
- **Linhas:** 1511–1799
- **Dados:** `dados_manga_tommy_semana.csv` + `igpdi.csv`
- **Conteúdo:** espelho de PALMER com a variedade Tommy Atkins

---

## Padrões observados (oportunidades de refatoração)

1. **Carregamento de pacotes duplicado** — `library(...)` repetido no `setup` chunk e em cada bloco de página (≈30 linhas por bloco). Em Quarto, basta um `setup`.
2. **`setwd()` hardcoded** repetido em cada página. Mover para parâmetro YAML ou variável global.
3. **Tema ggplot copiado** — o mesmo bloco `theme(axis.text.x=..., axis.text.y=..., ...)` aparece ~25 vezes. Já abstraído em `tema_card()` no protótipo.
4. **Cores hardcoded** (`mycolor1 <- "gold"`, etc.) — substituir pela paleta sóbria do `custom.scss`.
5. **Datas hardcoded** — linha 64 do Rmd: *"Linhas que precisam de ajuste: 71, 104, 107"*. Em Quarto, parametrizar via `params:` no YAML.
6. **Nomes de arquivo com ano fixo** — `manga_ibge2024.xlsx`, `marco_2026.csv`. Trocar por padrão `glue::glue()` ou listar o mais recente automaticamente.

## Ordem de migração sugerida

A ordem balanceia valor entregue × esforço × risco:

1. ✅ **BRASIL + VALE** — feito (validar visual)
2. **PALMER + TOMMY** — alta visibilidade (atualização semanal), código analítico mais complexo (tendência + sazonalidade), bom para validar que o `plotly` interativo funciona bem
3. **MERCADO TRABALHO** — atualização mensal, bom para validar parametrização de arquivo
4. **VOLUME CEASAS** — verificar antes se os dados continuarão sendo atualizados
5. **CONSUMO MANGA** — POF decenal, menos urgente

## Próximas decisões a tomar

- **Onde fica o repositório Git?** O dashboard publicado está em `observatoriosdemercado.github.io/manga` — o Rmd está versionado em algum lugar?
- **Atualizar dados é parte do escopo?** Ex: criar script de download automático CEPEA/Caged ou manter manual.
- **Adicionar uma sidebar de filtros?** Quarto dashboard suporta `sidebar` global — útil para filtros (variedade, ano, região).
- **Língua única ou bilingual?** Hoje tudo em PT-BR; manter assim.
