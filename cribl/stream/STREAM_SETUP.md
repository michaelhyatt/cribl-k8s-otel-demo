# Deploy Cribl Stream

## Overall design
![Diagram](../../images/stream-setup.png)

## Create hybrid worker group `otel-demo-k8s-wg`

## Copy the leader URL and token from `Kubernetes worker setup` dialog
![diagram](../../images/add-stream-worker.png)

## Deploy Cribl Stream worker
Set the variables:
```bash
export CRIBL_STREAM_VERSION=4.14.1
export CRIBL_STREAM_WORKER_GROUP=otel-demo-k8s-wg
export CRIBL_STREAM_TOKEN=<token>
export CRIBL_STREAM_LEADER_URL=<leader-url>
```
Run the `helm install`
```bash
helm install --repo "https://criblio.github.io/helm-charts/" --version "^${CRIBL_STREAM_VERSION}" --create-namespace -n "cribl" \
--set "config.host=${CRIBL_STREAM_LEADER_URL}" \
--set "config.token=${CRIBL_STREAM_TOKEN}" \
--set "config.group=${CRIBL_STREAM_WORKER_GROUP}" \
--set "config.tlsLeader.enable=true"  \
--set "env.CRIBL_K8S_TLS_REJECT_UNAUTHORIZED=0" \
--set "env.CRIBL_MAX_WORKERS=4" \
--values cribl/stream/values.yaml \
"cribl-worker" logstream-workergroup
```
Check the new worker appear in the UI.

# Set up the worker group

## Receive Cribl TCP traffic port 10300
Used to receive the OTel data from Edge Daemonset
<details>
<summary>Cribl TCP source JSON</summary>

```json
    {
        "id": "in_cribl_tcp",
        "disabled": false,
        "sendToRoutes": true,
        "pqEnabled": false,
        "streamtags": [],
        "host": "0.0.0.0",
        "tls": {
            "disabled": true,
            "requestCert": false
        },
        "maxActiveCxn": 1000,
        "enableProxyHeader": false,
        "enableLoadBalancing": false,
        "type": "cribl_tcp",
        "port": 10300,
        "connections": []
    }
```
</details>

## Cribl Lake datasets for Otel traffic
Create 3 Cribl Lake datasets to receive the OTel data:
* `otel_traces`
* `otel_metrics`
* `otel_logs`

We will now create Stream destinations that connect to them.

## Create 3 Stream Lake destinations
You can copy the below JSON or create them manually.
<details>
<summary>otel-traces JSON</summary>

