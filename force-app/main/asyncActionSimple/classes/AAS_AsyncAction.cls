/**
 * @description Contains common logic for AsyncActions.
 *
 * @author: Sergei Krivorotov
 * @date: 1/5/2024
 */
public abstract class AAS_AsyncAction implements Queueable, Database.AllowsCallouts {

    protected Integer availableAttempts = 1;
    protected Integer currentDepth = 0;
    protected Integer delay = 0;

    public abstract void executeAction();
    public abstract Type getType();

    public Integer getAvailableAttempts() {
        return availableAttempts;
    }

    public void setAvailableAttempts(Integer availableAttempts) {
        if (availableAttempts < 1) throw new AAS_AsyncActionException('Please set correct value for the Available Attempts (equals or more than 1)');
        this.availableAttempts = availableAttempts;
    }

    public virtual Integer getDelay() {
        return delay;
    }

    public void setDelay(Integer delay) {
        if (delay < 0 || delay > 10) throw new AAS_AsyncActionException('Please set correct Delay (form 0 to 10)');
        this.delay = delay;
    }

    @TestVisible
    protected virtual void handleFailure(Exception e) {
        System.debug('Can\'t Execute Action for the ' + getType().getName() + '\n\nError Message: ' + e.getMessage());
    }

    public void execute(QueueableContext queueableContext) {
        try {
            currentDepth = AsyncInfo.getCurrentQueueableStackDepth();
            executeAction();
        } catch (Exception e) {
            if (availableAttempts > currentDepth) {
                AAS_AsyncActionUtils.publishAsyncAction(this);
            } else {
                handleFailure(e);
            }
        }
    }

}