# Ollama API — Deep Research & Discovery

## 1. Overview

Ollama exposes a REST API on `http://localhost:11434` (default) for local/self-hosted instances. The API uses JSON payloads and supports streaming via newline-delimited JSON (NDJSON). Ollama also provides cloud-hosted model inference through `https://ollama.com` with API key authentication, using the same endpoint contracts as the local server.

**Base URL (Local):** `http://localhost:11434`
**Base URL (Cloud):** `https://ollama.com` (requires `Authorization: Bearer <API_KEY>` header)

All durations in responses are reported in **nanoseconds**. Model names follow the `model:tag` format (e.g., `llama3.2:latest`, `deepseek-r1:7b`).

---

## 2. Inference Endpoints

### 2.1 Generate a Completion — `POST /api/generate`

Generates a text response for a given prompt. Streaming is enabled by default.

#### Request Parameters

| Parameter    | Type     | Required | Description |
|-------------|----------|----------|-------------|
| `model`     | string   | **Yes**  | Model name (`model:tag` format) |
| `prompt`    | string   | No       | The prompt to generate a response for |
| `suffix`    | string   | No       | Text to append after the model response (fill-in-the-middle) |
| `images`    | string[] | No       | Base64-encoded images (multimodal models only, e.g., `llava`) |
| `think`     | boolean  | No       | Enable thinking/reasoning for supported thinking models |
| `format`    | string/object | No  | `"json"` for JSON mode, or a JSON Schema object for structured outputs |
| `options`   | object   | No       | Runtime model parameters (see §4 below) |
| `system`    | string   | No       | System message (overrides Modelfile) |
| `template`  | string   | No       | Prompt template (overrides Modelfile) |
| `stream`    | boolean  | No       | `false` returns a single response object (default: `true`) |
| `raw`       | boolean  | No       | `true` disables prompt templating |
| `keep_alive`| string   | No       | Duration model stays in memory after request (default: `"5m"`) |
| `context`   | int[]    | No       | *(Deprecated)* Context from a previous `/generate` call |

**Experimental Image Generation Parameters** (for image generation models only):

| Parameter | Type | Description |
|-----------|------|-------------|
| `width`   | int  | Width of generated image in pixels |
| `height`  | int  | Height of generated image in pixels |
| `steps`   | int  | Number of diffusion steps |

#### Response Fields (Streaming)

Each streamed JSON object contains:

| Field       | Type    | Description |
|-------------|---------|-------------|
| `model`     | string  | Model name |
| `created_at`| string  | ISO 8601 timestamp |
| `response`  | string  | Partial token text |
| `done`      | boolean | `true` on the final object |

The **final** response object includes performance statistics:

| Field                  | Type   | Description |
|------------------------|--------|-------------|
| `total_duration`       | int    | Total generation time (ns) |
| `load_duration`        | int    | Model load time (ns) |
| `prompt_eval_count`    | int    | Number of prompt tokens |
| `prompt_eval_duration` | int    | Prompt evaluation time (ns) |
| `eval_count`           | int    | Number of generated tokens |
| `eval_duration`        | int    | Generation time (ns) |
| `done_reason`          | string | Reason for completion (e.g., `"stop"`, `"unload"`) |

**Tokens per second** = `eval_count / eval_duration × 10⁹`

#### Special Behaviors

- **Load a model:** Send an empty prompt to preload a model into memory.
- **Unload a model:** Send an empty prompt with `"keep_alive": 0`.
- **Reproducible outputs:** Set `options.seed` to a fixed number.

---

### 2.2 Chat Completion — `POST /api/chat`

Generates the next message in a multi-turn conversation. Streaming is enabled by default.

#### Request Parameters

