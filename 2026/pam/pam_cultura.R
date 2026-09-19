# Específico da MANGA: configuração e texto da introdução (_intro.qmd).
# Usado junto com pam_funcoes.R (genérico, idêntico ao da uva).

# ---- Configuração da cultura --------------------------------------------------
pam_cfg <- list(
  cultura     = "manga",
  produto     = "c782/40262",           # SIDRA 5457: classificação 782, categoria 40262 = Manga
  pasta_dados = "dados_manga",          # tempecon/<pasta_dados>/<ano>/
  excluir_rs  = FALSE,                  # manga: não subtrai o RS dos totais (uva: TRUE)
  n_estados   = 6,                      # estados nos gráficos e tabelas
  n_cidades   = 20,                     # cidades nos gráficos e tabelas
  cor_cidade  = "orange",               # cor das barras de cidades
  rotulos     = c("Rio Grande do Norte" = "Rio G. do Norte")   # nomes abreviados nos gráficos
)

# Devolve os trechos (strings) usados na introdução de index.qmd e do boletim.
# Pontos de partida: objetos area, quanti, valor e prod já carregados.
pam_texto <- function(area, quanti, valor, prod) {
  fim <- max(area$regioes$ano); ant <- fim - 1; ini <- min(area$regioes$ano)
  no  <- \(d, l, a = fim) d$valor[d$local == l & d$ano == a]                # valor de um local/ano
  top <- \(d, n = Inf) d |> filter(ano == fim) |> arrange(desc(valor)) |> head(n)
  mil <- \(x, dg = 1) pam_fmt(x / 1000, dg)
  pct <- \(x, tot, dg = 1) pam_fmt(x / tot * 100, dg)
  vale <- "Vale do São Francisco"
  uma_reducao <- \(s) sub("um redução", "uma redução", s)
  t <- list(ini = ini, fim = fim, ibge = fim + 1)                           # ibge = ano de divulgação

  # ---- área
  abr <- no(area$regioes, "Brasil")
  t$area_br <- mil(abr)
  reg <- top(filter(area$regioes, local != "Brasil"), 2)
  t$area_regioes <- pam_lista(sprintf("a %s, com %s mil ha (%s%% do total)", reg$local, mil(reg$valor), pct(reg$valor, abr)))
  est <- top(area$estados)
  t$area_estados     <- pam_lista(sprintf("%s (%s mil ha)", est$local, mil(est$valor)))
  t$area_estados_pct <- pam_lista(paste0(pct(est$valor, abr), "%"))
  a0 <- no(area$vale, vale, ant); a1 <- no(area$vale, vale)
  t$area_vale <- uma_reducao(sprintf("%s, saindo de %s mil ha em %d para %s mil ha em %d, segundo o IBGE (%d), um %s.",
    if (a1 >= a0) "O Vale do São Francisco mantém sua trajetória de crescimento de área" else "A área do Vale do São Francisco variou no último ano",
    mil(a0), ant, mil(a1), fim, fim + 1, pam_var(a1, a0, "aumento", "redução")))
  c1 <- top(area$cidades, 1)
  t$area_cidade <- sprintf("A cidade de %s é a que possui a maior área plantada de manga no país, com %s mil ha.",
                           sub(" [(](..)[)]$", "/\\1", c1$local), mil(c1$valor))

  # ---- quantidade
  brq <- no(quanti$regioes, "Brasil"); neq <- no(quanti$regioes, "Nordeste"); qv <- no(quanti$vale, vale)
  milhoes <- \(x) if (x >= 1e6) paste(pam_fmt(x / 1e6, 2), "milhões de") else paste(mil(x), "mil")
  t$quanti_br <- milhoes(brq)
  t$quanti_ne <- pam_fmt(neq / brq * 100, 0)
  t$quanti_vale_pct <- pct(qv, brq)
  c4 <- top(quanti$cidades, 4)
  t$quanti_cidades     <- pam_lista(sprintf("%s com %s mil t", c4$local, mil(c4$valor)))
  t$quanti_cidades_pct <- pam_fmt(sum(c4$valor) / neq * 100, 0)
  t$quanti_vale <- uma_reducao(sprintf("O Vale do São Francisco produziu cerca de %s toneladas, um %s em relação ao volume de %d.",
    milhoes(qv), pam_var(qv, no(quanti$vale, vale, ant)), ant))

  # ---- produtividade (t/ha)
  pne <- no(prod$regioes, "Nordeste"); pbr <- no(prod$regioes, "Brasil")
  t$prod_ne <- pam_fmt(pne, 1); t$prod_br <- pam_fmt(pbr, 1)
  t$prod_comp <- if (pne >= pbr) "maior" else "menor"
  pe <- top(prod$estados, 3)
  t$prod_estado1 <- as.character(pe$local[1])
  t$prod_estados <- sprintf("%s t/ha", pam_fmt(pe$valor / 1000, 1))
  t$prod_seguido <- pam_lista(sprintf("%s (%s t/ha)", pe$local[-1], pam_fmt(pe$valor[-1] / 1000, 1)))
  pc <- top(prod$cidades, 1)
  t$prod_cidade <- sprintf("A cidade de %s tem a maior produtividade entre as principais cidades produtoras (%s t/ha).",
                           pc$local, pam_fmt(pc$valor, 1))
  pv <- no(prod$vale, vale); pv0 <- no(prod$vale, vale, ini)
  t$prod_vale <- sprintf("O Vale do São Francisco possui uma produtividade %s à média regional, cerca de %s t/ha, na média. No ano de %d, a produtividade nesta região foi de %s t/ha.",
    if (pv >= pne) "superior" else "inferior", pam_fmt(pv, 0), ini, pam_fmt(pv0, 1))
  t$prod_vale_expl <- if (pv > pv0 && no(area$vale, vale) > no(area$vale, vale, ini))
    " Assim, a explicação para o grande crescimento do volume de mangas no Vale do São Francisco tem dois fatores, o crescimento da área e o crescimento da produtividade por área."
  else ""

  # ---- valor da produção (mil R$ -> bilhões)
  vbr <- no(valor$regioes, "Brasil"); vv <- no(valor$vale, vale)
  t$valor_br <- pam_fmt(vbr / 1e6, 1)
  t$valor_vale_pct <- pam_fmt(vv / vbr * 100, 0)
  t$valor_vale <- pam_fmt(vv / 1e6, 1)
  t
}
