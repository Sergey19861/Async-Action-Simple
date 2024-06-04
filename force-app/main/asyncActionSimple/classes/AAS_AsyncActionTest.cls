/**
 * @author: Sergei Krivorotov
 * @date: 1/5/2024
 */
@IsTest
private class AAS_AsyncActionTest {

    //used this variables due lost of results in separate transactions.
    private static String testResultPositive = '';
    private static String testResultNegative = '';

    private static final String NEGATIVE_RESULT = 'Negative Result';
    private static final Integer LIMIT_OF_QUEUEABLE_JOBS = 2;

    public with sharing class AsyncActionPositive extends AAS_AsyncAction {

        private Integer num;
        private Integer multiplier;
        private Account patient;

        private AsyncActionPositive(Integer num, Integer multiplier) {
            this.num = num;
            this.multiplier = multiplier;
        }

        public override void executeAction() {
            patient = new Account(Name = 'Test' + num * multiplier);
            testResultPositive = patient.Name;
        }

        public override Type getType() {
            return AsyncActionPositive.class;
        }
    }

    public with sharing class AsyncActionTestNegative extends AAS_AsyncAction {

        public override void executeAction() {
            insert new Account();
        }

        public override Type getType() {
            return AsyncActionTestNegative.class;
        }

        protected override void handleFailure(Exception e) {
            testResultNegative = NEGATIVE_RESULT;
        }
    }

    @IsTest
    static void testAsyncActionExecutor() {
        AsyncActionPositive action = new AsyncActionPositive(2, 3);
        Test.startTest();
        AAS_AsyncActionExecutor.execute(action);
        Test.stopTest();
        System.assert(testResultPositive.contains('6'));
    }

    @IsTest
    static void testAsyncActionTrigger() {
        AsyncActionPositive action = new AsyncActionPositive(2, 3);
        Test.startTest();
        AAS_AsyncActionExecutor.isTestRunning = true;
        AAS_AsyncActionExecutor.execute(action);
        AAS_AsyncActionExecutor.isTestRunning = false;
        System.assert([SELECT Id FROM AsyncApexJob WHERE Status = 'Queued'].size() == 0);
        Test.stopTest();
        System.assert([SELECT Id FROM AsyncApexJob WHERE Status = 'Queued'].size() == 1);
    }

    @IsTest
    static void testPublishAsyncAction() {
        AsyncActionPositive action = new AsyncActionPositive(2, 3);
        Test.startTest();
        AAS_AsyncActionUtils.publishAsyncAction(action);
        System.assert([SELECT Id FROM AsyncApexJob WHERE Status = 'Queued'].size() == 0);
        Test.stopTest();
        System.assert([SELECT Id FROM AsyncApexJob WHERE Status = 'Queued'].size() == 1);
    }

    @IsTest
    static void testAsyncActionExecutorList() {
        Set<AAS_AsyncAction> asyncActions = new Set<AAS_AsyncAction>();
        for (Integer i = 0; i < LIMIT_OF_QUEUEABLE_JOBS + 2; i++) {
            asyncActions.add(new AsyncActionPositive(2, 5));
        }
        Test.startTest();
        AAS_AsyncActionExecutor.execute(asyncActions);
        System.assert(testResultPositive.contains('10') == false);
        Test.stopTest();
        System.assert(testResultPositive.contains('10'));
    }

    @IsTest
    static void testFailedAction() {
        Integer amount = 20;
        Set<AAS_AsyncAction> failedActions = new Set<AAS_AsyncAction>();
        for (Integer i = 0; i < amount; i++) {
            AAS_AsyncAction negativeAction = new AsyncActionTestNegative();
            negativeAction.setDelay(1);
            negativeAction.setAvailableAttempts(2);
            failedActions.add(negativeAction);
            System.assert([SELECT Id FROM AsyncApexJob WHERE Status = 'Queued'].size() == 0);
        }
        Test.startTest();
        AAS_AsyncActionExecutor.execute(failedActions);
        Test.stopTest();
        System.assert([SELECT Id FROM AsyncApexJob WHERE Status = 'Queued'].size() == amount);
    }

    @IsTest
    static void testOverrideHandleFailure() {
        Test.startTest();
        AAS_AsyncActionExecutor.execute(new AsyncActionTestNegative());
        System.assert(testResultNegative == '');
        Test.stopTest();
        System.assert([SELECT Id FROM AsyncApexJob WHERE Status = 'Queued'].size() == 0);
        System.assert(testResultNegative == NEGATIVE_RESULT);
    }

}
