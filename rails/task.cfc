/** Prepare this standalone example using the JRuby distributed by bx-jruby. */
component {
    property name="serverService" inject="ServerService";

    /** Install locked gems and prepare the database before starting CommandBox. */
    function run() {
        var root = getDirectoryFromPath(getCurrentTemplatePath());
        assertStopped(root);
        var jars = directoryList(root & "modules/bx-jruby/libs", false, "path", "jruby-complete-*.jar");
        if (arrayLen(jars) != 1 || !directoryExists(root & "modules/bx-jruby-rack/gateway")) {
            throw(message="Run box install before setup.");
        }
        directoryCreate(root & "config", true, true);
        directoryCreate(root & "storage", true, true);
        var secretPath = root & "storage/session-secret";
        if (!fileExists(secretPath)) {
            var random = createObject("java", "java.security.SecureRandom").init();
            var bytes = random.generateSeed(64);
            fileWrite(secretPath, toBase64(bytes));
        }
        var runtimeEnv = {
            "BUNDLE_PATH": root & "bundles/ruby-app",
            "DESK_DATABASE": root & "storage/desk.sqlite3",
            "SESSION_SECRET": trim(fileRead(secretPath)),
            "RAILS_ENV": "development"
        };
        var homePath = root & ".boxlang";
        var configPath = root & "config/boxlang.json";
        var config = {
            "modulesDirectory": [root & "modules"],
            "modules": {"bxjrubyrack": {"settings": {"apps": [{
                "id": "fieldwork-rails", "root": root & "app", "mount": "/ruby",
                "environment": "development", "workers": 1, "bundler": {"frozen": true},
                "runtime": {"env": runtimeEnv}
            }]}}}
        };
        fileWrite(configPath, serializeJSON(config));
        var params = '<init-param><param-name>boxlang-home</param-name><param-value>' & xmlFormat(homePath) & '</param-value></init-param>'
            & '<init-param><param-name>boxlang-config-path</param-name><param-value>' & xmlFormat(configPath) & '</param-value></init-param>';
        fileWrite(root & "config/gateway.xml", '<?xml version="1.0" encoding="UTF-8"?>'
            & '<web-app xmlns="https://jakarta.ee/xml/ns/jakartaee" version="5.0">'
            & '<filter><filter-name>RubyRack</filter-name><filter-class>modules.bxjrubyrack.gateway.RackGateway</filter-class>'
            & params & '</filter><filter-mapping><filter-name>RubyRack</filter-name><url-pattern>/*</url-pattern><dispatcher>REQUEST</dispatcher></filter-mapping>'
            & '<servlet><servlet-name>BoxLangServlet</servlet-name><servlet-class>ortus.boxlang.servlet.BoxLangServlet</servlet-class>'
            & params & '<load-on-startup>1</load-on-startup></servlet>'
            & '<servlet-mapping><servlet-name>BoxLangServlet</servlet-name><url-pattern>*.bxm</url-pattern><url-pattern>*.bxs</url-pattern><url-pattern>*.bx</url-pattern></servlet-mapping>'
            & '<welcome-file-list><welcome-file>index.bxm</welcome-file></welcome-file-list></web-app>');
        runRuby(root, jars[1], runtimeEnv, ["-S", "bundle", "install"]);
        runRuby(root, jars[1], runtimeEnv, ["bin/prepare.rb"]);
        var serverConfig = deserializeJSON(fileRead(root & "server.json"));
        print.line("Ready. Run box server start, then open http://localhost:" & serverConfig.web.http.port & "/");
    }

    /** Explicitly recreate only this example's local database; preserve its session secret. */
    function reset() {
        var root = getDirectoryFromPath(getCurrentTemplatePath());
        assertStopped(root);
        var database = root & "storage/desk.sqlite3";
        for (var suffix in ["", "-wal", "-shm", "-journal"]) {
            if (fileExists(database & suffix)) {
                fileDelete(database & suffix);
            }
        }
        this.run();
    }

    /** Never migrate or reset a database while its registered web server is running. */
    private function assertStopped(required string root) {
        var details = serverService.resolveServerDetails({serverConfigFile: arguments.root & "server.json"});
        if (serverService.isServerRunning(details.serverInfo)) {
            throw(message="Stop this example with box server stop before running setup or reset.");
        }
    }

    /** Use argument arrays, including on paths with spaces; never construct a shell command. */
    private function runRuby(required string root, required string jar, required struct runtimeEnv, required array args) {
        var java = createObject("java", "java.lang.System").getProperty("java.home") & "/bin/java";
        var commandArgs = [java, "-jar", arguments.jar];
        arrayAppend(commandArgs, arguments.args, true);
        var builder = createObject("java", "java.lang.ProcessBuilder").init(commandArgs);
        builder.directory(createObject("java", "java.io.File").init(arguments.root & "app"));
        for (var key in arguments.runtimeEnv) {
            builder.environment().put(key, arguments.runtimeEnv[key]);
        }
        builder.environment().put("RACK_ENV", "development");
        builder.environment().put("BUNDLE_FROZEN", "true");
        builder.environment().put("BUNDLE_GEMFILE", arguments.root & "app/Gemfile");
        builder.inheritIO();
        if (builder.start().waitFor() != 0) {
            throw(message="Ruby setup failed. Fix the error above and run box task run again.");
        }
    }
}
