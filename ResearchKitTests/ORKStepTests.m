/*
 Copyright (c) 2015, Ricardo Sánchez-Sáez.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


@import XCTest;
@import ResearchKit;
@import ResearchKit.Private;


@interface ORKStepTests : XCTestCase

@end


@implementation ORKStepTests

- (void)testFormStep {
    // Test duplicate form step identifier validation
    ORKFormStep *formStep = [[ORKFormStep alloc] initWithIdentifier:@"form" title:@"Form" text:@"Form test"];
    NSMutableArray *items = [NSMutableArray new];
    
    ORKFormItem *item = nil;
    item = [[ORKFormItem alloc] initWithIdentifier:@"formItem1"
                                              text:@"formItem1"
                                      answerFormat:[ORKNumericAnswerFormat decimalAnswerFormatWithUnit:nil]];
    [items addObject:item];

    item = [[ORKFormItem alloc] initWithIdentifier:@"formItem2"
                                              text:@"formItem2"
                                      answerFormat:[ORKNumericAnswerFormat decimalAnswerFormatWithUnit:nil]];
    [items addObject:item];

    [formStep setFormItems:items];
    XCTAssertNoThrow([formStep validateParameters]);

    item = [[ORKFormItem alloc] initWithIdentifier:@"formItem2"
                                              text:@"formItem2"
                                      answerFormat:[ORKNumericAnswerFormat decimalAnswerFormatWithUnit:nil]];
    [items addObject:item];

    [formStep setFormItems:items];
    XCTAssertThrows([formStep validateParameters]);
}

- (void)testReactionTimeStep {
    ORKReactionTimeStep *validReactionTimeStep = [[ORKReactionTimeStep alloc] initWithIdentifier:@"ReactionTimeStep"];
    
    validReactionTimeStep.maximumStimulusInterval = 8;
    validReactionTimeStep.minimumStimulusInterval = 4;
    validReactionTimeStep.thresholdAcceleration = 0.5;
    validReactionTimeStep.numberOfAttempts = 3;
    validReactionTimeStep.timeout = 10;

    XCTAssertNoThrow([validReactionTimeStep validateParameters]);
    
    ORKReactionTimeStep *reactionTimeStep = [validReactionTimeStep copy];
    XCTAssertEqualObjects(reactionTimeStep, validReactionTimeStep);

    // minimumStimulusInterval cannot be zero or less
    reactionTimeStep = [validReactionTimeStep copy];
    validReactionTimeStep.minimumStimulusInterval = 0;
    XCTAssertThrows([validReactionTimeStep validateParameters]);

    // minimumStimulusInterval cannot be higher than maximumStimulusInterval
    reactionTimeStep = [validReactionTimeStep copy];
    validReactionTimeStep.maximumStimulusInterval = 8;
    validReactionTimeStep.minimumStimulusInterval = 10;
    XCTAssertThrows([validReactionTimeStep validateParameters]);

    // thresholdAcceleration cannot be zero or less
    reactionTimeStep = [validReactionTimeStep copy];
    validReactionTimeStep.thresholdAcceleration = 0;
    XCTAssertThrows([validReactionTimeStep validateParameters]);

    // timeout cannot be zero or less
    reactionTimeStep = [validReactionTimeStep copy];
    validReactionTimeStep.timeout = 0;
    XCTAssertThrows([validReactionTimeStep validateParameters]);

    // numberOfAttempts cannot be zero or less
    reactionTimeStep = [validReactionTimeStep copy];
    validReactionTimeStep.numberOfAttempts = 0;
    XCTAssertThrows([validReactionTimeStep validateParameters]);
}

- (void)testPageResult {
    
    NSArray *steps = @[[[ORKStep alloc] initWithIdentifier:@"step1"],
                       [[ORKStep alloc] initWithIdentifier:@"step2"],
                       [[ORKStep alloc] initWithIdentifier:@"step3"],
                       ];
    ORKPageStep *pageStep = [[ORKPageStep alloc] initWithIdentifier:@"pageStep" steps:steps];
    
    ORKChoiceQuestionResult *step1Result1 = [[ORKChoiceQuestionResult alloc] initWithIdentifier:@"step1.result1"];
    step1Result1.choiceAnswers = @[ @(1) ];
    ORKChoiceQuestionResult *step1Result2 = [[ORKChoiceQuestionResult alloc] initWithIdentifier:@"step1.result2"];
    step1Result2.choiceAnswers = @[ @(2) ];
    ORKChoiceQuestionResult *step2Result1 = [[ORKChoiceQuestionResult alloc] initWithIdentifier:@"step2.result1"];
    step2Result1.choiceAnswers = @[ @(3) ];
    
    ORKStepResult *inputResult = [[ORKStepResult alloc] initWithStepIdentifier:@"pageStep"
                                                                       results:@[step1Result1, step1Result2, step2Result1]];
    
    ORKPageResult *pageResult = [[ORKPageResult alloc] initWithPageStep:pageStep stepResult:inputResult];
    
    // Check steps going forward
    ORKStep *step1 = [pageStep stepAfterStepWithIdentifier:nil withResult:pageResult];
    XCTAssertNotNil(step1);
    XCTAssertEqualObjects(step1.identifier, @"step1");
    
    ORKStep *step2 = [pageStep stepAfterStepWithIdentifier:@"step1" withResult:pageResult];
    XCTAssertNotNil(step2);
    XCTAssertEqualObjects(step2.identifier, @"step2");
    
    ORKStep *step3 = [pageStep stepAfterStepWithIdentifier:@"step2" withResult:pageResult];
    XCTAssertNotNil(step3);
    XCTAssertEqualObjects(step3.identifier, @"step3");
    
    ORKStep *step4 = [pageStep stepAfterStepWithIdentifier:@"step3" withResult:pageResult];
    XCTAssertNil(step4);
    
    // Check steps going backward
    ORKStep *backStep2 = [pageStep stepBeforeStepWithIdentifier:@"step3" withResult:pageResult];
    XCTAssertEqualObjects(backStep2, step2);
    
    ORKStep *backStep1 = [pageStep stepBeforeStepWithIdentifier:@"step2" withResult:pageResult];
    XCTAssertEqualObjects(backStep1, step1);
    
    ORKStep *backStepNil = [pageStep stepBeforeStepWithIdentifier:@"step1" withResult:pageResult];
    XCTAssertNil(backStepNil);
    
    // Check identifier
    XCTAssertEqualObjects([pageStep stepWithIdentifier:@"step1"], step1);
    XCTAssertEqualObjects([pageStep stepWithIdentifier:@"step2"], step2);
    XCTAssertEqualObjects([pageStep stepWithIdentifier:@"step3"], step3);
}

- (void)testStep {
    ORKStep *step = [[ORKStep alloc] initWithIdentifier:@"STEP"];
    ORKOrderedTask *task = [[ORKOrderedTask alloc] initWithIdentifier:@"TASK" steps:NULL];
    ORKResult *result = [[ORKResult alloc] initWithIdentifier:@"RESULT"];
    
    [step setTitle:@"Title"];
    [step setText:@"Text"];
    [step setTask:task];
    
    ORKStepViewController *controller = [step instantiateStepViewControllerWithResult:result];
    
    XCTAssertEqual([step title], @"Title");
    XCTAssertEqual([step text], @"Text");
    XCTAssertEqual([step task], task);
    XCTAssertEqual([controller restorationIdentifier], [step identifier]);
    XCTAssertEqual([controller restorationClass], [step stepViewControllerClass]);
    XCTAssertEqual([controller step], step);
    XCTAssertEqual([step stepViewControllerClass], [ORKStepViewController class]);
    XCTAssertEqual([step isRestorable], YES);
    XCTAssert([step.identifier isEqualToString:@"STEP"]);
    XCTAssert([step isEqual:step]);
    XCTAssertEqual([step requestedPermissions], ORKPermissionNone);
    XCTAssertEqualObjects([step requestedHealthKitTypesForReading], nil);
}

- (void)testORKNavigablePageStep {
    ORKQuestionStep *stepOne = [ORKQuestionStep questionStepWithIdentifier:@"stepOne"
                                                                     title:@"QUESTION"
                                                                  question:@"Which step do we go to?"
                                                                    answer:[ORKAnswerFormat booleanAnswerFormat]];
    
    ORKStep *stepTwo = [[ORKStep alloc] initWithIdentifier:@"stepTwo"];
    ORKStep *stepThree = [[ORKStep alloc] initWithIdentifier:@"stepThree"];
    ORKStep *stepFour = [[ORKStep alloc] initWithIdentifier:@"stepFour"];
    
    NSArray *steps = [NSArray arrayWithObjects:stepOne, stepTwo, stepThree, stepFour, nil];
    ORKNavigableOrderedTask *task = [[ORKNavigableOrderedTask alloc] initWithIdentifier:@"task" steps:steps];
    
    ORKBooleanQuestionResult *result = [[ORKBooleanQuestionResult alloc] initWithIdentifier:@"stepOne.result"];
    result.booleanAnswer = @(YES);
    
    ORKStepResult *stepResult = [[ORKStepResult alloc] initWithStepIdentifier:@"stepOne" results:@[result]];
    ORKTaskResult *taskResult = [[ORKTaskResult alloc] initWithIdentifier:@"task"];
    taskResult.results = @[stepResult];
    
    // Creating predicates
    ORKResultSelector *resultSelector = [ORKResultSelector selectorWithStepIdentifier:@"stepOne" resultIdentifier:@"stepOne.result"];
    NSPredicate *stepOneYes = [ORKResultPredicate predicateForBooleanQuestionResultWithResultSelector:resultSelector expectedAnswer:YES];
    NSPredicate *stepOneNo = [ORKResultPredicate predicateForBooleanQuestionResultWithResultSelector:resultSelector expectedAnswer:NO];
    
    // Creating navigation rule and setting it to task
    ORKStepNavigationRule *navigationRule = [[ORKPredicateStepNavigationRule alloc] initWithResultPredicates:@[stepOneYes, stepOneNo]
                                                                                  destinationStepIdentifiers:@[@"stepTwo", @"stepThree"]
                                                                                       defaultStepIdentifier:@"stepFour"];
    [task setNavigationRule:navigationRule forTriggerStepIdentifier:@"stepOne"];
    ORKNavigablePageStep *pageStep = [[ORKNavigablePageStep alloc] initWithIdentifier:@"pageStep" pageTask:task];
    
    // Check step if answer is YES
    ORKStep *nextStep = [pageStep stepAfterStepWithIdentifier:@"stepOne" withResult:taskResult];
    XCTAssert([nextStep.identifier isEqualToString:@"stepTwo"]);

    // Check step if answer is NO
    result.booleanAnswer = @(NO);
    stepResult = [[ORKStepResult alloc] initWithStepIdentifier:@"stepOne" results:@[result]];
    taskResult.results = @[stepResult];
    nextStep = [pageStep stepAfterStepWithIdentifier:@"stepOne" withResult:taskResult];
    XCTAssert([nextStep.identifier isEqualToString:@"stepThree"]);
    
    // Check step if answer is NULL
    result.booleanAnswer = NULL;
    stepResult = [[ORKStepResult alloc] initWithStepIdentifier:@"stepOne" results:@[result]];
    taskResult.results = @[stepResult];
    nextStep = [pageStep stepAfterStepWithIdentifier:@"stepOne" withResult:taskResult];
    XCTAssert([nextStep.identifier isEqualToString:@"stepFour"]);

}

- (void)testPasscodeStep {
    
    ORKPasscodeStep *step = [ORKPasscodeStep passcodeStepWithIdentifier:@"STEP" passcodeFlow:ORKPasscodeFlowAuthenticate];
    XCTAssert([step.identifier isEqualToString:@"STEP"]);
    XCTAssertEqual(step.passcodeFlow, ORKPasscodeFlowAuthenticate);
    XCTAssertEqual(step.passcodeType, ORKPasscodeType4Digit);
}

- (void)testPDFViewerStep {
    NSString *identifier = @"STEP";
    NSURL *url = [NSURL URLWithString:@"TESTINGURL"];
    
    ORKPDFViewerStep *step = [[ORKPDFViewerStep alloc] initWithIdentifier:identifier pdfURL:url];
    step.actionBarOption = ORKPDFViewerActionBarOptionExcludeShare;
    
    XCTAssertEqual([step identifier], identifier);
    XCTAssertEqual([step pdfURL], url);
    XCTAssertEqual([step actionBarOption], ORKPDFViewerActionBarOptionExcludeShare);
}

- (void)testRegistrationStep {
    NSString *identifier = @"STEP";
    NSString *title = @"TITLE";
    NSString *text = @"TEXT";
    
    NSString *pattern = @"^(?=.*\\d)(?=.*[a-z])(?=.*[A-Z]).{4,8}$";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionAnchorsMatchLines error:nil];
    
    ORKRegistrationStep *step = [[ORKRegistrationStep alloc] initWithIdentifier:identifier title:title text:text passcodeValidationRegularExpression:regex passcodeInvalidMessage:@"Invalid Password" options:ORKRegistrationStepDefault];
    
    XCTAssertEqual([step identifier], identifier);
    XCTAssertEqual([step title], title);
    XCTAssertEqual([step text], text);
    XCTAssertEqual([step options], ORKRegistrationStepDefault);
    XCTAssert([[[[step formItems] objectAtIndex:0] identifier] isEqualToString:@"ORKRegistrationFormItemEmail"]);
    XCTAssert([[[[step formItems] objectAtIndex:1] identifier] isEqualToString:@"ORKRegistrationFormItemPassword"]);
    XCTAssert([[[[step formItems] objectAtIndex:2] identifier] isEqualToString:@"ORKRegistrationFormItemConfirmPassword"]);
}

@end


