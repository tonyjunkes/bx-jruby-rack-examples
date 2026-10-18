import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import test from 'node:test';

const cleanupUrl = new URL('./cleanup.mjs', import.meta.url).href;
const expectedAttempts = ['rails:log', 'rails:stop', 'sinatra:log', 'sinatra:stop', 'rack:log', 'rack:stop'];

// Run in a child so assertions observe the real exit status without changing the test runner's status.
function runCleanup({ failures = [], initialExitCode = 0, failAcceptance = false } = {}) {
    const fixture = `
        import { cleanupServers } from ${JSON.stringify(cleanupUrl)};
        const failures = new Set(${JSON.stringify(failures)});
        const attempts = [];
        process.exitCode = ${initialExitCode};
        try {
            if (${failAcceptance}) {
                throw new Error('original acceptance failure');
            }
        } finally {
            await cleanupServers(['rails', 'sinatra', 'rack'], async (app, args) => {
                const operation = app + ':' + args[1];
                attempts.push(operation);
                if (failures.has(operation)) {
                    throw new Error(operation + ' failed');
                }
            });
            console.log(JSON.stringify(attempts));
        }
    `;
    const result = spawnSync(process.execPath, ['--input-type=module', '-e', fixture], {
        encoding: 'utf8', windowsHide: true, timeout: 10000
    });
    assert.ifError(result.error);
    assert.deepEqual(JSON.parse(result.stdout), expectedAttempts, 'Every app receives log and shutdown attempts');
    return result;
}

test('successful cleanup exits successfully', () => {
    const result = runCleanup();
    assert.equal(result.status, 0);
    assert.equal(result.stderr, '');
});

test('shutdown failures fail the process after attempting the remaining apps', () => {
    const result = runCleanup({ failures: ['rails:stop', 'rack:stop'] });
    assert.equal(result.status, 1);
    assert.match(result.stderr, /Server cleanup failed: rails:stop failed/);
    assert.match(result.stderr, /Server cleanup failed: rack:stop failed/);
});

test('log collection remains best effort and does not prevent shutdown', () => {
    const result = runCleanup({ failures: ['rails:log'] });
    assert.equal(result.status, 0);
    assert.match(result.stderr, /Could not collect server log: rails:log failed/);
});

test('cleanup preserves an existing failure exit code', () => {
    const result = runCleanup({ failures: ['rails:stop'], initialExitCode: 7 });
    assert.equal(result.status, 7);
    assert.match(result.stderr, /Server cleanup failed: rails:stop failed/);
});

test('cleanup does not replace the original acceptance error', () => {
    const result = runCleanup({ failures: ['rails:log', 'rails:stop'], failAcceptance: true });
    assert.equal(result.status, 1);
    assert.match(result.stderr, /original acceptance failure/);
    assert.match(result.stderr, /Server cleanup failed: rails:stop failed/);
});
