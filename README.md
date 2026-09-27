# Ocorrências registradas em Sorocaba — MVP de Engenharia de Dados

Pipeline em Databricks que transforma arquivos anuais da Secretaria da Segurança
Pública do Estado de São Paulo (SSP-SP) em tabelas Delta nas camadas Bronze,
Silver e Gold. O recorte cobre ocorrências cuja circunscrição pertence a Sorocaba
(código IBGE `3552205`) nos quatro anos completos de 2022 a 2025.

> **Autoria e modalidade:** trabalho individual de **Paulo Musachio
> (`pmusachio`)** para o MVP de Engenharia de Dados. As decisões, o código, a
> execução e a interpretação dos resultados são de responsabilidade do autor.

> **Estado desta versão:** pipeline executado integralmente no Databricks em 8 de
> setembro de 2026. As contagens, conclusões e limitações abaixo foram obtidas das
> tabelas persistidas no Unity Catalog.

## 1. Contexto de Negócio e Perguntas

### Problema e objetivo

Os dados de ocorrências policiais são publicados em arquivos anuais extensos, com
variações de esquema e valores ausentes. Isso dificulta a consulta conjunta do
histórico municipal. Este MVP cria uma base persistente, documentada e verificável
para analisar **ocorrências registradas** em Sorocaba. Elas não são tratadas como
medida direta de criminalidade real, risco individual ou efetividade policial.

O público interessado inclui estudantes, pesquisadores e cidadãos que desejem
consultar estatísticas descritivas. O objetivo original considera seis perguntas:

1. Quais bairros concentram mais ocorrências e como isso muda?
2. Existe sazonalidade por dia, mês e horário?
3. Quais tipos predominam por bairro/região?
4. Há tendência de crescimento, queda ou estabilidade?
5. Existe relação entre tipo de local e tipo de ocorrência?
6. Existe correlação espacial entre tipos de ocorrência?

O notebook 03 apresenta três análises viáveis com as tabelas construídas: **A1**,
evolução mensal e anual dos registros; **A2**, frequência e variação anual das
naturezas no município; **A3**, distribuição das principais naturezas por dia da
semana e período do dia. A correspondência parcial entre essas análises e as seis
perguntas originais é avaliada na seção 7. As perguntas não respondidas continuam
fazendo parte do objetivo e são reconhecidas como limitações da entrega.

O período foi limitado a quatro anos completos. O ano parcial de 2026 foi excluído
para não produzir comparações assimétricas.

### Limites de interpretação

- Uma linha representa um registro administrativo, não necessariamente um evento
  independente nem toda a criminalidade ocorrida.
- Um BO pode conter mais de uma natureza; `num_bo` isolado não é chave única.
- Ausência ou imprecisão de data, hora ou classificação reduz a cobertura.
- Os resultados não sustentam causalidade, previsão, comparação de risco individual
  ou recomendação operacional.

## 2. Carga dos Dados

### Fonte e contexto bruto