| Parameter    | Type     | Required | Description |
|-------------|----------|----------|-------------|
| `model`     | string   | **Yes**  | Model name |
| `messages`  | object[] | No       | Array of message objects for conversation history |
| `tools`     | object[] | No       | Tool/function definitions for tool calling |
| `think`     | boolean  | No       | Enable thinking for supported models |
| `format`    | string/object | No  | `"json"` or JSON Schema for structured output |
| `options`   | object   | No       | Runtime model parameters (see §4) |
| `stream`    | boolean  | No       | `false` for single response (default: `true`) |
| `keep_alive`| string   | No       | Duration model stays loaded (default: `"5m"`) |

#### Message Object

| Field        | Type     | Description |
|-------------|----------|-------------|
| `role`      | string   | `"system"`, `"user"`, `"assistant"`, or `"tool"` |
| `content`   | string   | Message content |
| `thinking`  | string   | Model's thinking process (thinking models) |
| `images`    | string[] | Base64-encoded images (multimodal, user messages only) |
| `tool_calls`| object[] | Tool calls requested by the model |
| `tool_name` | string   | Name of the tool that produced this result |

#### Response Fields

Same streaming structure as `/api/generate`, with `message` object instead of `response`:

```json
{
  "model": "llama3.2",
  "message": {
    "role": "assistant",
    "content": "partial token...",
    "tool_calls": [...]
  },
  "done": false
}
```

#### Tool Calling

Tools are defined using OpenAI-style function schemas in the `tools` array:

```json
{
  "type": "function",
  "function": {
    "name": "get_weather",
    "description": "Get the weather in a given city",
    "parameters": {
      "type": "object",
      "properties": {
        "city": { "type": "string", "description": "The city name" }
      },
      "required": ["city"]
    }
  }
}
```

The model responds with `tool_calls` in the assistant message. The client executes the tool and sends the result back as a `"role": "tool"` message with `tool_name` set.

---

### 2.3 Generate Embeddings — `POST /api/embed`

Generates vector embeddings from text input. Supports single or batch input.

| Parameter    | Type          | Required | Description |
|-------------|---------------|----------|-------------|
| `model`     | string        | **Yes**  | Embedding model name |
| `input`     | string/string[] | **Yes** | Text or array of texts to embed |
| `truncate`  | boolean       | No       | Truncate input to fit context length (default: `true`) |
| `options`   | object        | No       | Model parameters |
| `keep_alive`| string        | No       | Memory duration (default: `"5m"`) |
| `dimensions`| int           | No       | Number of embedding dimensions |

#### Response

```json
{
  "model": "all-minilm",
  "embeddings": [[0.010, -0.001, 0.050, ...]],
  "total_duration": 14143917,
  "load_duration": 1019500,
  "prompt_eval_count": 8
}
```

> **Note:** The legacy `POST /api/embeddings` endpoint (singular `prompt` parameter, singular `embedding` response) is deprecated in favor of `/api/embed`.

---

## 3. Model Management Endpoints

### 3.1 List Local Models — `GET /api/tags`

Returns all models available on the local Ollama server.

#### Response

```json
{
  "models": [
    {
      "name": "llama3.2:latest",
      "model": "llama3.2:latest",
      "modified_at": "2025-05-04T17:37:44.706Z",
      "size": 2019393189,
      "digest": "a80c4f17acd5...",
      "details": {
        "parent_model": "",
        "format": "gguf",
        "family": "llama",
        "families": ["llama"],
        "parameter_size": "3.2B",
        "quantization_level": "Q4_K_M"
      }
    }
  ]
}
```

### 3.2 Show Model Information — `POST /api/show`

Retrieves detailed metadata about a model.

| Parameter | Type    | Required | Description |
|-----------|---------|----------|-------------|
| `model`   | string  | **Yes**  | Model name |
| `verbose` | boolean | No       | Include full tokenizer data |

#### Response Fields

| Field         | Description |
|---------------|-------------|
| `modelfile`   | The Modelfile content |
| `parameters`  | Model parameters (e.g., stop tokens) |
| `template`    | Prompt template |
| `details`     | Format, family, parameter count, quantization |
| `model_info`  | Architecture details, context length, vocab size |
| `capabilities`| Array of capabilities (e.g., `["completion", "vision"]`) |

