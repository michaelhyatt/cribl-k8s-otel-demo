SELECT DISTINCT count(trace_id) as unique_traces
FROM read_json(
    '/tmp/kind-data/node-*/disk-spool/*/otlp.type=*/*.json.gz'
);