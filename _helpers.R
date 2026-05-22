#' Helpers analíticos para o Dashboard Mercado de Manga (Quarto)
#'
#' Centraliza a preparação de séries de preços CEPEA (Palmer/Tommy),
#' deflacionamento por IGP-DI, decomposição STL e cálculos comparativos.

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
  library(tidyr)
  library(tsutils)
  library(lubridate)
})

DADOS_DIR <- "C:/Users/Lenovo/Dropbox/tempecon/dados_manga"

#' Lê uma série semanal CEPEA e a tabela de IGP-DI, retornando o data.frame
#' com a coluna `preco_def` (deflacionada para o último IGP-DI disponível) e
#' uma coluna `date` semanal.
ler_serie_preco <- function(arquivo_csv, dir = DADOS_DIR) {
  dados <- read.csv2(file.path(dir, arquivo_csv),
                     header = TRUE, sep = ";", dec = ".")
  colnames(dados)[1] <- "produto"

  igpdi <- read.csv2(file.path(dir, "igpdi.csv"),
                     header = TRUE, sep = ";", dec = ".")

  # Alinhar pelo menor comprimento (Palmer/Tommy e IGP-DI podem ficar
  # temporariamente fora de sincronia entre atualizacoes).
  n <- min(nrow(dados), nrow(igpdi))
  dados <- dados[seq_len(n), , drop = FALSE]
  igpdi <- igpdi[seq_len(n), , drop = FALSE]

  dados_comb <- cbind(dados, igpdi)
  dadosp <- dados_comb[, -c(1, 2, 6, 7)]
  colnames(dadosp) <- c("ano", "semana", "preco", "igpdi")

  dadosp$preco_def <- dadosp$preco * (tail(dadosp$igpdi, 1) / dadosp$igpdi)

  date <- seq(as.Date("2012-01-07"), by = "1 week", length.out = nrow(dadosp) + 5)
  date <- date[date != as.Date("2016-12-31")]
  date[date == as.Date("2022-12-31")] <- as.Date("2023-01-01")
  date <- date[date != as.Date("2023-12-30")]
  dadosp$date <- date[seq_len(nrow(dadosp))]

  dadosp
}

#' Computa todos os objetos analíticos a partir do data.frame retornado por
#' `ler_serie_preco()`: série temporal, tendência (centered moving average),
#' sazonalidade multiplicativa, envelope mín/méd/máx por semana e tabelas de
#' variação semanal para os últimos anos.
analise_preco <- function(dadosp, ano_atual, semana_atual) {
  preco_ts <- ts(dadosp$preco_def, start = c(2012, 1), frequency = 52)

  trend <- as.numeric(cmav(preco_ts, outplot = FALSE))

  decompa <- decompose(preco_ts, type = "multiplicative")
  saz <- tibble(semana = 1:52, fator = as.numeric(decompa$figure))

  # Envelope mín/méd/máx considera anos completos até ano_atual-1
  preco_completo <- window(preco_ts, end = c(ano_atual - 1, 52))
  seas_ref <- seasplot(preco_completo, trend = FALSE, outplot = FALSE)
  medias <- colMeans(seas_ref$season)[1:52]

  envelope <- tibble(
    semana = 1:52,
    minimo = apply(seas_ref$season, 2, min)[1:52],
    media  = round(medias, 2),
    maximo = apply(seas_ref$season, 2, max)[1:52]
  )

  # Preços por ano (52 semanas, preenchidos com NA quando faltam)
  preco_por_ano <- function(yr) {
    v <- dadosp %>% filter(ano == yr) %>% pull(preco_def)
    out <- rep(NA_real_, 52)
    out[seq_along(v)] <- v
    out
  }
  anos_recentes <- tibble(
    semana = 1:52,
    `Ano anterior 2` = round(preco_por_ano(ano_atual - 2), 2),
    `Ano anterior 1` = round(preco_por_ano(ano_atual - 1), 2),
    `Ano atual`      = round(preco_por_ano(ano_atual),     2)
  )
  names(anos_recentes)[2:4] <- c(as.character(ano_atual - 2),
                                 as.character(ano_atual - 1),
                                 as.character(ano_atual))

  # Variação semanal % (ano corrente e ano anterior)
  var_pct <- function(v) (v / dplyr::lag(v) - 1) * 100
  variacao <- tibble(
    semana = 1:52,
    !!as.character(ano_atual - 1) := round(var_pct(preco_por_ano(ano_atual - 1)), 2),
    !!as.character(ano_atual)     := round(var_pct(preco_por_ano(ano_atual)),     2)
  )

  list(
    serie    = dadosp,
    ts       = preco_ts,
    trend    = trend,
    sazonal  = saz,
    envelope = envelope,
    anos     = anos_recentes,
    variacao = variacao,
    preco_atual = tail(na.omit(dadosp$preco_def), 1),
    preco_mesma_sem_ano_ant1 = preco_por_ano(ano_atual - 1)[semana_atual],
    preco_mesma_sem_ano_ant2 = preco_por_ano(ano_atual - 2)[semana_atual]
  )
}

#' Formata um valor monetário em R$ usando vírgula decimal brasileira.
fmt_brl <- function(x, casas = 2) {
  if (is.na(x)) return("—")
  paste0("R$ ", format(round(x, casas),
                       decimal.mark = ",",
                       big.mark = ".",
                       nsmall = casas))
}

#' Remove artefatos que o ggplotly insere nos nomes dos traces:
#'   - sufixos ",1", ",2", ",NA" gerados quando uma variavel esta
#'     mapeada em mais de uma estetica (ex: color + linetype + fill)
#'   - nomes envoltos em parenteses tipo "(serie,1,NA)" -> "serie"
#' Tambem evita que a mesma serie apareca duas vezes na legenda.
limpar_legenda_plotly <- function(p) {
  limpar_nome <- function(x) {
    if (is.null(x)) return(x)
    # (X,Y,Z,...) -> X
    x <- sub("^\\(([^,]+).*\\)$", "\\1", x)
    # X,1  ou  X,NA  -> X  (repete enquanto houver sufixo do tipo)
    repeat {
      novo <- sub(",(\\d+|NA)$", "", x)
      if (identical(novo, x)) break
      x <- novo
    }
    x
  }

  p$x$data <- lapply(p$x$data, function(d) {
    if (!is.null(d$name))        d$name        <- limpar_nome(d$name)
    if (!is.null(d$legendgroup)) d$legendgroup <- limpar_nome(d$legendgroup)
    d
  })

  vistos <- character(0)
  p$x$data <- lapply(p$x$data, function(d) {
    if (!is.null(d$name) && d$name %in% vistos) {
      d$showlegend <- FALSE
    } else if (!is.null(d$name)) {
      vistos <<- c(vistos, d$name)
    }
    d
  })
  p
}