### 3.3 Pull a Model — `POST /api/pull`

Downloads a model from the Ollama library. Supports resumable downloads and streaming progress.

| Parameter  | Type    | Required | Description |
|-----------|---------|----------|-------------|
| `model`   | string  | **Yes**  | Model name to pull |
| `insecure`| boolean | No       | Allow insecure connections |
| `stream`  | boolean | No       | Stream progress updates (default: `true`) |

#### Streaming Progress Response

```json
{"status": "pulling manifest"}
{"status": "pulling <digest>", "digest": "sha256:...", "total": 2142590208, "completed": 241970}
{"status": "verifying sha256 digest"}
{"status": "writing manifest"}
{"status": "success"}
```

### 3.4 Push a Model — `POST /api/push`

Uploads a model to a model library (requires account and public key).

| Parameter  | Type    | Required | Description |
|-----------|---------|----------|-------------|
| `model`   | string  | **Yes**  | Model name (`namespace/model:tag`) |
| `insecure`| boolean | No       | Allow insecure connections |
| `stream`  | boolean | No       | Stream progress (default: `true`) |

### 3.5 Create a Model — `POST /api/create`

Creates a custom model from a base model, GGUF file, or Safetensors directory.

| Parameter    | Type    | Required | Description |
|-------------|---------|----------|-------------|
| `model`     | string  | **Yes**  | Name for the new model |
| `from`      | string  | No       | Base model name |
| `files`     | object  | No       | Dict of filenames to SHA256 digests |
| `adapters`  | object  | No       | Dict of LoRA adapter filenames to digests |
| `template`  | string  | No       | Prompt template |
| `license`   | string/string[] | No | License text(s) |
| `system`    | string  | No       | System prompt |
| `parameters`| object  | No       | Model parameters |
| `messages`  | object[]| No       | Conversation seed messages |
| `stream`    | boolean | No       | Stream creation progress |
| `quantize`  | string  | No       | Quantization type (`q4_K_M`, `q4_K_S`, `q8_0`) |

### 3.6 Copy a Model — `POST /api/copy`

Creates a copy of an existing model under a new name.

| Parameter     | Type   | Required | Description |
|--------------|--------|----------|-------------|
| `source`     | string | **Yes**  | Source model name |
| `destination`| string | **Yes**  | Destination model name |

### 3.7 Delete a Model — `DELETE /api/delete`

Deletes a model and its data.

| Parameter | Type   | Required | Description |
|-----------|--------|----------|-------------|
| `model`   | string | **Yes**  | Model name to delete |

---

## 4. Blob Management

### 4.1 Check if a Blob Exists — `HEAD /api/blobs/:digest`

Checks if a binary blob exists on the server.

**Path Parameter:** `digest` — SHA256 digest of the blob.
**Response:** `200 OK` if exists, `404 Not Found` if not.

### 4.2 Push a Blob — `POST /api/blobs/:digest`

Uploads a binary file (e.g., GGUF model) to the server.

**Path Parameter:** `digest` — Expected SHA256 digest.
**Response:** `201 Created` on success, `400 Bad Request` on digest mismatch.

---

## 5. System Endpoints

### 5.1 List Running Models — `GET /api/ps`

Lists models currently loaded in memory.

#### Response

```json
{
  "models": [
    {
      "name": "mistral:latest",
      "model": "mistral:latest",
      "size": 5137025024,
      "digest": "2ae6f6dd7a3d...",
      "details": { "format": "gguf", "family": "llama", "parameter_size": "7.2B" },
      "expires_at": "2024-06-04T14:38:31.837Z",
      "size_vram": 5137025024
    }
  ]
}
```

### 5.2 Version — `GET /api/version`

Returns the Ollama server version.

```json
{ "version": "0.5.1" }
```

---

## 6. Runtime Model Options (§4 Reference)