```json
{
  "id": "otel-traces",
  "systemFields": [
    "cribl_pipe"
  ],
  "streamtags": [],
  "awsAuthenticationMethod": "auto",
  "signatureVersion": "v4",
  "reuseConnections": true,
  "rejectUnauthorized": true,
  "enableAssumeRole": false,
  "durationSeconds": 3600,
  "stagePath": "$CRIBL_HOME/state/outputs/staging",
  "addIdToStagePath": true,
  "objectACL": "private",
  "removeEmptyDirs": true,
  "format": "json",
  "baseFileName": "`CriblOut`",
  "fileNameSuffix": "`.${C.env[\"CRIBL_WORKER_ID\"]}.${__format}${__compression === \"gzip\" ? \".gz\" : \"\"}`",
  "maxFileSizeMB": 32,
  "maxOpenFiles": 100,
  "headerLine": "",
  "onBackpressure": "block",
  "maxFileOpenTimeSec": 300,
  "maxFileIdleTimeSec": 30,
  "maxConcurrentFileParts": 4,
  "verifyPermissions": true,
  "maxClosingFilesToBackpressure": 100,
  "compress": "gzip",
  "emptyDirCleanupSec": 300,
  "type": "cribl_lake",
  "destPath": "otel_traces"
}
```
</details>
<details>
<summary>otel-metrics JSON</summary>

```json
{
  "id": "otel-metrics",
  "systemFields": [
    "cribl_pipe"
  ],
  "streamtags": [],
  "awsAuthenticationMethod": "auto",
  "signatureVersion": "v4",
  "reuseConnections": true,
  "rejectUnauthorized": true,
  "enableAssumeRole": false,
  "durationSeconds": 3600,
  "stagePath": "$CRIBL_HOME/state/outputs/staging",
  "addIdToStagePath": true,
  "objectACL": "private",
  "removeEmptyDirs": true,
  "format": "json",
  "baseFileName": "`CriblOut`",
  "fileNameSuffix": "`.${C.env[\"CRIBL_WORKER_ID\"]}.${__format}${__compression === \"gzip\" ? \".gz\" : \"\"}`",
  "maxFileSizeMB": 32,
  "maxOpenFiles": 100,
  "headerLine": "",
  "onBackpressure": "block",
  "maxFileOpenTimeSec": 300,
  "maxFileIdleTimeSec": 30,
  "maxConcurrentFileParts": 4,
  "verifyPermissions": true,
  "maxClosingFilesToBackpressure": 100,
  "compress": "gzip",
  "emptyDirCleanupSec": 300,
  "type": "cribl_lake",
  "destPath": "otel_metrics"
}
```
</details>
<details>
<summary>otel-logs JSON</summary>

```json
{
  "id": "otel-logs",
  "systemFields": [
    "cribl_pipe"
  ],
  "streamtags": [],
  "awsAuthenticationMethod": "auto",
  "signatureVersion": "v4",
  "reuseConnections": true,
  "rejectUnauthorized": true,
  "enableAssumeRole": false,
  "durationSeconds": 3600,
  "stagePath": "$CRIBL_HOME/state/outputs/staging",
  "addIdToStagePath": true,
  "objectACL": "private",
  "removeEmptyDirs": true,
  "format": "json",
  "baseFileName": "`CriblOut`",
  "fileNameSuffix": "`.${C.env[\"CRIBL_WORKER_ID\"]}.${__format}${__compression === \"gzip\" ? \".gz\" : \"\"}`",
  "maxFileSizeMB": 32,
  "maxOpenFiles": 100,
  "headerLine": "",
  "onBackpressure": "block",
  "maxFileOpenTimeSec": 300,
  "maxFileIdleTimeSec": 30,
  "maxConcurrentFileParts": 4,
  "verifyPermissions": true,
  "maxClosingFilesToBackpressure": 100,
  "compress": "gzip",
  "emptyDirCleanupSec": 300,
  "type": "cribl_lake",
  "destPath": "otel_logs"
}
```
</details>

## Create an Output Router destination to send data to Lake
This router uses the above Lake destinations to simplify the routes config. Copy and paste the JSON below into a new Router destination
<details>
<summary>otel-router-to-lake JSON</summary>

```json
{
  "id": "otel-router-to-lake",
  "systemFields": [
    "cribl_pipe"
  ],
  "streamtags": [],
  "rules": [
    {
      "final": true,
      "filter": "__otlp.type == 'traces'",
      "output": "otel-traces",
      "description": "Otel traces to Lake"
    },
    {
      "final": true,
      "filter": "__otlp.type == 'logs'",
      "output": "otel-logs",
      "description": "Otel logs to Lake"
    },
    {
      "final": true,
      "filter": "__otlp.type == 'metrics'",
      "output": "otel-metrics",
      "description": "Otel metrics to Lake"
    }
  ],
  "type": "router"
}
```
</details>

## Create Prometheus destination
Remote Write URL: `http://prometheus.elastic.svc.cluster.local:9201`
<details>
<summary>elastic-prometheus JSON</summary>

```json
{
  "id": "elastic-prometheus",
  "systemFields": [
    "cribl_host",
    "cribl_wp"
  ],
  "streamtags": [],
  "metricRenameExpr": "name.replace(/[^a-zA-Z0-9_]/g, '_')",
  "sendMetadata": true,
  "concurrency": 5,
  "maxPayloadSizeKB": 4096,
  "maxPayloadEvents": 0,
  "rejectUnauthorized": false,
  "timeoutSec": 30,
  "flushPeriodSec": 1,
  "useRoundRobinDns": false,
  "failedRequestLoggingMode": "none",
  "safeHeaders": [],
  "responseRetrySettings": [],
  "timeoutRetrySettings": {
    "timeoutRetry": false
  },
  "responseHonorRetryAfterHeader": false,
  "onBackpressure": "block",
  "authType": "none",
  "metricsFlushPeriodSec": 60,
  "type": "prometheus",
  "url": "http://prometheus.elastic.svc.cluster.local:9201"
}
```
</details>

## Create OTel destination
endpoint (no http://): `apm.elastic.svc.cluster.local:8200`
<details>
<summary>elastic-otel JSON</summary>

```json
{
  "id": "elastic-otel",
  "systemFields": [
    "cribl_pipe"
  ],
  "streamtags": [],
  "protocol": "grpc",
  "otlpVersion": "1.3.1",
  "compress": "gzip",
  "authType": "none",
  "concurrency": 5,
  "maxPayloadSizeKB": 4096,
  "timeoutSec": 30,
  "flushPeriodSec": 1,
  "failedRequestLoggingMode": "none",
  "connectionTimeout": 10000,
  "keepAliveTime": 30,
  "onBackpressure": "block",
  "tls": {
    "disabled": true
  },
  "type": "open_telemetry",
  "endpoint": "apm.elastic.svc.cluster.local:8200"
}
```
</details>

### Receive Cribl HTTP traffic port 10200
Used for data replay from Search using `| send <url>`
This source will be connected to OTel destination in QuickConnect.
<details>
<summary>Cribl HTTP source JSON</summary>

```json
{
  "id": "in_cribl_http",
  "disabled": false,
  "sendToRoutes": true,
  "pqEnabled": false,
  "streamtags": [],
  "host": "0.0.0.0",
  "tls": {
    "disabled": true,
    "requestCert": false
  },
  "maxActiveReq": 256,
  "maxRequestsPerSocket": 0,
  "enableProxyHeader": false,
  "captureHeaders": false,
  "activityLogSampleRate": 100,
  "requestTimeout": 0,
  "socketTimeout": 0,
  "keepAliveTimeout": 5,
  "enableHealthCheck": false,
  "ipAllowlistRegex": "/.*/",
  "ipDenylistRegex": "/^$/",
  "type": "cribl_http",
  "port": 10200,
  "connections": [
    {
      "output": "elastic-otel"
    }
  ]
}
```
</details>

## Install `cribl-opentelemetry` pack from Dispensary
It is used to translate OTel traces into metrics. Change the filter on the `traces_to_metrics` route in the pack from `__inputId.startsWith('open_telemetry')` to `true`.

## Create `metrics-to-elastic` pipeline
Create the `metrics-to-elastic` pipeline and copy the following JSON.
<details>
<summary>metrics-to-elastic JSON</summary>

```json
{
  "id": "metrics-to-elastic",
  "conf": {
    "output": "default",
    "streamtags": [],
    "groups": {},
    "asyncFuncTimeout": 1000,
    "functions": [
      {
        "id": "comment",
        "filter": "true",
        "conf": {
          "comment": "Invoke the OTel to metrics pack"
        }
      },
      {
        "id": "chain",
        "filter": "true",
        "conf": {
          "processor": "pack:cribl-opentelemetry"
        },
        "description": "Invoke the Cribl OpenTelemetry pack"
      },
      {
        "id": "comment",
        "filter": "true",
        "conf": {
          "comment": "Reduce the granularity of metrics by aggregating them"
        }
      },
      {
        "id": "aggregation",
        "filter": "true",
        "disabled": false,
        "conf": {
          "passthrough": false,
          "preserveGroupBys": false,
          "sufficientStatsOnly": false,
          "metricsMode": true,
          "timeWindow": "60s",
          "aggregations": [
            "sum(duration).as(duration)",
            "sum(http_2xx).as(http_2xx)",
            "sum(http_3xx).as(http_3xx)",
            "sum(http_4xx).as(http_4xx)",
            "sum(http_5xx).as(http_5xx)",
            "sum(otel_status_0).as(otel_status_0)",
            "sum(otel_status_1).as(otel_status_1)",
            "sum(otel_status_2).as(otel_status_2)",
            "sum(requests_error).as(requests_error)",
            "sum(requests_total).as(requests_total)",
            "max(start_time_unix_nano).as(max_starttime)"
          ],
          "cumulative": false,
          "flushOnInputClose": false,
          "groupbys": [
            "service",
            "resource_url",
            "status_code"
          ]
        },
        "description": "Aggregate metrics before sending them"
      },
      {
        "id": "comment",
        "filter": "true",
        "conf": {
          "comment": "Fix the timestamp to max_time of the aggregated spans"
        }
      },
      {
        "id": "auto_timestamp",
        "filter": "true",
        "conf": {
          "srcField": "max_starttime",
          "dstField": "_time",
          "defaultTimezone": "UTC",
          "timeExpression": "time.getTime() / 1000",
          "offset": 0,
          "maxLen": 150,
          "defaultTime": "now",
          "latestDateAllowed": "+1week",
          "earliestDateAllowed": "-420weeks"
        }
      }
    ]
  }
}
```
</details>

## Create pipeline for k8s logs and events (3 pipelines)

<details>
<summary>1: edge logs from k8s</summary>

```json
{
  "id": "cribl_k8s_edge_logs",
  "conf": {
    "output": "default",
    "streamtags": [],
    "groups": {},
    "asyncFuncTimeout": 1000,
    "functions": [
      {
        "id": "comment",
        "filter": "true",
        "conf": {
          "comment": "Parse JSON K8S logs sent from the Cribl Edge container"
        }
      },
      {
        "id": "comment",
        "filter": "true",
        "conf": {
          "comment": "For additional details, see this pack's README under Pack Settings."
        }
      },
      {
        "id": "comment",
        "filter": "true",
        "conf": {
          "comment": "Author: Cribl Packs Team"
        }
      },
      {
        "id": "serde",
        "filter": "_raw.startsWith(\"{\")",
        "conf": {
          "mode": "extract",
          "type": "json",
          "srcField": "_raw",
          "fieldFilterExpr": "value !== '' && value !== null"
        },
        "description": "Parse the JSON _raw field"
      },
      {
        "id": "auto_timestamp",
        "filter": "true",
        "conf": {
          "srcField": "time",
          "dstField": "_time",
          "defaultTimezone": "local",
          "timeExpression": "time.getTime() / 1000",
          "offset": 0,
          "maxLen": 150,
          "defaultTime": "now",
          "latestDateAllowed": "+1week",
          "earliestDateAllowed": "-420weeks"
        },
        "description": "Use the time field as the timestamp"
      },
      {
        "id": "comment",
        "filter": "true",
        "conf": {
          "comment": "[Optional - disable if unneeded] Call a pipeline containing custom filter logic"
        }
      },
      {
        "id": "chain",
        "filter": "true",
        "disabled": true,
        "conf": {
          "processor": "cribl_k8s_edge_logs_filter"
        },
        "description": "Call a pipeline containing custom filter logic"
      },
      {
        "id": "serialize",
        "filter": "true",
        "conf": {
          "type": "json",
          "dstField": "_raw",
          "fields": [
            "!_*",
            "!cribl*",
            "!source",
            "!sourcetype",
            "!kube_*",
            "!host",
            "*"
          ]
        },
        "description": "Serialize the processed log into JSON format"
      },
      {
        "id": "eval",
        "filter": "true",
        "conf": {
          "keep": [
            "_*",
            "cribl_*",
            "source",
            "sourcetype",
            "host",
            "kube_*"
          ],
          "remove": [
            "*"
          ],
          "add": [
            {
              "disabled": false,
              "value": "C.vars.k8s_edge_logs_sourcetype || 'k8s:edge:logs'",
              "name": "sourcetype"
            },
            {
              "disabled": false,
              "value": "C.vars.k8s_edge_logs_source || 'edge-k8s-logs-' + kube_namespace + '-' + kube_pod",
              "name": "source"
            }
          ]
        },
        "description": "Remove unneeded fields and set common fields"
      }
    ],
    "description": "Process JSON logs sent from Edge nodes monitoring K8S"
  }
}
```
</details>

<details>
<summary>2: K8s_logs</summary> 

```json
{
  "id": "cribl_k8s_logs",
  "conf": {
    "output": "default",
    "streamtags": [],
    "groups": {},
    "asyncFuncTimeout": 1000,
    "functions": [
      {
        "id": "comment",
        "filter": "true",
        "conf": {
          "comment": "Parse JSON and non-JSON K8S logs"
        }
      },
      {
        "id": "comment",
        "filter": "true",
        "conf": {
          "comment": "For additional details, see this pack's README under Pack Settings."
        }
      },
      {
        "id": "comment",
        "filter": "true",
        "conf": {
          "comment": "Author: Cribl Packs Team"
        }
      },
      {
        "id": "grok",
        "filter": "_raw.match(/\\s+\\w+\\s+\\w+\\s+{/)",
        "disabled": true,
        "conf": {
          "patternList": [],
          "source": "_raw",
          "pattern": "%{WORD:log_level}%{SPACE}%{WORD:log_type}%{SPACE}%{GREEDYDATA:_json}"
        }
      },
      {
        "id": "regex_extract",
        "filter": "_raw.match(/\\s+\\w+\\s+\\w+\\s+{/)",
        "disabled": false,
        "conf": {
          "source": "_raw",
          "iterations": 100,
          "overwrite": true,
          "regex": "/\\s+(?<log_level>\\w+)\\s+(?<log_type>\\w+)\\s+(?<_json>.+)/"
        },
        "description": "Parse log_level+type+JSON"
      },
      {
        "id": "chain",
        "filter": "true",
        "disabled": true,
        "conf": {
          "processor": "cribl_k8s_logs_filter"
        },
        "description": "Call a pipeline containing custom filter logic"
      },
      {
        "id": "eval",
        "filter": "_json==null",
        "disabled": false,
        "conf": {
          "add": [
            {
              "disabled": false,
              "name": "message",
              "value": "_raw"
            }
          ]
        },
        "description": "Set the message field to _raw for non-JSON logs"
      },
      {
        "id": "serialize",
        "filter": "true",
        "disabled": false,
        "conf": {
          "type": "json",
          "dstField": "_raw",
          "fields": [
            "!_*",
            "!cribl*",
            "!source",
            "!sourcetype",
            "!host",
            "!kube_*",
            "log_*",
            "*"
          ]
        },
        "description": "Serialize the processed log into JSON format"
      },
      {
        "id": "eval",
        "filter": "true",
        "disabled": false,
        "conf": {
          "keep": [
            "cribl_*",
            "source",
            "sourcetype",
            "host",
            "log_*",
            "kube_*",
            "_time",
            "_raw"
          ],
          "remove": [
            "*"
          ],
          "add": [
            {
              "disabled": false,
              "value": "C.vars.k8s_logs_sourcetype || 'k8s:logs'",
              "name": "sourcetype"
            },
            {
              "disabled": false,
              "value": "C.vars.k8s_logs_source || 'edge-k8s-logs-' + kube_namespace + '-' + kube_pod",
              "name": "source"
            }
          ]
        },
        "description": "Remove unneeded fields and set common fields"
      }
    ],
    "description": ""
  }
}
```
</details>

<details>
<summary>3:k8s events : </summary>

```json
{
  "id": "cribl_k8s_events",
  "conf": {
    "output": "default",
    "streamtags": [],
    "groups": {},
    "asyncFuncTimeout": 1000,
    "functions": [
      {
        "id": "comment",
        "filter": "true",
        "conf": {
          "comment": "Process JSON K8S Events sent from the Cribl Edge container"
        }
      },
      {
        "id": "comment",
        "filter": "true",
        "conf": {
          "comment": "For additional details, see this pack's README under Pack Settings."
        }
      },
      {
        "id": "comment",
        "filter": "true",
        "conf": {
          "comment": "Author: Cribl Packs Team"
        }
      },
      {
        "id": "serde",
        "filter": "true",
        "disabled": false,
        "conf": {
          "mode": "extract",
          "type": "json",
          "srcField": "object",
          "remove": [
            "_raw"
          ],
          "fieldFilterExpr": "value !== '' && value !== null"
        },
        "description": "Parse the object JSON field"
      },
      {
        "id": "auto_timestamp",
        "filter": "true",
        "conf": {
          "srcField": "metadata.creationTimestamp",
          "dstField": "_time",
          "defaultTimezone": "UTC",
          "timeExpression": "time.getTime() / 1000",
          "offset": 0,
          "maxLen": 150,
          "defaultTime": "now",
          "latestDateAllowed": "+1week",
          "earliestDateAllowed": "-420weeks"
        },
        "description": "Use metadata.creationTimestamp as _time"
      },
      {
        "id": "comment",
        "filter": "true",
        "conf": {
          "comment": "Note: Edge K8S events do not have a value for involvedObject but metadata.name has the same value"
        }
      },
      {
        "id": "eval",
        "filter": "true",
        "conf": {
          "add": [
            {
              "disabled": false,
              "name": "involvedObject",
              "value": "metadata.name"
            },
            {
              "disabled": false,
              "name": "kube_namespace",
              "value": "regarding.name"
            }
          ]
        },
        "description": "Assign involvedObject and namespace fields"
      },
      {
        "id": "comment",
        "filter": "true",
        "conf": {
          "comment": "[Optional - disable if unneeded] Call a pipeline containing custom filter logic"
        }
      },
      {
        "id": "chain",
        "filter": "true",
        "disabled": true,
        "conf": {
          "processor": "cribl_k8s_events_filter"
        },
        "description": "Call a pipeline containing custom filter logic"
      },
      {
        "id": "serialize",
        "filter": "true",
        "disabled": false,
        "conf": {
          "type": "json",
          "dstField": "_raw",
          "fields": [
            "!_*",
            "!cribl*",
            "!source",
            "!sourcetype",
            "!host",
            "!type",
            "!involvedObject",
            "!reason",
            "!kube_*",
            "!object*",
            "*"
          ]
        },
        "description": "Serializes the JSON object into _raw"
      },
      {
        "id": "eval",
        "filter": "true",
        "disabled": false,
        "conf": {
          "keep": [
            "_raw",
            "cribl_*",
            "_time",
            "source",
            "sourcetype",
            "host",
            "reason",
            "involvedObject",
            "type",
            "message",
            "kube_*"
          ],
          "remove": [
            "*"
          ],
          "add": [
            {
              "disabled": false,
              "value": "C.vars.k8s_events_sourcetype || 'k8s:events'",
              "name": "sourcetype"
            },
            {
              "disabled": false,
              "name": "source",
              "value": "C.vars.k8s_events_source || 'edge-k8s-events'"
            }
          ]
        },
        "description": "Removed unneeded fields and add common fields"
      }
    ],
    "description": ""
  }
}
```
</details>

## Update the routes
Use the following JSON to install the routes
<details>
<summary>routes JSON</summary>

```json
{
  "id": "default",
  "routes": [
    {
      "id": "PQqbqi",
      "name": "Replay",
      "final": true,
      "disabled": false,
      "pipeline": "passthru",
      "description": "",
      "enableOutputExpression": false,
      "filter": "__inputId=='cribl_http:in_cribl_http' && cribl_search_id",
      "clones": [],
      "output": "elastic-otel"
    },
    {
      "id": "T7i2rY",
      "name": "K8s_EDGE_to_lake",
      "final": true,
      "disabled": false,
      "pipeline": "cribl_k8s_edge_logs",
      "description": "",
      "enableOutputExpression": false,
      "filter": "__inputId=='cribl_http:in_cribl_http'  &&  kube_container=='edge'",
      "clones": [],
      "output": "k8s_router_to_lake",
      "groupId": "yNkwet"
    },
    {
      "id": "3LhVQf",
      "name": "K8s_logs_to_lake",
      "final": true,
      "disabled": false,
      "pipeline": "cribl_k8s_logs",
      "description": "",
      "enableOutputExpression": false,
      "filter": "__inputId=='cribl_http:in_cribl_http'  && kube_namespace!=null",
      "clones": [],
      "output": "k8s_router_to_lake",
      "groupId": "yNkwet"
    },
    {
      "id": "clUbDl",
      "name": "K8s_events_to_lake",
      "final": true,
      "disabled": false,
      "pipeline": "cribl_k8s_events",
      "description": "",
      "enableOutputExpression": false,
      "filter": "__inputId=='cribl_http:in_cribl_http'  && _raw.includes('events.k8s.io')",
      "clones": [],
      "output": "k8s_router_to_lake",
      "groupId": "yNkwet"
    },
    {
      "id": "atAndy",
      "name": "Send logs, metrics and traces to Lake",
      "final": false,
      "disabled": false,
      "pipeline": "passthru",
      "description": "",
      "enableOutputExpression": false,
      "filter": "__otlp.type",
      "clones": [
        {}
      ],
      "output": "otel-router-to-lake"
    },
    {
      "id": "Dk4BhU",
      "name": "Create RED metrics from OTel traces",
      "final": false,
      "disabled": false,
      "pipeline": "metrics-to-elastic",
      "description": "",
      "enableOutputExpression": false,
      "filter": "__otlp.type == 'traces'",
      "clones": [
        {}
      ],
      "output": "elastic-prometheus"
    },
    {
      "id": "IDxs9F",
      "name": "Send everything to Elastic",
      "final": false,
      "disabled": true,
      "pipeline": "passthru",
      "description": "",
      "enableOutputExpression": false,
      "filter": "true",
      "clones": [
        {}
      ],
      "output": "elastic-otel"
    },
    {
      "id": "default",
      "name": "default",
      "final": true,
      "disabled": false,
      "pipeline": "devnull",
      "description": "",
      "enableOutputExpression": false,
      "filter": "true",
      "clones": [],
      "output": "devnull"
    }
  ],
  "comments": [],
  "groups": {
    "yNkwet": {
      "name": "K8s logs and events",
      "index": 1
    }
  }
}
```
</details>

## Commit and deploy, test
* Test the data flowing through sources. You may need to deploy Edge and `otel-demo` first.
* Test the destinations are available. You may need to deploy the Elastic stack first.

 ## for k8s sources
  * install the [k8s pack](https://packs.cribl.io/packs/cribl-kubernetes). it contains the http source on port 11200:
  * Change the variable C.vars['k8s_http_port'] to  10200 In pack->Knowledge->variables
  * configure the variables within the pack for the k8s datasets : 
  * DO set those datasets : k8s_logs, k8s_metrics, K8s_events

