/** Attempt every shutdown and fail the run without masking an earlier test error. */
export async function cleanupServers(apps, runBox) {
    let shutdownFailed = false;
    for (const app of apps) {
        try {
            await runBox(app, ['server', 'log']);
        } catch (error) {
            console.error('Could not collect server log: ' + error.message);
        }
        try {
            await runBox(app, ['server', 'stop']);
        } catch (error) {
            shutdownFailed = true;
            console.error('Server cleanup failed: ' + error.message);
        }
    }
    if (shutdownFailed && !process.exitCode) {
        process.exitCode = 1;
    }
}
