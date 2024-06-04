/**
 * @description Contains logic to enqueue Async Actions.
 *
 * @author: Sergei Krivorotov
 * @date: 1/5/2024
 */
public with sharing class AAS_AsyncActionExecutor {

    @TestVisible
    private static Boolean isTestRunning = false;

    public static void execute(AAS_AsyncAction action) {
        execute(new Set<AAS_AsyncAction>{action});
    }

    public static void execute(Set<AAS_AsyncAction> actions) {
        List<Async_Action__e> asyncActionEvents = new List<Async_Action__e>();
        for (AAS_AsyncAction action : actions) {
            if (isQueueableLimitNotReached() && isTestRunning() == false) {
                AAS_AsyncActionUtils.enqueueJob(action);
            } else {
                asyncActionEvents.add(AAS_AsyncActionUtils.createAsyncEvent(action));
            }
            if (asyncActionEvents.size() > 0) {
                EventBus.publish(asyncActionEvents);
            }
        }
    }

    private static Boolean isQueueableLimitNotReached() {
        return (Limits.getLimitQueueableJobs() - Limits.getQueueableJobs()) > 0;
    }

    private static Boolean isTestRunning() {
        return Test.isRunningTest() && isTestRunning;
    }

}