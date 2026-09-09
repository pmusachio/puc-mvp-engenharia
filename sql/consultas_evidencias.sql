-- Databricks SQL
-- Consultas auxiliares utilizadas para conferir as tabelas persistidas e
-- produzir as evidências 03, 04, 05 e 08 do README

-- Evidência 03 - manifesto dos arquivos anuais carregados na Bronze

SELECT
    ano_arquivo,
    arquivo,
    tamanho_bytes,
    LENGTH(sha256) AS caracteres_sha256,
    linhas_estaduais_lidas,
    linhas_sorocaba_mantidas,
    status
FROM workspace.sorocaba_seguranca.bronze_manifesto
ORDER BY ano_arquivo;


-- Evidência 04 - conservação, linhagem e confirmação do recorte municipal

SELECT
    COUNT(*) AS total_bronze,
    COUNT(DISTINCT id_registro_fonte) AS hashes_distintos,
    COUNT(DISTINCT _arquivo_origem) AS arquivos_origem,
    MIN(_ano_arquivo) AS ano_minimo,
    MAX(_ano_arquivo) AS ano_maximo,
    SUM(
        CASE
            WHEN TRIM(CD_IBGE) <> '3552205' OR CD_IBGE IS NULL THEN 1
            ELSE 0
        END
    ) AS linhas_fora_sorocaba
FROM workspace.sorocaba_seguranca.bronze_recorte_sorocaba;


-- Evidência 05 - contagem dos objetos persistidos nas camadas Silver e Gold

WITH contagens AS (
    SELECT 'silver_ocorrencias' AS objeto, COUNT(*) AS linhas
    FROM workspace.sorocaba_seguranca.silver_ocorrencias

    UNION ALL

    SELECT 'dim_tempo' AS objeto, COUNT(*) AS linhas
    FROM workspace.sorocaba_seguranca.dim_tempo

    UNION ALL

    SELECT 'dim_periodo_dia' AS objeto, COUNT(*) AS linhas
    FROM workspace.sorocaba_seguranca.dim_periodo_dia

    UNION ALL

    SELECT 'dim_natureza' AS objeto, COUNT(*) AS linhas
    FROM workspace.sorocaba_seguranca.dim_natureza

    UNION ALL

    SELECT 'fato_ocorrencia' AS objeto, COUNT(*) AS linhas
    FROM workspace.sorocaba_seguranca.fato_ocorrencia

    UNION ALL

    SELECT 'perfil_qualidade_bronze' AS objeto, COUNT(*) AS linhas
    FROM workspace.sorocaba_seguranca.perfil_qualidade_bronze

    UNION ALL

    SELECT 'perfil_qualidade_silver' AS objeto, COUNT(*) AS linhas
    FROM workspace.sorocaba_seguranca.perfil_qualidade_silver

    UNION ALL

    SELECT 'validacoes_qualidade' AS objeto, COUNT(*) AS linhas
    FROM workspace.sorocaba_seguranca.validacoes_qualidade
)
SELECT objeto, linhas
FROM contagens
ORDER BY objeto;


-- Evidência 08 - síntese das validações de qualidade por status

SELECT
    status,
    COUNT(*) AS total
FROM workspace.sorocaba_seguranca.validacoes_qualidade
GROUP BY status
ORDER BY status;


-- Detalhamento de qualquer resultado diferente de OK. Na execução documentada,
-- esta consulta retorna somente a observação informativa sobre a duplicata
-- idêntica encontrada na Bronze
SELECT
    categoria,
    validacao,
    resultado_observado,
    status,
    detalhe
FROM workspace.sorocaba_seguranca.validacoes_qualidade
WHERE status <> 'OK'
ORDER BY categoria, validacao;
