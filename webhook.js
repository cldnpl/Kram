const http = require('http');
const crypto = require('crypto');
const { spawn } = require('child_process');
const fs = require('fs');

const PORT = 9001;
const SECRET = fs.readFileSync('/opt/kram/.webhook_secret', 'utf8').trim();
const DEPLOY_SCRIPT = '/opt/kram/deploy.sh';
const LOG_FILE = '/var/log/kram-deploy.log';
const ENV_FILE = '/opt/kram/.webhook.env';

let isDeploying = false;
let pendingDeployContext = null;

function loadEnvFile(filePath) {
  if (!fs.existsSync(filePath)) {
    return;
  }

  const lines = fs.readFileSync(filePath, 'utf8').split(/\r?\n/);
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) {
      continue;
    }

    const equalSignIndex = trimmed.indexOf('=');
    if (equalSignIndex === -1) {
      continue;
    }

    const key = trimmed.slice(0, equalSignIndex).trim();
    let value = trimmed.slice(equalSignIndex + 1).trim();

    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }

    if (!(key in process.env)) {
      process.env[key] = value;
    }
  }
}

loadEnvFile(ENV_FILE);

const TELEGRAM_BOT_TOKEN = (process.env.TELEGRAM_BOT_TOKEN || '').trim();
const TELEGRAM_CHAT_IDS = parseTelegramChatIds(
  process.env.TELEGRAM_CHAT_IDS || '',
  process.env.TELEGRAM_CHAT_ID || ''
);

function parseTelegramChatIds(many, single) {
  const ids = [];

  if (many && many.trim()) {
    for (const part of many.split(',')) {
      const id = part.trim();
      if (id) {
        ids.push(id);
      }
    }
  } else if (single && single.trim()) {
    ids.push(single.trim());
  }

  return [...new Set(ids)];
}

function log(msg) {
  const line = `[${new Date().toISOString()}] [webhook] ${msg}\n`;
  process.stdout.write(line);
  fs.appendFileSync(LOG_FILE, line);
}

