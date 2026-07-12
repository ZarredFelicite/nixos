#!/usr/bin/env node

import { chmod, unlink } from "node:fs/promises";
import { createConnection, createServer } from "node:net";
import { dirname } from "node:path";
import { pathToFileURL } from "node:url";

const MAX_REQUEST_BYTES = 64 * 1024 * 1024;
const socketPath =
  process.env.LLM_API_SOCKET ??
  `${process.env.XDG_RUNTIME_DIR}/llm-api/daemon.sock`;

function readStdin() {
  return new Promise((resolve, reject) => {
    let input = "";
    process.stdin.setEncoding("utf8");
    process.stdin.on("data", (chunk) => {
      input += chunk;
      if (Buffer.byteLength(input) > MAX_REQUEST_BYTES) {
        reject(new Error("Request exceeds 64 MiB"));
      }
    });
    process.stdin.on("end", () => resolve(input));
    process.stdin.on("error", reject);
  });
}

async function runClient() {
  const request = (await readStdin()).trim();
  if (!request) throw new Error("Expected a JSON request on stdin");
  JSON.parse(request);

  await new Promise((resolve, reject) => {
    const socket = createConnection(socketPath);
    let response = "";
    let settled = false;

    const finish = (error) => {
      if (settled) return;
      settled = true;
      socket.destroy();
      if (error) reject(error);
      else resolve();
    };

    socket.setEncoding("utf8");
    socket.setTimeout(10 * 60 * 1000, () => finish(new Error("Daemon request timed out")));
    socket.on("connect", () => socket.write(`${request}\n`));
    socket.on("data", (chunk) => {
      response += chunk;
      if (Buffer.byteLength(response) > MAX_REQUEST_BYTES) {
        finish(new Error("Response exceeds 64 MiB"));
        return;
      }
      const newline = response.indexOf("\n");
      if (newline !== -1) {
        process.stdout.write(response.slice(0, newline + 1));
        finish();
      }
    });
    socket.on("end", () => {
      if (!settled && response.length > 0) {
        process.stdout.write(response.endsWith("\n") ? response : `${response}\n`);
        finish();
      } else if (!settled) {
        finish(new Error("Daemon closed the connection without a response"));
      }
    });
    socket.on("error", finish);
  });
}

function validateRequest(request) {
  if (request === null || typeof request !== "object" || Array.isArray(request)) {
    throw new Error("Request must be a JSON object");
  }
  if (typeof request.prompt !== "string" || request.prompt.length === 0) {
    throw new Error("prompt must be a non-empty string");
  }
  if (typeof request.model !== "string" || request.model.length === 0) {
    throw new Error("model must be a non-empty string");
  }
  if (request.provider !== undefined && request.provider !== "openai-codex") {
    throw new Error(`Unsupported provider: ${request.provider}`);
  }
  if (!["off", "minimal", "low", "medium", "high", "xhigh", "max"].includes(request.thinking)) {
    throw new Error(`Invalid thinking level: ${request.thinking}`);
  }
  if (request.systemPrompt !== undefined && typeof request.systemPrompt !== "string") {
    throw new Error("systemPrompt must be a string");
  }
  if (request.images !== undefined && !Array.isArray(request.images)) {
    throw new Error("images must be an array");
  }
}

function imageContent(images = []) {
  return images.map((image) => {
    if (
      image === null ||
      typeof image !== "object" ||
      typeof image.data !== "string" ||
      typeof image.mimeType !== "string"
    ) {
      throw new Error("Each image requires base64 data and mimeType strings");
    }
    return {
      type: "image",
      data: image.data,
      mimeType: image.mimeType,
    };
  });
}

