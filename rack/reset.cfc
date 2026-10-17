/** Keep the short `box task run reset` entry point while setup owns reset behavior. */
component {
    property name="taskService" inject="taskService@task-commands";

    /** Delegate to the setup task so server checks and database paths have one owner. */
    function run() {
        taskService.runTask(getDirectoryFromPath(getCurrentTemplatePath()) & "task.cfc", "reset");
    }
}
