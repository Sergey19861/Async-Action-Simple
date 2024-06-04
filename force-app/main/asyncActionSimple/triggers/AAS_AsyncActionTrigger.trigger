/**
 * @author: Sergei Krivorotov
 * @date: 1/5/2024
 */
trigger AAS_AsyncActionTrigger on Async_Action__e (after insert) {
    Set<AAS_AsyncAction> actions = new Set<AAS_AsyncAction>();
    for (Async_Action__e event : (List<Async_Action__e>) Trigger.new) {
        Type actionType = Type.forName(event.Type__c);
        actions.add((AAS_AsyncAction) JSON.deserialize(event.Body__c, actionType));
    }
    AAS_AsyncActionExecutor.execute(actions);
}