The `options` object in inference requests supports the following parameters:

### Sampling Parameters

| Option              | Type    | Description |
|--------------------|---------|-------------|
| `temperature`      | float   | Controls randomness (0.0 = deterministic, higher = creative) |
| `top_k`            | int     | Limits token selection to top-K most probable tokens |
| `top_p`            | float   | Nucleus sampling — cumulative probability threshold |
| `min_p`            | float   | Minimum probability threshold for token consideration |
| `typical_p`        | float   | Typical sampling probability |
| `seed`             | int     | Random seed for reproducible outputs |
| `num_predict`      | int     | Max tokens to generate (-1 = infinite, -2 = fill context) |
| `stop`             | string[]| Stop sequences — generation halts when encountered |

### Repetition Control

| Option              | Type    | Description |
|--------------------|---------|-------------|
| `repeat_penalty`   | float   | Penalty for repeated tokens (higher = less repetition) |
| `repeat_last_n`    | int     | Lookback window for repetition penalty (0 = disabled, -1 = full context) |
| `presence_penalty` | float   | Penalize tokens based on presence in prior text |
| `frequency_penalty`| float   | Penalize tokens based on frequency in prior text |
| `penalize_newline` | boolean | Whether to penalize newline tokens |

### Context & Memory

| Option      | Type | Description |
|-------------|------|-------------|
| `num_ctx`   | int  | Context window size in tokens (default: 2048; model-dependent max, e.g., 128K for Llama 3.1) |
| `num_keep`  | int  | Number of tokens to retain from the initial prompt |

### Hardware & Performance

| Option       | Type    | Description |
|-------------|---------|-------------|
| `num_thread` | int    | CPU threads for computation |
| `num_gpu`    | int    | Number of model layers offloaded to GPU |
| `num_batch`  | int    | Batch size for prompt evaluation |
| `main_gpu`   | int    | Primary GPU index |
| `use_mmap`   | boolean| Memory-mapped I/O for model loading |
| `numa`       | boolean| NUMA optimization |

### Advanced Sampling

| Option              | Type  | Description |
|--------------------|-------|-------------|
| `tfs_z`            | float | Tail-free sampling parameter |
| `mirostat`         | int   | Mirostat sampling mode (0 = disabled, 1 = v1, 2 = v2) |
| `mirostat_tau`     | float | Target entropy for Mirostat |
| `mirostat_eta`     | float | Learning rate for Mirostat |

---

## 7. Advanced Features

### 7.1 Multimodal / Vision Support

Models with vision capabilities (e.g., `llava`, `gemma3`, `llama3.2-vision`) accept base64-encoded images:

- **`/api/generate`**: Pass `images` as a top-level array parameter alongside `prompt`.
- **`/api/chat`**: Pass `images` inside individual user message objects in the `messages` array.

Images are preprocessed (resized, normalized) before being fed to the model's vision encoder. The `capabilities` field in `/api/show` responses indicates whether a model supports `"vision"`.

### 7.2 Structured Outputs & JSON Mode

Two modes are available via the `format` parameter:

1. **JSON Mode** (`"format": "json"`): Ensures valid JSON output (structure depends on prompt).
2. **Schema Mode** (`"format": { "type": "object", ... }`): Enforces strict JSON Schema compliance — ideal for function calling and API integration.

### 7.3 Thinking Models

Models with reasoning capabilities support a `think` parameter. When enabled, the model includes its internal reasoning process in the `thinking` field of the response message, separate from the final `content`.

### 7.4 Image Generation (Experimental)

Image generation models use the standard `/api/generate` endpoint with optional `width`, `height`, and `steps` parameters. The response streams progress updates and returns the final image as a base64-encoded string in the `image` field.

### 7.5 Context Window Management

