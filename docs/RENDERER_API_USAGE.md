# Renderer API guide

This document describes the HTTP API for rendering PG or PGML problems from scripts.

## Base URL and endpoints

- The renderer serves requests at `{SITE_HOST}{baseURL}{formURL}`.
- Defaults are `baseURL: ''` and `formURL: '/render-api'` in `render_app.conf.dist`.
- Primary render endpoint: `POST /`.
- Compatibility endpoint: `POST /render-api`.
- Health check: `GET /health`.

## Request format

- Send request parameters as `application/json` or form-encoded data.
- For JSON clients, set `Content-Type: application/json`.
- For form-encoded requests, use `application/x-www-form-urlencoded`.
- Required parameters include a source and a seed:
  - Provide one source, in this order of precedence:
    - `problemSourceURL`: URL to fetch JSON with a `raw_source` field.
    - `problemSource`: raw PG source string (can be base64 encoded).
    - `sourceFilePath`: file path relative to `Library/`, `Contrib/`, or `private/`.
  - `problemSeed`: integer seed for reproducible randomization.
- Parameter precedence is `problemSourceURL` then `problemSource` then `sourceFilePath`.

## Common parameters and defaults

| Key | Type | Default | Notes |
| --- | ---- | ------- | ----- |
| problemSeed | number | required | Seed for reproducible randomization. |
| outputFormat | string | `default` | Output style (also supports `static`, `ptx`, `raw`). |
| displayMode | string | `MathJax` | Math rendering mode (`MathJax` or `ptx`). |
| _format | string | `html` | Response structure (`html` or `json`). |

## Minimal request example

```bash
curl -X POST "http://localhost:3000/render-api" \
  -H "Content-Type: application/json" \
  -d '{
    "sourceFilePath": "private/myproblem.pg",
    "problemSeed": 1234,
    "outputFormat": "html"
  }'
```

## Form-encoded request example

```bash
curl -X POST "http://localhost:3000/render-api" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "sourceFilePath=private/myproblem.pg" \
  --data-urlencode "problemSeed=1234" \
  --data-urlencode "outputFormat=html"
```

## Response format

- Use `_format` to control response structure:
  - `_format: "html"` returns HTML content (default).
  - `_format: "json"` returns JSON describing the render.
- Errors return non-200 status codes with a JSON payload containing `message` and `status`.
- JSON responses include an `inputs_ref` echo of the resolved request parameters.

## Response examples

### HTML response (default)

```html
<!doctype html>
<html>
  <head>...</head>
  <body>...</body>
</html>
```

### JSON response (`_format: "json"`)

Fields vary by `outputFormat`. Example shape:

```json
{
  "inputs_ref": {
    "sourceFilePath": "private/myproblem.pg",
    "problemSeed": 1234,
    "outputFormat": "default"
  }
}
```

### Error response

```json
{
  "message": "[abc123] Failed to retrieve problem source.",
  "status": 500
}
```

## problemSourceURL expectations

When using `problemSourceURL`, the renderer fetches JSON and reads a `raw_source` field.
The `raw_source` value is used as-is, so provide plain PG source text.

Example response from your source service:

```json
{
  "raw_source": "DOCUMENT();\nloadMacros(\"PGstandard.pl\");\nTEXT(beginproblem());\nENDDOCUMENT();\n"
}
```

## problemSource base64 usage

The renderer accepts raw PG source in `problemSource`. If you send base64-encoded content, the renderer will
decode it before rendering. Only base64-encode when your transport or client requires it.

Example JSON payload with base64 content:

```json
{
  "problemSource": "RE9DVU1FTlQoKTsKTG9hZE1hY3JvcygiUEdzdGFuZGFyZC5wbCIpOwpURVhUKGJlZ2lucHJvYmxlbSgpKTsKRU5ERE9DVU1FTlQoKTsK",
  "problemSeed": 1234,
  "outputFormat": "default"
}
```

## Rendering and display options

- `outputFormat`: controls the problem output style (`default`, `static`, `ptx`, `raw`).
- `displayMode`: controls math display (`MathJax` or `ptx`).
- `language`: locale identifier (default `en`).

## Interaction options

- `hidePreviewButton`: hide the preview answers button.
- `hideCheckAnswersButton`: hide the submit answers button.
- `showCorrectAnswersButton`: enable the show correct answers button.

## Content options

- `isInstructor`: enable instructor view and features (preferred over `permissionLevel`).
- `showHints`: show hints when available.
- `showSolutions`: show solutions when available.
- `hideAttemptsTable`: hide the attempts table.
- `showSummary`: show the summary under the attempts table.
- `showComments`: render author comments.
- `showFooter`: show renderer footer information.
- `includeTags`: include tags in JSON responses.

## JWT endpoints

- `POST /render-api/jwt` returns a problem JWT based on the request parameters.
- `POST /render-api/jwe` returns a JWE-encrypted problem JWT.
- When a `problemJWT` is provided, its values override request parameters.

### JWT flow example

1) Request a JWT for a specific problem:

```bash
curl -X POST "http://localhost:3000/render-api/jwt" \
  -H "Content-Type: application/json" \
  -d '{
    "sourceFilePath": "private/myproblem.pg",
    "problemSeed": 1234,
    "outputFormat": "default"
  }'
```

2) Use the returned token in a render request:

```bash
curl -X POST "http://localhost:3000/render-api" \
  -H "Content-Type: application/json" \
  -d '{
    "problemJWT": "<JWT_FROM_STEP_1>"
  }'
```

## PGML lint helper

The repo root includes `pglint.py`, a Python 3.12 CLI that posts PG content to the renderer API and emits
pyflakes-style issue lines.

- The default endpoint in `pglint.py` is `/render-api/render`.
- For this renderer, override it to `/render-api` or `/`.

### Issue keys and messages

- Default issue keys: `errors`, `warnings`.
- Default message keys: `message`, `error`, `warning`, `detail`, `stderr`.
- Override issue keys with `--error-keys` when your API uses different keys.

Example payload template:

```json
{
  "sourceFilePath": "{{PG_PATH}}",
  "problemSource": "{{PG_SOURCE}}",
  "problemSeed": "{{PG_SEED}}",
  "outputFormat": "{{PG_FORMAT}}"
}
```

Example run:

```bash
/opt/homebrew/opt/python@3.12/bin/python3.12 ./pglint.py \
  --endpoint /render-api \
  --payload-template /path/to/payload.json \
  private/example.pg
```
