import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import net from 'node:net';
import { spawn } from 'node:child_process';
import { chromium } from 'playwright';

const root = path.resolve(import.meta.dirname, '..');
const output = path.join(root, 'output', 'acceptance-' + Date.now());
const box = process.env.BOX_BINARY || (process.platform === 'win32' ? 'box.exe' : 'box');
const apps = [];
const ignored = new Set(['modules', 'bundles', '.boxlang', 'storage', '.engine', '.bundle', 'log', 'tmp']);
let sequence = 0;
fs.mkdirSync(output, { recursive: true });

async function runBox(app, args, { expectFailure = false } = {}) {
    const log = path.join(output, `${++sequence}-${app.framework}-${args.slice(0, 3).join('-')}.log`);
    const descriptor = fs.openSync(log, 'w');
    let code;
    try {
        code = await new Promise((resolve, reject) => {
            const child = spawn(box, args, {
                cwd: app.folder, stdio: ['ignore', descriptor, descriptor], windowsHide: true,
                env: { ...process.env, BOX_SERVER_START_TIMEOUT: '300' }
            });
            const timeout = setTimeout(() => {
                child.kill();
                reject(new Error(`CommandBox timed out: ${args.join(' ')}; inspect ${log}`));
            }, 600000);
            child.on('error', error => { clearTimeout(timeout); reject(error); });
            child.on('exit', result => { clearTimeout(timeout); resolve(result); });
        });
    } finally {
        fs.closeSync(descriptor);
    }
    if (expectFailure) {
        assert.notEqual(code, 0, `Expected rejection: ${log}`);
        assert.match(fs.readFileSync(log, 'utf8'), /Stop this example/);
    } else {
        assert.equal(code, 0, `CommandBox failed: inspect ${log}`);
    }
}

async function freePort() {
    const probe = net.createServer();
    await new Promise(resolve => probe.listen(0, '127.0.0.1', resolve));
    const port = probe.address().port;
    await new Promise(resolve => probe.close(resolve));
    return port;
}

function decode(value) {
    return value.replaceAll('&amp;', '&').replaceAll('&quot;', '"').replaceAll('&#39;', "'");
}

class Client {
    constructor(app) {
        this.app = app;
        this.cookies = new Map();
    }

    async request(uri, options = {}) {
        const response = await fetch(new URL(uri, this.app.base), {
            ...options, redirect: 'manual', signal: AbortSignal.timeout(60000),
            headers: { cookie: [...this.cookies].map(([key, value]) => key + '=' + value).join('; '), ...options.headers }
        });
        for (const cookie of response.headers.getSetCookie()) {
            const [pair] = cookie.split(';');
            const separator = pair.indexOf('=');
            this.cookies.set(pair.slice(0, separator), pair.slice(separator + 1));
        }
        return { response, html: await response.text() };
    }

    async get(uri, expected = 200) {
        const result = await this.request(uri);
        assert.equal(result.response.status, expected, `${this.app.framework} ${uri}: ${result.html.slice(0, 500)}`);
        return result.html;
    }

    async post(formUri, target, fields, expected = 303) {
        const html = await this.get(formUri);
        const inputs = html.match(/<input\b[^>]*>/g) || [];
        const field = inputs.find(input => /name="authenticity_token"/.test(input));
        assert.ok(field, 'Rendered form has an authenticity token');
        const token = decode(field.match(/value="([^"]*)"/)[1]);
        const body = new URLSearchParams({ authenticity_token: token, ...fields });
        const result = await this.request(target, {
            method: 'POST', headers: { 'content-type': 'application/x-www-form-urlencoded' }, body
        });
        assert.equal(result.response.status, expected, `${this.app.framework} POST ${target}: ${result.html.slice(0, 500)}`);
        return result;
    }
}

function location(result, expectedPrefix) {
    const uri = new URL(result.response.headers.get('location'), 'http://localhost').pathname;
    assert.ok(uri.startsWith(expectedPrefix), uri);
    return uri;
}