function escapeHtml(str) {
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

async function sendTelegramMessage(text) {
  if (!TELEGRAM_BOT_TOKEN || TELEGRAM_CHAT_IDS.length === 0) {
    return;
  }

  for (const chatId of TELEGRAM_CHAT_IDS) {
    await telegramRequest('sendMessage', {
      chat_id: chatId,
      text,
      parse_mode: 'HTML',
      disable_web_page_preview: true,
    });
  }
}

async function telegramRequest(method, payload) {
  if (!TELEGRAM_BOT_TOKEN || TELEGRAM_CHAT_IDS.length === 0) {
    return null;
  }

  try {
    const res = await fetch(`https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/${method}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });

    const bodyText = await res.text();
    let bodyJson = null;
    try {
      bodyJson = JSON.parse(bodyText);
    } catch (_err) {
      bodyJson = null;
    }

    if (!res.ok || (bodyJson && bodyJson.ok === false)) {
      const description = bodyJson?.description || bodyText;
      if (description.includes('message is not modified')) {
        return bodyJson;
      }
      log(`Telegram API error (${res.status}): ${description}`);
      return bodyJson;
    }

    return bodyJson;
  } catch (error) {
    log(`Telegram send failed: ${error.message}`);
    return null;
  }
}

function signatureMatches(sigHeader, expected) {
  const actualBuffer = Buffer.from(sigHeader || '', 'utf8');
  const expectedBuffer = Buffer.from(expected, 'utf8');
  if (actualBuffer.length !== expectedBuffer.length) {
    return false;
  }
  return crypto.timingSafeEqual(actualBuffer, expectedBuffer);
}

function buildDeployContext(payload) {
  const branch = String(payload.ref || '').replace('refs/heads/', '') || 'unknown';
  const repo = payload.repository?.full_name || 'unknown';
  const pusher = payload.pusher?.name || payload.sender?.login || 'unknown';
  const commit = String(payload.after || '').slice(0, 7) || 'unknown';
  const commitMessage = String(payload.head_commit?.message || '').split('\n')[0] || 'No commit message';
  const compareUrl = payload.compare || '';

  return {
    branch,
    repo,
    pusher,
    commit,
    commitMessage,
    compareUrl,
  };
}

function notifyDeployQueued(ctx) {
  const msg =
    `<b>Kram deploy queued</b>\n` +
    `A deploy is running. Latest push will deploy next.\n` +
    `Repo: <code>${escapeHtml(ctx.repo)}</code>\n` +
    `Branch: <code>${escapeHtml(ctx.branch)}</code>\n` +
    `Commit: <code>${escapeHtml(ctx.commit)}</code>\n` +
    `By: <code>${escapeHtml(ctx.pusher)}</code>\n` +
    `Message: ${escapeHtml(ctx.commitMessage)}`;
  void sendTelegramMessage(msg);
}

function formatUtc(dateValue) {
  const d = dateValue instanceof Date ? dateValue : new Date(dateValue);
  return d.toISOString().replace('T', ' ').replace(/\.\d{3}Z$/, ' UTC');
}

function stageIcon(status) {
  if (status === 'done') {
    return '[x]';
  }
  if (status === 'running') {
    return '[~]';
  }
  if (status === 'warning') {
    return '[-]';
  }
  if (status === 'failed') {
    return '[!]';
  }
  return '[ ]';
}

function contextStateLabel(ctx) {
  if (ctx.state === 'success' && ctx.progress.health === 'warning') {
    return 'SUCCESS (health pending)';
  }
  if (ctx.state === 'success') {
    return 'SUCCESS';
  }
  if (ctx.state === 'failed') {
    return 'FAILED';
  }
  return 'RUNNING';
}

function durationSeconds(ctx) {
  if (!(ctx.startedAt instanceof Date)) {
    return null;
  }
  const end = ctx.finishedAt instanceof Date ? ctx.finishedAt : new Date();
  const seconds = Math.round((end.getTime() - ctx.startedAt.getTime()) / 1000);
  return seconds >= 0 ? seconds : null;
}

function buildDeployMessage(ctx) {
  const lines = [
    '<b>Kram Backend Deploy</b>',
    `Status: <b>${contextStateLabel(ctx)}</b>`,
    `Repo: <code>${escapeHtml(ctx.repo)}</code>`,
    `Branch: <code>${escapeHtml(ctx.branch)}</code>`,
    `Commit: <code>${escapeHtml(ctx.commit)}</code>`,
    `By: <code>${escapeHtml(ctx.pusher)}</code>`,
    `Message: ${escapeHtml(ctx.commitMessage)}`,
    `Started: <code>${escapeHtml(formatUtc(ctx.startedAt))}</code>`,
    '',
    '<b>Progress</b>',
    '<code>' +
      `${stageIcon(ctx.progress.webhook)} Webhook received\n` +
      `${stageIcon(ctx.progress.git)} Git pull\n` +
      `${stageIcon(ctx.progress.rebuild)} Docker rebuild\n` +
      `${stageIcon(ctx.progress.health)} API health check\n` +
      `${stageIcon(ctx.progress.done)} Completed` +
      '</code>',
  ];

  if (ctx.compareUrl) {
    lines.push(`Compare: ${escapeHtml(ctx.compareUrl)}`);
  }

  const elapsed = durationSeconds(ctx);
  if (elapsed !== null) {
    lines.push(`Duration: <code>${elapsed}s</code>`);
  }

  if (ctx.state !== 'running' && ctx.finishedAt) {
    lines.push(`Finished: <code>${escapeHtml(formatUtc(ctx.finishedAt))}</code>`);
  }

  if (ctx.state === 'failed' && ctx.errorMessage) {
    lines.push(`Error: <code>${escapeHtml(ctx.errorMessage)}</code>`);
  }

  const showTail =
    ctx.outputTail.length > 0 &&
    ctx.state !== 'running' &&
    (ctx.state === 'failed' || ctx.progress.health === 'warning');
  if (showTail) {
    const tail = ctx.outputTail.slice(-5).join('\n');
    lines.push('<b>Last logs</b>');
    lines.push(`<code>${escapeHtml(tail)}</code>`);
  }

  let message = lines.join('\n');
  if (message.length > 3900) {
    message = message.slice(0, 3885) + '\n...';
  }
  return message;
}

async function renderDeployMessage(ctx) {
  if (!TELEGRAM_BOT_TOKEN || TELEGRAM_CHAT_IDS.length === 0) {
    return;
  }

  const text = buildDeployMessage(ctx);

  for (const chatId of TELEGRAM_CHAT_IDS) {
    const currentMessageId = ctx.telegramMessageIds.get(chatId);
    if (!currentMessageId) {
      const response = await telegramRequest('sendMessage', {
        chat_id: chatId,
        text,
        parse_mode: 'HTML',
        disable_web_page_preview: true,
      });
      const messageId = response?.result?.message_id;
      if (messageId) {
        ctx.telegramMessageIds.set(chatId, messageId);
      }
      continue;
    }

    await telegramRequest('editMessageText', {
      chat_id: chatId,
      message_id: currentMessageId,
      text,
      parse_mode: 'HTML',
      disable_web_page_preview: true,
    });
  }
}

function queueDeployRender(ctx) {
  if (!TELEGRAM_BOT_TOKEN || TELEGRAM_CHAT_IDS.length === 0) {
    return;
  }

  ctx.renderRequested = true;
  if (ctx.renderInFlight) {
    return;
  }

  ctx.renderInFlight = true;
  (async () => {
    while (ctx.renderRequested) {
      ctx.renderRequested = false;
      await renderDeployMessage(ctx);
    }
    ctx.renderInFlight = false;
  })();
}

function setStage(ctx, stage, status) {
  if (ctx.progress[stage] === status) {
    return;
  }
  ctx.progress[stage] = status;
  queueDeployRender(ctx);
}

function parseDeployLine(ctx, line) {
  const clean = line.trim();
  if (!clean) {
    return;
  }

  log(`deploy: ${clean}`);
  const lower = clean.toLowerCase();
  const shouldStoreTail =
    clean.startsWith('[') ||
    lower.includes('error') ||
    lower.includes('failed') ||
    lower.includes('timed out') ||
    lower.includes('healthy');
  if (shouldStoreTail) {
    ctx.outputTail.push(clean);
    if (ctx.outputTail.length > 30) {
      ctx.outputTail.shift();
    }
  }

  if (clean.includes('Starting Kram deployment')) {
    setStage(ctx, 'git', 'running');
    return;
  }

  if (clean.includes('Code updated, rebuilding containers')) {
    setStage(ctx, 'git', 'done');
    setStage(ctx, 'rebuild', 'running');
    return;
  }

  if (clean.includes('Waiting for API to be ready')) {
    if (ctx.progress.rebuild !== 'done') {
      setStage(ctx, 'rebuild', 'done');
    }
    setStage(ctx, 'health', 'running');
    return;
  }

  if (clean.includes('Kram API is healthy')) {
    setStage(ctx, 'health', 'done');
    return;
  }

  if (clean.includes('Health check timed out')) {
    setStage(ctx, 'health', 'warning');
  }
}

function finalizeDeploy(ctx, ok, errorMessage) {
  ctx.finishedAt = new Date();
  if (ok) {
    ctx.state = 'success';

    if (ctx.progress.git === 'running') {
      ctx.progress.git = 'done';
    }
    if (ctx.progress.rebuild === 'running') {
      ctx.progress.rebuild = 'done';
    }
    if (ctx.progress.health === 'running') {
      ctx.progress.health = 'done';
    }
    if (ctx.progress.health === 'pending') {
      ctx.progress.health = 'warning';
    }
    ctx.progress.done = 'done';
  } else {
    ctx.state = 'failed';
    ctx.errorMessage = errorMessage || 'unknown error';
    if (ctx.progress.health === 'running') {
      ctx.progress.health = 'failed';
    } else if (ctx.progress.rebuild === 'running') {
      ctx.progress.rebuild = 'failed';
    } else if (ctx.progress.git === 'running') {
      ctx.progress.git = 'failed';
    }
    ctx.progress.done = 'failed';
  }
  queueDeployRender(ctx);
}

function runDeploy(context) {
  isDeploying = true;
  log(`Push event received for ${context.branch}@${context.commit}, starting deployment...`);
  queueDeployRender(context);

  const child = spawn('/bin/bash', [DEPLOY_SCRIPT], {
    stdio: ['ignore', 'pipe', 'pipe'],
  });

  let stdoutBuffer = '';
  let stderrBuffer = '';
  let killedByTimeout = false;
  const timeoutHandle = setTimeout(() => {
    killedByTimeout = true;
    child.kill('SIGTERM');
  }, 600000);

  child.stdout.on('data', (chunk) => {
    stdoutBuffer += chunk.toString();
    const lines = stdoutBuffer.split('\n');
    stdoutBuffer = lines.pop() || '';
    for (const line of lines) {
      parseDeployLine(context, line);
    }
  });

  child.stderr.on('data', (chunk) => {
    stderrBuffer += chunk.toString();
    const lines = stderrBuffer.split('\n');
    stderrBuffer = lines.pop() || '';
    for (const line of lines) {
      parseDeployLine(context, line);
    }
  });

  child.on('close', (code, signal) => {
    clearTimeout(timeoutHandle);

    if (stdoutBuffer.trim()) {
      parseDeployLine(context, stdoutBuffer.trim());
    }
    if (stderrBuffer.trim()) {
      parseDeployLine(context, stderrBuffer.trim());
    }

    isDeploying = false;
    if (killedByTimeout) {
      log('Deployment failed: timed out after 10 minutes');
      finalizeDeploy(context, false, 'timed out after 10 minutes');
    } else if (code === 0) {
      log('Deployment completed successfully');
      finalizeDeploy(context, true);
    } else {
      const errorMsg = `exit code ${code}${signal ? ` (${signal})` : ''}`;
      log(`Deployment failed: ${errorMsg}`);
      finalizeDeploy(context, false, errorMsg);
    }

    if (pendingDeployContext) {
      const nextContext = pendingDeployContext;
      pendingDeployContext = null;
      log(`Processing queued deployment for ${nextContext.branch}@${nextContext.commit}`);
      runDeploy(nextContext);
    }
  });
}

const server = http.createServer((req, res) => {
  if (req.method !== 'POST' || req.url !== '/webhook') {
    res.writeHead(404);
    res.end('Not found');
    return;
  }

  let body = '';
  req.on('data', chunk => { body += chunk; });
  req.on('end', () => {
    // Verify signature
    const sig = req.headers['x-hub-signature-256'] || '';
    const expected = 'sha256=' + crypto.createHmac('sha256', SECRET).update(body).digest('hex');
    if (!signatureMatches(sig, expected)) {
      log('Invalid signature, ignoring request');
      res.writeHead(401);
      res.end('Unauthorized');
      return;
    }

    const event = req.headers['x-github-event'];
    if (event !== 'push') {
      res.writeHead(200);
      res.end('Ignored');
      return;
    }

    res.writeHead(200);
    res.end('Deploying...');

    let payload;
    try {
      payload = JSON.parse(body);
    } catch (error) {
      log(`Failed to parse payload JSON: ${error.message}`);
      return;
    }

    const context = {
      ...buildDeployContext(payload),
      startedAt: new Date(),
      finishedAt: null,
      state: 'running',
      errorMessage: '',
      outputTail: [],
      renderInFlight: false,
      renderRequested: false,
      telegramMessageIds: new Map(),
      progress: {
        webhook: 'done',
        git: 'running',
        rebuild: 'pending',
        health: 'pending',
        done: 'pending',
      },
    };

    if (isDeploying) {
      pendingDeployContext = context;
      log(`Deployment already in progress, queued latest push for ${context.branch}@${context.commit}`);
      notifyDeployQueued(context);
      return;
    }

    runDeploy(context);
  });
});

server.listen(PORT, '127.0.0.1', () => {
  log(`Webhook server listening on port ${PORT}`);
  if (!TELEGRAM_BOT_TOKEN || TELEGRAM_CHAT_IDS.length === 0) {
    log('Telegram is disabled. Set TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_IDS in /opt/kram/.webhook.env');
  }
});