- **Default context:** Most models default to 2048–4096 tokens.
- **Extending context:** Set `options.num_ctx` up to the model's maximum (visible via `/api/show` → `model_info.*.context_length`).
- **Statefulness:** The API is stateless per request. For multi-turn conversations, the client must send the full conversation history in each request.
- **Overflow behavior:** When input exceeds `num_ctx`, oldest messages are trimmed. Persist system prompts by prepending them to each request.

### 7.6 Model Loading & Memory Management

- **`keep_alive`**: Controls how long a model remains in VRAM after a request (default: 5 minutes). Set to `0` to unload immediately, or `"-1"` to keep indefinitely.
- **Preloading:** Send an empty prompt/messages to load a model without generating output.
- **`/api/ps`**: Monitor which models are loaded and their VRAM usage.

---

## 8. Ollama Cloud vs. Self-Hosted

### 8.1 Self-Hosted

- Full local control — models and data stay on-premise.
- API at `http://localhost:11434` (configurable).
- No API key required for local access.
- Offline-capable after model download.

### 8.2 Ollama Cloud

Ollama offers cloud-hosted inference at `https://ollama.com`:

- **Same API contracts** as local — uses `/api/generate`, `/api/chat`, etc.
- **Authentication:** Requires API key via `Authorization: Bearer <key>` header.
- **Model library:** Browse available models at `https://ollama.com/library`.
- **Cloud models:** Use the `:cloud` tag suffix to run larger models on cloud infrastructure without local hardware requirements.
- **Data privacy:** Ollama states no user data is retained on their servers.

### 8.3 Model Library Interaction

For the mobile client, the Ollama library at `ollama.com/library` provides a browseable catalog of models. The client can:

1. **Browse** available models from the library (web scraping or future API).
2. **Pull** models to a connected Ollama server via `POST /api/pull`.
3. **Monitor progress** via streamed pull status updates.
4. **Delete** models via `DELETE /api/delete`.
5. **Inspect** model details via `POST /api/show`.

This gives users a cloud-like experience of "browsing and downloading" models instantly to their self-hosted server.

---

## 9. Complete API Reference Table

| Endpoint                 | Method | Purpose                              | Streaming |
|-------------------------|--------|--------------------------------------|-----------|
| `/api/generate`         | POST   | Text/image generation                | Yes       |
| `/api/chat`             | POST   | Multi-turn chat completion           | Yes       |
| `/api/embed`            | POST   | Generate embeddings (batch)          | No        |
| `/api/embeddings`       | POST   | Generate embeddings (deprecated)     | No        |
| `/api/tags`             | GET    | List local models                    | No        |
| `/api/show`             | POST   | Show model details                   | No        |
| `/api/pull`             | POST   | Download model from library          | Yes       |
| `/api/push`             | POST   | Upload model to library              | Yes       |
| `/api/create`           | POST   | Create custom model                  | Yes       |
| `/api/copy`             | POST   | Copy/rename a model                  | No        |
| `/api/delete`           | DELETE | Delete a model                       | No        |
| `/api/blobs/:digest`    | HEAD   | Check blob existence                 | No        |
| `/api/blobs/:digest`    | POST   | Upload blob                          | No        |
| `/api/ps`               | GET    | List running/loaded models           | No        |
| `/api/version`          | GET    | Server version                       | No        |

---

## 10. Key Takeaways for Mobile Client Development

1. **Use native API only** — avoid `/v1/*` OpenAI-compatible wrappers.
2. **Streaming is critical** — parse NDJSON for real-time token display in chat UI.
3. **Conversation state is client-managed** — store and replay full message history.
4. **Multimodal support** — implement camera/gallery image input for vision models.
5. **Tool calling** — support function schemas and tool result round-trips.
6. **Model management UI** — pull, delete, inspect models with progress tracking.
7. **Structured outputs** — leverage JSON Schema for app-internal data extraction.
8. **Context window awareness** — let users configure `num_ctx` and show token usage.
9. **Thinking models** — display reasoning trace in a collapsible UI section.
10. **Connection flexibility** — support both local server URLs and Ollama Cloud with API key.