async function workflow(app) {
    const client = new Client(app);
    app.client = client;
    const landing = await client.get('/');
    assert.match(landing, /BoxLang host/);
    assert.match(landing, /READY/);
    assert.doesNotMatch(landing, /SESSION_SECRET|BUNDLE_PATH|session-secret/);
    assert.match(await client.get('/ruby/'), /Good work starts here/);
    assert.match(await client.get('/ruby/tickets'), /30 tickets/);
    const pageOne = await client.get('/ruby/tickets?q=our&page=1');
    assert.match(pageOne, /q=our/);
    const nextLink = decode(pageOne.match(/href="([^"]+)">Next<\/a>/)[1]);
    assert.equal(new URL(nextLink, app.base).searchParams.get('q'), 'our');
    assert.match(await client.get(nextLink), /Page 2 of 2/);
    const first = await client.get('/ruby/tickets');
    assert.equal((first.match(/class="ticket-link"/g) || []).length, 20);
    assert.match(await client.get('/ruby/tickets?page=2'), /Page 2 of 2/);
    assert.match(await client.get('/ruby/tickets?page=-20'), /Page 1 of 2/);
    assert.match(await client.get('/ruby/tickets?page=999'), /Page 2 of 2/);
    assert.match(await client.get('/ruby/tickets?q=definitely-missing'), /No tickets found/);
    assert.match(await client.get('/ruby/tickets?status=open&priority=low&assignee=unassigned'), /3 tickets/);
    assert.match(await client.get('/ruby/tickets?status=active'), /20 tickets/);
    assert.match(await client.get('/ruby/tickets?status=active&priority=urgent'), /5 tickets/);
    assert.match(await client.get('/ruby/tickets?q=%27%20OR%201%3D1--'), /0 tickets/);
    assert.match(await client.get('/ruby/tickets?q=%25'), /0 tickets/);
    assert.match(await client.get('/ruby/tickets?q=_'), /0 tickets/);

    const invalid = await client.request('/ruby/tickets', {
        method: 'POST', headers: { 'content-type': 'application/x-www-form-urlencoded' }, body: 'ticket[title]=forged'
    });
    assert.equal(invalid.response.status, 403, 'Missing CSRF is rejected');
    await client.post('/ruby/tickets/new', '/ruby/tickets', {
        'ticket[title]': '', 'ticket[description]': '', 'ticket[status]': 'bogus', 'ticket[priority]': 'bogus'
    }, 422);
    await client.post('/ruby/tickets/new', '/ruby/tickets', {
        'ticket[title]': 'Invalid customer', 'ticket[description]': 'Must not create an orphan ticket.',
        'ticket[customer_id]': '999999', 'ticket[assignee_id]': '999999', 'ticket[status]': 'open', 'ticket[priority]': 'normal'
    }, 422);
    await client.post('/ruby/customers/new', '/ruby/customers', {
        'customer[name]': '', 'customer[company]': '', 'customer[email]': 'invalid'
    }, 422);

    const customer = location(await client.post('/ruby/customers/new', '/ruby/customers', {
        'customer[name]': 'Casey <script>alert(1)</script>', 'customer[company]': 'Acceptance Workshop', 'customer[email]': 'casey@example.test'
    }), '/ruby/customers/');
    const customerId = customer.split('/').at(-1);
    assert.match(await client.get(customer), /&lt;script&gt;/);
    await client.post(customer + '/edit', customer, {
        'customer[name]': 'Casey <script>alert(1)</script>', 'customer[company]': 'Acceptance Workshop Updated', 'customer[email]': 'casey@example.test'
    });
    const ticket = location(await client.post('/ruby/tickets/new', '/ruby/tickets', {
        'ticket[title]': 'Acceptance <script>alert(1)</script>', 'ticket[description]': 'Find the customer’s next step.\nKeep this detail.',
        'ticket[customer_id]': customerId, 'ticket[assignee_id]': '', 'ticket[priority]': 'urgent', 'ticket[status]': 'open'
    }), '/ruby/tickets/');
    app.ticket = ticket;
    const detail = await client.get(ticket);
    assert.match(detail, /Acceptance &lt;script&gt;/);
    assert.doesNotMatch(detail, /<script>alert/);
    assert.match(detail, /Acceptance Workshop Updated/);
    await client.post('/ruby/', '/ruby/identity', { agent_id: '3' });
    await client.post(ticket, ticket + '/comments', { 'comment[body]': '' }, 422);
    await client.post(ticket, ticket + '/comments', { 'comment[body]': 'Acceptance update <b>safe text</b>', 'comment[agent_id]': '1' });
    const conversation = await client.get(ticket);
    const update = conversation.match(/<article class="comment">[\s\S]*?<\/article>/g).find(article => article.includes('Acceptance update'));
    assert.match(update, /Sam Rivera/);
    assert.doesNotMatch(update, /Maya Chen/);
    assert.match(update, /Acceptance update &lt;b&gt;safe text&lt;\/b&gt;/);
    await client.post(ticket + '/edit', ticket, {
        'ticket[title]': 'Acceptance <script>alert(1)</script>', 'ticket[description]': 'Find the customer’s next step.',
        'ticket[customer_id]': customerId, 'ticket[assignee_id]': '2', 'ticket[priority]': 'high', 'ticket[status]': 'in_progress'
    });
    let filtered = await client.get('/ruby/tickets?q=Acceptance&status=in_progress&priority=high&assignee=2');
    assert.match(filtered, /1 tickets/);
    assert.match(filtered, /Jordan Ellis/);
    await client.post(ticket + '/edit', ticket, {
        'ticket[title]': 'Acceptance <script>alert(1)</script>', 'ticket[description]': 'Find the customer’s next step.',
        'ticket[customer_id]': customerId, 'ticket[assignee_id]': '2', 'ticket[priority]': 'high', 'ticket[status]': 'resolved'
    });
    assert.match(await client.get(customer), /Acceptance &lt;script&gt;/);
    assert.match(await client.get('/ruby/tickets?q=Acceptance&status=resolved'), /1 tickets/);
    await client.get('/ruby/tickets/999999', 404);
    await client.get('/ruby/customers/999999', 404);
    await client.get('/ruby/unknown', 404);
    const css = await client.request('/ruby/assets/desk.css');
    assert.equal(css.response.status, 200);
    assert.match(css.response.headers.get('content-type'), /text\/css/);
    for (const uri of ['/app/config.ru', '/app/Gemfile', '/app/Gemfile.lock', '/storage/desk.sqlite3', '/storage/session-secret', '/config/boxlang.json', '/modules/bx-jruby/box.json', '/box.json', '/task.cfc']) {
        await client.get(uri, 404);
    }
    assert.ok(client.cookies.has('_fieldwork_' + app.framework), 'Distinct session cookie name');
    await runBox(app, ['task', 'run', 'reset'], { expectFailure: true });
    console.log(app.framework + ': HTTP workflows, CSRF, escaping, filters and source isolation passed');
}