| Item | Definição |
|---|---|
| Publicador | Secretaria da Segurança Pública do Estado de São Paulo |
| Conjunto | Números sem Mistério / dados criminais |
| Página oficial | [Consultas estatísticas da SSP-SP](https://www.ssp.sp.gov.br/estatistica/consultas) |
| Arquivos | `SPDadosCriminais_2022.xlsx` a `SPDadosCriminais_2025.xlsx` |
| URL direta | `https://www.ssp.sp.gov.br/assets/estatistica/transparencia/spDados/SPDadosCriminais_{ANO}.xlsx` |
| Data de acesso | 5 de setembro de 2026 |
| Abrangência original | Estado de São Paulo |
| Recorte | Circunscrição de Sorocaba, código IBGE `3552205` |
| Período | 2022, 2023, 2024 e 2025 completos |
| Grão | Uma natureza registrada em uma linha de BO |
| Abas e colunas | Duas abas semestrais por ano; 29 colunas fonte em 2022–2024, 30 em 2025 e 33 nomes normalizados distintos na união |
| Tamanho publicado | 2022: 199.282.273 B; 2023: 218.413.769 B; 2024: 197.574.881 B; 2025: 195.899.014 B; o manifesto confirma os bytes efetivamente baixados |
| Termos de uso | A [política de dados abertos da SSP-SP](https://www.ssp.sp.gov.br/transparencia/dados-abertos) prevê acesso e reutilização de dados públicos. Não foi identificada licença Creative Commons específica na página consultada; a evidência dos termos efetivamente exibidos acompanha a entrega. |

A fonte foi escolhida porque contém data e classificação necessárias às perguntas.
Endereços, coordenadas e campos alheios ao recorte analítico não seguem para a
Silver/Gold e nenhum dado bruto é publicado neste repositório.

Checksums observados na coleta de 5 de setembro de 2026:

| Ano | Tamanho (bytes) | SHA-256 |
|---:|---:|---|
| 2022 | 199.282.273 | `608399e58e40da0d8dbb30d73db62add1408b4f354191c12f629b108b8f7e810` |
| 2023 | 218.413.769 | `84c595a451251b3c532f4483a672134813e5ec3e224ca27db58ec4854ee801df` |
| 2024 | 197.574.881 | `b58715efaf1128c971fc5113b5a856cbb29e3e09ece8706e2eec1827fbf10d26` |
| 2025 | 195.899.014 | `4ab5b40229d245a0f50b65e74ea9e9b7750bbdb3bff7b02d961d78b9c4143d8c` |

### Aquisição e persistência

1. Execute [`scripts/coletar_dados.py`](scripts/coletar_dados.py) localmente para
   baixar os quatro XLSX e calcular os checksums.
2. Envie os arquivos, sem alteração, para
   `/Volumes/workspace/sorocaba_seguranca/dados/xlsx/`.
3. Execute [`notebooks/00_coleta_bronze.ipynb`](notebooks/00_coleta_bronze.ipynb), que
   realiza uma carga integral manual de 2022–2025.
4. O notebook valida os arquivos, lê as abas em lotes com `openpyxl`, localiza
   `CD_IBGE` pelo cabeçalho (aceitando também o alias histórico `COD_IBGE`) e
   mantém somente `3552205` na captura Bronze.
5. Os XLSX originais permanecem imutáveis no Volume e não entram no Git.

O filtro durante a leitura reduz memória, mas a Bronze municipal preserva todas as
colunas e valores como texto. Arquivo, aba, ano, instante e hash permitem rastrear
cada linha até sua origem.

![Git folder conectado ao repositório](docs/evidencias/01-git-folder.png)

![Quatro XLSX originais no Volume](docs/evidencias/02-volume-xlsx.png)

![Manifesto da carga Bronze](docs/evidencias/03-manifesto-bronze.png)

![Recorte municipal persistido na Bronze](docs/evidencias/04-bronze-recorte.png)

## 3. Modelagem e Catálogo de Dados

### Arquitetura e grão

```text
SSP-SP
  └─ XLSX 2022–2025 no Unity Catalog Volume (originais imutáveis)
       └─ bronze_manifesto + bronze_recorte_sorocaba
            ├─ perfil_qualidade_bronze (sobre bronze_recorte_sorocaba)
            └─ silver_ocorrencias
                 ├─ perfil_qualidade_silver (sobre silver_ocorrencias)
                 └─ Gold: dim_tempo + dim_periodo_dia + dim_natureza
                            └─ fato_ocorrencia

matriz_transformacoes: documenta as etapas Bronze → Silver → Gold
validacoes_qualidade: verifica tabelas da coleta, Bronze, Silver e Gold
```

- **Plataforma:** Databricks Free Edition.
- **Catálogo/schema:** `workspace.sorocaba_seguranca`.
- **Volume:** `workspace.sorocaba_seguranca.dados`, pasta `xlsx`.
- **Formato:** Delta Lake.
- **Modelo Gold:** esquema estrela.
- **Grão da fato:** uma natureza criminal em um registro-fonte deduplicado de BO
  cuja circunscrição possui código IBGE `3552205`.
- **Medida:** `qtd_ocorrencia = 1`, aditiva em todas as dimensões.
- **Desconhecido:** exatamente uma linha `sk = -1` por dimensão.

```mermaid
erDiagram
    dim_tempo ||--o{ fato_ocorrencia : sk_tempo
    dim_periodo_dia ||--o{ fato_ocorrencia : sk_periodo_dia
    dim_natureza ||--o{ fato_ocorrencia : sk_natureza
    fato_ocorrencia {
        string id_registro_fonte
        string num_bo
        int ano_bo
        long sk_tempo FK
        long sk_periodo_dia FK
        long sk_natureza FK
        int mes_estatistica
        int ano_estatistica
        int qtd_ocorrencia
    }
    dim_tempo {
        long sk_tempo PK
        date data
        int ano
        int mes
        string nome_mes
        int dia
        int dia_semana_num
        string dia_semana_nome
        boolean fim_de_semana
    }
    dim_periodo_dia {
        long sk_periodo_dia PK
        int hora
        string faixa_horaria
        string periodo_dia
        boolean hora_informada
    }
    dim_natureza {
        long sk_natureza PK
        string natureza_apurada
        string rubrica
        string descr_conduta
    }
```

### Catálogo completo das tabelas persistidas

Os tipos e domínios abaixo formam o contrato do pipeline. Mínimos, máximos,
cardinalidades e categorias observados devem ser transcritos das tabelas de perfil
somente depois da execução.

<details>
<summary><strong>bronze_manifesto</strong> — um registro por arquivo e execução</summary>

| Coluna | Tipo | Domínio e descrição |
|---|---|---|
| `ano_arquivo` | int | 2022–2025 |
| `arquivo` | string | Nome do XLSX |
| `url_fonte` | string | URL HTTPS da SSP-SP |
| `caminho_volume` | string | Caminho absoluto em `/Volumes/.../xlsx/` |
| `tamanho_bytes` | bigint | Inteiro positivo obtido do arquivo |
| `sha256` | string | 64 caracteres hexadecimais dos bytes originais |
| `guias` | string | Lista das abas processadas |
| `linhas_estaduais_lidas` | bigint | Linhas de dados percorridas |
| `linhas_sorocaba_mantidas` | bigint | Linhas cujo código IBGE é `3552205` |
| `dt_ingestao` | timestamp | Instante da execução |
| `status` | string | `OK`; uma falha interrompe a carga antes da publicação do manifesto |

</details>

<details>
<summary><strong>bronze_recorte_sorocaba</strong> — captura textual municipal</summary>

As colunas originais são convertidas para identificadores maiúsculos ASCII com
underscore; seus **valores não são transformados**. Variações anuais permanecem
separadas e campos ausentes ficam nulos.

| Coluna fonte normalizada | Tipo | Conteúdo |
|---|---|---|
| `NOME_DEPARTAMENTO` | string | Departamento de registro |
| `NOME_SECCIONAL` | string | Seccional de registro |
| `NOME_DELEGACIA` | string | Delegacia de registro |
| `CIDADE` | string | Município de registro na variante de 2022 |
| `NOME_MUNICIPIO` | string | Município de registro nas demais variantes |
| `NUM_BO` | string | Número do BO |
| `ANO_BO` | string | Ano do BO ainda sem tipagem |
| `DATA_COMUNICACAO_BO` | string | Data de registro na variante de 2022 |
| `DATA_REGISTRO` | string | Data de registro nas demais variantes |
| `DATA_OCORRENCIA_BO` | string | Data informada da ocorrência |
| `HORA_OCORRENCIA_BO` | string | Hora informada |
| `DESCR_PERIODO` | string | Período na variante de 2022 |
| `DESC_PERIODO` | string | Período nas demais variantes |
| `DESCR_TIPOLOCAL` | string | Grupo do local, quando disponível |
| `DESCR_SUBTIPOLOCAL` | string | Subgrupo do local |
| `BAIRRO` | string | Bairro informado |
| `LOGRADOURO` | string | Logradouro informado |
| `NUMERO_LOGRADOURO` | string | Número informado |
| `LATITUDE` | string | Latitude informada |
| `LONGITUDE` | string | Longitude informada |
| `NOME_DEPARTAMENTO_CIRCUNCRICAO` | string | Departamento do local do fato; grafia observada na fonte |
| `NOME_SECCIONAL_CIRCUNCRICAO` | string | Seccional do local do fato; grafia observada na fonte |
| `NOME_DELEGACIA_CIRCUNCRICAO` | string | Delegacia do local do fato; grafia observada na fonte |
| `NOME_MUNICIPIO_CIRCUNCRICAO` | string | Município do local do fato; grafia observada na fonte |
| `RUBRICA` | string | Classificação jurídica registrada |
| `DESCR_CONDUTA` | string | Conduta/circunstância associada |
| `NATUREZA_APURADA` | string | Natureza apurada informada |
| `MES_ESTATISTICA` | string | Mês de entrada na estatística |
| `ANO_ESTATISTICA` | string | Ano de entrada na estatística |
| `CMD` | string | Comando da Polícia Militar |
| `BTL` | string | Batalhão da Polícia Militar |
| `CIA` | string | Companhia da Polícia Militar |
| `CD_IBGE` | string | Código municipal observado nos arquivos atuais; filtro `3552205` |
| `id_registro_fonte` | string | SHA-256 de todas as colunas originais, sem auditoria |
| `_arquivo_origem` | string | Nome do XLSX |
| `_guia_origem` | string | Aba de origem |
| `_ano_arquivo` | int | 2022–2025 |
| `_dt_ingestao` | timestamp | Instante da captura |

O notebook 00 imprime e perfila a união real dos cabeçalhos. Uma coluna nova deve
ser avaliada e acrescentada a este catálogo antes da entrega final.

</details>

<details>
<summary><strong>silver_ocorrencias</strong> — dados reconciliados e deduplicados</summary>

| Coluna | Tipo | Domínio e descrição | Origem/regra |
|---|---|---|---|
| `id_registro_fonte` | string | SHA-256, chave técnica única | Bronze |
| `cod_ibge` | int | Apenas `3552205` | `try_cast(cod_ibge)` e filtro |
| `num_bo` | string | Pode repetir | `num_bo`; sentinelas para nulo |
| `ano_bo` | int | Ano válido ou nulo | `try_cast(ano_bo)` |
| `dt_ocorrencia_bo` | date | Data válida ou nulo | `data_ocorrencia_bo` |
| `hora_ocorrencia_bo` | int | 0–23 ou nulo | Hora extraída com parse tolerante |
| `periodo_dia` | string | `MADRUGADA`, `MANHÃ`, `TARDE`, `NOITE`, `HORA INCERTA` ou nulo | Período limpo/derivado |
| `origem_periodo` | string | `FONTE`, `DERIVADO DA HORA` ou `NÃO INFORMADO` | Indicador da regra aplicada |
| `rubrica` | string | Texto limpo ou nulo | `rubrica` |
| `natureza_apurada` | string | Texto limpo ou nulo | `natureza_apurada` |
| `descr_conduta` | string | Texto limpo ou nulo | `descr_conduta` |
| `mes_estatistica` | int | 1–12 ou nulo | `try_cast(mes_estatistica)` |
| `ano_estatistica` | int | Ano válido ou nulo | `try_cast(ano_estatistica)` |
| `_arquivo_origem` | string | XLSX de origem | Bronze |
| `_guia_origem` | string | Aba de origem | Bronze |
| `_ano_arquivo` | int | 2022–2025 | Bronze |
| `_dt_ingestao` | timestamp | Instante da captura | Bronze |

</details>

<details>
<summary><strong>dim_tempo</strong> — uma linha por data, mais sentinela</summary>

| Coluna | Tipo | Domínio e descrição |
|---|---|---|
| `sk_tempo` | bigint | Chave determinística; `-1` para desconhecido |
| `data` | date | De `1976-01-02` a `2025-12-31`; nulo na sentinela. A análise aplica explicitamente o recorte 2022–2025. |
| `ano` | int | Ano civil ou `-1` |
| `mes` | int | 1–12 ou `-1` |
| `nome_mes` | string | Janeiro–Dezembro ou `NÃO INFORMADO` |
| `dia` | int | 1–31 ou `-1` |
| `dia_semana_num` | int | 1–7 ou `-1` |
| `dia_semana_nome` | string | Domingo–Sábado ou `NÃO INFORMADO` |
| `fim_de_semana` | boolean | `true`, `false` ou nulo na sentinela |

</details>

<details>
<summary><strong>dim_periodo_dia</strong> — hora e faixa temporal</summary>

| Coluna | Tipo | Domínio e descrição |
|---|---|---|
| `sk_periodo_dia` | bigint | Chave determinística; `-1` para desconhecido |
| `hora` | int | 0–23 ou nulo quando não informada |
| `faixa_horaria` | string | Intervalo horário derivado ou `NÃO INFORMADO` |
| `periodo_dia` | string | Categoria documentada ou `NÃO INFORMADO` |
| `hora_informada` | boolean | Indica hora válida |

</details>

<details>
<summary><strong>dim_natureza</strong> — classificação da ocorrência</summary>

| Coluna | Tipo | Domínio e descrição |
|---|---|---|
| `sk_natureza` | bigint | Chave determinística; `-1` para desconhecido |
| `natureza_apurada` | string | Categoria observada ou `NÃO INFORMADO` |
| `rubrica` | string | Classificação observada ou `NÃO INFORMADO` |
| `descr_conduta` | string | Conduta observada ou `NÃO INFORMADO` |

</details>

<details>
<summary><strong>fato_ocorrencia</strong> — uma linha por registro deduplicado</summary>

| Coluna | Tipo | Domínio e descrição |
|---|---|---|
| `id_registro_fonte` | string | Chave técnica única da Silver |
| `num_bo` | string | Identificador degenerado; pode repetir |
| `ano_bo` | int | Ano do BO ou nulo |
| `sk_tempo` | bigint | FK não nula para `dim_tempo` |
| `sk_periodo_dia` | bigint | FK não nula para `dim_periodo_dia` |
| `sk_natureza` | bigint | FK não nula para `dim_natureza` |
| `mes_estatistica` | int | 1–12 ou nulo |
| `ano_estatistica` | int | Ano estatístico ou nulo |
| `qtd_ocorrencia` | int | Sempre `1`; medida aditiva |

</details>

<details>
<summary><strong>matriz_transformacoes</strong> — auditoria das mudanças</summary>

| Coluna | Tipo | Descrição |
|---|---|---|
| `ordem` | int | Ordem da transformação |
| `regra` | string | Regra aplicada |
| `motivo` | string | Justificativa |
| `campos_afetados` | string | Lista dos atributos |
| `linhas_antes` | bigint | Contagem de entrada |
| `linhas_depois` | bigint | Contagem de saída |
| `linhas_afetadas` | bigint | Quantidade alterada ou removida |
| `dt_execucao` | timestamp | Instante da execução |

</details>

<details>
<summary><strong>perfil_qualidade_bronze</strong> e <strong>perfil_qualidade_silver</strong></summary>

As duas tabelas usam o mesmo contrato e contêm uma linha por atributo.

| Coluna | Tipo | Descrição |
|---|---|---|
| `camada` | string | `BRONZE` ou `SILVER` |
| `atributo` | string | Nome da coluna perfilada |
| `tipo_dado` | string | Tipo Spark/Delta |
| `total_linhas` | bigint | Total da tabela |
| `qtd_nulos` / `pct_nulos` | bigint / double | Completude observada |
| `qtd_distintos` | bigint | Cardinalidade |
| `valor_min` / `valor_max` | string | Limites como texto ou `N/A` |
| `completude_status` / `completude_justificativa` | string | Avaliação fundamentada |
| `consistencia_status` / `qtd_inconsistentes` / `consistencia_justificativa` | string / bigint / string | Tipo, formato, domínio e coerência |
| `unicidade_status` / `qtd_duplicados` / `unicidade_justificativa` | string / bigint / string | Unicidade ou `N/A` justificado |
| `acuracia_contextual_status` / `qtd_sem_confirmacao` / `acuracia_contextual_justificativa` | string / bigint / string | Plausibilidade sem alegar conferência externa |
| `outliers_status` / `qtd_outliers` / `outliers_justificativa` | string / bigint / string | Outliers ou `N/A` justificado |
| `impacto_analitico` | string | Efeito sobre as perguntas |
| `dt_perfil` | timestamp | Instante do perfil |

</details>

<details>
<summary><strong>validacoes_qualidade</strong> — testes do pipeline/modelo</summary>

| Coluna | Tipo | Descrição |
|---|---|---|
| `categoria` | string | Completude, consistência, unicidade, integridade ou reconciliação |
| `validacao` | string | Nome estável da regra |
| `resultado_observado` | string | Valor produzido |
| `resultado_esperado` | string | Condição de aceitação |
| `status` | string | `OK`, `ATENÇÃO`, `INFORMATIVO` ou `ERRO` |
| `detalhe` | string | Diagnóstico e impacto |
| `dt_validacao` | timestamp | Instante do teste |

</details>

### Linhagem de coluna da Gold

| Destino | Origem Silver | Origem Bronze | Regra |
|---|---|---|---|
| `dim_tempo.*` | `dt_ocorrencia_bo` | `data_ocorrencia_bo` | Parse tolerante e derivações civis |
| `dim_periodo_dia.hora` | `hora_ocorrencia_bo` | `hora_ocorrencia_bo` | Extração/validação 0–23 |
| `dim_periodo_dia.periodo_dia` | `periodo_dia` | `descr_periodo`/`desc_periodo`; hora como fallback | Normalização e derivação rastreada |
| `dim_natureza.*` | Campos homônimos | `natureza_apurada`, `rubrica`, `descr_conduta` | Limpeza textual |
| `fato_ocorrencia.id_registro_fonte` | Mesmo nome | Hash da linha original | Deduplicação apenas por hash |
| `fato_ocorrencia.num_bo` / `ano_bo` | Campos homônimos | `num_bo` / `ano_bo` | Limpeza e tipagem |
| FKs | Chaves naturais Silver | Data, hora/período e natureza | Join; ausência recebe `-1` |
| `mes_estatistica` / `ano_estatistica` | Campos homônimos | Campos homônimos | Tipagem tolerante |
| `qtd_ocorrencia` | — | — | Literal `1` |

![Tabelas Silver e Gold persistidas](docs/evidencias/05-tabelas-silver-gold.png)

![Modelo e comentários no Unity Catalog](docs/evidencias/06-modelo-catalogo.png)

## 4. Pipeline de Dados

### Ordem de execução

| Ordem | Artefato | Responsabilidade | Saídas |
|---:|---|---|---|
| 1 | [`00_coleta_bronze.ipynb`](notebooks/00_coleta_bronze.ipynb) | Inventário, leitura em lotes, filtro municipal e hash | Manifesto e Bronze |
| 2 | [`01_pipeline_bronze_silver_gold.ipynb`](notebooks/01_pipeline_bronze_silver_gold.ipynb) | Reconciliação, tipagem, limpeza, deduplicação e estrela | Silver, Gold e matriz |
| 3 | [`02_qualidade_dados.ipynb`](notebooks/02_qualidade_dados.ipynb) | Perfil por atributo e testes de integridade | Perfis e validações |
| 4 | [`03_analise_perguntas_negocio.ipynb`](notebooks/03_analise_perguntas_negocio.ipynb) | Três análises, tabelas, gráficos e conclusão | Resultados no notebook |

As consultas SQL auxiliares usadas para conferir os objetos persistidos e gerar
as evidências 03, 04, 05 e 08 estão consolidadas em
[`consultas_evidencias.sql`](sql/consultas_evidencias.sql). Elas são somente
leitura e não duplicam as consultas analíticas do notebook 03.

### Matriz de transformações

As contagens abaixo foram copiadas de `matriz_transformacoes` após a execução
integral. “Afetadas” representa valores alterados ou linhas removidas pela regra.

| Regra | Motivo | Campos | Antes | Depois | Afetadas |
|---|---|---|---:|---:|---:|
| Sanitizar apenas nomes de coluna | Compatibilidade Delta | Cabeçalhos Bronze | 65.326 | 65.326 | 0 |
| Filtrar Sorocaba durante a leitura | Não persistir o conjunto estadual | `CD_IBGE`/`COD_IBGE` | 4.792.830 | 65.326 | 4.727.504 |
| Conciliar aliases por nome | Variações anuais | Período e seleção dos campos canônicos | 65.326 | 65.326 | 50.114 |
| Converter sentinelas em nulo | Representar ausência real | Campos Silver | 65.326 | 65.326 | 63.804 |
| Tipar com conversões tolerantes | Medir inválidos sem abortar | Datas, inteiros e hora | 65.326 | 65.326 | 17 |
| Confirmar `cod_ibge = 3552205` | Impedir outro município | `cod_ibge` | 65.326 | 65.326 | 0 |
| Normalizar categorias | Evitar diferença só por caixa/espaço | Natureza, rubrica, conduta, período | 65.326 | 65.326 | 65.324 |
| Derivar período só se ausente e hora válida | Aumentar cobertura com rastreio | `periodo_dia`, `origem_periodo` | 65.326 | 65.326 | 49.191 |
| Deduplicar por `id_registro_fonte` | Remover somente linhas idênticas | Registro completo | 65.326 | 65.325 | 1 |
| Resolver FKs e criar medida unitária | Impedir FK nula e conservar o grão | Três FKs e `qtd_ocorrencia` | 65.325 | 65.325 | 1.382 |

### Reprodução em workspace novo

Pré-requisitos: conta no Databricks Free Edition, acesso ao GitHub e Python 3 local.
Não há credenciais versionadas.

1. Clone este repositório em um Git folder do Databricks.
2. Execute localmente `python3 scripts/coletar_dados.py`.
3. Confirme quatro arquivos, anos 2022–2025, e guarde seus checksums.
4. No Catalog Explorer, crie/use `workspace.sorocaba_seguranca` e o Volume `dados`.
5. Crie a pasta `xlsx` e envie os quatro arquivos originais.
6. Execute manualmente os notebooks `00`, `01`, `02` e `03`, nessa ordem.
7. Se um teste obrigatório falhar, corrija a causa e reexecute desde o notebook 00.
8. Capture as evidências e substitua somente os resultados observados neste README.

![Execução sequencial concluída](docs/evidencias/12-execucao-completa.png)

## 5. Qualidade de Dados

O notebook 02 perfila **cada coluna** de `bronze_recorte_sorocaba` e
`silver_ocorrencias`, incluindo atributos Bronze que não seguem para a Silver. Ele
avalia completude, consistência, unicidade, acurácia contextual e outliers. Quando
uma dimensão não se aplica, registra `N/A` e uma justificativa.

| Teste | Esperado | Observado |
|---|---|---|
| Arquivos no manifesto | 4 distintos, 2022–2025, checksum válido | 4 arquivos e 4 anos; 0 checksum/tamanho inválido — `OK` |
| Recorte municipal | 100% com `cod_ibge = 3552205` | 65.326 linhas Bronze e 65.325 Silver; 0 fora do município — `OK` |
| Hash | Nenhum nulo | 0 nulo e formato válido — `OK` |
| Deduplicação | Zero repetição do hash na Silver | 65.326 → 65.325; 1 repetição idêntica removida e 0 duplicata na Silver — `OK` |
| Hora | Somente 0–23 ou nulo | 0 valor fora do domínio; 16.134 nulos (24,698%) — `OK` |
| Período | Somente categorias documentadas | 0 valor fora do domínio; 1.344 nulos (2,057%) — `OK` |
| Datas impossíveis/futuras | Zero; datas antigas plausíveis não são rejeitadas | 0 impossível/futura; 299 nulas e 591 fora do recorte analítico — `OK` |
| Sentinelas | Exatamente uma chave `-1` por dimensão | Uma em cada uma das três dimensões — `OK` |
| FKs nulas/órfãs | Zero | 0 nula e 0 órfã nas três FKs — `OK` |
| Conservação | `SUM(qtd_ocorrencia) = COUNT(silver_ocorrencias)` | 65.325 = 65.325 — `OK` |
| Cobertura do perfil | Todas as colunas Bronze e Silver | 38/38 atributos Bronze e 17/17 Silver — `OK` |

**Resultado da qualidade:** foram executadas 40 validações: 39 com status `OK`,
uma `INFORMATIVO` e nenhuma `ATENÇÃO` ou `ERRO`. A única observação informativa
foi um grupo repetido de forma idêntica na Bronze, removido exclusivamente pelo
hash da linha original. A Silver eliminou valores inválidos de hora, período e
data por conversão tolerante; isso aumenta a consistência, mas não cria informação
ausente. Permaneceram 299 datas nulas, 16.134 horas nulas e 1.344 períodos nulos,
todos explicitamente contabilizados nas análises. Dos períodos válidos, 49.190
foram derivados da hora e 14.791 vieram da fonte.

![Perfil por atributo antes e depois](docs/evidencias/07-perfil-qualidade.png)

Na comparação exibida na imagem, os **95,9082%** de ausência na Bronze se referem
somente à coluna `DESCR_PERIODO`; os **2,0574%** da Silver se referem a
`periodo_dia` após conciliar `DESCR_PERIODO` com `DESC_PERIODO`, derivar períodos
da hora quando possível e remover a linha duplicada. Portanto, a diferença não
mede o ganho de preenchimento de uma mesma coluna nem a cobertura da fonte
consolidada antes do tratamento.

![Validações de integridade](docs/evidencias/08-validacoes-qualidade.png)

![Observação informativa da qualidade](docs/evidencias/08-validacoes-qualidade-obs.png)

## 6. Análise de Dados

Os resultados são produzidos pelo notebook 03 sobre a Gold. Cada consulta exibe
tabela, gráfico, cobertura e reconciliação com a fato.
Nas capturas anteriores à revisão, os rótulos "pergunta 1–3" correspondem às
análises A1–A3 abaixo, não à numeração das seis perguntas originais.

### Análise A1 — evolução mensal e anual

- **Método:** `SUM(qtd_ocorrencia)` por ano e mês da `dim_tempo`.
- **Resposta:** foram analisadas 64.435 ocorrências com data entre 2022 e 2025.
  O total anual passou de 14.917 em 2022 para 16.347 em 2025, aumento de 9,6%.
  O maior total anual foi 16.975 em 2023 e o pico mensal ocorreu em setembro de
  2023, com 1.526 registros.
- **Discussão/limitação:** a cobertura temporal foi 98,64% da fato. A variação
  descreve registros administrativos e não demonstra aumento causal da
  criminalidade. Foram excluídos do recorte analítico 299 registros sem data e
  591 com data fora de 2022–2025.
- **Reconciliação:** 64.435 analisados + 299 sem data + 591 fora do período =
  65.325 linhas da fato.

![Resultado e gráfico da análise A1](docs/evidencias/09-pergunta-1.png)

### Análise A2 — naturezas mais frequentes e variação

- **Método:** ranking no período completo e evolução anual das principais.
- **Resposta:** `FURTO - OUTROS` concentrou 37.053 registros (57,5%), seguido por
  `LESÃO CORPORAL DOLOSA`, com 7.979 (12,4%), e `FURTO DE VEÍCULO`, com 6.518
  (10,1%). A categoria líder variou de 9.101 em 2022 para 9.338 em 2025 (+2,6%).

| Natureza | 2022 | 2023 | 2024 | 2025 | Total |
|---|---:|---:|---:|---:|---:|
| FURTO - OUTROS | 9.101 | 9.494 | 9.120 | 9.338 | 37.053 |
| LESÃO CORPORAL DOLOSA | 1.610 | 2.009 | 2.079 | 2.281 | 7.979 |
| FURTO DE VEÍCULO | 1.280 | 1.811 | 1.713 | 1.714 | 6.518 |
| ROUBO - OUTROS | 1.475 | 1.610 | 1.294 | 969 | 5.348 |
| LESÃO CORPORAL CULPOSA POR ACIDENTE DE TRÂNSITO | 600 | 696 | 800 | 752 | 2.848 |

- **Discussão/limitação:** os 64.435 registros do recorte temporal possuíam
  natureza classificada. As categorias são administrativas e mudanças de
  registro/classificação podem influenciar a série; frequência não mede gravidade.
- **Reconciliação:** a soma de todas as naturezas no ranking foi 64.435, igual ao
  total válido usado na análise A1.

![Resultado e gráfico da análise A2](docs/evidencias/10-pergunta-2.png)

### Análise A3 — dia da semana e período do dia

- **Método:** principais naturezas da análise A2 agregadas por dia e período.
- **Resposta:** a combinação de maior frequência foi diferente em cada uma das
  cinco naturezas líderes.

| Natureza | Dia/período de maior frequência | Registros |
|---|---|---:|
| FURTO - OUTROS | Sábado / madrugada | 1.763 |
| LESÃO CORPORAL DOLOSA | Domingo / noite | 628 |
| FURTO DE VEÍCULO | Quarta-feira / madrugada | 354 |
| ROUBO - OUTROS | Sexta-feira / noite | 303 |
| LESÃO CORPORAL CULPOSA POR ACIDENTE DE TRÂNSITO | Sexta-feira / tarde | 197 |

- **Discussão/limitação:** as cinco naturezas somaram 59.746 registros; 1.025
  (1,72%) não tinham período disponível. Parte dos períodos foi derivada de hora
  válida e continua identificada por `origem_periodo`. A concentração descreve a
  base e não recomenda alocação policial.
- **Reconciliação:** 59.746 no cruzamento de dia/período, incluindo a categoria
  não informada, igual ao total anual das mesmas cinco naturezas.

![Resultado e gráfico da análise A3](docs/evidencias/11-pergunta-3.png)

![Resposta e reconciliação da análise A3](docs/evidencias/11-pergunta-3-resposta.png)

### Conclusão geral

O pipeline tornou comparáveis quatro arquivos anuais e produziu três análises
descritivas. Elas respondem diretamente à pergunta original 4, parcialmente à 2
e não respondem às perguntas 1, 3, 5 e 6. O volume registrado cresceu 9,6% entre
2022 e 2025, mas o maior total anual ocorreu em 2023. `FURTO - OUTROS` dominou
a composição, com 57,5% dos
registros com data no período, enquanto as combinações de dia e período de maior
frequência variaram entre as cinco principais naturezas. A boa reconciliação entre
Silver, fato e agregações demonstra consistência interna; ainda assim, ausências de
data/hora, datas fora do recorte e a natureza administrativa da fonte impedem
inferências causais, estimativas de risco individual ou recomendações de
intervenção.

## 7. Autoavaliação

### Atingimento dos objetivos

| Pergunta original | Status | Evidência e razão |
|---|---|---|
| 1. Bairros e mudança | Não respondida | A Gold e as análises não agregam por bairro; A1 é municipal. |
| 2. Sazonalidade por dia, mês e horário | Parcial | A1 mostra mês; A3 mostra dia da semana e período do dia. Não há análise por hora nem conclusão sobre repetição sazonal. |
| 3. Tipos por bairro/região | Não respondida | A2 classifica naturezas para todo o município, sem recorte por bairro/região. |
| 4. Crescimento, queda ou estabilidade | Respondida descritivamente | A1 mostra aumento de 9,6% entre 2022 e 2025 e pico anual em 2023, somente para registros com data no período. |
| 5. Tipo de local × ocorrência | Não respondida | Não foi feito cruzamento por tipo de local; esse campo não compõe a Silver/Gold atual. |
| 6. Correlação espacial entre tipos | Não respondida | Não foi calculada correlação espacial; coordenadas não compõem a Silver/Gold atual. |

### Dificuldades encontradas

- Leitura de 4.792.830 linhas em XLSX grandes no Free Edition, tratada com
  `openpyxl` em modo somente leitura e lotes; a principal célula Bronze levou
  aproximadamente 20 minutos.
- O acesso externo do ambiente não foi confiável, por isso os arquivos originais
  foram baixados pelo coletor local e enviados manualmente ao Volume.
- Variações de nomes/disponibilidade de colunas, reconciliadas por nome.
- Sentinelas textuais e tipagem estrita, tratadas antes da conversão tolerante.
- Diferença entre município de registro e circunscrição, resolvida pelo código
  IBGE do local do fato.
- Risco de remover fatos legítimos, evitado ao deduplicar somente pelo hash de toda
  a linha original.

### Limitações

- Uma fonte e um município.
- Dependência da cobertura e semântica dos registros administrativos.
- Sem denominador populacional: resultados são contagens, não taxas.
- Sem validação externa da acurácia de cada BO.
- Período parcialmente dependente da disponibilidade da hora; 49.190 valores
  foram derivados e 1.344 permaneceram nulos.
- Existem 299 datas nulas e 591 datas fora do recorte 2022–2025; a data não nula
  mais antiga observada foi `1976-01-02`.

### Trabalhos futuros

Somente depois de todos os testes e evidências desta versão estarem completos:

- avaliar fonte populacional para taxas comparáveis;
- investigar outra fonte oficial que responda a uma pergunta adicional clara;
- ampliar o período quando existir outro ano completo;
- testar o mesmo contrato em outros municípios.

### Reflexão final

O pipeline e as três análises implementadas funcionaram dentro das coberturas
declaradas, mas o objetivo original de seis perguntas foi atingido apenas em parte:
uma foi respondida descritivamente, uma parcialmente e quatro ficaram sem resposta.
As decisões de filtrar Sorocaba ainda durante a leitura,
preservar a Bronze textual, deduplicar apenas hashes idênticos e rastrear a origem
do período foram as que mais protegeram o grão e a auditabilidade. Em uma próxima
execução, eu manteria o mesmo contrato, mas avaliaria a conversão dos XLSX oficiais
para um formato de leitura mais eficiente antes do processamento distribuído,
preservando os originais e os checksums como evidência.

## Evidências finais e conferência

![Página oficial da fonte e termos exibidos](docs/evidencias/13-fonte-termos-uso.png)

![Arquivos anuais publicados pela SSP-SP](docs/evidencias/13-fonte-arquivos-publicados.png)

- [x] Quatro notebooks executados em ordem, sem erro.
- [x] Todo resultado de execução substituído por valor real.
- [x] Catálogo conferido com `DESCRIBE TABLE` para todas as tabelas.
- [x] Toda coluna Bronze e Silver presente no perfil.
- [x] Testes aprovados ou observações informativas discutidas.
- [x] Três análises com tabela, gráfico, resposta, discussão e limitação.
- [x] Seis perguntas originais mantidas e avaliadas na conclusão e autoavaliação.
- [x] As 16 imagens existem, são legíveis e aparecem neste README.
- [x] Nenhum XLSX bruto, registro individual, credencial ou PDF do curso está no Git.
- [x] As saídas agregadas e os perfis de qualidade foram preservados nos notebooks.
