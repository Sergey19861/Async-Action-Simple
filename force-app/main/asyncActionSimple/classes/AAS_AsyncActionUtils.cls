/**
 * @description Contains service logic for the Async Action functionality
 *
 * @author: Sergei Krivorotov
 * @date: 1/9/2024
 */
public with sharing class AAS_AsyncActionUtils {

    public static Id enqueueJob(AAS_AsyncAction action) {
        AsyncOptions asyncOptions = new AsyncOptions();
        asyncOptions.maximumQueueableStackDepth = action.getAvailableAttempts();
        asyncOptions.minimumQueueableDelayInMinutes = action.getDelay();
        return System.enqueueJob(action, asyncOptions);
    }

    //Used to enqueue Async Action in separate transaction.
    public static void publishAsyncAction(AAS_AsyncAction action) {
        EventBus.publish(createAsyncEvent(action));
    }

    public static Async_Action__e createAsyncEvent(AAS_AsyncAction action) {
        return new Async_Action__e(
                Body__c = JSON.serialize(action),
                Type__c = action.getType().getName()
        );
    }

}