async function browserChecks() {
    const browser = await chromium.launch();
    try {
        const context = await browser.newContext();
        const page = await context.newPage();
        for (const [index, app] of apps.entries()) {
            await page.setViewportSize({ width: 1440, height: 1000 });
            await page.goto(app.base + '/ruby/');
            await page.getByRole('heading', { name: 'Good work starts here.' }).waitFor();
            await page.locator('#agent').selectOption(String(index + 2));
            await page.getByRole('button', { name: 'Switch agent' }).click();
            await page.screenshot({ path: path.join(output, app.framework + '-desktop.png'), fullPage: true });
            await page.setViewportSize({ width: 390, height: 844 });
            await page.goto(app.base + '/ruby/tickets');
            assert.ok(await page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth), 'No page-level mobile overflow');
            await page.screenshot({ path: path.join(output, app.framework + '-mobile.png'), fullPage: true });
            await page.goto(app.base + app.ticket);
            await page.getByRole('heading', { name: 'Conversation', exact: true }).waitFor();
            await page.screenshot({ path: path.join(output, app.framework + '-detail-mobile.png'), fullPage: true });
        }
        for (const [index, app] of apps.entries()) {
            await page.goto(app.base + '/ruby/');
            assert.equal(await page.locator('#agent').inputValue(), String(index + 2), 'Sessions isolated across localhost ports');
        }
        await context.close();
    } finally {
        await browser.close();
    }
    console.log('Desktop/mobile rendering and browser cookie isolation passed');
}

try {
    for (const [index, framework] of ['rails', 'sinatra', 'rack'].entries()) {
        const folder = path.join(output, framework + ' app');
        const source = path.join(root, framework);
        fs.cpSync(source, folder, {
            recursive: true,
            filter: sourcePath => !ignored.has(path.basename(sourcePath)) && sourcePath !== path.join(source, 'config')
        });
        const config = JSON.parse(fs.readFileSync(path.join(folder, 'server.json'), 'utf8'));
        assert.equal(config.web.http.port, 8081 + index);
        const port = await freePort();
        config.name += '-acceptance-' + process.pid;
        config.web.http.port = port;
        fs.writeFileSync(path.join(folder, 'server.json'), JSON.stringify(config, null, 4));
        const app = { framework, folder, base: 'http://127.0.0.1:' + port };
        apps.push(app);
        console.log(framework + ': installing released modules and preparing copied app');
        await runBox(app, ['install']);
        await runBox(app, ['task', 'run']);
        app.secret = fs.readFileSync(path.join(folder, 'storage/session-secret'), 'utf8');
        await runBox(app, ['server', 'start']);
        await workflow(app);
    }
    await browserChecks();
    for (const app of apps) {
        await runBox(app, ['server', 'stop']);
        await runBox(app, ['task', 'run']);
        assert.equal(fs.readFileSync(path.join(app.folder, 'storage/session-secret'), 'utf8'), app.secret);
        await runBox(app, ['server', 'start']);
        assert.match(await app.client.get('/ruby/tickets'), /31 tickets/);
        assert.match(await app.client.get(app.ticket), /Acceptance update/);
        await runBox(app, ['server', 'stop']);
        await runBox(app, ['task', 'run', 'reset']);
        await runBox(app, ['server', 'start']);
        assert.match(await new Client(app).get('/ruby/tickets'), /30 tickets/);
        assert.equal(fs.readFileSync(path.join(app.folder, 'storage/session-secret'), 'utf8'), app.secret);
        console.log(app.framework + ': restart persistence, idempotent setup and reset passed');
    }
    console.log('All acceptance checks passed. Artifacts: ' + output);
} finally {
    for (const app of apps) {
        try {
            await runBox(app, ['server', 'log']);
        } catch (error) {
            console.error('Could not collect server log: ' + error.message);
        }
        try {
            await runBox(app, ['server', 'stop']);
        } catch (error) {
            console.error('Server cleanup failed: ' + error.message);
        }
    }
}