async function runServer() {
  const sdkPath = process.env.PI_SDK_PATH;
  if (!sdkPath) throw new Error("PI_SDK_PATH is not set");

  const {
    AuthStorage,
    createAgentSession,
    DefaultResourceLoader,
    getAgentDir,
    ModelRegistry,
    SessionManager,
    SettingsManager,
  } = await import(pathToFileURL(sdkPath).href);

  const cwd = process.env.HOME;
  const agentDir = getAgentDir();
  const authStorage = AuthStorage.create();
  const modelRegistry = ModelRegistry.create(authStorage);

  async function processRequest(request) {
    validateRequest(request);
    const model = modelRegistry.find("openai-codex", request.model);
    if (!model) throw new Error(`Model not found: openai-codex/${request.model}`);

    const settingsManager = SettingsManager.inMemory({
      compaction: { enabled: false },
      retry: { enabled: true, maxRetries: 1, baseDelayMs: 500 },
    });
    const loader = new DefaultResourceLoader({
      cwd,
      agentDir,
      settingsManager,
      noExtensions: true,
      noSkills: true,
      noPromptTemplates: true,
      noThemes: true,
      noContextFiles: true,
      systemPromptOverride: () => request.systemPrompt ?? "You are a helpful assistant.",
      appendSystemPromptOverride: () => [],
    });
    await loader.reload();

    const { session } = await createAgentSession({
      cwd,
      agentDir,
      model,
      thinkingLevel: request.thinking,
      authStorage,
      modelRegistry,
      noTools: "all",
      resourceLoader: loader,
      sessionManager: SessionManager.inMemory(cwd),
      settingsManager,
    });

    let output = "";
    const unsubscribe = session.subscribe((event) => {
      if (
        event.type === "message_update" &&
        event.assistantMessageEvent.type === "text_delta"
      ) {
        output += event.assistantMessageEvent.delta;
      }
    });

    try {
      await session.prompt(request.prompt, {
        expandPromptTemplates: false,
        images: imageContent(request.images),
      });

      const lastAssistant = [...session.messages]
        .reverse()
        .find((message) => message.role === "assistant");
      if (lastAssistant?.stopReason === "error") {
        throw new Error(lastAssistant.errorMessage ?? "Model request failed");
      }
      if (!output && lastAssistant) {
        output = lastAssistant.content
          .filter((part) => part.type === "text")
          .map((part) => part.text)
          .join("");
      }

      return {
        ok: true,
        output,
        model: request.model,
        thinking: request.thinking,
        sessionFile: session.sessionFile ?? null,
      };
    } finally {
      unsubscribe();
      session.dispose();
    }
  }

  await unlink(socketPath).catch((error) => {
    if (error.code !== "ENOENT") throw error;
  });

  const server = createServer((connection) => {
    connection.setEncoding("utf8");
    let input = "";
    let handled = false;

    const respond = async () => {
      if (handled) return;
      handled = true;
      try {
        const request = JSON.parse(input.trim());
        const response = await processRequest(request);
        connection.end(`${JSON.stringify(response)}\n`);
      } catch (error) {
        connection.end(`${JSON.stringify({ ok: false, error: error.message })}\n`);
      }
    };

    connection.on("data", (chunk) => {
      input += chunk;
      if (Buffer.byteLength(input) > MAX_REQUEST_BYTES) {
        input = "";
        handled = true;
        connection.end(`${JSON.stringify({ ok: false, error: "Request exceeds 64 MiB" })}\n`);
      } else if (input.includes("\n")) {
        input = input.slice(0, input.indexOf("\n"));
        void respond();
      }
    });
    connection.on("end", () => {
      if (input.trim()) void respond();
    });
    connection.on("error", (error) => console.error("Client connection error:", error));
  });

  server.on("error", (error) => {
    console.error("Server error:", error);
    process.exitCode = 1;
  });

  server.listen(socketPath, async () => {
    await chmod(socketPath, 0o600);
    console.error(`llm-api daemon listening on ${socketPath}`);
  });

  const shutdown = () => {
    server.close(() => process.exit(0));
  };
  process.on("SIGINT", shutdown);
  process.on("SIGTERM", shutdown);
}

try {
  if (process.argv.includes("--client")) await runClient();
  else await runServer();
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
}
