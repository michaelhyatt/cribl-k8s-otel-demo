SELECT
    attributes -> 'http.target' as path,
    (CAST(end_time_unix_nano AS BIGINT) - CAST(start_time_unix_nano AS BIGINT)) / 1_000_000 AS duration 
FROM read_json(
    '/tmp/kind-data/node-*/disk-spool/*/otlp.type=traces/*.json.gz',
    maximum_depth => 2
)
WHERE name = 'POST'
AND path IS NOT NULL
ORDER BY duration DESC
LIMIT 5
;